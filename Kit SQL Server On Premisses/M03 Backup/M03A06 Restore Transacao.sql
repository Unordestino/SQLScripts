/*********************************************
 Autor: Landry Duailibe

 Hands On - Restore Marcando Transação
**********************************************/
USE master
go
CREATE DATABASE TestDB
go

/*************************************** 
 Hands On
****************************************/
DROP TABLE IF exists TestDB.dbo.Clientes
go
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

BACKUP DATABASE TestDB TO DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.bak' WITH format,compression,stats=5


/******************
 2) Backup LOG
*******************/
INSERT TestDB.dbo.Clientes VALUES (2,'Paula','2222-2222')

BEGIN TRANSACTION HandsOn1 WITH MARK 'Transacao 1'
INSERT TestDB.dbo.Clientes VALUES (3,'Luana','3333-3333')
INSERT TestDB.dbo.Clientes VALUES (4,'Landry','4444-4444')
COMMIT

INSERT TestDB.dbo.Clientes VALUES (5,'Marina','5555-5555')
go

BEGIN TRANSACTION HandsOn2 WITH MARK 'Transacao 2'
INSERT TestDB.dbo.Clientes VALUES (6,'Carla','6666-6666')
INSERT TestDB.dbo.Clientes VALUES (7,'João','7777-7777')
INSERT TestDB.dbo.Clientes VALUES (8,'Rafael','8888-8888')
COMMIT
go

INSERT TestDB.dbo.Clientes VALUES (9,'Luciana','9999-9999')
go

SELECT * FROM msdb.dbo.logmarkhistory

SELECT * FROM TestDB.dbo.Clientes

BACKUP LOG TestDB TO DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.trn' WITH format,compression

/****************************
 Restore MARK
*****************************/
ALTER DATABASE TestDB_MARK SET single_user WITH rollback immediate

RESTORE DATABASE TestDB_MARK FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.bak' WITH file=1, norecovery, replace,
MOVE 'TestDB' TO 'C:\MSSQL_Data\TestDB_MARK.mdf',
MOVE 'TestDB_log' TO 'C:\MSSQL_Data\TestDB_MARK_log.ldf'

-- Restore parando no final da transação marcada
RESTORE LOG TestDB_MARK FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.trn' 
WITH stopatmark = 'HandsOn1',
standby = 'C:\_HandsOn_AdmSQL\Backup\TestDB_Parcial.std'

-- Restore parando antes da execução da transação marcada
RESTORE LOG TestDB_MARK FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\TestDB.trn' 
WITH stopbeforemark = 'HandsOn1',
standby = 'C:\_HandsOn_AdmSQL\Backup\TestDB_Parcial.std'

RESTORE LOG TestDB_MARK WITH recovery

SELECT * FROM TestDB_MARK.dbo.Clientes

-- Exclui banco
use master
go
ALTER DATABASE TestDB SET single_user WITH rollback immediate
DROP DATABASE IF exists TestDB
ALTER DATABASE TestDB_MARK SET single_user WITH rollback immediate
DROP DATABASE IF exists TestDB_MARK
TRUNCATE TABLE msdb.dbo.logmarkhistory

