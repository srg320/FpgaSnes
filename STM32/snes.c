#include "snes.h"
#include "fpga.h"

static void SNESDebugSel(uint8_t value) {
	uint8_t buf[1];
	buf[0] = value;
	FPGA_SPI_RegWrite(SNES_DBGSEL, 1, buf);
}

static void SNESDebugRegWrite(uint8_t reg, uint8_t value) {
	uint8_t buf[1];
    buf[0] = reg;
	FPGA_SPI_RegWrite(SNES_DBGREG, 1, buf);
	buf[0] = value;
	FPGA_SPI_RegWrite(SNES_DBGWR, 1, buf);
}

static uint8_t SNESDebugRegRead(uint8_t reg) {
	uint8_t buf[1];
    buf[0] = reg;
	FPGA_SPI_RegWrite(SNES_DBGREG, 1, buf);
	return FPGA_SPI_RegRead(SNES_DBGRD);
}

void SNESControl(uint8_t value) {
    uint8_t buf[1];
    buf[0] = value;
    FPGA_SPI_RegWrite(SNES_CTRL, 1, buf);
}

void SnesPpuRegWrite(uint8_t reg, uint8_t value)
{
    uint8_t buf;

    FPGA_SPI_RegWrite(SNES_BUSADDR, 1, &reg);
    FPGA_SPI_RegWrite(SNES_BUSDATA, 1, &value);
    
    buf = 0x02;
    FPGA_SPI_RegWrite(SNES_BUSRW, 1, &buf);
	buf = 0x00;
    FPGA_SPI_RegWrite(SNES_BUSRW, 1, &buf);
}

uint8_t SnesPpuRegRead(uint8_t reg)
{
    uint8_t buf;

    FPGA_SPI_RegWrite(SNES_BUSADDR, 1, &reg);
    
    buf = 0x01;
    FPGA_SPI_RegWrite(SNES_BUSRW, 1, &buf);
	buf = 0x00;
    FPGA_SPI_RegWrite(SNES_BUSRW, 1, &buf);
	
	return FPGA_SPI_RegRead(SNES_BUSDATA);
}


void LoaderAddrSet(uint32_t addr) {
    uint8_t buf[3];
    buf[0] = addr;
    buf[1] = addr>>8;
    buf[2] = addr>>16;
    FPGA_SPI_RegWrite(SNES_LDADDR, 3, buf);
}

void SnesLoaderWrite(uint32_t addr, uint32_t len, uint8_t* buf)
{
	for (int i=0; i < len; i++) {
		//LoaderAddrSet(addr+i);
		FPGA_SPI_RegWrite(SNES_LDDATA, 1, &buf[i]);
	}
}

void SnesLoaderRead(uint32_t addr, uint32_t len, uint8_t* buf)
{
	for (int i=0; i < len; i++) {
		LoaderAddrSet(addr+i);
		buf[i] = FPGA_SPI_RegRead(SNES_LDDATA);
	}
}

void SnesCPURegsRead(SnesCPUReg* regs) {
    uint8_t temp = 0x01;
	FPGA_SPI_RegWrite(SNES_DBGSEL, 1, &temp);
	for (uint8_t i=0; i < sizeof(SnesCPUReg); i++) {
		FPGA_SPI_RegWrite(SNES_DBGREG, 1, &i);
		((uint8_t*)regs)[i] = FPGA_SPI_RegRead(SNES_DBGRD);
	}
}

void SnesCPURegs2Read(SnesCPUReg2* regs) {
	uint8_t temp = 0x02;
	FPGA_SPI_RegWrite(SNES_DBGSEL, 1, &temp);
	for (uint8_t i=0; i < sizeof(SnesCPUReg2)-sizeof(uint32_t); i++) {
		FPGA_SPI_RegWrite(SNES_DBGREG, 1, &i);
		((uint8_t*)regs)[i] = FPGA_SPI_RegRead(SNES_DBGRD);
	}
	
	temp = 0x04;
	FPGA_SPI_RegWrite(SNES_DBGSEL, 1, &temp);
	for (uint8_t i=sizeof(SnesCPUReg2)-sizeof(uint32_t), r=0; i < sizeof(SnesCPUReg2); i++,r++) {
		FPGA_SPI_RegWrite(SNES_DBGREG, 1, &r);
		((uint8_t*)regs)[i] = FPGA_SPI_RegRead(SNES_DBGRD);
	}
}

