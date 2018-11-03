#include "stdint.h"

#define SNES_STAT      	(0x01<<1)
#define SNES_CTRL      	(0x02<<1)
#define SNES_BUSADDR	(0x03<<1)
#define SNES_BUSDATA	(0x04<<1)
#define SNES_BUSRW      (0x05<<1)
#define SNES_LDADDR		(0x06<<1)
#define SNES_LDDATA		(0x07<<1)
#define SNES_DBGSEL		(0x08<<1)
#define SNES_DBGRD		(0x09<<1)
#define SNES_DBGCTL		(0x0A<<1)
#define SNES_DBGREG		(0x0B<<1)
#define SNES_MAPCTL		(0x0C<<1)
#define SNES_MAPRMASK	(0x0D<<1)
#define SNES_MAPBSMASK	(0x0E<<1)
#define SNES_DBGWR      (0x0F<<1)
#define SNES_DBGRW      (0x10<<1)

#define SNES_RST		(0x01)
#define SNES_LOADER_EN	(0x80)
#define SNES_CART_EN	(0x40)
#define SNES_WRAM_EN	(0x20)
#define SNES_VRAM_EN	(0x10)
#define SNES_ARAM_EN	(0x08)

#define DBG_STEP		(0x01)
#define DBG_SCPU_RUN	(0x02)
#define DBG_SMP_RUN		(0x04)
#define DBG_MAP_RUN		(0x08)
#define DBG_SCPU_TRACE	(0x08)
#define DBG_SCPU_BRK	(0x10)
#define DBG_SMP_BRK		(0x20)
#define DBG_HV_BRK      (0x40)
#define DBG_MAP_BRK     (0x80)

#define DBG_STEP		(0x01)
#define DBG_TRACE		(0x02)
#define DBG_BP_OP		(0x04)
#define DBG_BP_RW		(0x08)
#define DBG_RUN     	(0x80)

#define DBG_SCPU_RW      (0x40)

#define GET_MASK(s)      ((1<<(10+(s)))-1)

#pragma pack(1)
typedef struct {
    uint8_t Title[21];
    uint8_t MapMode;
    uint8_t RomType;
	uint8_t RomSize;
	uint8_t RamSize;
	uint8_t Region;
    uint8_t Company;
	uint8_t Version;
    uint16_t CSComp;
	uint16_t Checksum;
} SnesRomHeader;

#pragma pack(1)
typedef struct {
    uint16_t A;
    uint16_t X;
    uint16_t Y;
	uint16_t PC;
	uint8_t P;
	uint16_t SP;
    uint16_t D;
	uint8_t PBR;
    uint8_t DBR;
	uint8_t AdrInc;
	uint16_t AX;
	uint8_t ABR;
	uint16_t DX;
	uint8_t INT;
} SnesCPUReg;

#pragma pack(1)
typedef struct {
    uint8_t NMITIMEN;
    uint8_t WRIO;
    uint8_t WRMPYA;
    uint8_t WRMPYB;
	uint16_t WRDIV;
    uint8_t WRDIVB;
	uint16_t HTIME;
	uint16_t VTIME;
    uint8_t MEMSEL;
	uint8_t MDMAEN;
	uint8_t HDMAEN;
	uint8_t UNUSED1;
	uint8_t UNUSED2;
	uint8_t RDNMI;
	uint8_t TIMEUP;
	uint8_t HVBJOY;
	uint16_t RDDIV;
	uint16_t RDMPY;
	uint8_t MDR;
	uint16_t H_CNT;
	uint16_t V_CNT;
	uint16_t JOY1;
	uint16_t FRAMES;
	uint8_t TEMP;
	uint32_t WMADD;
} SnesCPUReg2;

#pragma pack(1)
typedef struct {
    uint8_t DMAP;
    uint8_t BBAD;
    uint16_t A1T;
    uint8_t A1B;
	uint16_t DAS;
    uint8_t DASB;
	uint16_t A2A;
	uint8_t NTLR;
	uint8_t UNUSED[5];
} SnesDMAReg;

#pragma pack(1)
typedef struct {
    uint8_t INIDISP;
    uint8_t OBSEL;
    uint16_t OAMADD;
    uint8_t BGMODE;
	uint8_t MOSAIC;
    uint8_t BG1SC;
	uint8_t BG2SC;
	uint8_t BG3SC;
    uint8_t BG4SC;
	uint8_t BG12NBA;
	uint8_t BG34NBA;
	uint8_t TM;
	uint8_t TS;
	uint16_t BG1HOFS;
	uint16_t BG1VOFS;
	uint16_t BG2HOFS;
	uint16_t BG2VOFS;
	uint16_t BG3HOFS;
	uint16_t BG3VOFS;
	uint16_t BG4HOFS;
	uint16_t BG4VOFS;
	uint8_t WH0;
	uint8_t WH1;
	uint8_t WH2;
	uint8_t WH3;
	uint8_t W12SEL;
	uint8_t W34SEL;
	uint8_t WOBJSEL;
	uint8_t WBGLOG;
	uint8_t WOBJLOG;
	uint8_t TMW;
	uint8_t TSW;
	uint8_t CGWSEL;
	uint8_t CGADSUB;
	uint8_t VMAIN;
	uint16_t OPHCT;
	uint16_t OPVCT;
	uint16_t H_CNT;
	uint16_t V_CNT;
	uint16_t VMADD;
	uint8_t TEMP;
	uint8_t M7SEL;
	uint16_t M7A;
	uint16_t M7B;
	uint16_t M7C;
	uint16_t M7D;
	uint16_t M7X;
	uint16_t M7Y;
	uint16_t M7HOFS;
	uint16_t M7VOFS;
	uint16_t FRAMES;
} SnesPPUReg;

