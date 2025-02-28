/*******************************************************************
 Autor: Landry Duailibe
 
 Hands On: Histórico de JOBs
********************************************************************/
use master
go

-- https://learn.microsoft.com/en-us/sql/relational-databases/system-tables/dbo-sysjobs-transact-sql?view=sql-server-ver16
SELECT * FROM msdb.dbo.sysjobs

-- https://learn.microsoft.com/en-us/sql/relational-databases/system-tables/dbo-sysjobhistory-transact-sql?view=sql-server-ver16
SELECT * FROM msdb.dbo.sysjobhistory

/***************************
 Historico de execução
****************************/
SELECT j.name as JOB, 
CASE WHEN jh.run_date IS NULL OR jh.run_time IS NULL THEN NULL
ELSE CAST(CAST(jh.run_date AS CHAR(8)) + ' ' + STUFF(STUFF(RIGHT('000000' + 
CAST(jh.run_time AS VARCHAR(6)),6),3,0,':'),6,0,':') AS DATETIME) END as DataHora,
CASE jh.run_status
WHEN 0 THEN 'Falha'
WHEN 1 THEN 'Sucesso'
WHEN 2 THEN 'Retry'
WHEN 3 THEN 'Cancelado'
WHEN 4 THEN 'Em Execução' 
ELSE 'N/A' END as [Status],
STUFF(STUFF(RIGHT('000000' + 
CAST(jh.run_duration AS VARCHAR(6)),6),3,0,':'),6,0,':') AS [Duracao (HH:MM:SS)],
jh.message as Mensagem

FROM msdb.dbo.sysjobhistory AS jh 
INNER JOIN msdb.dbo.sysjobs AS j
ON jh.job_id = j.job_id	
WHERE jh.step_id = 0 
ORDER BY DataHora DESC


-- Criar JOB para mostrar status de execução
WAITFOR DELAY '00:00:15'