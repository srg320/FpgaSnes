//--------------------------------------------------------------
// File     : stm32_ub_atadrive.c
// Datum    : 26.02.2013
// Version  : 1.0
// Autor    : UB
// EMail    : mc-4u(@)t-online.de
// Web      : www.mikrocontroller-4u.de
// CPU      : STM32F4
// IDE      : CooCox CoIDE 1.7.0
// Module   : keine
// Funktion : FATFS-Dateisystem für ATA-Medien
//            LoLevel-IO-Modul (nur Dummy-Funktionen)
//--------------------------------------------------------------


//--------------------------------------------------------------
// Includes
//--------------------------------------------------------------
#include "stm32_ub_atadrive.h"


//--------------------------------------------------------------
// init der Hardware fuer die ATA-Funktionen
// muss vor der Benutzung einmal gemacht werden
//--------------------------------------------------------------
void UB_ATADrive_Init(void)
{

}

//--------------------------------------------------------------
// Check ob Medium eingelegt ist
// Return Wert :
//   > 0  = wenn Medium eingelegt ist
//     0  = wenn kein Medium eingelegt ist
//--------------------------------------------------------------
uint8_t UB_ATADrive_CheckMedia(void)
{
  uint8_t ret_wert=0;

  return(ret_wert);
}

//--------------------------------------------------------------
// init der Disk
// Return Wert :
//    0 = alles ok
//  < 0 = Fehler
//--------------------------------------------------------------
int ATA_disk_initialize(void)
{
  int ret_wert=-1;

  return(ret_wert);
}


//--------------------------------------------------------------
// Disk Status abfragen
// Return Wert :
//    0 = alles ok
//  < 0 = Fehler
//--------------------------------------------------------------
int ATA_disk_status(void)
{
  int ret_wert=-1;

  return(ret_wert);
}


//--------------------------------------------------------------
// READ-Funktion
// Return Wert :
//    0 = alles ok
//  < 0 = Fehler
//--------------------------------------------------------------
int ATA_disk_read(BYTE *buff, DWORD sector, BYTE count)
{
  int ret_wert=-1;

  return(ret_wert);
}


//--------------------------------------------------------------
// WRITE-Funktion
// Return Wert :
//    0 = alles ok
//  < 0 = Fehler
//--------------------------------------------------------------
int ATA_disk_write(const BYTE *buff, DWORD sector, BYTE count)
{
  int ret_wert=-1;

  return(ret_wert);
}


//--------------------------------------------------------------
// IOCTL-Funktion
// Return Wert :
//    0 = alles ok
//  < 0 = Fehler
//--------------------------------------------------------------
int ATA_disk_ioctl(BYTE cmd, void *buff)
{
  int ret_wert=-1;

  return(ret_wert);
}


