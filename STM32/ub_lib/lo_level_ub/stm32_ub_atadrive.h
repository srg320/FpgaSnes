//--------------------------------------------------------------
// File     : stm32_ub_atadrive.h
//--------------------------------------------------------------

//--------------------------------------------------------------
#ifndef __STM32F4_UB_ATADRIVE_H
#define __STM32F4_UB_ATADRIVE_H


//--------------------------------------------------------------
// Includes
//--------------------------------------------------------------
#include "stm32f4xx.h"
#include "diskio.h"






//--------------------------------------------------------------
// Globale Funktionen
//--------------------------------------------------------------
void UB_ATADrive_Init(void);
uint8_t UB_ATADrive_CheckMedia(void);
int ATA_disk_initialize(void);
int ATA_disk_status(void);
int ATA_disk_read(BYTE *buff, DWORD sector, BYTE count);
int ATA_disk_write(const BYTE *buff, DWORD sector, BYTE count);
int ATA_disk_ioctl(BYTE cmd, void *buff); 


//--------------------------------------------------------------
#endif // __STM32F4_UB_ATADRIVE_H
