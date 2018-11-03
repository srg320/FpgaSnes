#include "ALC5628.h"
#include "i2c.h"

static void ALC5628_GPIO_Init(void)
{
	
}

static void ALC5628_Delay(int value)
{
    volatile int i;
    for(i = value*100; i>0; i--);
}


static void ALC5628_Reset(void)
{
	
}

static void ALC5628_WriteRegister(uint8_t RegisterAddr, uint16_t RegisterValue)
{
	I2CWriteReg2(RegisterAddr,RegisterValue);
}

static uint32_t ALC5628_VolumeCtrl(uint8_t Volume)
{

}


void ALC5628_Init(uint8_t Volume)
{
	uint16_t temp = 0; 
	
	ALC5628_GPIO_Init();   
	
	ALC5628_Reset();   
	
	temp = I2CRead(0x00);
	
	ALC5628_WriteRegister(0x00, 0x0707);  
	ALC5628_WriteRegister(0x00, 0x0707);  
	
	temp = I2CRead(0x00);
	temp = I2CRead(0x00);
	
	temp = I2CRead(0x3E);
	ALC5628_WriteRegister(0x3E, temp|0x8000);
	
	temp = I2CRead(0x3C);
	ALC5628_WriteRegister(0x3C, temp|0x2000);
	
	temp = I2CRead(0x3C);
	ALC5628_WriteRegister(0x3C, temp|0x07F8);
	
	temp = I2CRead(0x3A);
	ALC5628_WriteRegister(0x3A, temp|0x8030);
	
	temp = I2CRead(0x3E);
	ALC5628_WriteRegister(0x3E, temp|0x1600);
	
	temp = I2CRead(0x0C);
	ALC5628_WriteRegister(0x0C, 0x1F1F);//(temp&(~0x3F3F))|
	
	temp = I2CRead(0x1C);
	ALC5628_WriteRegister(0x1C, temp|0x0700);
	
	temp = I2CRead(0x00);
	
	temp = I2CRead(0x02);
	
	ALC5628_WriteRegister(0x02, 0x0808 | 0x8080); //
	
	temp = I2CRead(0x02);
	
//	ALC5628_WriteRegister(0x0A, 0x0000);
	
	temp = I2CRead(0x04);
	ALC5628_WriteRegister(0x04, 0x1010);
	
	temp = I2CRead(0x42);
	ALC5628_WriteRegister(0x42, 0xc000);
	
	temp = I2CRead(0x44);
	ALC5628_WriteRegister(0x44, 0x7E20);//0x2628
	
	temp = I2CRead(0x3C);
	ALC5628_WriteRegister(0x3C, temp|0x5008);
	
	ALC5628_WriteRegister(0x34, 0x8001);
//	ALC5628_WriteRegister(0x38, 0x2000);
}

void ALC5628_Volume(uint8_t volume)
{
	ALC5628_VolumeCtrl(volume);
}