#pragma pack(1)
typedef struct {
    uint8_t A;
    uint8_t X;
    uint8_t Y;
    uint16_t PC;
	uint8_t PSW;
	uint8_t SP;
	uint16_t AX;
} SnesSPC700Reg;

#pragma pack(1)
typedef struct {
    uint8_t CPUI0;
    uint8_t CPUI1;
    uint8_t CPUI2;
    uint8_t CPUI3;
	uint8_t CPUO0;
    uint8_t CPUO1;
    uint8_t CPUO2;
    uint8_t CPUO3;
	uint8_t TEST;
	uint8_t CONTROL;
	uint8_t T0DIV;
	uint8_t T1DIV;
	uint8_t T2DIV;
	uint8_t T0OUT;
	uint8_t T1OUT;
	uint8_t T2OUT;
} SnesSMPReg;

#pragma pack(1)
typedef struct {
    uint16_t A;
    uint16_t B;
    uint8_t FlagsA;
    uint8_t FlagsB;
	uint16_t PC;
    uint16_t RP;
    uint8_t DP;
    uint16_t TR;
	uint16_t TRB;
	uint16_t K;
	uint16_t L;
	uint16_t M;
	uint16_t N;
	uint16_t DR;
	uint16_t SR;
	uint8_t SP;
	uint16_t IDB;
} SnesDSPnReg;

#pragma pack(1)
typedef struct {
    uint32_t A;
    uint8_t PC;
    uint8_t BANK;
    uint8_t FLAGS;
	uint8_t SP;
    uint32_t ROMB;
    uint32_t RAMB;
    uint32_t MAR;
	uint8_t MBR;
	uint16_t DPR;
	uint16_t P;
	uint16_t CASHE_PAGE0;
	uint16_t CASHE_PAGE1;
	uint8_t CASHE_BANK;
	uint16_t IR;
	uint8_t WS;
	uint8_t STATES;
} SnesCX4Reg;

#pragma pack(1)
typedef struct {
    uint8_t HEADER;
    uint32_t DEC_ADDR;
    uint8_t DEC_OUT_DATA0;
    uint8_t DEC_OUT_DATA1;
	uint8_t DEC_DONE;
	uint8_t DMAEN;
	uint8_t DMARUN;
	uint8_t ROMBANKC;
	uint8_t ROMBANKD;
	uint8_t ROMBANKE;
	uint8_t ROMBANKF;
	uint8_t STATE;
	uint16_t DMAS0;
} SnesSDD1Reg;

void SNESControl(uint8_t value);
void SnesPpuRegWrite(uint8_t reg, uint8_t value);
uint8_t SnesPpuRegRead(uint8_t reg);
void SnesPpuVramWrite(uint16_t addr, uint16_t len, uint16_t* buf);
void SnesPpuVramRead(uint16_t addr, uint16_t len, uint16_t* buf);
void SnesPpuGramWrite(uint8_t addr, uint16_t len, uint16_t* buf);
void SnesPpuGramRead(uint8_t addr, uint16_t len, uint16_t* buf);
void SnesPpuOAMWrite(uint16_t addr, uint16_t len, uint8_t* buf);
void SnesPpuOAMRead(uint16_t addr, uint16_t len, uint8_t* buf);

void SnesLoaderWrite(uint32_t addr, uint32_t len, uint8_t* buf);
void SnesLoaderRead(uint32_t addr, uint32_t len, uint8_t* buf);
void LoaderAddrSet(uint32_t addr);
void LoaderAddrRead(uint8_t* buf);
void LoaderJoy1Set(uint16_t data);

void SnesCPURegsRead(SnesCPUReg* regs);
void SnesCPURegs2Read(SnesCPUReg2* regs);
void SnesDMARegsRead(SnesDMAReg* regs);
void SnesPPURegsRead(SnesPPUReg* regs);
void SnesSPC700RegsRead(SnesSPC700Reg* regs);
void SnesSMPRegsRead(SnesSMPReg* regs);
void CPUDebugControl(uint8_t value);
void HVCounterSet(uint16_t h, uint16_t v);
void SnesWRAMRead(uint32_t addr, uint32_t len, uint8_t* buf);
void SnesVRAMRead(uint32_t addr, uint32_t len, uint8_t* buf);
void SnesARAMRead(uint32_t addr, uint32_t len, uint8_t* buf);
void SnesARAMWrite(uint32_t addr, uint32_t len, uint8_t* buf);

void SnesCPURegWrite(uint8_t reg, uint8_t value);
void SnesSPC700RegWrite(uint8_t reg, uint8_t value);
void SnesSMPRegWrite(uint8_t reg, uint8_t value);
void SnesDSPRegsRead(uint8_t* buf);
void SnesDSPRegsWrite(uint8_t* buf);

void LoaderVmuteSet(uint8_t data);
void SnesBgObjControl(uint16_t value);

void SnesMapperControl(uint8_t value);
void SnesMapperMask(uint32_t rom, uint32_t sram);


void SnesDSPnRegsRead(SnesDSPnReg* regs);
void SnesCX4RegsRead(SnesCX4Reg* regs);
void SnesSDD1RegsRead(SnesSDD1Reg* regs);

//SPC File
enum { signature_size = 35 };

#pragma pack(1)
typedef struct {
    char    signature [signature_size];
	uint8_t has_id666;
	uint8_t version;
	uint8_t pcl, pch;
	uint8_t a;
	uint8_t x;
	uint8_t y;
	uint8_t psw;
	uint8_t sp;
	char    text [212];
	uint8_t ram [0x10000];
	uint8_t dsp [128];
	uint8_t unused [0x40];
	uint8_t ipl_rom [0x40];
} spc_file_t;
