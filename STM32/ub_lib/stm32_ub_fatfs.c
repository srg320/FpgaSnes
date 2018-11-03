//--------------------------------------------------------------
// File     : stm32_ub_fatfs.c
// Datum    : 01.05.2014
// Version  : 1.4
// Autor    : UB
// EMail    : mc-4u(@)t-online.de
// Web      : www.mikrocontroller-4u.de
// CPU      : STM32F4
// IDE      : CooCox CoIDE 1.7.4
// GCC      : 4.7 2012q4
// Module   : FATFS (GPIO, MISC, SDIO, DMA)
// Funktion : File-Funktionen per FatFS-Library
//            an MMC-Devices
//
// Hinweis  : Anzahl der Devices : 1
//            Typ vom Device     : MMC
//            (fьr USB oder MMC+USB gibt es andere LIBs) 
//
//            Doku aller FATFS-Funktionen "doc/00index_e.html"
//
// Speed-MMC: ReadBlock  = 2,38MByte/sec (Puffer=512 Bytes)
//            WriteBlock = 499kByte/sec  (Puffer=512 Bytes)
//--------------------------------------------------------------
// Warning  : The STM32F4 in Revision-A generates a
//            "SDIO_IT_DCRCFAIL" in function "SD_ProcessIRQSrc"
//            To avoid this set the Define "SDIO_STM32F4_REV" to 0
//            (check the STM-Errata-Sheet for more information)
//            [Thanks to Major for posting this BUG...UB]
//--------------------------------------------------------------

//--------------------------------------------------------------
//Используемые выводы:

//1-битный режим:
//PC8 : SDIO_D0 = SD-карта DAT0
//PC12 : SDIO_CK = SD-карта Clock
//PD2 : SDIO_CMD = SD-карта CMD
//Примечание: вывод CD SD-карты должен быть подключен к Vcc!!

//4х-битный режим:
//PC8 : SDIO_D0 = SD-карта DAT0
//PC9 : SDIO_D1 = SD-карта DAT1
//PC10 : SDIO_D2 = SD-карта DAT2
//PC11 : SDIO_D3 = SD-карта DAT3/CD
//PC12 : SDIO_CK = SD-карта Clock
//PD2 : SDIO_CMD = SD-карта CMD

//Вывод обнаружения карты:
//PC0 : SD_Detect-Pin (Hi = SD-карта не вставленна)
//--------------------------------------------------------------


//--------------------------------------------------------------
// Includes
//--------------------------------------------------------------
#include "stm32_ub_fatfs.h"



//--------------------------------------------------------------
// Глобальные переменные
//--------------------------------------------------------------
static FATFS FileSystemObject;


//--------------------------------------------------------------
// Функция инициализации
// (инициализации для всех систем)
//--------------------------------------------------------------
void UB_Fatfs_Init(void)
{
  // инициализировать оборудование для функций SD-карты
  UB_SDCard_Init();
  // инициализировать оборудование для функций USB
  UB_USBDisk_Init();
  // инициализации аппаратных средств для функций ATA
  UB_ATADrive_Init();
}

//--------------------------------------------------------------
// Запрос статуса карты
// dev : [MMC_0]
// Возвращаемое значение:
//     FATFS_OK    => подключено
//  FATFS_NO_MEDIA => отключено
//--------------------------------------------------------------
FATFS_t UB_Fatfs_CheckMedia(MEDIA_t dev)
{
  FATFS_t ret_wert=FATFS_NO_MEDIA;
  uint8_t check=SD_NOT_PRESENT;

  // проверить наличие носителя
  if(dev==MMC_0) check=UB_SDCard_CheckMedia();
  if(check==SD_PRESENT) {
    ret_wert=FATFS_OK;
  }
  else {
    ret_wert=FATFS_NO_MEDIA;
  }

  return(ret_wert);
}

//--------------------------------------------------------------
// Монтирование носителя
// dev : [MMC_0]
// Возвращаемое значение:
//     FATFS_OK       => нет ошибки
//  FATFS_MOUNT_ERR   => ошибка
//  FATFS_GETFREE_ERR => ошибка
//--------------------------------------------------------------
FATFS_t UB_Fatfs_Mount(MEDIA_t dev)
{
  FATFS_t ret_wert=FATFS_MOUNT_ERR;
  FRESULT check=FR_INVALID_PARAMETER;
  DWORD fre_clust;
  FATFS	*fs;

  if(dev==MMC_0) check=f_mount(0, &FileSystemObject);
  if(check == FR_OK) {
    if(dev==MMC_0) check=f_getfree("0:", &fre_clust, &fs);
    if(check == FR_OK) {
      ret_wert=FATFS_OK;
    }
    else {
      ret_wert=FATFS_GETFREE_ERR;
    }
  }
  else {
    ret_wert=FATFS_MOUNT_ERR;
  }

  return(ret_wert);
}


