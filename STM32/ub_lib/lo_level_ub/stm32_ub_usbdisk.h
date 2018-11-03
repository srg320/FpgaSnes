//--------------------------------------------------------------
// File     : stm32_ub_usbdisk.h
//--------------------------------------------------------------

//--------------------------------------------------------------
#ifndef __STM32F4_UB_USBDISK_H
#define __STM32F4_UB_USBDISK_H


//--------------------------------------------------------------
// Includes
//--------------------------------------------------------------
#include "stm32f4xx.h"
#include "diskio.h"






//--------------------------------------------------------------
// Globale Funktionen
//--------------------------------------------------------------
void UB_USBDisk_Init(void);
uint8_t UB_USBDrive_CheckMedia(void);
int USB_disk_initialize(void);
int USB_disk_status(void);
int USB_disk_read(BYTE *buff, DWORD sector, BYTE count);
int USB_disk_write(const BYTE *buff, DWORD sector, BYTE count);
int USB_disk_ioctl(BYTE cmd, void *buff); 


//--------------------------------------------------------------
#endif // __STM32F4_UB_USBDISK_H
