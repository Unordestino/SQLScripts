/*******************************************
 Autor: Landry Duailibe

 Hands On: Criptografia de Backup
********************************************/
use master
go

/*******************************
 Cria Master Key
********************************/
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Landry123*'

-- Exporta MasterKey
OPEN MASTER KEY DECRYPTION BY PASSWORD = 'Landry123*'

BACKUP MASTER KEY TO FILE = 'C:\_HandsOn_AdmSQL\Backup\master.key'
ENCRYPTION BY PASSWORD = 'Landry123*'


/******************************
 Cria Certificado
*******************************/
CREATE CERTIFICATE BackupEncryptCert WITH SUBJECT = 'Certificado para criptografia de Backup'

-- Exporta Certificado
BACKUP CERTIFICATE BackupEncryptCert TO FILE = 'C:\_HandsOn_AdmSQL\Backup\BackupEncryptCert.cer'
WITH PRIVATE KEY (FILE = 'C:\_HandsOn_AdmSQL\Backup\BackupEncryptCert.key',
ENCRYPTION BY PASSWORD = 'Landry123*')


/*****************************
 Backup Criptografado
******************************/
BACKUP DATABASE AdventureWorks TO DISK = 'C:\_HandsOn_AdmSQL\Backup\AdventureWorks_Encrypt.bak' WITH compression, stats = 10,
ENCRYPTION (ALGORITHM = AES_256, SERVER CERTIFICATE = BackupEncryptCert)


RESTORE DATABASE AdventureWorks_Encrypt FROM DISK = 'C:\_HandsOn_AdmSQL\Backup\AdventureWorks_Encrypt.bak' WITH recovery, stats = 10,
MOVE 'AdventureWorks2012' TO 'C:\MSSQL_Data\AdventureWorks_Encrypt.mdf',
MOVE 'AdventureWorks2012_log' TO 'C:\MSSQL_Data\AdventureWorks_Encrypt_log.ldf'

-- Exclui
DROP CERTIFICATE BackupEncryptCert
DROP MASTER KEY
DROP DATABASE AdventureWorks_Encrypt

/********************************************
 Restore do Certificado em Outra Instancia
*********************************************/
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Landry123*'

CREATE CERTIFICATE BackupEncryptCert FROM FILE = 'C:\_HandsOn_AdmSQL\Backup\BackupEncryptCert.cer'
WITH PRIVATE KEY ( FILE = 'C:\_HandsOn_AdmSQL\Backup\BackupEncryptCert.key', 
DECRYPTION BY PASSWORD = 'Landry123*')


RESTORE DATABASE AdventureWorks_Encrypt FROM DISK = N'C:\_HandsOn_AdmSQL\Backup\AdventureWorks_Encrypt.bak' WITH RECOVERY, STATS = 10,
MOVE 'AdventureWorks2012' TO 'C:\MSSQL_Data_SQL02\AdventureWorks_Encrypt.mdf',
MOVE 'AdventureWorks2012_log' TO 'C:\MSSQL_Data_SQL02\AdventureWorks_Encrypt_log.mdf'
/*
Msg 33111, Level 16, State 3, Line 59
Cannot find server certificate with thumbprint '0x4B40E913C8B1FD1692AA0E05D879CD095D774B20'.
Msg 3013, Level 16, State 1, Line 59
RESTORE DATABASE is terminating abnormally.
*/

-- Exclui
DROP CERTIFICATE BackupEncryptCert
DROP MASTER KEY
DROP DATABASE AdventureWorks_Encrypt