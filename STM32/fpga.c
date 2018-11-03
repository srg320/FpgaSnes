#include "fpga.h"

static void FPGA_SPI_LowLevel_Init();
static uint8_t FPGA_SPI_SendByte(uint8_t byte);

void FPGA_SPI_Init()
{
    FPGA_SPI_LowLevel_Init();
}

static void FPGA_SPI_LowLevel_Init()
{
    GPIO_InitTypeDef GPIO_InitStructure;
    
    RCC_AHB1PeriphClockCmd(FPGA_SPI_SCK_GPIO_CLK | FPGA_SPI_MISO_GPIO_CLK | 
			   FPGA_SPI_MOSI_GPIO_CLK | FPGA_SPI_CS_GPIO_CLK, ENABLE);
	
	
    GPIO_PinAFConfig(FPGA_SPI_SCK_GPIO_PORT, FPGA_SPI_SCK_SOURCE, FPGA_SPI_SCK_AF);
    GPIO_PinAFConfig(FPGA_SPI_MISO_GPIO_PORT, FPGA_SPI_MISO_SOURCE, FPGA_SPI_MISO_AF);
    GPIO_PinAFConfig(FPGA_SPI_MOSI_GPIO_PORT, FPGA_SPI_MOSI_SOURCE, FPGA_SPI_MOSI_AF);

    //GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF;
    GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
    GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_DOWN;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;

    /* SPI SCK pin configuration */
    GPIO_InitStructure.GPIO_Pin = FPGA_SPI_SCK_PIN;
    GPIO_Init(FPGA_SPI_SCK_GPIO_PORT, &GPIO_InitStructure);

    /* SPI  MOSI pin configuration */
    GPIO_InitStructure.GPIO_Pin =  FPGA_SPI_MOSI_PIN;
    GPIO_Init(FPGA_SPI_MOSI_GPIO_PORT, &GPIO_InitStructure);

    /* SPI MISO pin configuration */
    //GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN;
    GPIO_InitStructure.GPIO_Pin = FPGA_SPI_MISO_PIN;
    GPIO_Init(FPGA_SPI_MISO_GPIO_PORT, &GPIO_InitStructure);
    
    SPI_InitTypeDef  SPI_InitStructure;
	
    RCC_APB1PeriphClockCmd(FPGA_SPI_CLK, ENABLE);
	
    /* SPI configuration -------------------------------------------------------*/
    SPI_I2S_DeInit(FPGA_SPI);
    SPI_StructInit(&SPI_InitStructure);
    SPI_InitStructure.SPI_Direction = SPI_Direction_2Lines_FullDuplex;
    SPI_InitStructure.SPI_DataSize = SPI_DataSize_8b;
    SPI_InitStructure.SPI_CPOL = SPI_CPOL_Low;
    SPI_InitStructure.SPI_CPHA = SPI_CPHA_1Edge;
    SPI_InitStructure.SPI_NSS = SPI_NSS_Soft;
    SPI_InitStructure.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_4;
    SPI_InitStructure.SPI_FirstBit = SPI_FirstBit_MSB;
    SPI_InitStructure.SPI_CRCPolynomial = 7;
    SPI_InitStructure.SPI_Mode = SPI_Mode_Master;
    SPI_Init(FPGA_SPI, &SPI_InitStructure);
    
    /* Enable SPI2  */
    SPI_Cmd(FPGA_SPI, ENABLE);
    
    SPI_NSSInternalSoftwareConfig(FPGA_SPI, SPI_NSSInternalSoft_Set);
    
    /* Configure GPIO PIN for Lis Chip select */
    GPIO_InitStructure.GPIO_Pin = FPGA_SPI_CS_PIN;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
    GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(FPGA_SPI_CS_GPIO_PORT, &GPIO_InitStructure);

    /* Deselect : Chip Select high */
	GPIO_SetBits(FPGA_SPI_CS_GPIO_PORT, FPGA_SPI_CS_PIN);
	GPIO_ResetBits(FPGA_SPI_CS_GPIO_PORT, FPGA_SPI_CS_PIN);
    GPIO_SetBits(FPGA_SPI_CS_GPIO_PORT, FPGA_SPI_CS_PIN);
}

