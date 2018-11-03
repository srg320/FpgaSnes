#include "stm32f4xx.h"

#define ALC5628_RST_PIN               GPIO_Pin_13                  /* PC.13 */
#define ALC5628_RST_GPIO_PORT         GPIOC                       /* GPIOC */
#define ALC5628_RST_GPIO_CLK          RCC_AHB1Periph_GPIOC
#define ALC5628_RST_SOURCE            GPIO_PinSource13

void ALC5628_Init(uint8_t volume);
void ALC5628_Volume(uint8_t volume);
