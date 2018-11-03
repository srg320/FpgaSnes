#include "stm32f4xx.h"
#include "fpga.h"
#include "i2c.h"
#include "ALC5628.h"
#include "lcd.h"
#include "stm32_ub_fatfs.h"

#include "snes.h"
#include "string.h"

void Delay(int v) {
    for(volatile int i=0; i<100000*v; i++);
}

#pragma location = 0x20010000
uint8_t ram[65536];

void CPUStep(int trace) {
	uint8_t temp = /*trace ? DBG_TRACE :*/ 0;
	SnesCPURegWrite(3, DBG_RUN | DBG_STEP | temp);
	Delay(10);
	SnesCPURegWrite(3, temp);
}

void CPURun(uint8_t value) {
	SnesCPURegWrite(3, value | DBG_RUN);
	Delay(10);
	SnesCPURegWrite(3, value & ~DBG_RUN);
}

void CPUSetBreakpoint(uint32_t value) {
	SnesCPURegWrite(0, (uint8_t)value);
	SnesCPURegWrite(1, (uint8_t)(value>>8));
	SnesCPURegWrite(2, (uint8_t)(value>>16));
}

void CPURun2() {
	CPUDebugControl(DBG_SCPU_BRK | DBG_SCPU_RUN | DBG_SCPU_RW);
	Delay(10);
	CPUDebugControl(DBG_SCPU_BRK | DBG_SCPU_RW);
}

void SMPStep(int trace) {
	uint8_t temp = 0;
	SnesSPC700RegWrite(3, DBG_RUN | DBG_STEP | temp);//
	Delay(10);
	SnesSPC700RegWrite(3, temp);//
}

void SMPRun(uint8_t value) {
	SnesSPC700RegWrite(3, value | DBG_RUN);
	Delay(10);
	SnesSPC700RegWrite(3, value & ~DBG_RUN);
}

void SMPSetBreakpoint(uint32_t value) {
	SnesSPC700RegWrite(0, (uint8_t)value);
	SnesSPC700RegWrite(1, (uint8_t)(value>>8));
	SnesSPC700RegWrite(2, (uint8_t)(value>>16));
}

void MapStep(int trace) {
	CPUDebugControl(DBG_MAP_BRK | DBG_MAP_RUN | DBG_STEP);//
	Delay(10);
	CPUDebugControl(DBG_MAP_BRK);//
}

void MapRun() {
	CPUDebugControl(DBG_MAP_BRK | DBG_MAP_RUN);
	Delay(10);
	CPUDebugControl(DBG_MAP_BRK);
}


void GetMapper(SnesRomHeader* loheader, SnesRomHeader* hiheader, SnesRomHeader* exhiheader, 
			   uint8_t* mapCtrl, uint8_t* mapSize) {
	SnesRomHeader* header = 0;
	if ((loheader->MapMode & 0xE0) == 0x20 && 
		(loheader->Checksum + loheader->CSComp == 0xFFFF || (loheader->MapMode & 0x0F) == 0x00 || (loheader->MapMode & 0x0F) == 0x02)) {
		header = loheader;
	}
	else if ((exhiheader->MapMode & 0xE0) == 0x20 && 
			 (exhiheader->Checksum + exhiheader->CSComp == 0xFFFF || (exhiheader->MapMode & 0x0F) == 0x05)) {
		header = exhiheader;
	}
	else if ((hiheader->MapMode & 0xE0) == 0x20 && 
			 (hiheader->Checksum + hiheader->CSComp == 0xFFFF || (hiheader->MapMode & 0x0F) == 0x01)) {
		header = hiheader;
	}
	else {
		header = 0;
	}
	
	if (header) {
		*mapCtrl = header->MapMode & 0x0F;
		if ((header->Region >= 0x02 && header->Region <= 0x0C) || header->Region == 0x11) { //PAL Regions
			*mapCtrl |= 0x80;
		}
		
		if (header->MapMode == 0x20 && header->RomType == 0x05) {	//DSP2
			*mapCtrl |= 0x10;
	  	} 
		else if (header->MapMode == 0x30 && header->RomType == 0x05 && header->Company == 0xb2) {	//DSP3
			*mapCtrl |= 0x20;
		}
		else if (header->MapMode == 0x30 && header->RomType == 0x03) {	//DSP4
			*mapCtrl |= 0x30;
		}
		
		
		*mapSize = ((header->RamSize & 0x0F) << 4) | (header->RomSize & 0x0F);
		
		if ((header->RomSize & 0x0F) < 5) {
			*mapSize &= ~0x0F;
			*mapSize |= 0x0C;
		}
	}
	else {
		*mapCtrl = 0x20;
		*mapSize = 0x0C;
	}
}