void SnesWRAMRead(uint32_t addr, uint32_t len, uint8_t* buf) {
	SNESDebugSel(0x04);
	
	for (int i=0; i < len; i++, addr++) {
		SNESDebugRegWrite(0x80, (uint8_t)addr);
		SNESDebugRegWrite(0x81, (uint8_t)(addr>>8));
		SNESDebugRegWrite(0x82, (uint8_t)(addr>>16));
		buf[i] = SNESDebugRegRead(0x80);
		
	}
}

void SnesVRAMRead(uint32_t addr, uint32_t len, uint8_t* buf) {
	SNESDebugSel(0x20);
	
	for (int i=0; i < len; i++, addr++) {
		if ((i&0x1) == 0) {
			SNESDebugRegWrite(0x80, (uint8_t)addr);
			SNESDebugRegWrite(0x81, (uint8_t)(addr>>8));
		
			buf[i] = SNESDebugRegRead(0x80);
		}
		else {
			buf[i] = SNESDebugRegRead(0x81);
		}
	}
}

void SnesARAMRead(uint32_t addr, uint32_t len, uint8_t* buf) {
	SNESDebugSel(0x40);
	
	for (int i=0; i < len; i++, addr++) {
		SNESDebugRegWrite(0x81, (uint8_t)addr);
		SNESDebugRegWrite(0x82, (uint8_t)(addr>>8));
		buf[i] = SNESDebugRegRead(0x80);
	}
}

void SnesARAMWrite(uint32_t addr, uint32_t len, uint8_t* buf) {
	SNESDebugSel(0x40);
	
	for (int i=0; i < len; i++, addr++) {
		SNESDebugRegWrite(0x81, (uint8_t)addr);
		SNESDebugRegWrite(0x82, (uint8_t)(addr>>8));
		SNESDebugRegWrite(0x80, *buf);
		buf++;
	}
}

void SnesDMARegsRead(SnesDMAReg* regs) {
	uint8_t temp = 0x02;
	FPGA_SPI_RegWrite(SNES_DBGSEL, 1, &temp);
	for (uint8_t i=0; i < sizeof(SnesDMAReg)*8; i++) {
		temp = i|0x80;
		FPGA_SPI_RegWrite(SNES_DBGREG, 1, &temp);
		((uint8_t*)regs)[i] = FPGA_SPI_RegRead(SNES_DBGRD);
	}
}

void SnesPPURegsRead(SnesPPUReg* regs) {
	uint8_t temp = 0x20;
	FPGA_SPI_RegWrite(SNES_DBGSEL, 1, &temp);
	for (uint8_t i=0; i < sizeof(SnesPPUReg); i++) {
		FPGA_SPI_RegWrite(SNES_DBGREG, 1, &i);
		((uint8_t*)regs)[i] = FPGA_SPI_RegRead(SNES_DBGRD);
	}
}


//Debug
void CPUDebugControl(uint8_t value) {
    uint8_t buf[1];
    buf[0] = value;
    FPGA_SPI_RegWrite(SNES_DBGCTL, 1, buf);
}

//void HVCounterSet(uint16_t h, uint16_t v) {
//    uint8_t buf[3];
//    buf[0] = (uint8_t)h;
//    buf[1] = (uint8_t)v;
//    buf[2] = ((h>>8)&0x01) | ((v>>7)&0x02);
//    FPGA_SPI_RegWrite(SNES_DBGHV, 3, buf);
//}

//CPU
void SnesCPURegWrite(uint8_t reg, uint8_t value)
{
	uint8_t temp = 0x01;
	FPGA_SPI_RegWrite(SNES_DBGSEL, 1, &temp);
	
	uint8_t buf[1];
    buf[0] = reg | 0x80;
	FPGA_SPI_RegWrite(SNES_DBGREG, 1, buf);
	buf[0] = value;
	FPGA_SPI_RegWrite(SNES_DBGWR, 1, buf);
}