void FPGA_SPI_RegWrite(uint8_t reg, uint16_t len, uint8_t* buf)
{
    FPGA_CS_LOW();
    FPGA_SPI_SendByte(reg);
    FPGA_CS_HIGH();
  
    while(len > 0)
    {
        FPGA_CS_LOW();
		FPGA_SPI_SendByte(*buf);
		FPGA_CS_HIGH();
        len--;
        buf++;
    }
}

uint8_t FPGA_SPI_RegRead(uint8_t reg)
{  
    uint8_t ret = 0;
	
    FPGA_CS_LOW();
    ret = FPGA_SPI_SendByte(reg | 0x01);
    FPGA_CS_HIGH();
	
    FPGA_CS_LOW();
    ret = FPGA_SPI_SendByte(0);
    FPGA_CS_HIGH();
	
    return ret;
}

uint8_t FPGA_SPI_RegReads(uint8_t reg, uint16_t len, uint8_t* buf)
{  
    uint8_t ret = 0;
	
    FPGA_CS_LOW();
    ret = FPGA_SPI_SendByte(reg | 0x01);
    FPGA_CS_HIGH();
	
	while(len > 0)
    {
		FPGA_CS_LOW();
		*buf = FPGA_SPI_SendByte(0);
		FPGA_CS_HIGH();
		len--;
        buf++;
	}
    return ret;
}

static uint8_t FPGA_SPI_SendByte(uint8_t byte)
{
    uint16_t ret = 0;
	
    FPGA_SPI->DR = byte;
    while(SPI_I2S_GetFlagStatus(FPGA_SPI,SPI_I2S_FLAG_TXE) == RESET);
    
    while (SPI_I2S_GetFlagStatus(FPGA_SPI, SPI_I2S_FLAG_RXNE) == RESET);
    ret = FPGA_SPI->DR;
    
    return ret;
}

/////////////////////////////////////////////////////////////////
static void FPGA_Delay(int value)
{
    volatile int i;
    for(i = value*100; i>0; i--);
}

static void FPGA_SendByte(uint8_t byte)
{
    for (int i = 7; i>=0; i--)
    {
        if (byte & (1<<i))
            FPGA_DATA0_HIGH();
        else
            FPGA_DATA0_LOW();
		
        FPGA_DSCK_HIGH();
        FPGA_DSCK_LOW();
    }
}

unsigned char swap(unsigned char value)
{
    unsigned char d = 0, mask = 0;
    
    for(int i = 0; i < 8; ++i)
    {
        mask = 1<<7-i;
        if ((value & mask) != 0)
        {
            d |= 1<<i;
        }
    }
    return d;
}


