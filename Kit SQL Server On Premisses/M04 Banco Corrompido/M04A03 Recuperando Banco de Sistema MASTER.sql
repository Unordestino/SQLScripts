/**********************************************************************
 Autor: Landry Duailibe

 Hands On: Recuperando Banco de Sistema MASTER
 https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/restore-the-master-database-transact-sql?view=sql-server-ver16
 https://learn.microsoft.com/en-us/sql/relational-databases/databases/rebuild-system-databases?view=sql-server-ver16
***********************************************************************/
use master
go

CREATE DATABASE TesteDB
go

CREATE LOGIN LoginTeste WITH PASSWORD = 'Pa$$w0rd'


BACKUP DATABASE master TO DISK = 'C:\_HandsOn_AdmSQL\Backup\master.bak' WITH format,compression,differential
/*
Msg 3024, Level 16, State 0, Line 4
You can only perform a full backup of the master database. Use BACKUP DATABASE to back up the entire master database.
Msg 3013, Level 16, State 1, Line 4
BACKUP DATABASE is terminating abnormally.
*/

BACKUP DATABASE master TO DISK = 'C:\_HandsOn_AdmSQL\Backup\master.bak' WITH format,compression


/****************************************
 Restore Banco master
 Iniciar a instância com -f e -m
 ou
 cd C:\Program Files\Microsoft SQL Server\MSSQLXX.instance\MSSQL\Binn
 sqlservr -c -f -s <instance> -mSQLCMD

 cd C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Binn
  sqlservr -c -f -s MSSQLSERVER -mSQLCMD

 -f configuração mínima
 -m monousuário
 -mSQLCMD conexão apenas a apartir do SQLCMD
 -c inicializa o SQL Server como aplicação, sem utilizar o Service Control Manager
 -s nome da instância, MSSQLSERVER para default

*****************************************/

RESTORE DATABASE master FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\master.bak' WITH REPLACE


/***********************************************
 Rebuild
 cd C:\Program Files\Microsoft SQL Server\160\Setup Bootstrap\SQL2022
 setup /QUIET /ACTION=REBUILDDATABASE /INSTANCENAME=MSSQLSERVER /SQLSYSADMINACCOUNTS=srv-handson\sqlservice /SAPWD=sql$expert2024! /SQLCOLLATION=SQL_Latin1_General_CP1_CI_AS
************************************************/


