/*******************************************
 Autor: Landry Duailibe

 Hands On: WRITELOG WAIT
********************************************/
use master
go

/**************************
 Prepara Hands On
 - Leva +- 2 minutos
***************************/
DROP DATABASE IF exists HandsOn_nTransacoes
go
DROP DATABASE IF exists HandsOn_1Transacao
go

-- 1) Multiplas Transações
CREATE DATABASE HandsOn_nTransacoes
ON  PRIMARY 
(NAME = 'HandsOn_nTransacoes', FILENAME = 'C:\MSSQL_Data\HandsOn_nTransacoes.mdf', SIZE = 6GB, MAXSIZE = UNLIMITED, FILEGROWTH = 500MB)
LOG ON 
(NAME = 'HandsOn_nTransacoes_log', FILENAME = 'C:\MSSQL_Data\HandsOn_nTransacoes_log.ldf' , SIZE = 1GB, MAXSIZE = UNLIMITED, FILEGROWTH = 64MB)
go
--ALTER DATABASE HandsOn_nTransacoes SET RECOVERY SIMPLE
go
DROP TABLE IF exists HandsOn_nTransacoes.dbo.Venda
go
CREATE TABLE HandsOn_nTransacoes.dbo.Venda (
Venda_ID int not null identity CONSTRAINT pk_Venda PRIMARY KEY,
Data_Venda datetime not null,
Cliente_ID int null,
Produto_ID int null,
Valor_Total decimal(19,2) null,
Obs char(4000) null)
go
use HandsOn_nTransacoes
go
-- SP com múltiplas Transações
CREATE or ALTER PROC dbo.spu_SQLStress20
as
set nocount on

DECLARE @i int = 1
WHILE @i < 10000 BEGIN
	INSERT Venda (Data_Venda,Cliente_ID,Produto_ID,Valor_Total,Obs)
    VALUES (getdate(), @i , @i + 100, @i / 0.5, 'Teste Log: ' + ltrim(str(@i)))
	SET @i += 1
END
go

-- 2) Uma transação
CREATE DATABASE HandsOn_1Transacao
ON  PRIMARY 
(NAME = 'HandsOn_1Transacao', FILENAME = 'C:\MSSQL_Data\HandsOn_1Transacao.mdf', SIZE = 6GB, MAXSIZE = UNLIMITED, FILEGROWTH = 500MB)
LOG ON 
(NAME = 'HandsOn_1Transacao_log', FILENAME = 'C:\MSSQL_Data\HandsOn_1Transacao_log.ldf' , SIZE = 1GB, MAXSIZE = UNLIMITED, FILEGROWTH = 64MB)
go
--ALTER DATABASE HandsOn_1Transacao SET RECOVERY SIMPLE
go
DROP TABLE IF exists HandsOn_1Transacao.dbo.Venda
go
CREATE TABLE HandsOn_1Transacao.dbo.Venda (
Venda_ID int not null identity CONSTRAINT pk_Venda PRIMARY KEY,
Data_Venda datetime not null,
Cliente_ID int null,
Produto_ID int null,
Valor_Total decimal(19,2) null,
Obs char(4000) null)
go
use HandsOn_1Transacao
go
-- SP uma Transação
CREATE or ALTER PROC dbo.spu_SQLStress20
as
set nocount on

BEGIN TRY
	BEGIN TRAN

		DECLARE @i int = 1
		WHILE @i < 10000 BEGIN
			INSERT Venda (Data_Venda,Cliente_ID,Produto_ID,Valor_Total,Obs)
			VALUES (getdate(), @i , @i + 100, @i / 0.5, 'Teste Log: ' + ltrim(str(@i)))
			SET @i += 1
		END

	COMMIT
END TRY
BEGIN CATCH
	THROW
	IF @@TRANCOUNT > 0
		ROLLBACK
END CATCH
go
use master
go
/********************************* FIM PRepara Hands On *****************************/


/*******************************************************
 sys.dm_os_wait_stats
 https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-wait-stats-transact-sql?view=sql-server-ver16

 - waiting_tasks_count: quantidade de ocorrências no período.
 - wait_time_ms: tempo total de espera em milissegundos acumulado no período. (1 seg = 1000 milissegundos / 1 min = 60000 milissegundos)
 - max_wait_time_ms: tempo de espera máximo encontrado no período.
 - signal_wait_time_ms: Diferença entre a hora em que o thread de espera foi sinalizado e quando ele começou a ser executado.
********************************************************/

-- Zera estatísticas da DMV sys.dm_os_wait_stats
DBCC SQLPERF ('sys.dm_os_wait_stats', CLEAR)

SELECT wait_type,waiting_tasks_count, wait_time_ms 
FROM sys.dm_os_wait_stats 
WHERE wait_type in ('WRITELOG')


EXEC HandsOn_nTransacoes.dbo.spu_SQLStress20
/*****************************************************
1) Várias transações

wait_type	waiting_tasks_count	wait_time_ms
WRITELOG	10005				4655
***************************************************/

EXEC HandsOn_1Transacao.dbo.spu_SQLStress20
/*****************************************************
2) Uma transação

wait_type	waiting_tasks_count	wait_time_ms
WRITELOG	7					140
***************************************************/

/******************
 Exclui Bancos
*******************/
DROP DATABASE IF exists HandsOn_nTransacoes
DROP DATABASE IF exists HandsOn_1Transacao


