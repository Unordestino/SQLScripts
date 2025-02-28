/**********************************************************************
 Autor: Landry Duailibe

 Hands On: Recuperando Banco de Sistema MSDB
***********************************************************************/
use master
go

BACKUP DATABASE msdb TO DISK = 'C:\_HandsOn_AdmSQL\Backup\msdb.bak' WITH format,compression

BACKUP DATABASE msdb TO DISK = 'C:\_HandsOn_AdmSQL\Backup\msdb.dif' WITH format,compression,differential

BACKUP LOG msdb TO DISK = 'C:\_HandsOn_AdmSQL\Backup\msdb.trn' WITH format,compression
/*
Msg 4208, Level 16, State 1, Line 7
The statement BACKUP LOG is not allowed while the recovery model is SIMPLE. Use BACKUP DATABASE or change the recovery model using ALTER DATABASE.
Msg 3013, Level 16, State 1, Line 7
BACKUP LOG is terminating abnormally.
*/

/**********************
 Restore
***********************/
RESTORE DATABASE msdb FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\msdb.bak' WITH recovery,replace
/*
Msg 3101, Level 16, State 1, Line 18
Exclusive access could not be obtained because the database is in use.
Msg 3013, Level 16, State 1, Line 18
RESTORE DATABASE is terminating abnormally.
*/

RESTORE DATABASE msdb FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\msdb.bak' WITH norecovery,replace
RESTORE DATABASE msdb FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\msdb.dif' WITH recovery,replace
