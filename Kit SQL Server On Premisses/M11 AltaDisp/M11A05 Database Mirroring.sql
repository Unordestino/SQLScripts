/*******************************************
 Autor: Landry Duailibe
  
 Hands On: Database Mirror
********************************************/
use master
go

/****************** Prepara Demonstração ***********************/
CREATE DATABASE MirrorDB
go

Use MirrorDB
go
-- DROP TABLE dbo.Clientes 
CREATE TABLE dbo.Clientes 
(ClienteID int not null primary key,Nome varchar(50),Telefone varchar(20))
go

INSERT dbo.Clientes VALUES 
(1,'Jose','1111-1111'),
(2,'Maria','2222-2222'),
(3,'Ana','3333-3333')
go

SELECT * FROM dbo.Clientes
go
/****************** Fim Prepara Demonstração ***********************/

/****************** Inicio Demonstração Database Mirror ***************/
use Master
go

/*************************** 
 Cria ENDPOINT 
****************************/
-- PRINCIPAL: Criar endpoint e recovery model FULL
-- DROP ENDPOINT endpoint_mirroring
CREATE ENDPOINT endpoint_mirroring STATE = STARTED
AS TCP ( LISTENER_PORT = 5022 ) FOR DATABASE_MIRRORING (ROLE=PARTNER)
go
ALTER DATABASE MirrorDB SET RECOVERY FULL
go

GRANT CONNECT ON ENDPOINT::endpoint_mirroring TO [cursoadm\SQLService]

-- MIRROR: Criar endpoint
-- DROP ENDPOINT endpoint_mirroring
CREATE ENDPOINT endpoint_mirroring STATE = STARTED
AS TCP ( LISTENER_PORT = 5022 ) FOR DATABASE_MIRRORING (ROLE=PARTNER)
go
GRANT CONNECT ON ENDPOINT::endpoint_mirroring TO [cursoadm\SQLService]

-- WITNESS: Criar endpoint
CREATE ENDPOINT endpoint_mirroring STATE = STARTED
AS TCP ( LISTENER_PORT = 5022 ) FOR DATABASE_MIRRORING (ROLE=WITNESS)
go
GRANT CONNECT ON ENDPOINT::endpoint_mirroring TO [cursoadm\SQLService]


/************************** 
 BACKUP e RESTORE 
 - Criar pasta D:\MirrorSinc
***************************/
-- PRINCIPAL: Fazer Backup FULL e LOG

BACKUP DATABASE MirrorDB TO DISK = 'F:\HandsOn\Backup\MirrorDB.bak' 
WITH format,compression,stats=5

BACKUP LOG MirrorDB TO DISK = 'F:\HandsOn\Backup\MirrorDB.trn' 
with format,compression,stats=5

-- MIRROR: Criar pasta E:\Mirror e fazer Restore dos Backups FULL e LOG

RESTORE DATABASE MirrorDB FROM DISK = 'F:\HandsOn\Backup\MirrorDB.bak' 
WITH norecovery,stats=5

RESTORE LOG MirrorDB FROM DISK = 'F:\HandsOn\Backup\MirrorDB.trn' 
WITH norecovery,stats=5

/***************** Inicializa o MIRROR ******************************/
-- MIRROR: Link do Mirror com o Principal
ALTER DATABASE MirrorDB SET PARTNER = 'TCP://sql1-cursoadm:5022'

-- ALTER DATABASE MirrorDB SET PARTNER OFF
go

-- PRINCIPAL: Link do Principal com o Mirror
ALTER DATABASE MirrorDB SET PARTNER = 'TCP://sql2-cursoadm:5022'
go

-- PRINCIPAL: Link do Principal com o witness 
ALTER DATABASE MirrorDB SET WITNESS = 'TCP://sql1-cursoadm:5022'
go

/************************** TESTE de INSERT *************************/
-- MIRROR: Cria Database Snapshot e Consulta tabela Clientes
-- DROP DATABASE MirrorDB_Snapshot
CREATE DATABASE MirrorDB_Snapshot ON
( NAME = 'MirrorDB_Data', FILENAME = 'F:\data\MirrorDB.ss')
AS SNAPSHOT OF MirrorDB
go
-- DROP DATABASE MirrorDB_Snapshot

SELECT * FROM MirrorDB_Snapshot.dbo.Clientes

-- PRINCIPAL: Consulta tabela
INSERT MirrorDB.dbo.Clientes VALUES (4,'Landry','4444-4444')

SELECT * FROM MIRRORDB.DBO.CLIENTES



/*********************** 
 Comando para FAILOVER 
************************/ 
-- Failover manual

ALTER DATABASE MirrorDB SET PARTNER FAILOVER

-- Parar MIRROR na perda do Principal
ALTER DATABASE MirrorDB SET PARTNER OFF
RESTORE LOG MirrorDB with recovery


ALTER DATABASE MirrorDB SET PARTNER FORCE_SERVICE_ALLOW_DATA_LOSS

/*******************************
 Troca de modo de operação
********************************/

ALTER DATABASE MirrorDB SET PARTNER SAFETY OFF

ALTER DATABASE MirrorDB SET PARTNER SAFETY FULL


/******************** Exclui ENDPOINT e BANCO ************************/ 
-- Drop endpoint
DROP ENDPOINT endpoint_mirroring

-- Drop database
DROP DATABASE MirrorDB

