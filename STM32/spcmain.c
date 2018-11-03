#include "stm32f4xx.h"
#include "stm32_ub_fatfs.h"
#include "fpga.h"
#include "i2c.h"
#include "AXP209.h"
#include "ALC5628.h"
#include "btn.h"
#include "nes.h"
#include "snes.h"
#include "loader.h"

#include "grfx.h"

#include "string.h"

void Delay(int v) {
    for(volatile int i=0; i<100000*v; i++);
}


#pragma location = 0x20010000
uint8_t ram[65536] = {0};


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

int main()
{
    uint8_t buf[512];
	uint8_t vol = 0xB0;
	
	SystemInit();
	NVIC_PriorityGroupConfig(NVIC_PriorityGroup_4);
    
	uint16_t ttt;
    I2CInit();
    ALC5628_Init(vol);
    UB_Fatfs_Init();

	uint16_t buf16[256];
	uint32_t aaa = 0;
	
	DIR dir;
	FIL file; 
	uint32_t read, addr=0;
	uint8_t fbuf[512];
	uint8_t header[256], tail[256], smpregs[16];
	
	SnesSPC700Reg SPC700Regs;
	SnesSMPReg SMPRegs;

//	FPGA_Configure(0,0);
//	
//    if(UB_Fatfs_CheckMedia(MMC_0)==FATFS_OK) {
//        if(UB_Fatfs_Mount(MMC_0)==FATFS_OK) {
//			if (FR_OK == f_opendir(&dir, "0:")) {
//			}
//			if(UB_Fatfs_OpenFile(&file, "0:/SPCPlayer.bin", F_RD)==FATFS_OK) {	
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
	Delay(50);
	
	SNESControl(SNES_LOADER_EN);
	Delay(50);
	
	if(UB_Fatfs_CheckMedia(MMC_0)==FATFS_OK) {
        if(UB_Fatfs_Mount(MMC_0)==FATFS_OK) {
			if (FR_OK != f_opendir(&dir, "0:/SPC")) {
				while (1);
			}
			//if(UB_Fatfs_OpenFile(&file, "0:/SPC/axel-f.spc", F_RD)==FATFS_OK) {
			//if(UB_Fatfs_OpenFile(&file, "0:/SPC/btbm/btbm-12.spc", F_RD)==FATFS_OK) {
			if(UB_Fatfs_OpenFile(&file, "0:/SPC/ewj2/ewj2-07.spc", F_RD)==FATFS_OK) {
			//if(UB_Fatfs_OpenFile(&file, "0:/SPC/dkc/dkc-02.spc", F_RD)==FATFS_OK) {
                FATFS_t ret = UB_Fatfs_ReadBlock(&file, fbuf, 512, &read);
				memcpy(header, fbuf, 256);
				memcpy(smpregs, fbuf+0x1F0, 16);
				read -= 256;
				for (int i = 0; i < 256; i++) fbuf[i] = fbuf[i+256];
                while (read) {
					if (addr+read >= 65536) {
						SnesARAMWrite(addr, 256, fbuf);
						addr += 256;
					}
					else {
						SnesARAMWrite(addr, read, fbuf);
						addr += read;
					}
					if (addr >= 65536) break;
					ret = UB_Fatfs_ReadBlock(&file, fbuf, 512, &read);
                }
                memcpy(tail, fbuf+256, 256);
                UB_Fatfs_CloseFile(&file);
            }
            UB_Fatfs_UnMount(MMC_0);
        }
    }
	
	spc_file_t* spc_file = (spc_file_t*)header;
		
	SnesSPC700RegWrite(4,spc_file->pch);
	SnesSPC700RegWrite(3,spc_file->pcl);
	SnesSPC700RegWrite(0,spc_file->a);
	SnesSPC700RegWrite(1,spc_file->x);
	SnesSPC700RegWrite(2,spc_file->y);
	SnesSPC700RegWrite(5,spc_file->psw);
	SnesSPC700RegWrite(6,spc_file->sp);
	
	for (int i = 0; i < 16; i++) {
		SnesSMPRegWrite(i,smpregs[i]);//
	}
	
	SnesDSPRegsWrite(tail);
	
	LoaderVmuteSet(~0xff);
	
//	SMPSetBreakpoint(0xffffff);//0x978239 0x97c658
//	SMPRun(0);
	
	SNESControl(0);
	Delay(50);
	
	SNESControl(SNES_RST);
	
	while (1) {
		while (!(FPGA_SPI_RegRead(SNES_STAT) & (0x01)));
	
		SnesSPC700RegsRead(&SPC700Regs);
		SnesSMPRegsRead(&SMPRegs);
		SnesDSPRegsRead(ram);
		
		SnesARAMRead(0x0000, 0x1000, (uint8_t*)ram);
		
		SMPStep(1);
//		SMPRun();
 	}
}
