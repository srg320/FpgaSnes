#include "lcd.h"
#include "loader.h"
#include "stm32f4xx.h"

#include "Fonts/fonts.h"
#include "Fonts/font24.c"
#include "Fonts/font20.c"
#include "Fonts/font16.c"
#include "Fonts/font12.c"
#include "Fonts/font8.c"


static LCD_DrawPropTypeDef DrawProp;
static uint32_t Lcd_XSize, Lcd_YSize;

static void DrawChar(uint16_t Xpos, uint16_t Ypos, const uint8_t *c);

void BSP_LCD_Init(void)
{
	BSP_LCD_SetXSize(400);
	BSP_LCD_SetYSize(240);
	BSP_LCD_SetFont(&LCD_DEFAULT_FONT);
	BSP_LCD_SetTextColor(0xFF);
	BSP_LCD_SetBackColor(0x00);
	
	LoaderLCDAddr(0);
	for (int j=0; j < BSP_LCD_GetYSize(); j++) {
		for (int i=0; i < BSP_LCD_GetXSize(); i++) {
			LoaderLCDWrite(0x0000);
		}
	}
	
	GPIO_InitTypeDef GPIO_InitStructure;
    
    RCC_AHB1PeriphClockCmd(LCD_BL_GPIO_CLK, ENABLE);
	
	/* Configure GPIO PIN for LCD Backlight */
    GPIO_InitStructure.GPIO_Pin = LCD_BL_PIN;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
    GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(LCD_BL_GPIO_PORT, &GPIO_InitStructure);

    GPIO_SetBits(LCD_BL_GPIO_PORT, LCD_BL_PIN);
}
void BSP_LCD_SetTextColor(uint32_t Color)
{
  DrawProp.TextColor = Color;
}

uint32_t BSP_LCD_GetTextColor(void)
{
  return DrawProp.TextColor;
}

void BSP_LCD_SetBackColor(uint32_t Color)
{
  DrawProp.BackColor = Color;
}

uint32_t BSP_LCD_GetBackColor(void)
{
  return DrawProp.BackColor;
}

void BSP_LCD_SetFont(sFONT *fonts)
{
  DrawProp.pFont = fonts;
}

sFONT *BSP_LCD_GetFont(void)
{
  	return DrawProp.pFont;
}

uint32_t BSP_LCD_GetXSize(void)
{
  	return Lcd_XSize;
}

uint32_t BSP_LCD_GetYSize(void)
{
  	return Lcd_YSize;
}

void BSP_LCD_SetXSize(uint32_t imageWidthPixels)
{
  	Lcd_XSize = imageWidthPixels;
}

void BSP_LCD_SetYSize(uint32_t imageHeightPixels)
{
  	Lcd_YSize = imageHeightPixels;
}

void BSP_LCD_Clear(uint32_t Color)
{ 	
	for (int j=0; j < BSP_LCD_GetYSize(); j++) {
		for (int i=0; i < BSP_LCD_GetXSize(); i++) {
			LoaderLcdDrawPixel(i,j,Color);
		}
	}
}

void BSP_LCD_ClearStringLine(uint32_t Line)
{
  uint32_t color_backup = DrawProp.TextColor;
  DrawProp.TextColor = DrawProp.BackColor;
  
  /* Draw rectangle with background color */
//  BSP_LCD_FillRect(0, (Line * DrawProp[ActiveLayer].pFont->Height), BSP_LCD_GetXSize(), DrawProp[ActiveLayer].pFont->Height);
  
  DrawProp.TextColor = color_backup;
  BSP_LCD_SetTextColor(DrawProp.TextColor);  
}


void BSP_LCD_DrawPixel(uint16_t Xpos, uint16_t Ypos, uint32_t RGB_Code)
{
	LoaderLcdDrawPixel(Xpos,Ypos,RGB_Code);
}

void BSP_LCD_DisplayChar(uint16_t Xpos, uint16_t Ypos, uint8_t Ascii)
{
	DrawChar(Xpos, Ypos, &DrawProp.pFont->table[(Ascii-' ') * DrawProp.pFont->Height * ((DrawProp.pFont->Width + 7) / 8)]);
}

uint16_t BSP_LCD_DisplayStringAt(uint16_t Xpos, uint16_t Ypos, char *Text, Text_AlignModeTypdef Mode)
{
  uint16_t ref_column = 1, i = 0;
  uint32_t size = 0, xsize = 0; 
  uint8_t  *ptr = Text;
  
  /* Get the text size */
  while (*ptr++) size ++ ;
  
  /* Characters number per line */
  xsize = (BSP_LCD_GetXSize()/DrawProp.pFont->Width);
  
  switch (Mode)
  {
  case CENTER_MODE:
    {
      ref_column = Xpos + ((xsize - size)* DrawProp.pFont->Width) / 2;
      break;
    }
  case LEFT_MODE:
    {
      ref_column = Xpos;
      break;
    }
  case RIGHT_MODE:
    {
      ref_column = - Xpos + ((xsize - size)*DrawProp.pFont->Width);
      break;
    }    
  default:
    {
      ref_column = Xpos;
      break;
    }
  }
  
  /* Check that the Start column is located in the screen */
  if ((ref_column < 1) || (ref_column >= 0x8000))
  {
    ref_column = 1;
  }

  /* Send the string character by character on LCD */
  while ((*Text != 0) & (((BSP_LCD_GetXSize() - (i*DrawProp.pFont->Width)) & 0xFFFF) >= DrawProp.pFont->Width))
  {
    /* Display one character on LCD */
    BSP_LCD_DisplayChar(ref_column, Ypos, *Text);
    /* Decrement the column position by 16 */
    ref_column += DrawProp.pFont->Width;
    /* Point on the next character */
    Text++;
    i++;
  }  
  
  return DrawProp.pFont->Height;
}

