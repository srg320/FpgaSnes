//--------------------------------------------------------------
// File     : stm32_ub_fatfs.h
//--------------------------------------------------------------

//--------------------------------------------------------------
#ifndef __STM32F4_UB_FATFS_H
#define __STM32F4_UB_FATFS_H


//--------------------------------------------------------------
// Includes
//--------------------------------------------------------------
#include "stm32f4xx.h"
#include "ff.h"                // FATFS-Funktionen
#include "stm32_ub_sdcard.h"   // SD-Funktionen
#include "stm32_ub_usbdisk.h"  // USB-Funktionen
#include "stm32_ub_atadrive.h" // ATA-Funktionen


//--------------------------------------------------------------
// Тип карты (в данном примере только MMC)
//--------------------------------------------------------------
typedef enum {
  MMC_0 = 0       // данная библиотека поддерживает только MMC
}MEDIA_t;


//--------------------------------------------------------------
// коды ошибок
//--------------------------------------------------------------
typedef enum {
  FATFS_OK =0,
  FATFS_NO_MEDIA,
  FATFS_MOUNT_ERR,
  FATFS_GETFREE_ERR,
  FATFS_UNLINK_ERR,
  FATFS_OPEN_ERR,
  FATFS_CLOSE_ERR,
  FATFS_PUTS_ERR,
  FATFS_SEEK_ERR,
  FATFS_RD_STRING_ERR,
  FATFS_RD_BLOCK_ERR,
  FATFS_WR_BLOCK_ERR,
  FATFS_EOF,
  FATFS_DISK_FULL
}FATFS_t;


//--------------------------------------------------------------
// Режим для OpenFile
//--------------------------------------------------------------
typedef enum {
  F_RD =0,    // зачитать (только если файл существует)
  F_WR,       // записать (только если файл существует) и добавить данные
  F_WR_NEW,   // записать (создать новый файл) и добавить данные
  F_WR_CLEAR  // записать поверх (удалить старые данные)
}FMODE_t;


//--------------------------------------------------------------
// Глобальная функция
//--------------------------------------------------------------
void UB_Fatfs_Init(void);
FATFS_t UB_Fatfs_CheckMedia(MEDIA_t dev);
FATFS_t UB_Fatfs_Mount(MEDIA_t dev);
FATFS_t UB_Fatfs_UnMount(MEDIA_t dev);
FATFS_t UB_Fatfs_DelFile(const char* name);
FATFS_t UB_Fatfs_OpenFile(FIL* fp, const char* name, FMODE_t mode);
FATFS_t UB_Fatfs_CloseFile(FIL* fp);
FATFS_t UB_Fatfs_WriteString(FIL* fp, const char* text);
FATFS_t UB_Fatfs_ReadString(FIL* fp, char* text, uint32_t len);
uint32_t UB_Fatfs_FileSize(FIL* fp);
FATFS_t UB_Fatfs_ReadBlock(FIL* fp, unsigned char* buf, uint32_t len, uint32_t* read);
FATFS_t UB_Fatfs_WriteBlock(FIL* fp, unsigned char* buf, uint32_t len, uint32_t* write);


//--------------------------------------------------------------
#endif // __STM32F4_UB_FATFS_H
