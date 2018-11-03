#include "i2c.h"

void I2CInit()
{
    GPIO_InitTypeDef  GPIO_I2C;
    I2C_InitTypeDef   I2C_init;
        
    /*  GPIO Setup  */
    RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOB, ENABLE);
    GPIO_I2C.GPIO_Pin = GPIO_Pin_6 | GPIO_Pin_7;
    GPIO_I2C.GPIO_Mode = GPIO_Mode_AF;
    GPIO_I2C.GPIO_OType = GPIO_OType_OD;
    GPIO_I2C.GPIO_Speed = GPIO_Speed_2MHz;
    GPIO_I2C.GPIO_PuPd = GPIO_PuPd_NOPULL;
    GPIO_Init(GPIOB, &GPIO_I2C);
    
    // Connect I2C2 pins to AF
    GPIO_PinAFConfig(GPIOB, GPIO_PinSource6, GPIO_AF_I2C1); // SCL
    GPIO_PinAFConfig(GPIOB, GPIO_PinSource7, GPIO_AF_I2C1); // SDA
    
    /*  I2C Setup  */
    RCC_APB1PeriphClockCmd(RCC_APB1Periph_I2C1, ENABLE);
    I2C_DeInit(I2C1);
    I2C_init.I2C_Mode = I2C_Mode_I2C;
    I2C_init.I2C_ClockSpeed = 100000;
    I2C_init.I2C_DutyCycle = I2C_DutyCycle_2;
    I2C_init.I2C_OwnAddress1 = 0x00;
    I2C_init.I2C_Ack = I2C_Ack_Enable;
    I2C_init.I2C_AcknowledgedAddress = I2C_AcknowledgedAddress_7bit;
    
    I2C_Cmd(I2C1,ENABLE);
	
	I2C_Init(I2C1,&I2C_init);
}

    
void I2CWriteReg(uint8_t reg, uint8_t data) {
    uint8_t index;

    I2C_AcknowledgeConfig(I2C1, ENABLE);

    I2C_GenerateSTART(I2C1, ENABLE);
    while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_MODE_SELECT));

    I2C_Send7bitAddress(I2C1, 0x30, I2C_Direction_Transmitter);
    while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_TRANSMITTER_MODE_SELECTED));

    I2C_SendData(I2C1, reg);
    while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_BYTE_TRANSMITTED));

    I2C_SendData(I2C1, data);
    while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_BYTE_TRANSMITTED));

    I2C_NACKPositionConfig(I2C1, I2C_NACKPosition_Current);
    I2C_AcknowledgeConfig(I2C1, DISABLE);

    I2C_GenerateSTOP(I2C1, ENABLE);

    while (I2C_GetFlagStatus(I2C1, I2C_FLAG_STOPF));
}

void I2CWriteReg2(uint8_t reg, uint16_t data) {
    uint8_t index;

    I2C_AcknowledgeConfig(I2C1, ENABLE);

    I2C_GenerateSTART(I2C1, ENABLE);
    while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_MODE_SELECT));

    I2C_Send7bitAddress(I2C1, 0x30, I2C_Direction_Transmitter);
    while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_TRANSMITTER_MODE_SELECTED));

    I2C_SendData(I2C1, reg);
    while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_BYTE_TRANSMITTED));

    I2C_SendData(I2C1, data>>8);
    while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_BYTE_TRANSMITTED));
	I2C_SendData(I2C1, (uint8_t)data);
    while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_BYTE_TRANSMITTED));

    I2C_NACKPositionConfig(I2C1, I2C_NACKPosition_Current);
    I2C_AcknowledgeConfig(I2C1, DISABLE);

    I2C_GenerateSTOP(I2C1, ENABLE);

    while (I2C_GetFlagStatus(I2C1, I2C_FLAG_STOPF));
}

uint16_t I2CRead(uint8_t reg)
{
    uint16_t value;
    
    I2C_AcknowledgeConfig(I2C1, ENABLE);

    I2C_GenerateSTART(I2C1, ENABLE);
    while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_MODE_SELECT));

    I2C_Send7bitAddress(I2C1, 0x30, I2C_Direction_Transmitter);
    while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_TRANSMITTER_MODE_SELECTED));

    I2C_SendData(I2C1, reg);
    while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_BYTE_TRANSMITTED));

    I2C_GenerateSTART(I2C1, ENABLE);
    while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_MODE_SELECT));

    I2C_Send7bitAddress(I2C1, 0x30, I2C_Direction_Receiver);
    while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_RECEIVER_MODE_SELECTED));

	while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_BYTE_RECEIVED));
	I2C_NACKPositionConfig(I2C1, I2C_NACKPosition_Current);
    I2C_AcknowledgeConfig(I2C1, DISABLE);
	value = (uint16_t)I2C_ReceiveData(I2C1)*256;
	
	while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_BYTE_RECEIVED));
	value |= (uint16_t)I2C_ReceiveData(I2C1);

    I2C_GenerateSTOP(I2C1, ENABLE);
    while (I2C_GetFlagStatus(I2C1, I2C_FLAG_STOPF));

    return value;
}
