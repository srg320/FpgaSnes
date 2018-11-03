#include "stm32f4xx.h"

void I2CInit();
void I2CWriteReg(uint8_t reg, uint8_t data);
void I2CWriteReg2(uint8_t reg, uint16_t data);
uint16_t I2CRead(uint8_t reg);