//SMP
void SnesSPC700RegsRead(SnesSPC700Reg* regs) {
	SNESDebugSel(0x08);
	for (uint8_t i=0; i < sizeof(SnesSPC700Reg); i++) {
		((uint8_t*)regs)[i] = SNESDebugRegRead(i);
	}
}

void SnesSPC700RegWrite(uint8_t reg, uint8_t value)
{
	SNESDebugSel(0x08);
	SNESDebugRegWrite(reg, value);
}

void SnesSMPRegsRead(SnesSMPReg* regs) {
	SNESDebugSel(0x10);
	for (uint8_t i=0; i < sizeof(SnesSMPReg); i++) {
		((uint8_t*)regs)[i] = SNESDebugRegRead(i);
	}
}

void SnesSMPRegWrite(uint8_t reg, uint8_t value)
{
	SNESDebugSel(0x10);
	SNESDebugRegWrite(reg, value);
}

//DSP
void SnesDSPRegsRead(uint8_t* buf)
{
	SNESDebugSel(0x40);
	for (uint8_t i=0; i <= 0x7F; i++) {
		*buf = SNESDebugRegRead(i);
		buf++;
	}
}

void SnesDSPRegsWrite(uint8_t* buf)
{
	SNESDebugSel(0x40);
	for (uint8_t i=0; i <= 0x7F; i++) {
		SNESDebugRegWrite(i, *buf);
		buf++;
	}
}

void LoaderVmuteSet(uint8_t data) {
    SNESDebugSel(0x40);
	SNESDebugRegWrite(0x83, data);
}

//void SnesBgObjControl(uint16_t value) {
//    uint8_t buf[2];
//    buf[0] = (uint8_t)value;
//	buf[1] = (uint8_t)(value>>8);
//    FPGA_SPI_RegWrite(SNES_BGOBJCTL, 2, buf);
//}

//Mapper
void SnesMapperControl(uint8_t value) {
    uint8_t buf[1];
    buf[0] = value;
    FPGA_SPI_RegWrite(SNES_MAPCTL, 1, buf);
}

void SnesMapperMask(uint32_t rom, uint32_t sram) {
    uint8_t buf[3];
    buf[0] = rom;
    buf[1] = rom>>8;
    buf[2] = rom>>16;
    FPGA_SPI_RegWrite(SNES_MAPRMASK, 3, buf);
	buf[0] = sram;
    buf[1] = sram>>8;
    buf[2] = sram>>16;
    FPGA_SPI_RegWrite(SNES_MAPBSMASK, 3, buf);
}

void SnesDSPnRegsRead(SnesDSPnReg* regs) {
	uint8_t temp = 0x80;
	FPGA_SPI_RegWrite(SNES_DBGSEL, 1, &temp);
	for (uint8_t i=0; i < sizeof(SnesDSPnReg); i++) {
		FPGA_SPI_RegWrite(SNES_DBGREG, 1, &i);
		((uint8_t*)regs)[i] = FPGA_SPI_RegRead(SNES_DBGRD);
	}
}

void SnesCX4RegsRead(SnesCX4Reg* regs) {
	uint8_t temp = 0x80;
	FPGA_SPI_RegWrite(SNES_DBGSEL, 1, &temp);
	for (uint8_t i=0; i < sizeof(SnesCX4Reg); i++) {
		FPGA_SPI_RegWrite(SNES_DBGREG, 1, &i);
		((uint8_t*)regs)[i] = FPGA_SPI_RegRead(SNES_DBGRD);
	}
}

void SnesSDD1RegsRead(SnesSDD1Reg* regs) {
	uint8_t temp = 0x80;
	FPGA_SPI_RegWrite(SNES_DBGSEL, 1, &temp);
	for (uint8_t i=0; i < sizeof(SnesSDD1Reg); i++) {
		FPGA_SPI_RegWrite(SNES_DBGREG, 1, &i);
		((uint8_t*)regs)[i] = FPGA_SPI_RegRead(SNES_DBGRD);
	}
}