//--------------------------------------------------------------
// Размонтирование носителя
// dev : [MMC_0]
// Возвращаемое значение:
//     FATFS_OK       => нет ошибки
//  FATFS_MOUNT_ERR   => ошибка
//--------------------------------------------------------------
FATFS_t UB_Fatfs_UnMount(MEDIA_t dev)
{
  FATFS_t ret_wert=FATFS_MOUNT_ERR;
  FRESULT check=FR_INVALID_PARAMETER;

  if(dev==MMC_0) check=f_mount(0, NULL);
  if(check == FR_OK) {
    ret_wert=FATFS_OK;
  }
  else {
    ret_wert=FATFS_MOUNT_ERR;
  }

  return(ret_wert);
}


//--------------------------------------------------------------
// Удалить файл
// Файл не может быть открыт
// Имя и полный путь, "0: /Test.txt"
// Возвращаемое значение:
//     FATFS_OK       => нет ошибки
//  FATFS_UNLINK_ERR  => ошибка
//--------------------------------------------------------------
FATFS_t UB_Fatfs_DelFile(const char* name)
{
  FATFS_t ret_wert=FATFS_UNLINK_ERR;
  FRESULT check=FR_INVALID_PARAMETER;

  check=f_unlink(name);
  if(check==FR_OK) {
    ret_wert=FATFS_OK;
  }
  else {
    ret_wert=FATFS_UNLINK_ERR;
  }

  return(ret_wert);
}


//--------------------------------------------------------------
// Открытие файла (для чтения или записи)
// Файл передается через &-оператор
// Имя и полный путь, "0: /Test.txt"
// режим : [F_RD, F_WR, F_WR_NEW, F_WR_CLEAR]
// Возвращаемое значение:
//     FATFS_OK       => нет ошибки
//  FATFS_OPEN_ERR => ошибка
//  FATFS_SEEK_ERR => Ошибка в WR и WR_NEW
//--------------------------------------------------------------
FATFS_t UB_Fatfs_OpenFile(FIL* fp, const char* name, FMODE_t mode)
{
  FATFS_t ret_wert=FATFS_OPEN_ERR;
  FRESULT check=FR_INVALID_PARAMETER;

  if(mode==F_RD) check = f_open(fp, name, FA_OPEN_EXISTING | FA_READ); 
  if(mode==F_WR) check = f_open(fp, name, FA_OPEN_EXISTING | FA_WRITE);
  if(mode==F_WR_NEW) check = f_open(fp, name, FA_OPEN_ALWAYS | FA_WRITE);
  if(mode==F_WR_CLEAR) check = f_open(fp, name, FA_CREATE_ALWAYS | FA_WRITE);

  if(check==FR_OK) {
    ret_wert=FATFS_OK;
    if((mode==F_WR) || (mode==F_WR_NEW)) {
      // Указатель на конец файла
      check = f_lseek(fp, f_size(fp));
      if(check!=FR_OK) {
        ret_wert=FATFS_SEEK_ERR;
      }
    }
  }
  else {
    ret_wert=FATFS_OPEN_ERR;
  }   

  return(ret_wert);
}

//--------------------------------------------------------------
// Закрытие файла
// Файл передается через &-оператор
// Возвращаемое значение:
//     FATFS_OK     => нет ошибки
//  FATFS_CLOSE_ERR => ошибка
//--------------------------------------------------------------
FATFS_t UB_Fatfs_CloseFile(FIL* fp)
{
  FATFS_t ret_wert=FATFS_CLOSE_ERR;
  FRESULT check=FR_INVALID_PARAMETER;

  check=f_close(fp);

  if(check==FR_OK) {
    ret_wert=FATFS_OK;
  }
  else {
    ret_wert=FATFS_CLOSE_ERR;
  }   

  return(ret_wert);
}


//--------------------------------------------------------------
// Запись строки в файл
// Файл должен быть открыт
// Файл передается через &-оператор
// Знак ('\n') означает конец строки
// Возвращаемое значение:
//     FATFS_OK       => нет ошибки
//  FATFS_PUTS_ERR => ошибка
//--------------------------------------------------------------
FATFS_t UB_Fatfs_WriteString(FIL* fp, const char* text)
{
  FATFS_t ret_wert=FATFS_PUTS_ERR;
  int check=0;

  check=f_puts(text, fp);

  if(check>=0) {
    ret_wert=FATFS_OK;
    // добавить конец строки
    f_putc('\n', fp);
  }
  else {
    ret_wert=FATFS_PUTS_ERR;
  }   

  return(ret_wert);
}


