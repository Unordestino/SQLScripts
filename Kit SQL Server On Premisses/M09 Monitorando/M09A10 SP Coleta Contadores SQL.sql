use DBA
go

/*********************************
 Tabela DBA_Coleta_Contadores
*********************************/
DROP TABLE IF exists dbo.DBA_Coleta_Contadores
go
CREATE TABLE dbo.DBA_Coleta_Contadores (
DBA_Coleta_Contadores_ID int NOT NULL identity CONSTRAINT pk_DBA_Coleta_Contadores PRIMARY KEY,
Empresa varchar(100) NOT NULL,
NomeServidor varchar(200) NOT NULL,
DataColeta datetime NOT NULL,

MEM_RAM_GB decimal(16, 2) NULL,
MEM_Livre_GB decimal(16, 2) NULL,

[Forwarded Records/sec] int NULL,
[Full Scans/sec] int NULL,
[Index Searches/sec] int NULL,
[Page Splits/sec] int NULL,
[Log Flush Waits/sec] int NULL,
[Transactions/sec] int NULL,
[Latch Waits/sec] int NULL,
[Lock Waits/sec] int NULL,
[Number of Deadlocks/sec] int NULL,
[Batch Requests/sec] int NULL,
[Page life expectancy] int NULL,
[Total Server Memory (KB)] int NULL,
[Target Server Memory (KB)] int NULL,
[Database pages] int NULL,
[Page lookups/sec] int NULL,
[User Connections] int NULL,
Processado bit not null default (0))
go


/**************************************************
 Stored Procedure: spu_DBA_Coleta_Recorrente
 - Coleta de informações de desempenho
 - Agendar execução a cada 30 segundos

 select * from dbo.DBA_Coleta_Contadores
 select * from dbo.tb_DBA_Coleta_Waits

 TRUNCATE TABLE dbo.DBA_Coleta_Contadores
 TRUNCATE TABLE dbo.tb_DBA_Coleta_Waits
***************************************************/
go
-- DROP PROCEDURE spu_DBA_Coleta_Recorrente
CREATE or ALTER PROC dbo.spu_DBA_Coleta_Recorrente
@Empresa varchar(100) = 'SQL Server Expert'
AS
set nocount on

DECLARE @DataColeta datetime

/****************************************************************
 Valor Acumulado
 cntr_type = 272696576

 - aferir dois valores, subtrair e dividir pelo tempo em segundos
   (V2 - V1) / Intervalo Seg
*****************************************************************/

/****************************
 1a coleta
*****************************/
SELECT counter_name as Contador,cntr_value as Valor
INTO #PrimeiraColeta
FROM sys.dm_os_performance_counters
WHERE cntr_type = 272696576
and instance_name in ('_Total','')
and counter_name in ('Lock Waits/sec',
'Number of Deadlocks/sec',
'Transactions/sec',
'Log Flush Waits/sec','Latch Waits/sec',
'Full Scans/sec','Index Searches/sec',
'Forwarded Records/sec','Page Splits/sec',
'Batch Requests/sec','Page lookups/sec')
ORDER BY 1,2

WAITFOR DELAY '00:00:10'

/****************************
 2a Coleta
*****************************/
SELECT counter_name as Contador,cntr_value as Valor
INTO #SegundaColeta
FROM sys.dm_os_performance_counters
WHERE cntr_type = 272696576
and instance_name in ('_Total','')
and counter_name in ('Lock Waits/sec',
'Number of Deadlocks/sec',
'Transactions/sec',
'Log Flush Waits/sec','Latch Waits/sec',
'Full Scans/sec','Index Searches/sec',
'Forwarded Records/sec','Page Splits/sec',
'Batch Requests/sec','Page lookups/sec')
ORDER BY 1,2

SET @DataColeta = getdate()