int FPGA_Configure(unsigned char* data, int count)
{
    unsigned char d;
    unsigned int cnt = 0;
    unsigned char *p;
    
    GPIO_InitTypeDef GPIO_InitStructure;
    
    RCC_AHB1PeriphClockCmd(FPGA_SPI_SCK_GPIO_CLK | FPGA_SPI_MISO_GPIO_CLK | 
			   FPGA_SPI_MOSI_GPIO_CLK, ENABLE);
	
	
    GPIO_PinAFConfig(FPGA_SPI_SCK_GPIO_PORT, FPGA_SPI_SCK_SOURCE, FPGA_SPI_SCK_AF);
    GPIO_PinAFConfig(FPGA_SPI_MISO_GPIO_PORT, FPGA_SPI_MISO_SOURCE, FPGA_SPI_MISO_AF);
    GPIO_PinAFConfig(FPGA_SPI_MOSI_GPIO_PORT, FPGA_SPI_MOSI_SOURCE, FPGA_SPI_MOSI_AF);

    //GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF;
    GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
    GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_DOWN;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;

    /* SPI SCK pin configuration */
    GPIO_InitStructure.GPIO_Pin = FPGA_SPI_SCK_PIN;
    GPIO_Init(FPGA_SPI_SCK_GPIO_PORT, &GPIO_InitStructure);

    /* SPI  MOSI pin configuration */
    GPIO_InitStructure.GPIO_Pin =  FPGA_SPI_MOSI_PIN;
    GPIO_Init(FPGA_SPI_MOSI_GPIO_PORT, &GPIO_InitStructure);

    /* SPI MISO pin configuration */
    GPIO_InitStructure.GPIO_Pin = FPGA_SPI_MISO_PIN;
    GPIO_Init(FPGA_SPI_MISO_GPIO_PORT, &GPIO_InitStructure);
    
    SPI_InitTypeDef  SPI_InitStructure;
	
    RCC_APB1PeriphClockCmd(FPGA_SPI_CLK, ENABLE);
	
    /* SPI configuration -------------------------------------------------------*/
    SPI_I2S_DeInit(FPGA_SPI);
    SPI_StructInit(&SPI_InitStructure);
    SPI_InitStructure.SPI_Direction = SPI_Direction_2Lines_FullDuplex;
    SPI_InitStructure.SPI_DataSize = SPI_DataSize_8b;
    SPI_InitStructure.SPI_CPOL = SPI_CPOL_Low;
    SPI_InitStructure.SPI_CPHA = SPI_CPHA_1Edge;
    SPI_InitStructure.SPI_NSS = SPI_NSS_Soft;
    SPI_InitStructure.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_2;
    SPI_InitStructure.SPI_FirstBit = SPI_FirstBit_LSB;
    SPI_InitStructure.SPI_CRCPolynomial = 7;
    SPI_InitStructure.SPI_Mode = SPI_Mode_Master;
    SPI_Init(FPGA_SPI, &SPI_InitStructure);
    
    /* Enable SPI2  */
    SPI_Cmd(FPGA_SPI, ENABLE);
    
    SPI_NSSInternalSoftwareConfig(FPGA_SPI, SPI_NSSInternalSoft_Set);
	
    //GPIO_InitTypeDef GPIO_InitStructure;
    RCC_AHB1PeriphClockCmd(/*FPGA_DSCK_GPIO_CLK | FPGA_DATA0_GPIO_CLK |*/ 
				FPGA_NCONFIG_GPIO_CLK | FPGA_CONFDONE_GPIO_CLK | 
				FPGA_NSTATUS_GPIO_CLK, ENABLE);
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
    GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
    GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
	
    /* NCONFIG pin configuration */
    GPIO_InitStructure.GPIO_Pin = FPGA_NCONFIG_PIN;
    GPIO_Init(FPGA_NCONFIG_GPIO_PORT, &GPIO_InitStructure);
		
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN;
    GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_UP;
	
    /* CONFDONE pin configuration */
    GPIO_InitStructure.GPIO_Pin = FPGA_CONFDONE_PIN;
    GPIO_Init(FPGA_CONFDONE_GPIO_PORT, &GPIO_InitStructure);
	
    /* NSTATUS pin configuration */
    GPIO_InitStructure.GPIO_Pin = FPGA_NSTATUS_PIN;
    GPIO_Init(FPGA_NSTATUS_GPIO_PORT, &GPIO_InitStructure);
	
    
    FPGA_NCONFIG_LOW();
    FPGA_Delay(1000);
    while (FPGA_NSTATUS() != 0);
    
    FPGA_NCONFIG_HIGH();
    FPGA_Delay(1000);
    while (FPGA_NSTATUS() == 0);
    
    return 0; 
}

int FPGA_SendBytes(unsigned char* data, int len)
{
    unsigned char d;
    unsigned int cnt = 0;
	
    for (int i=0; i<len; i++) 
    {
        d = data[i];
        
        FPGA_SPI_SendByte(d);
        
        if(FPGA_CONFDONE() == 1) 
			return 1;
        
        cnt++;
        if(cnt > len) 
        {
            return -1; 
        }  
    }
    
    return 0; 
}