//--------------------------------------------------------------
// Чтение строки из файла
// Файл должен быть открыт
// Файл передается через &-оператор
// text : строка
// len  : Размер буфера строки, читает LEN символов или пока не достигнут конец файла
// Возвращаемое значение:
//     FATFS_OK       => нет ошибки
//    FATFS_EOF        => Fileende erreicht
// FATFS_RD_STRING_ERR => ошибка
//--------------------------------------------------------------
FATFS_t UB_Fatfs_ReadString(FIL* fp, char* text, uint32_t len)
{
  FATFS_t ret_wert=FATFS_RD_STRING_ERR;
  int check;

  f_gets(text, len, fp);
  check=f_eof(fp);
  if(check!=0) return(FATFS_EOF);
  check=f_error(fp);
  if(check!=0) return(FATFS_RD_STRING_ERR);
  ret_wert=FATFS_OK;

  return(ret_wert);
}


//--------------------------------------------------------------
// Чтение размера файла
// Файл должен быть открыт
// Файл передается через &-оператор
// Возвращаемое значение:
//   >0 => Размер файла в байтах
//   0  => ошибка
//--------------------------------------------------------------
uint32_t UB_Fatfs_FileSize(FIL* fp)
{
  uint32_t ret_wert=0;
  int filesize;

  filesize=f_size(fp);
  if(filesize>=0) ret_wert=(uint32_t)(filesize);

  return(ret_wert);
}


//--------------------------------------------------------------
// Чтение блока данных из файла
// Файл должен быть открыт
// Файл передается через &-оператор
// buf  : буффер для данных
// len  : Размер буфера данных (512 байт макс), читает LEN символов или пока не достигнут конец файла
// read : Количество считанных символов
// Возвращаемое значение:
//     FATFS_OK       => нет ошибки
//    FATFS_EOF        => достигнут конец файла
//  FATFS_RD_BLOCK_ERR => ошибка
//--------------------------------------------------------------
FATFS_t UB_Fatfs_ReadBlock(FIL* fp, unsigned char* buf, uint32_t len, uint32_t* read)
{
  FATFS_t ret_wert=FATFS_RD_BLOCK_ERR;
  FRESULT check=FR_INVALID_PARAMETER;
  UINT ulen,uread;

  ulen=(UINT)(len);
  if(ulen>_MAX_SS) {
    ret_wert=FATFS_RD_BLOCK_ERR;
    *read=0;
  }
  else {
    check=f_read(fp, buf, ulen, &uread);
    if(check==FR_OK) {
      *read=(uint32_t)(uread);
      if(ulen==uread) {
        ret_wert=FATFS_OK;
      }
      else {
        ret_wert=FATFS_EOF;
      }
    }
    else {
      ret_wert=FATFS_RD_BLOCK_ERR;
      *read=0;
    }
  }

  return(ret_wert);
}


//--------------------------------------------------------------
// Запись блока данных в файл
// Файл должен быть открыт
// Файл передается через &-оператор
// buf  : буффер для данных
// len  : Размер буфера данных (512 байт макс), запишет LEN символов
// write : Количество записанных символов
// Возвращаемое значение:
//     FATFS_OK       => нет ошибки
//    FATFS_DISK_FULL  => kein Speicherplatz mehr
//  FATFS_WR_BLOCK_ERR => ошибка
//--------------------------------------------------------------
FATFS_t UB_Fatfs_WriteBlock(FIL* fp, unsigned char* buf, uint32_t len, uint32_t* write)
{
  FATFS_t ret_wert=FATFS_WR_BLOCK_ERR;
  FRESULT check=FR_INVALID_PARAMETER;
  UINT ulen,uwrite;

  ulen=(UINT)(len);
  if(ulen>_MAX_SS) {
    ret_wert=FATFS_WR_BLOCK_ERR;
    *write=0;
  }
  else {
    check=f_write(fp, buf, ulen, &uwrite);
    if(check==FR_OK) {
      *write=(uint32_t)(uwrite);
      if(ulen==uwrite) {
        ret_wert=FATFS_OK;
      }
      else {
        ret_wert=FATFS_DISK_FULL;
      }
    }
    else {
      ret_wert=FATFS_WR_BLOCK_ERR;
      *write=0;
    }
  }

  return(ret_wert);
}

