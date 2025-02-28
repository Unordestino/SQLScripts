/*******************************************
 Autor: Landry Duailibe
 
 Hands On: Transparent data encryption (TDE)
********************************************/
use master
go

/****************** Prepara Hands On ***********************/
DROP DATABASE IF exists DBCript
go
CREATE DATABASE DBCript
go

use DBCript
go
-- DROP TABLE dbo.Clientes 
CREATE TABLE dbo.Clientes (
ClienteID int not null CONSTRAINT pk_Clientes PRIMARY KEY,
Nome varchar(50),
Telefone varchar(20))
go

INSERT dbo.Clientes VALUES 
(1,'Jose','1111-1111'),
(2,'Maria','2222-2222'),
(3,'Maria','3333-3333')
go

SELECT * FROM dbo.Clientes

/********************************/

use master
go

-- Cria Master Key
-- DROP MASTER KEY
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Pa$$w0rd';

-- Cria Certificado
-- DROP CERTIFICATE DBCriptCert
CREATE CERTIFICATE DBCriptCert WITH SUBJECT = 'Certificado para TDE', EXPIRY_DATE = '99991231'

-- Backup Certificado
BACKUP CERTIFICATE DBCriptCert TO FILE = 'C:\_HandsOn_AdmSQL\Backup\DBCriptCert.cer'
WITH PRIVATE KEY (FILE = 'C:\_HandsOn_AdmSQL\Backup\DBCriptCert.key',
ENCRYPTION BY PASSWORD = 'Pa$$w0rd')


/*********************************
 Habilitando TDE
**********************************/
use DBCript
go

CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_128
ENCRYPTION BY SERVER CERTIFICATE DBCriptCert

ALTER DATABASE DBCript SET ENCRYPTION ON


/**************************
 Backup com criptografia
***************************/
BACKUP DATABASE DBCript to disk = 'C:\_HandsOn_AdmSQL\Backup\DBCript.bak' with init,compression
go

-- Ver status de Banco criptografado
SELECT name as Banco, is_encrypted 
FROM sys.databases 
WHERE name = 'DBCript'

/*************************
 Verifica Status
**************************/
SELECT DB_NAME(database_id) as Banco,
encryption_state, encryption_state_desc, percent_complete,
key_algorithm, key_length, encryptor_type
FROM sys.dm_database_encryption_keys
WHERE DB_NAME(database_id) in ('DBCript')
and percent_complete > 0
ORDER BY Banco

SELECT name as Banco, is_encrypted 
FROM sys.databases
where database_id > 4
and name not in ('ReportServer','ReportServerTempDB','SSISDB')
ORDER BY name

/**************************************
 - Restore na instancia2 gera erro
***************************************/
restore database DBCript from disk = 'C:\_HandsOn_AdmSQL\Backup\DBCript.bak' with
move 'DBCript' to 'C:\MSSQL_Data_SQL02\DBCript.mdf',
move 'DBCript_Log' to 'C:\MSSQL_Data_SQL02\DBCript_Log.ldf'
/*
Msg 33111, Level 16, State 3, Line 66
Cannot find server certificate with thumbprint '0xE9323F15BA9A9BBD57EED44EC88B41A1C010D6A7'.
Msg 3013, Level 16, State 1, Line 66
RESTORE DATABASE is terminating abnormally.
*/

-- Cria Master Key
use master
go
-- DROP MASTER KEY
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Pa$$w0rd'
go

-- Importa Certificado
-- DROP CERTIFICATE DBCriptCert
CREATE CERTIFICATE DBCriptCert FROM FILE = 'C:\_HandsOn_AdmSQL\Backup\DBCriptCert.cer'
WITH PRIVATE KEY ( FILE = 'C:\_HandsOn_AdmSQL\Backup\DBCriptCert.key', 
DECRYPTION BY PASSWORD = 'Pa$$w0rd')
go

-- Restaurar o banco

-- DROP
USE master
go
DROP DATABASE IF exists DBCript
DROP CERTIFICATE DBCriptCert
DROP MASTER KEY