void BSP_LCD_DisplayStringAtLine(uint16_t Line, char *ptr)
{  
  BSP_LCD_DisplayStringAt(0, LINE(Line), ptr, LEFT_MODE);
}


void BSP_LCD_DrawHLine(uint16_t Xpos, uint16_t Ypos, uint16_t Length)
{
  	for (int i=0; i < Length; i++) {
		LoaderLcdDrawPixel(Xpos+i,Ypos,DrawProp.TextColor);
	}
}

void BSP_LCD_DrawVLine(uint16_t Xpos, uint16_t Ypos, uint16_t Length)
{
  	for (int i=0; i < Length; i++) {
		LoaderLcdDrawPixel(Xpos,Ypos+i,DrawProp.TextColor);
	}
}


void BSP_LCD_DrawLine(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2)
{
	int16_t deltax = 0, deltay = 0, x = 0, y = 0, xinc1 = 0, xinc2 = 0, 
	yinc1 = 0, yinc2 = 0, den = 0, num = 0, num_add = 0, num_pixels = 0, 
	curpixel = 0;
	
	deltax = ABS(x2 - x1);        /* The difference between the x's */
	deltay = ABS(y2 - y1);        /* The difference between the y's */
	x = x1;                       /* Start x off at the first pixel */
	y = y1;                       /* Start y off at the first pixel */
	
	if (x2 >= x1)                 /* The x-values are increasing */
	{
		xinc1 = 1;
		xinc2 = 1;
	}
	else                          /* The x-values are decreasing */
	{
		xinc1 = -1;
		xinc2 = -1;
	}
	
	if (y2 >= y1)                 /* The y-values are increasing */
	{
		yinc1 = 1;
		yinc2 = 1;
	}
	else                          /* The y-values are decreasing */
	{
		yinc1 = -1;
		yinc2 = -1;
	}
	
	if (deltax >= deltay)         /* There is at least one x-value for every y-value */
	{
		xinc1 = 0;                  /* Don't change the x when numerator >= denominator */
		yinc2 = 0;                  /* Don't change the y for every iteration */
		den = deltax;
		num = deltax / 2;
		num_add = deltay;
		num_pixels = deltax;         /* There are more x-values than y-values */
	}
	else                          /* There is at least one y-value for every x-value */
	{
		xinc2 = 0;                  /* Don't change the x for every iteration */
		yinc1 = 0;                  /* Don't change the y when numerator >= denominator */
		den = deltay;
		num = deltay / 2;
		num_add = deltax;
		num_pixels = deltay;         /* There are more y-values than x-values */
	}
	
	for (curpixel = 0; curpixel <= num_pixels; curpixel++)
	{
		LoaderLcdDrawPixel(x, y, DrawProp.TextColor);   /* Draw the current pixel */
		num += num_add;                            /* Increase the numerator by the top of the fraction */
		if (num >= den)                           /* Check if numerator >= denominator */
		{
			num -= den;                             /* Calculate the new numerator value */
			x += xinc1;                             /* Change the x as appropriate */
			y += yinc1;                             /* Change the y as appropriate */
		}
		x += xinc2;                               /* Change the x as appropriate */
		y += yinc2;                               /* Change the y as appropriate */
	}
}

void BSP_LCD_DrawRect(uint16_t Xpos, uint16_t Ypos, uint16_t Width, uint16_t Height)
{
  /* Draw horizontal lines */
  BSP_LCD_DrawHLine(Xpos, Ypos, Width);
  BSP_LCD_DrawHLine(Xpos, (Ypos+ Height), Width);
  
  /* Draw vertical lines */
  BSP_LCD_DrawVLine(Xpos, Ypos, Height);
  BSP_LCD_DrawVLine((Xpos + Width), Ypos, Height);
}


void BSP_LCD_FillRect(uint16_t Xpos, uint16_t Ypos, uint16_t Width, uint16_t Height)
{
  	for (int j=0; j < Height; j++) {
		for (int i=0; i < Width; i++) {
			LoaderLcdDrawPixel(Xpos+i,Ypos+j,DrawProp.TextColor);
		}
	}
}


void BSP_LCD_FillRectangle(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, uint32_t Color)
{ 	
	for (int j=y1; j <= y2; j++) {
		for (int i=x1; i <= x2; i++) {
			LoaderLcdDrawPixel(i,j,Color);
		}
	}
}


/*****************************************************************************/
static void DrawChar(uint16_t Xpos, uint16_t Ypos, const uint8_t *c)
{
  uint32_t i = 0, j = 0;
  uint16_t height, width;
  uint8_t  offset;
  uint8_t  *pchar;
  uint32_t line;
  
  height = DrawProp.pFont->Height;
  width  = DrawProp.pFont->Width;
  
  offset =  8 *((width + 7)/8) -  width ;
  
  for(i = 0; i < height; i++)
  {
    pchar = ((uint8_t *)c + (width + 7)/8 * i);
    
    switch(((width + 7)/8))
    {
      
    case 1:
      line =  pchar[0];      
      break;
      
    case 2:
      line =  (pchar[0]<< 8) | pchar[1];      
      break;
      
    case 3:
    default:
      line =  (pchar[0]<< 16) | (pchar[1]<< 8) | pchar[2];      
      break;
    } 
    
    for (j = 0; j < width; j++)
    {
      if(line & (1 << (width- j + offset- 1))) 
      {
        BSP_LCD_DrawPixel((Xpos + j), Ypos, DrawProp.TextColor);
      }
      else
      {
        BSP_LCD_DrawPixel((Xpos + j), Ypos, DrawProp.BackColor);
      } 
    }
    Ypos++;
  }
}
