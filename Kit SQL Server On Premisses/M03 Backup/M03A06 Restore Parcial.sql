/*********************************************
 Autor: Landry Duailibe

 Hands On - Backup
**********************************************/
USE master
go
CREATE DATABASE TestDB
go

/*************************************** 
 Hands On Restore Parcial
****************************************/
CREATE TABLE TestDB.dbo.Clientes 
(ClienteID int not null primary key,
Nome varchar(50),
Telefone varchar(20))
go

/******************
 1) Backup FULL
*******************/
INSERT TestDB.dbo.Clientes VALUES (1,'Jose','1111-1111')
go

DECLARE @Arquivo varchar(4000)
set @Arquivo = 'C:\_HandsOn_AdmSQL\Backup\TestDB_' + convert(char(8),getdate(),112)+ '_H' + replace(convert(char(8),getdate(),108),':','') + '.bak'
--SELECT @Arquivo

BACKUP DATABASE TestDB TO DISK = @Arquivo WITH format,compression,stats=5
go

/******************
 3) Backup LOG
*******************/
INSERT TestDB.dbo.Clientes VALUES (2,'Paula','2222-2222') -- 15:47
INSERT TestDB.dbo.Clientes VALUES (3,'Luana','3333-3333') -- 15:50
INSERT TestDB.dbo.Clientes VALUES (4,'Landry','4444-4444') -- 15:53

SELECT * FROM TestDB.dbo.Clientes


DECLARE @Arquivo varchar(4000)
set @Arquivo = 'C:\_HandsOn_AdmSQL\Backup\TestDB_' + convert(char(8),getdate(),112)+ '_H' + replace(convert(char(8),getdate(),108),':','') + '.trn'

BACKUP LOG TestDB TO DISK = @Arquivo WITH format,compression
go

/****************************
 Restore STANDBY
*****************************/
RESTORE DATABASE TestDB_Parcial FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB_20240524_H154641.bak' WITH file=1, norecovery, replace,
MOVE 'TestDB' TO 'C:\MSSQL_Data\TestDB_Parcial.mdf',
MOVE 'TestDB_log' TO 'C:\MSSQL_Data\TestDB_Parcial_log.ldf'

RESTORE LOG TestDB_Parcial FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB_20240524_H155351.trn' WITH  
standby = 'C:\_HandsOn_AdmSQL\Backup\TestDB_Parcial.std',
stopat = '20240524 15:48:00.000'

RESTORE LOG TestDB_Parcial FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB_20240524_H155351.trn' WITH  
standby = 'C:\_HandsOn_AdmSQL\Backup\TestDB_Parcial.std',
stopat = '20240524 15:51:00.000'

RESTORE LOG TestDB_Parcial WITH recovery

SELECT * FROM TestDB_Parcial.dbo.Clientes

-- Exclui banco
use master
go
ALTER DATABASE TestDB SET single_user WITH rollback immediate
DROP DATABASE IF exists TestDB
ALTER DATABASE TestDB_Parcial SET single_user WITH rollback immediate
DROP DATABASE IF exists TestDB_Parcial

