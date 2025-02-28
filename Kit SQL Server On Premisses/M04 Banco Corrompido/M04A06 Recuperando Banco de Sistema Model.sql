/**********************************************************************
 Autor: Landry Duailibe

 Hands On: Recuperando Banco de Sistema MODEL
***********************************************************************/
use master
go

-- Iniciar com Trace Flag 3608 (-t3608) e fazer Backup no SQLCMD
BACKUP DATABASE master TO DISK = 'C:\_HandsOn_AdmSQL\Backup\master.bak' WITH format,compression
BACKUP DATABASE msdb TO DISK = 'C:\_HandsOn_AdmSQL\Backup\msdb.bak' WITH format,compression


/*****************************************************************************
 Restore MASTER

 1) Rebuild
 cd C:\Program Files\Microsoft SQL Server\160\Setup Bootstrap\SQL2022
 setup /QUIET /ACTION=REBUILDDATABASE /INSTANCENAME=MSSQLSERVER /SQLSYSADMINACCOUNTS=srv-handson\sqlservice /SAPWD=sql$expert2024! /SQLCOLLATION=SQL_Latin1_General_CP1_CI_AS

 2) Iniciar a instância com -f e -m

 3) Restore com o SQLCMD 
******************************************************************************/

RESTORE DATABASE master FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\master.bak' WITH REPLACE

/**********************
 Restore MSDB
***********************/
RESTORE DATABASE msdb FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\msdb.bak' WITH recovery,replace