/****************************
 CTE 1a coleta x 2a Coleta
*****************************/
;WITH CTE_DuasColetas as (
SELECT @Empresa as Empresa,@@SERVERNAME as NomeServidor,
@DataColeta as DataColeta,*
FROM (
SELECT a.Contador, (b.Valor - a.Valor) / 10 as Valor
FROM #PrimeiraColeta a
JOIN #SegundaColeta b ON a.Contador = b.Contador) a
PIVOT (max(Valor) FOR Contador in 
([Forwarded Records/sec],[Full Scans/sec],[Index Searches/sec],
[Page Splits/sec],[Log Flush Waits/sec],[Transactions/sec],
[Latch Waits/sec],[Lock Waits/sec],[Number of Deadlocks/sec],
[Batch Requests/sec],[Page lookups/sec]) ) b),

/***********************
 CTE Valor direto
************************/
CTE_UmaColeta as (
SELECT @Empresa as Empresa,@@SERVERNAME as NomeServidor,
@DataColeta as DataColeta,
(select 
cast((total_physical_memory_kb/1024.00)/1024.00 as decimal(16,2)) as MEM_RAM_GB
from sys.dm_os_sys_memory) as MEM_RAM_GB,
(select 
cast((available_physical_memory_kb/1024.00)/1024.00 as decimal(16,2)) as MEM_Livre_GB
from sys.dm_os_sys_memory) as MEM_Livre_GB,* 

FROM (
SELECT counter_name,cntr_value
FROM sys.dm_os_performance_counters
WHERE cntr_type = 65792
and instance_name in ('_Total','')
and counter_name in ('Page life expectancy',
'Total Server Memory (KB)','Target Server Memory (KB)',
'Database pages','User Connections')) a
PIVOT (max(cntr_value) FOR counter_name in 
([Page life expectancy],[Total Server Memory (KB)],[Target Server Memory (KB)],
[Database pages],[User Connections]) ) b)


/*****************************
 Inclusão dados de contadores
******************************/
INSERT dbo.DBA_Coleta_Contadores
(Empresa, NomeServidor, DataColeta, MEM_RAM_GB, MEM_Livre_GB, 
[Forwarded Records/sec], [Full Scans/sec], [Index Searches/sec], [Page Splits/sec], 
[Log Flush Waits/sec], [Transactions/sec], [Latch Waits/sec], [Lock Waits/sec], 
[Number of Deadlocks/sec], [Batch Requests/sec], [Page life expectancy], 
[Total Server Memory (KB)], [Target Server Memory (KB)], [Database pages], [User Connections],
[Page lookups/sec])

SELECT a.Empresa,a.NomeServidor,a.DataColeta, a.MEM_RAM_GB, a.MEM_Livre_GB,
[Forwarded Records/sec], [Full Scans/sec], [Index Searches/sec], [Page Splits/sec], 
[Log Flush Waits/sec], [Transactions/sec], [Latch Waits/sec], [Lock Waits/sec], 
[Number of Deadlocks/sec], [Batch Requests/sec], [Page life expectancy], 
[Total Server Memory (KB)], [Target Server Memory (KB)], [Database pages],[User Connections],
[Page lookups/sec]
FROM CTE_UmaColeta a 
JOIN CTE_DuasColetas b ON b.Empresa = a.Empresa 
and b.NomeServidor = a.NomeServidor and b.DataColeta = a.DataColeta

DROP TABLE #PrimeiraColeta
DROP TABLE #SegundaColeta
go
/******************************************** FIM SP ******************************************/


/***************************************
 Criar JOB executando a cada 5 minutos
****************************************/

EXEC dbo.spu_DBA_Coleta_Recorrente @Empresa = 'SQL Server Expert'

SELECT * FROM dbo.DBA_Coleta_Contadores

/**********************************************************
 Consulta de Análise consolidando os valores por Hora
***********************************************************/
go
DECLARE @DataAnalise date = '20240701'

select cast(DataColeta as date) as Dia, 
convert(char(2),DataColeta,108) as Hora,

avg(MEM_RAM_GB) as MEM_RAM_GB,
avg(MEM_Livre_GB) as MEM_Livre_GB,

avg([User Connections]) as UserConnections_AVG,
max([User Connections]) as UserConnections_MAX,

avg([Batch Requests/sec]) as BatchRequests_AVG,
max([Batch Requests/sec]) as BatchRequests_MAX,

avg([Transactions/sec]) as Transactions_AVG,
max([Transactions/sec]) as Transactions_MAX,

(max([Total Server Memory (KB)])/1024)/1024 as TotalServerMemory_GB_MAX,
(max([Target Server Memory (KB)])/1024)/1024 as TargetServerMemory_GB_MAX,
avg(((cast([Database pages] as decimal(16,2)) * 8.00)/1024)/1024) as BufferPool_GB,

-- Ideal 20 Page Splits a cada 100 Batch Requests no maximo
avg([Page Splits/sec]) as PageSplits_AVG,
avg(([Batch Requests/sec] / 100)) * 20 as PageSplits_Ideal,

-- Ideal 10 Forwarded Records a cada 100 Batch Requests no máximo
avg([Forwarded Records/sec]) as ForwardedRecords_AVG,
avg(([Batch Requests/sec] / 100)) * 10 as ForwardedRecords_Ideal,

-- (Index Searches/sec) / (Full Scans/sec) deve ser superior a 500
avg([Full Scans/sec]) as FullScans_AVG, 
avg([Index Searches/sec]) as IndexSearches_AVG, 
avg([Index Searches/sec]) / case when avg([Full Scans/sec]) = 0 then 1 else avg([Full Scans/sec]) end as ProporcaoSearcheScan_AVG, -- Verificar
max([Index Searches/sec]) / case when max([Full Scans/sec]) = 0 then 1 else max([Full Scans/sec]) end as ProporcaoSearcheScan_MAX, -- Verificar
avg([Index Searches/sec] / case when [Full Scans/sec] = 0 then 1 else [Full Scans/sec] end) as ProporcaoSearcheScan_AVG2, -- Verificar
max([Index Searches/sec] / case when [Full Scans/sec] = 0 then 1 else [Full Scans/sec] end) as ProporcaoSearcheScan_MAX2, -- Verificar
500.00 as ProporcaoSearcheScan_Ideal,

-- (Page lookups) / (Batch Requests) deve ser menor que 100 (plano de execução ineficiente, consultas com volume alto de IO)
avg([Page lookups/sec]) / case when avg([Batch Requests/sec]) = 0 then 1 else avg([Batch Requests/sec]) end as Pagelookups_AVG,
100.00 as Pagelookups_Ideal,

--  Page life expectancy deve ser superior a (Total Server Memory em GB) / 4 * 300
avg([Page life expectancy]) as PageLifeExpectancy_AVG,
avg(((([Total Server Memory (KB)]/1024)/1024) / 4)) * 300 as PageLifeExpectancy_Ideal,

avg([Log Flush Waits/sec]) as LogFlushWaits_AVG,

-- Vaor ideal inferior a 1.00
avg([Lock Waits/sec]) as LockWaitsSec_AVG,
max([Lock Waits/sec]) as LockWaitsSec_MAX,
1.00 as LockWaitsSec_Ideal,

max([Number of Deadlocks/sec]) as Deadlocks_sec

FROM dbo.DBA_Coleta_Contadores
WHERE DataColeta >= @DataAnalise and DataColeta < dateadd(dd,1,@DataAnalise)
GROUP BY cast(DataColeta as date), convert(char(2),DataColeta,108)

