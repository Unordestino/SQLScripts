/*********************************************
 Autor: Landry Duailibe

 Hands On - Backup
**********************************************/
USE master
go
CREATE DATABASE TestDB
go


/**************************
 BACKUP Device
***************************/

-- Cria DEVICE
EXEC master.dbo.sp_addumpdevice  
@devtype = N'disk', 
@logicalname = N'BackupMaster', 
@physicalname = N'C:\_HandsOn_AdmSQL\Backup\BackupMaster.bak'
go

-- Backup Device
BACKUP DATABASE master TO BackupMaster

-- Backup File
BACKUP DATABASE master TO DISK = 'C:\_HandsOn_AdmSQL\Backup\BackupMaster.bak'
go

/***********************************
 Habilitar Compressão na Instância
************************************/
EXEC sp_configure 'show advanced options', 1
RECONFIGURE

EXEC sp_configure 'backup compression default', 1
RECONFIGURE

/*************************************** 
 Hands On Backup e Restore
****************************************/
use TestDB
go

CREATE TABLE dbo.Clientes 
(ClienteID int not null primary key,
Nome varchar(50),
Telefone varchar(20))
go

SELECT * FROM TestDB.dbo.Clientes

/******************
 1) Backup FULL
*******************/
INSERT dbo.Clientes VALUES (1,'Jose','1111-1111')
go

BACKUP DATABASE TestDB TO DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.bak' WITH format,compression,stats=5


/******************
 2) Backup DIF
*******************/
INSERT dbo.Clientes VALUES (2,'Paula','2222-2222')
go

BACKUP DATABASE TestDB TO DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.bak' WITH noinit,compression,differential

/******************
 3) Backup LOG
*******************/
INSERT dbo.Clientes VALUES (3,'Luana','3333-3333')
go

BACKUP LOG TestDB TO DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.bak' WITH noinit,compression


RESTORE HEADERONLY FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.bak'
-- https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-headeronly-transact-sql?view=sql-server-ver16
/* BackupType
1 = FULL
2 = Transaction log
4 = File
5 = Differential database
6 = Differential file
7 = Partial
8 = Differential partial
*/

/***************************************
 4) Backup Log Reflexo Medular (RM)
****************************************/
INSERT dbo.Clientes VALUES (4,'Landry','4444-4444')
go

-- SIMULANDO FALHA: Parar o serviço do SQL Server e renomear o arquivo de dados

BACKUP LOG TestDB TO DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.bak' WITH noinit,compression,no_truncate
--WITH CONTINUE_AFTER_ERROR or WITH NO_TRUNCATE




/****************************
 Restore
*****************************/
-- Obtém informações de um Backup
RESTORE FILELISTONLY FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.bak' WITH file=1

RESTORE DATABASE TestDB FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.bak' WITH file=1, norecovery, replace
RESTORE DATABASE TestDB FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.bak' WITH file=2, norecovery
RESTORE LOG TestDB FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.bak' WITH file=3, norecovery
RESTORE LOG TestDB FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.bak' WITH file=4, recovery

-- RESTORE LOG TestDB WITH RECOVERY

SELECT * FROM TestDB.dbo.Clientes

/****************************
 Restore STANDBY
*****************************/
RESTORE DATABASE TestDB FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.bak' WITH file=1, norecovery, replace
RESTORE DATABASE TestDB FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.bak' WITH file=2, norecovery
RESTORE LOG TestDB FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.bak' WITH file=3, standby = 'C:\_HandsOn_AdmSQL\Backup\TestDB.std'
RESTORE LOG TestDB FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.bak' WITH file=4, recovery

SELECT * FROM TestDB.dbo.Clientes

/***********************************
 Histórico Backup
 https://learn.microsoft.com/en-us/sql/relational-databases/system-tables/backupset-transact-sql?view=sql-server-ver16
************************************/
SELECT * FROM msdb..backupset

-- Bancos sem Backup nos últimos 7 dias
SELECT [name] as Banco, recovery_model_desc as RecoveryModel, create_date as DataCriacao 
FROM sys.databases
WHERE database_id > 4 and NAME not in (
SELECT DISTINCT database_name FROM msdb..backupset
WHERE backup_start_date > DATEADD(DAY,-8,GETDATE()) AND  TYPE <> 'L')
/*
D = Database
I = Differential database
L = Log
F = File or filegroup
G = Differential file
P = Partial
Q = Differential partial
*/

-- Backups de um determinado Banco
SELECT a.backup_start_date as Datainicio,a.backup_finish_date as DataTermino,a.[database_name] as Banco, 
case a.[type]
when 'D' then 'FULL'
when 'I' then 'DIF'
when 'L' then 'LOG' end as TipoBackup,
b.physical_device_name as ArquivoBackup,
a.user_name as usuario, a.is_copy_only, a.is_snapshot
FROM  msdb..backupset a
JOIN msdb..backupmediafamily b on b.media_set_id = a.media_set_id
WHERE 1=1
and database_name = 'TestDB'
--and a.type <> 'L'
and backup_finish_date >= '20220601'
ORDER BY Banco,backup_finish_date desc


-- Exclui banco
use master
go
DROP DATABASE IF exists TestDB

