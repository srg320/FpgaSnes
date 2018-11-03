#include "stm32f4xx.h"

#define FPGA_DSCK_PIN               GPIO_Pin_3                  /* PB.3 */
#define FPGA_DSCK_GPIO_PORT         GPIOB                       /* GPIOB */
#define FPGA_DSCK_GPIO_CLK          RCC_AHB1Periph_GPIOB
#define FPGA_DSCK_SOURCE            GPIO_PinSource3

#define FPGA_DATA0_PIN               GPIO_Pin_5                  /* PB.5 */
#define FPGA_DATA0_GPIO_PORT         GPIOB                       /* GPIOB */
#define FPGA_DATA0_GPIO_CLK          RCC_AHB1Periph_GPIOB
#define FPGA_DATA0_SOURCE            GPIO_PinSource5

#define FPGA_NCONFIG_PIN               GPIO_Pin_9                 /* PA.9 */
#define FPGA_NCONFIG_GPIO_PORT         GPIOA                       /* GPIOD */
#define FPGA_NCONFIG_GPIO_CLK          RCC_AHB1Periph_GPIOA
#define FPGA_NCONFIG_SOURCE            GPIO_PinSource9

#define FPGA_CONFDONE_PIN               GPIO_Pin_7                  /* PC.07 */
#define FPGA_CONFDONE_GPIO_PORT         GPIOC                      /* GPIOC */
#define FPGA_CONFDONE_GPIO_CLK          RCC_AHB1Periph_GPIOC
#define FPGA_CONFDONE_SOURCE            GPIO_PinSource7

#define FPGA_NSTATUS_PIN               GPIO_Pin_10                  /* PA.10 */
#define FPGA_NSTATUS_GPIO_PORT         GPIOA                      /* GPIOB */
#define FPGA_NSTATUS_GPIO_CLK          RCC_AHB1Periph_GPIOA
#define FPGA_NSTATUS_SOURCE            GPIO_PinSource10

#define FPGA_DSCK_LOW()       GPIO_ResetBits(FPGA_DSCK_GPIO_PORT, FPGA_DSCK_PIN)
#define FPGA_DSCK_HIGH()      GPIO_SetBits(FPGA_DSCK_GPIO_PORT, FPGA_DSCK_PIN)
#define FPGA_DATA0_LOW()       GPIO_ResetBits(FPGA_DATA0_GPIO_PORT, FPGA_DATA0_PIN)
#define FPGA_DATA0_HIGH()      GPIO_SetBits(FPGA_DATA0_GPIO_PORT, FPGA_DATA0_PIN)
#define FPGA_NCONFIG_LOW()       GPIO_ResetBits(FPGA_NCONFIG_GPIO_PORT, FPGA_NCONFIG_PIN)
#define FPGA_NCONFIG_HIGH()      GPIO_SetBits(FPGA_NCONFIG_GPIO_PORT, FPGA_NCONFIG_PIN)

#define FPGA_CONFDONE()       GPIO_ReadInputDataBit(FPGA_CONFDONE_GPIO_PORT, FPGA_CONFDONE_PIN)
#define FPGA_NSTATUS()      GPIO_ReadInputDataBit(FPGA_NSTATUS_GPIO_PORT, FPGA_NSTATUS_PIN)


#define FPGA_SPI                       SPI3
#define FPGA_SPI_CLK                   RCC_APB1Periph_SPI3

#define FPGA_SPI_SCK_PIN               GPIO_Pin_3                  /* PB.3 */
#define FPGA_SPI_SCK_GPIO_PORT         GPIOB                       /* GPIOB */
#define FPGA_SPI_SCK_GPIO_CLK          RCC_AHB1Periph_GPIOB
#define FPGA_SPI_SCK_SOURCE            GPIO_PinSource3
#define FPGA_SPI_SCK_AF                GPIO_AF_SPI3

#define FPGA_SPI_MISO_PIN              GPIO_Pin_4                  /* PB.4 */
#define FPGA_SPI_MISO_GPIO_PORT        GPIOB                       /* GPIOB */
#define FPGA_SPI_MISO_GPIO_CLK         RCC_AHB1Periph_GPIOB
#define FPGA_SPI_MISO_SOURCE           GPIO_PinSource4
#define FPGA_SPI_MISO_AF               GPIO_AF_SPI3

#define FPGA_SPI_MOSI_PIN              GPIO_Pin_5                  /* PB.5 */
#define FPGA_SPI_MOSI_GPIO_PORT        GPIOB                       /* GPIOB */
#define FPGA_SPI_MOSI_GPIO_CLK         RCC_AHB1Periph_GPIOB
#define FPGA_SPI_MOSI_SOURCE           GPIO_PinSource5
#define FPGA_SPI_MOSI_AF               GPIO_AF_SPI3

#define FPGA_SPI_CS_PIN                GPIO_Pin_15                  /* PA.15 */
#define FPGA_SPI_CS_GPIO_PORT          GPIOA                       /* GPIOA */
#define FPGA_SPI_CS_GPIO_CLK           RCC_AHB1Periph_GPIOA
#define FPGA_SPI_CS_SOURCE             GPIO_PinSource15
#define FPGA_SPI_CS_AF                 GPIO_AF_SPI3

#define FPGA_FLAG_TIMEOUT         ((uint32_t)0x1000)

#define FPGA_CS_LOW()       GPIO_ResetBits(FPGA_SPI_CS_GPIO_PORT, FPGA_SPI_CS_PIN)
#define FPGA_CS_HIGH()      GPIO_SetBits(FPGA_SPI_CS_GPIO_PORT, FPGA_SPI_CS_PIN)

#define FPGA_SCK_LOW()       GPIO_ResetBits(FPGA_SPI_SCK_GPIO_PORT, FPGA_SPI_SCK_PIN)
#define FPGA_SCK_HIGH()      GPIO_SetBits(FPGA_SPI_SCK_GPIO_PORT, FPGA_SPI_SCK_PIN)
#define FPGA_MOSI_LOW()       GPIO_ResetBits(FPGA_SPI_MOSI_GPIO_PORT, FPGA_SPI_MOSI_PIN)
#define FPGA_MOSI_HIGH()      GPIO_SetBits(FPGA_SPI_MOSI_GPIO_PORT, FPGA_SPI_MOSI_PIN)
#define FPGA_MISO()       GPIO_ReadInputDataBit(FPGA_SPI_MISO_GPIO_PORT, FPGA_SPI_MISO_PIN)

void FPGA_SPI_Init();
void FPGA_SPI_RegWrite(uint8_t reg, uint16_t len, uint8_t* buf);
uint8_t FPGA_SPI_RegRead(uint8_t reg);
uint8_t FPGA_SPI_RegReads(uint8_t reg, uint16_t len, uint8_t* buf);

int FPGA_Configure(unsigned char* data, int count);
int FPGA_SendBytes(unsigned char* data, int len);