uint16_t CalcCRC(uint8_t* data, uint32_t len) {
	uint16_t temp = 0;
	for (uint32_t i = 0; i < len; i++) {
		temp += data[i];
	}
	return temp;
}


int main()
{
    uint8_t buf[512];
	uint8_t vol = 0xB0;
	
	SystemInit();
	NVIC_PriorityGroupConfig(NVIC_PriorityGroup_4);
    
    I2CInit();
	ALC5628_Init(vol);
    UB_Fatfs_Init();

	for(int i=0; i<65536; i++) ram[i] = 0;
	uint16_t buf16[256];
	uint32_t aaa = 0;
	
	GPIO_InitTypeDef GPIO_InitStructure;
    
    RCC_AHB1PeriphClockCmd(LCD_BL_GPIO_CLK, ENABLE);
	
	/* Configure GPIO PIN for LCD Backlight */
    GPIO_InitStructure.GPIO_Pin = LCD_BL_PIN;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
    GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(LCD_BL_GPIO_PORT, &GPIO_InitStructure);

    GPIO_SetBits(LCD_BL_GPIO_PORT, LCD_BL_PIN);
	
	
	DIR dir;
	FIL file; 
	uint32_t read, addr=0;
	uint8_t fbuf[512];
	uint16_t crc16 = 0;
	
	SnesRomHeader loheader, hiheader, exhiheader;
	uint8_t mapCtrl, mapSize;

//	FPGA_Configure(0,0);
//	
//    if(UB_Fatfs_CheckMedia(MMC_0)==FATFS_OK) {
//        if(UB_Fatfs_Mount(MMC_0)==FATFS_OK) {
//			if (FR_OK == f_opendir(&dir, "0:")) {
//			}
//			if(UB_Fatfs_OpenFile(&file, "0:/snes.bin", F_RD)==FATFS_OK) {	
//                FATFS_t ret = UB_Fatfs_ReadBlock(&file, fbuf, 512, &read);
//                while (read) {
//                    if (FPGA_SendBytes(fbuf, read) > 0)
//						break;
//					
//                    ret = UB_Fatfs_ReadBlock(&file, fbuf, 512, &read);
//                }
//                
//                UB_Fatfs_CloseFile(&file);
//            }
//            UB_Fatfs_UnMount(MMC_0);
//        }
//    }
	
    FPGA_SPI_Init();
	
	SNESControl(SNES_LOADER_EN | SNES_RST);
	Delay(100);
	
	SNESControl(SNES_LOADER_EN | SNES_CART_EN);
	LoaderAddrSet(0);
	
    if(UB_Fatfs_CheckMedia(MMC_0)==FATFS_OK) {
        if(UB_Fatfs_Mount(MMC_0)==FATFS_OK) {
			if (FR_OK == f_opendir(&dir, "0:")) {
			}
            if(UB_Fatfs_OpenFile(&file, 
			//"0:/8x8BG1Map2BPP32x328PAL.sfc"
			//"0:/8x8BGMap8BPP64x64.sfc"
			//"0:/8x8BGMapTileFlip.sfc"
			//"0:/WindowHDMA.sfc"
			//"0:/Mode7HDMA.sfc"
			//"0:/MosaicMode5.sfc"
			//"0:/RedSpaceHDMA.sfc"
			//"0:/Perspective.sfc"
			//"0:/HiColor3840.sfc"
			//"0:/InterlaceSimpsonsHDMA.sfc"
			//"0:/dma.sfc"		
			//"0:/test_hdmasync.smc"	
			//"0:/test_hdmatiming.smc"	
            	//"0:/test.sfc"
            	"0:/SNES Burn-in Test.sfc"
			//"0:/ppubusact.sfc"
			//"0:/Axel-F.sfc"
			//"0:/blargg_near_cd_quality2.smc"
			//"0:/Aaahh!!! Real Monsters.sfc"
			//"0:/Addams Family.sfc"
			//"0:/Alien 3.sfc"
			//"0:/Aladdin.sfc"		
			//"0:/Asterix & Obelix.sfc"	//PAL!!!
			//"0:/Battlemaniacs.sfc"	
			//"0:/Battletoads Double Dragon.sfc"
			//"0:/Batman Returns.sfc"	
			//"0:/Batman - Revenge Joker.sfc"	//not HIROM!!!	
			//"0:/Boogerman.sfc"
			//"0:/Bugs Bunny.sfc"
			//"0:/Chrono Trigger.sfc"		//HIROM
			//"0:/Clay Fighter.sfc"	
			//"0:/Clay Fighter Tournament Edition.sfc"
			//"0:/Clay Fighter 2.sfc"
			//"0:/Contra 3.sfc"	
			//"0:/Daffy Duck.sfc"
			//"0:/Donkey Kong Country.sfc"	//HIROM		
			//"0:/Dragon Quest 3.sfc"	//HIROM		
			//"0:/Dragon Quest 6.sfc"	//HIROM		
			//"0:/Dr Mario.sfc"	
			//"0:/Earthworm Jim.sfc"		//HIROM
			//"0:/Earthworm Jim 2.sfc"		//HIROM 
			//"0:/Final Fantasy 3.sfc"		//HIROM		
			//"0:/Final Fantasy 5.sfc"		//HIROM	
			//"0:/Flintstones - Treasure Sierra Madrock.sfc"	
			//"0:/Flintstones.sfc"
			//"0:/Gradius 3.sfc"
			//"0:/Indiana Jones Greatest Adventures.sfc"
			//"0:/Joe Mac.sfc"
			//"0:/Joe Mac 2.sfc" // ppu!!!
			//"0:/JoeMac3.sfc"	//PAL
			//"0:/Jungle Book.sfc"		
			//"0:/Jurassic Park.sfc"
			//"0:/Jurassic Park 2.sfc"					 
			//"0:/Killer Instinct.sfc"
			//"0:/Last Action Hero.sfc"
			//"0:/Lethal Weapon.sfc"
			//"0:/Lion King.sfc"	//HIROM	
			//"0:/Lord Rings.sfc"
			//"0:/Mask.sfc"
			//"0:/Mega Man X.sfc"
			//"0:/Mickeys Playtown Adventure.sfc"		//HIROM	
			//"0:/Mickey Mania.sfc"
			//"0:/Mortal Kombat.sfc"
			//"0:/Mortal Kombat 2.sfc"	//HIROM	
			//"0:/Mortal Kombat 3.sfc"	//HIROM	
			//"0:/Pitfall.sfc"
			//"0:/Prince Persia.sfc"
			//"0:/Prince Persia 2.sfc"
			//"0:/Rise Robots.sfc"	//HIROM		
			//"0:/Robocop 3.sfc"
			//"0:/Robo Cop Vs Terminator.sfc"
			//"0:/Rock Roll Racing.sfc"	
			//"0:/Rockman Forte (tr 1).sfc"
			//"0:/Road Runners Death Valley Rally.sfc"	
			//"0:/Romance Three Kingdoms 4.sfc"	
			//"0:/Sea Quest DSV.sfc"	
			//"0:/Seiken Densetsu 3 (E).sfc"	//HIROM	
			//"0:/Sim City.sfc"
			//"0:/Simpsons.sfc"	
			//"0:/Stargate.sfc"
			//"0:/Super Adventure Island.sfc"
			//"0:/Super Battle Tank.sfc"
			//"0:/Super Bomber Man.sfc"	//HIROM
			//"0:/Super Castlevania 4.sfc"
			//"0:/Super Double Dragon.sfc" // old joy!!!
			//"0:/Super Mario World.sfc"
			//"0:/Super Metroid.sfc"	//
			//"0:/Super Star Wars.sfc" // old joy!!!	
			//"0:/Super Street Fighter 2.sfc"
			//"0:/Teenage Mutant Ninja Turtles 4.sfc"
			//"0:/Terminator 2.sfc"
			//"0:/Tetris Attack.sfc"
			//"0:/The Legend of Zelda - A Link to the Past.sfc"
			//"0:/Time Trax.sfc" 					 
			//"0:/Timon Pumbaas Jungle Games.sfc" //HIROM
			//"0:/Tiny Toon Adventures - Buster Busts Loose!.sfc"
			//"0:/Tiny Toon Adventures - Wacky Sports Challenge.sfc"	
			//"0:/Tom Jerry.sfc"
			//"0:/Toy Story.sfc"	//HIROM	
			//"0:/Ultimate Mortal Kombat 3.sfc"	//HIROM	
			//"0:/Wolfenstein 3 D.sfc"
			//"0:/Tales Phantasia (lc).sfc"	//EXHIROM	
			//"0:/badapple_exhi_hdma_indirect.sfc"	//EXHIROM	
			//"0:/Pilotwings.sfc"	//DSP1
			//"0:/Ballz 3 D.sfc"	//DSP1
			//"0:/Aim For The Ace!.sfc"	//DSP1
			//"0:/Battle Racers (J).sfc"	//DSP1
			//"0:/Super Mario Kart.sfc"	//DSP1
			//"0:/Dungeon Master.sfc"	//DSP2 					 
			//"0:/SD Gundam GX_.sfc"	//DSP3	
			//"0:/Street Fighter Alpha 2.sfc" //SDD1
			//"0:/Star Ocean (tr).sfc" //SDD1	
			//"0:/Mega Man X 2.sfc" //CX4
			//"0:/Mega Man X 3.sfc" //CX4	
				
			//"0:/Top Gear 3000.sfc"	//DSP4 ???????
			, F_RD)==FATFS_OK) {
                FATFS_t ret = UB_Fatfs_ReadBlock(&file, fbuf, 512, &read);
                while (read) {
                    SnesLoaderWrite(addr, read, fbuf);
                    addr += read;
					if (addr == 0x008000) {
						memcpy(&loheader, fbuf+512-64, sizeof(SnesRomHeader));
					}
					else if (addr == 0x010000) {
						memcpy(&hiheader, fbuf+512-64, sizeof(SnesRomHeader));
					}
					else if (addr == 0x410000) {
						memcpy(&exhiheader, fbuf+512-64, sizeof(SnesRomHeader));
					}
					crc16 += CalcCRC(fbuf, read);
                    ret = UB_Fatfs_ReadBlock(&file, fbuf, 512, &read);
                }
                crc16 -= 0xFF+0xFF;
                UB_Fatfs_CloseFile(&file);
            }
            UB_Fatfs_UnMount(MMC_0);
        }
    }
	SNESControl(SNES_LOADER_EN);
	
	GetMapper(&loheader, &hiheader, &exhiheader, &mapCtrl, &mapSize);

	
	SnesCPUReg CPURegs;
	SnesCPUReg2 CPURegs2;
	SnesDMAReg DMARegs[8];
	SnesPPUReg PPURegs;
	SnesSPC700Reg SPC700Regs;
	SnesSMPReg SMPRegs;
	SnesDSPnReg DSPnRegs;
	SnesCX4Reg CX4Regs;
	SnesSDD1Reg SDD1Regs;


	CPUSetBreakpoint(0xcc249C);//0x808a72 0x80a5e6 0x80e457 0x80b299 
//	CPURun(DBG_BP_OP | DBG_TRACE);
	CPURun(0);
	
	SnesMapperControl(mapCtrl);
	SnesMapperMask(GET_MASK(mapSize&0x0F), GET_MASK((mapSize>>4)&0x0F));
		
	SNESControl(SNES_RST);
	Delay(100);
	SNESControl(0);
	Delay(100);
	
	while (1) {
		while (!(FPGA_SPI_RegRead(SNES_STAT) & (0x01)));
	
		SnesCPURegsRead(&CPURegs);
		SnesCPURegs2Read(&CPURegs2);
		SnesDMARegsRead(&DMARegs[0]);
		SnesPPURegsRead(&PPURegs);
//		SnesSPC700RegsRead(&SPC700Regs);
//		SnesSMPRegsRead(&SMPRegs);
//		SnesDSPnRegsRead(&DSPnRegs);
//		SnesCX4RegsRead(&CX4Regs);
		SnesSDD1RegsRead(&SDD1Regs);
		
//		SnesDSPRegsRead(ram);
		
		SnesWRAMRead(0x010000, 0x8000, (uint8_t*)ram);
		
//		CPUStep(1);
		CPURun(DBG_BP_OP | DBG_TRACE);
//		SMPStep(1);
//		SMPRun();
//		MapStep(1);
//		MapRun();
 	}
}
