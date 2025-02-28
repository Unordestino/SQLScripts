/*******************************************
 Autor: Landry
 
 - LogShipping
********************************************/
use master
go

/****************** Prepara Hands On ***********************/
CREATE DATABASE HandsOn
go
ALTER AUTHORIZATION ON DATABASE::HandsOn TO sa
go


DROP TABLE IF exists HandsOn.dbo.Clientes 
go
CREATE TABLE HandsOn.dbo.Clientes (
ClienteID int not null constraint PK_Clientes PRIMARY KEY,
Nome varchar(50),
Telefone varchar(20))
go

INSERT HandsOn.dbo.Clientes VALUES 
(1,'Jose','1111-1111'),
(2,'Maria','2222-2222'),
(3,'Ana','3333-3333')
go

SELECT * FROM HandsOn.dbo.Clientes
go
/****************** Fim Prepara Hands On ***********************/

/*************************************
 Criar duas pastas:
 - Origem  -> C:\LogShipping
 - Destino -> C:\LogShipping
 
 Compartilhamento Origem
 - \\SRVSQL2019\LogShipping
**************************************/
exec sp_helpdb HandsOn

SELECT name as Banco, recovery_model_desc 
FROM sys.databases WHERE name = 'HandsOn'

ALTER DATABASE HandsOn SET RECOVERY FULL

BACKUP DATABASE HandsOn TO DISK = 'C:\LogShipping\Sinc\HandsOn.bak'
WITH format,compression,stats=5

RESTORE DATABASE HandsOn FROM DISK = 'C:\LogShipping\Sinc\HandsOn.bak'
WITH norecovery, replace,
MOVE 'HandsOn' TO 'C:\MSSQL_Data\HandsOn.mdf',
MOVE 'HandsOn_Log' TO 'C:\MSSQL_Data\HandsOn_Log.ldf'

-- Consultar na Instancia2
SELECT * FROM HandsOn.dbo.Clientes
SELECT * FROM SRVSQL2022.HandsOn.dbo.Clientes

INSERT HandsOn.dbo.Clientes VALUES (4,'Landry','4444-4444')

RESTORE LOG HandsOn WITH RECOVERY

-- Para ver o relatório de LogShipping, ir para o servidor monitor e ver o relatório
-- "Transaction Log Shipping Status"
exec sp_help_log_shipping_monitor 
