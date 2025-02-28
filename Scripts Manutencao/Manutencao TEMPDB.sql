exec sp_helpdb tempdb

use tempdb
go

-- Completo
CHECKPOINT
go
dbcc freeproccache
go
dbcc dropcleanbuffers
go
dbcc freesessioncache
go
-- Cuidado perda temporária de desempenho
dbcc freesystemcache ('ALL')
go
--dbcc freesystemcache ('TEMPDB')
go

--waitfor delay '00:00:30'
CHECKPOINT
DBCC SHRINKFILE (N'tempdev' ,5000)
CHECKPOINT
DBCC SHRINKFILE (N'tempdev2' ,5000)
CHECKPOINT
DBCC SHRINKFILE (N'tempdev3' ,1000)
CHECKPOINT
DBCC SHRINKFILE (N'tempdev4' ,1000)
CHECKPOINT
DBCC SHRINKFILE (N'templog' ,5000)

/**********************************
 Loop de um arquivo
***********************************/
exec sp_helpdb tempdb
go

CHECKPOINT
dbcc freeproccache
dbcc dropcleanbuffers
dbcc freesessioncache
dbcc freesystemcache ('ALL')
--waitfor delay '00:00:02'
DBCC SHRINKFILE (N'tempdev' ,5000)
CHECKPOINT
DBCC SHRINKFILE (N'tempdev2' ,5000)
go 4


SELECT TOP 1000 PK_OcupacaoBD, Data, Tamanho_MB, EspacoUtil_MB,
EspacoLivreMB, ObjetosUsuarioMB, VersionStoreMB, ObjetosInternosMB, TransacoesXML
FROM msdb.dbo.DBA_Monitora_TempDB
ORDER BY Data desc

/*********************************************
 Transações Abertas
**********************************************/
SELECT tas.transaction_begin_time,trans.session_id AS [SPID],
ESes.host_name AS [HOST NAME],login_name AS [Login NAME],
tas.transaction_id,tas.name as Transaction_Name,
case 
when transaction_type = 1 then 'Read/write transaction'
when transaction_type = 2 then 'Read-only transaction'
when transaction_type = 3 then 'System transaction'
when transaction_type = 4 then 'Distributed transaction'
end as TransactionType,
case
when transaction_state = 0 then 'The transaction has not been completely initialized yet'
when transaction_state = 1 then 'The transaction has been initialized but has not started'
when transaction_state = 2 then 'The transaction is active'
when transaction_state = 3 then 'The transaction has ended. This is used for read-only transactions'
when transaction_state = 4 then 'The commit process has been initiated on the distributed transaction'
when transaction_state = 5 then 'The transaction is in a prepared state and waiting resolution'
when transaction_state = 6 then 'The transaction has been committed'
when transaction_state = 7 then 'The transaction is being rolled back'
when transaction_state = 8 then 'The transaction has been rolled back'
end as TransactionState

FROM sys.dm_tran_active_transactions tas
LEFT JOIN sys.dm_tran_session_transactions trans ON trans.transaction_id=tas.transaction_id
LEFT OUTER JOIN sys.dm_exec_sessions AS ESes ON trans.session_id = ESes.session_id
WHERE trans.session_id is not null
ORDER BY tas.transaction_begin_time

SELECT * FROM sys.dm_exec_sessions WHERE session_id = 682
SELECT log_reuse_wait_desc FROM sys.databases WHERE [name] = 'tempdb'

DBCC OPENTRAN

dbcc inputbuffer(601)

-- Transações ativas TEMPDB
SELECT 
dtat.transaction_id,
dtat.[name],
dtat.transaction_begin_time,
 case transaction_type  
      when 1 then 'Read/Write'   
      when 2 then 'Read-Only'    
      when 3 then 'System'   
      when 4 then 'Distributed'  
      else 'Unknown - ' + convert(varchar(20), transaction_type)     
 end as tranType,    
 case transaction_state 
      when 0 then 'Uninitialized' 
      when 1 then 'Not Yet Started' 
      when 2 then 'Active' 
      when 3 then 'Ended (Read-Only)' 
      when 4 then 'Committing' 
      when 5 then 'Prepared' 
      when 6 then 'Committed' 
      when 7 then 'Rolling Back' 
      when 8 then 'Rolled Back' 
      else 'Unknown - ' + convert(varchar(20), transaction_state) 
 end as tranState, 
 case dtc_state 
      when 0 then NULL 
      when 1 then 'Active' 
      when 2 then 'Prepared' 
      when 3 then 'Committed' 
      when 4 then 'Aborted' 
      when 5 then 'Recovered' 
      else 'Unknown - ' + convert(varchar(20), dtc_state) 
 end as dtcState
FROM sys.dm_tran_active_transactions dtat
INNER JOIN sys.dm_tran_database_transactions dtdt
ON dtat.transaction_id = dtdt.transaction_id
WHERE dtdt.database_id = 2 -- TempDB
ORDER BY transaction_begin_time

-- Transações geral

SELECT tst.session_id As [SPID],
tat.transaction_begin_time AS DataHora_Inicio,
es.original_login_name As [Login],
DB_NAME(tdt.database_id) AS Banco,
DATEDIFF(SECOND, tat.transaction_begin_time, GETDATE()) AS TempoExec,
tdt.database_transaction_log_record_count AS EspacoOcupado_Log,
CASE tat.transaction_state
WHEN 0 THEN 'A transação não foi completamente inicializada ainda…'
    WHEN 1 THEN 'A transação foi inicializada, mas não começou…'
    WHEN 2 THEN 'A transação esta ativa…'
    WHEN 3 THEN 'A transação foi encerrada…'
    WHEN 4 THEN 'Foi iniciado o processo de confirmação sobre o transação distribuída…'
    WHEN 5 THEN 'A transação está em estado preparação e esperando resolução…'
    WHEN 6 THEN 'A transação foi confirmada…'
    WHEN 7 THEN 'A transação esta sendo revertida para o estado anterior…'
    WHEN 8 THEN 'A transação foi revertida para o estado anterior…'
   ELSE 'Estado da transação desconhecido'
   END AS Estado_Transacao,
SUBSTRING(TXT.text, ( er.statement_start_offset / 2 ) + 1, ((CASE WHEN er.statement_end_offset = -1
THEN LEN(CONVERT(NVARCHAR(MAX), TXT.text)) * 2
ELSE er.statement_end_offset
END - er.statement_start_offset ) / 2 ) + 1) AS Ultima_Consulta,
TXT.text AS Consulta_Relacionada,
es.host_name As [Host],
   CASE tat.transaction_type
    WHEN 1 THEN 'Transação Read/Write'
    WHEN 2 THEN 'Transação Read-Only'
    WHEN 3 THEN 'Transação de Sistema'
                WHEN 4 THEN 'Transação distribuída'
            ELSE 'Tipo de Transação desconhecido'
            END AS Tipo_Transacao

FROM sys.dm_tran_session_transactions AS tst 
LEFT JOIN sys.dm_tran_active_transactions AS tat ON tst.transaction_id = tat.transaction_id
LEFT JOIN sys.dm_tran_database_transactions AS tdt ON tst.transaction_id = tdt.transaction_id
LEFT JOIN sys.dm_exec_sessions es ON tst.session_id = es.session_id
LEFT JOIN sys.dm_exec_requests er ON tst.session_id = er.session_id
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) TXT
ORDER BY DataHora_Inicio


SELECT session_id,host_name,program_name,original_login_name,login_time,last_request_end_time,status 
FROM sys.dm_exec_sessions 
WHERE session_id in (601,612,485,486,489,170,419,198,112,171)
ORDER BY last_request_end_time

SELECT * FROM sys.dm_exec_requests where session_id in (601,612,485,486,489,170,419,198,112,171)
SELECT * FROM sys.dm_exec_connections where session_id in (601,612,485,486,489,170,419,198,112,171)


-- kill 155

/*******************************
 Sessões consumindo TempDB
**********************************/
-- (@DT_REF nvarchar(8),@ParteBusca nvarchar(4000),@FabricanteBusca nvarchar(4000))exec [STARSOFT].[Reports_TotalStockAging_Cala] 30,60,90,120,180,360,540,720, @DT_REF,@ParteBusca,@FabricanteBusca
-- 174 (@DataRef datetime,@CodVendor nvarchar(3406),@CodERP int,@CodDivisao int,@Moneda nvarchar(5))      DECLARE @Data as varchar(8)      set @Data=CONVERT(varchar(8),@DataRef,112)       exec [Starsoft].[Reports_TotalStockAging_Peru] 30,60,90,120,180,360,540,720, @Data,'',@CodVendor,@CodERP, @CodDivisao, @Moneda     
-- 325
-- Objetos internos TEMPDB

SELECT 'kill ' + ltrim(str(session_id)) ComandoKILL,
SUM(internal_objects_alloc_page_count)   AS task_internal_objects_alloc_page_count,
SUM(internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count
FROM   sys.dm_db_task_space_usage
GROUP  BY 'kill ' + ltrim(str(session_id))
HAVING SUM(internal_objects_alloc_page_count) > 0 

-- Lista sessões com recursos na TEMPDB
;with CTE_tmp as (
select session_id, sum(internal_objects_alloc_page_count * 8) / 1024 as Internal_Objects_MB,
sum(user_objects_alloc_page_count * 8) / 1024 as User_Objects_MB
from sys.dm_db_session_space_usage a
where internal_objects_alloc_page_count<> 0
group by session_id )

select 'kill ' + ltrim(str(b.session_id)) ComandoKILL,
b.login_time,b.last_request_end_time,b.host_name,b.login_name,a.Internal_Objects_MB,
b.open_transaction_count,b.status,b.program_name

from CTE_tmp a
join sys.dm_exec_sessions b on a.session_id = b.session_id
--where last_request_end_time < '20190901'
order by 3 
/***************************************/

/**********************************************
 Transações abertas com WorkingTable
***********************************************/
SELECT *
FROM sys.dm_tran_session_transactions

SELECT b.transaction_begin_time,b.transaction_id,a.* 
FROM sys.dm_exec_requests a
JOIN sys.dm_tran_active_transactions b on a.transaction_id = b.transaction_id
where 1=1 
--and a.session_id > 50 
--and b.name = N'worktable'
order by 1

SELECT * FROM sys.dm_exec_sessions where session_id > 50 order by 2
SELECT * FROM sys.dm_exec_requests where session_id > 50 order by 3
SELECT * FROM sys.dm_exec_connections order by 1

SELECT * FROM sys.dm_exec_connections where session_id in (601)
KILL 55

SELECT last_request_end_time,login_time,session_id,program_name,login_name,db_name(database_id) as Banco
FROM sys.dm_exec_sessions where session_id > 50
order by 1 

/****************************************
 KILL
*****************************************/
select 'kill ' + ltrim(str(session_id))
from sys.dm_db_session_space_usage 
where internal_objects_alloc_page_count<> 0

group by session_id 

dbcc inputbuffer(118)
kill 294
kill 145
kill 53
kill 198
kill 298
kill 155




/***********************************
 Histórico Consultas TEMPDB
************************************/
select *
from dba.dbo.DBA_Monitora_TempDB
where data >= '20231101' --and data < '2019-02-05 21:10:30.263'
order by 1 

-- 2018-01-31 18:17:15.840
-- 2018-01-31 17:50:16.217
-- Job 0xEC64448B388EF14A9A6B820318003BD1 : Step 3

/***********************************************************************
 Função formata ID JOB para identificar JOB envolvido no Blocking
************************************************************************/
use DBA
go
CREATE function [dbo].[udf_sysjobs_getprocessid](@job_id uniqueidentifier)
returns varchar(8)
as
begin
return (substring(left(@job_id,8),7,2) +
substring(left(@job_id,8),5,2) +
substring(left(@job_id,8),3,2) +
substring(left(@job_id,8),1,2))
end
go

-- 8 primeiros digitos do uniqueidentifier sem o "0x"
SELECT * FROM msdb..sysjobs WHERE dbo.udf_sysjobs_getprocessid(job_id) = 'EC64448B'





/****************************************** ESTUDO *********************************************************/
select d.name, (size*8) as FileSizeKB 
from sys.database_files d
order by 2 desc

select * from tempdb.sys.all_objects
where is_ms_shipped = 0;


EXEC sp_spaceused @updateusage = N'TRUE';
GO
EXEC sp_msforeachtable 'EXEC sp_spaceused ''?'''
GO
SELECT
 mf.[file_id] [FileID]
,sf.[name] [LogicalName]
,mf.[type_desc] [FileType]
,FILEPROPERTY(sf.[name],'SpaceUsed')*CONVERT(FLOAT,8) [SpaceUsed_KB]
,(sf.[size]-FILEPROPERTY(sf.[name],'SpaceUsed'))*CONVERT(FLOAT,8) [AvailableSpace_KB]
,sf.[size] * CONVERT(FLOAT,8) [Size_KB]
,LTRIM(CASE mf.[is_percent_growth] WHEN 1 THEN STR(mf.[growth]) +' %' ELSE STR(mf.[growth]*CONVERT(FLOAT,8))+' KB' END) [AutoGrowth]
FROM sys.master_files mf
INNER JOIN sys.database_files sf ON mf.[file_id] = sf.[file_id] AND mf.[database_id] = DB_ID()


SELECT * FROM sys.dm_tran_active_transactions
  WHERE name = N'worktable';

-- Verifica transações em aberto
Select * from sys.dm_exec_sessions
where open_transaction_count > 0

Select session_id,open_transaction_count,host_name,program_name,login_name,cpu_time,logical_reads*8 as Total_IO,
total_elapsed_time,last_request_start_time
from sys.dm_exec_sessions
where open_transaction_count > 0

select db_name(resource_database_id) as Banco,
 *
from sys.dm_tran_locks where request_session_id = 186
order by 1 

Select * from sys.dm_exec_requests
where transaction_id > 0

Select * from sys.dm_exec_requests


-- Na TEMPDB
SELECT e.*,r.* FROM sys.dm_exec_requests r 
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS e
WHERE r.database_id = 2 -- 197

select * from sys.dm_tran_locks where resource_database_id= 2

select * from sys.dm_db_session_space_usage where user_objects_alloc_page_count<> 0

SELECT e.*,r.* FROM sys.dm_exec_requests r 
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS e
where r.session_id = 64


select  * from sys.dm_exec_sessions where session_id = 64


select session_id,login_time,last_request_end_time,host_name,login_name
from sys.dm_exec_sessions where session_id in (125,79,186)

select session_id, sum(internal_objects_alloc_page_count * 8) / 1024 as MB
from sys.dm_db_session_space_usage a
where internal_objects_alloc_page_count<> 0
group by session_id 
order by 2 desc

;with CTE_tmp as (
select session_id, sum(internal_objects_alloc_page_count * 8) / 1024 as MB
from sys.dm_db_session_space_usage a
where internal_objects_alloc_page_count<> 0
group by session_id )

select a.*,
b.login_time,b.last_request_end_time,b.host_name,b.login_name,b.open_transaction_count,b.status,b.program_name
from CTE_tmp a
join sys.dm_exec_sessions b on a.session_id = b.session_id
order by 2 desc


select 'kill ' + ltrim(str(session_id))
from sys.dm_db_session_space_usage 
where internal_objects_alloc_page_count<> 0
group by session_id 

kill 54
kill 69
kill 80
kill 81
kill 88

select *
from sys.dm_db_session_space_usage 
where session_id = 64


;WITH task_space_usage AS (
    -- SUM alloc/delloc pages
    SELECT session_id,
           request_id,
           SUM(internal_objects_alloc_page_count) AS alloc_pages,
           SUM(internal_objects_dealloc_page_count) AS dealloc_pages
    FROM sys.dm_db_task_space_usage WITH (NOLOCK)
    WHERE session_id <> @@SPID
    GROUP BY session_id, request_id
)
SELECT TSU.session_id,
       TSU.alloc_pages * 1.0 / 128 AS [internal object MB space],
       TSU.dealloc_pages * 1.0 / 128 AS [internal object dealloc MB space],
       EST.text,
       -- Extract statement from sql text
       ISNULL(
           NULLIF(
               SUBSTRING(
                 EST.text, 
                 ERQ.statement_start_offset / 2, 
                 CASE WHEN ERQ.statement_end_offset < ERQ.statement_start_offset 
                  THEN 0 
                 ELSE( ERQ.statement_end_offset - ERQ.statement_start_offset ) / 2 END
               ), ''
           ), EST.text
       ) AS [statement text],
       EQP.query_plan
FROM task_space_usage AS TSU
INNER JOIN sys.dm_exec_requests ERQ WITH (NOLOCK)
    ON  TSU.session_id = ERQ.session_id
    AND TSU.request_id = ERQ.request_id
OUTER APPLY sys.dm_exec_sql_text(ERQ.sql_handle) AS EST
OUTER APPLY sys.dm_exec_query_plan(ERQ.plan_handle) AS EQP
WHERE EST.text IS NOT NULL OR EQP.query_plan IS NOT NULL
ORDER BY 3 DESC;

/*
As Martin pointed out in a comment, this would not find active transactions 
that are occupying space in tempdb, it will only find active queries that are currently 
utilizing space there (and likely culprits for current log usage). You could change the 
inner join on sys.dm_exec_requests to a left outer join, then you will return rows 
for sessions that aren't currently actively running queries.
*/
--The query Martin posted...
SELECT database_transaction_log_bytes_reserved,session_id 
  FROM sys.dm_tran_database_transactions AS tdt 
  INNER JOIN sys.dm_tran_session_transactions AS tst 
  ON tdt.transaction_id = tst.transaction_id 
  WHERE database_id = 2;
/*
...would identify session_ids with active transactions that are occupying 
log space, but you wouldn't necessarily be able to determine the actual query 
that caused the problem, since if it's not running now it won't be captured 
in the above query for active requests. You may be able to reactively check 
the most recent query using DBCC INPUTBUFFER but it may not tell you what you want 
to hear. You can outer join in a similar way to capture those actively running, e.g.:
*/
SELECT tdt.database_transaction_log_bytes_reserved,tst.session_id,
       t.[text], [statement] = COALESCE(NULLIF(
         SUBSTRING(
           t.[text],
           r.statement_start_offset / 2,
           CASE WHEN r.statement_end_offset < r.statement_start_offset
             THEN 0
             ELSE( r.statement_end_offset - r.statement_start_offset ) / 2 END
         ), ''
       ), t.[text])
     FROM sys.dm_tran_database_transactions AS tdt
     INNER JOIN sys.dm_tran_session_transactions AS tst
     ON tdt.transaction_id = tst.transaction_id
         LEFT OUTER JOIN sys.dm_exec_requests AS r
         ON tst.session_id = r.session_id
         OUTER APPLY sys.dm_exec_sql_text(r.plan_handle) AS t
     WHERE tdt.database_id = 2;

/*
You can also use the DMV sys.dm_db_session_space_usage to see overall space 
utilization by session (but again you may not get back valid results for the 
query; if the query is not active, what you get back may not be the actual culprit).
*/
;WITH s AS
(
    SELECT 
        s.session_id,
        [pages] = SUM(s.user_objects_alloc_page_count 
          + s.internal_objects_alloc_page_count) 
    FROM sys.dm_db_session_space_usage AS s
    GROUP BY s.session_id
    HAVING SUM(s.user_objects_alloc_page_count 
      + s.internal_objects_alloc_page_count) > 0
)
SELECT s.session_id, s.[pages], t.[text], 
  [statement] = COALESCE(NULLIF(
    SUBSTRING(
        t.[text], 
        r.statement_start_offset / 2, 
        CASE WHEN r.statement_end_offset < r.statement_start_offset 
        THEN 0 
        ELSE( r.statement_end_offset - r.statement_start_offset ) / 2 END
      ), ''
    ), t.[text])
FROM s
LEFT OUTER JOIN 
sys.dm_exec_requests AS r
ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.plan_handle) AS t
ORDER BY s.[pages] DESC;


select * from sys.dm_exec_requests where session_id = 283
select * from sys.dm_db_session_space_usage  where session_id = 283
select * from sys.dm_exec_connections where session_id = 283
select * from sys.dm_exec_sql_text(0x02000000EB686C08F552FAF809335651039A04010660DE890000000000000000000000000000000000000000)
-- IP 10.5.192.210 ou 10.5.193.228
-- 283
kill 283
/*
With all of these queries at your disposal, you should be able to narrow down who is using up tempdb and how, especially if you catch them in the act.

some tips for minimizing tempdb utilization
1.use fewer #temp tables and @table variables
2.minimize concurrent index maintenance, and avoid the SORT_IN_TEMPDB option if it isn't needed
3.avoid unnecessary cursors; avoid static cursors if you think this may be a bottleneck, since static cursors use work tables in tempdb - though this is the type of cursor I always recommend if tempdb isn't a bottleneck
4.try to avoid spools (e.g. large CTEs that are referenced multiple times in the query)
5.don't use MARS
6.thoroughly test the use of snapshot / RCSI isolation levels - don't just turn it on for all databases since you've been told it's better than NOLOCK (it is, but it isn't free)
7.in some cases, it may sound unintuitive, but use more temp tables. e.g. breaking up a humongous query into parts may be slightly less efficient, but if it can avoid a huge memory spill to tempdb because the single, larger query requires a memory grant too large...
8.avoid enabling triggers for bulk operations
9.avoid overuse of LOB types (max types, XML, etc) as local variables
10.keep transactions short and sweet
11.don't set tempdb to be everyone's default database - 

You may also consider that your tempdb log usage may be caused by internal processes that you have little or no control over - for example database mail, event notifications, query notifications and service broker all use tempdb in some way. You can stop using these features, but if you're using them you can't dictate how and when they use tempdb.
*/


/*********************
 Ocupação da TEMPDB
**********************/
USE [tempdb]
GO
EXEC sp_spaceused @updateusage = N'TRUE';
GO

-- Determining the Amount of Free Space in tempdb
SELECT SUM(unallocated_extent_page_count) AS [free pages], 
(SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
FROM sys.dm_db_file_space_usage;

-- Determining the Amount Space Used by the Version Store
SELECT SUM(version_store_reserved_page_count) AS [version store pages used],
(SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB]
FROM sys.dm_db_file_space_usage;

-- Determining the Longest Running Transaction
SELECT transaction_id
FROM sys.dm_tran_active_snapshot_database_transactions 
ORDER BY elapsed_time_seconds DESC;


-- Determining the Amount of Space Used by Internal Objects
SELECT SUM(internal_object_reserved_page_count) AS [internal object pages used],
(SUM(internal_object_reserved_page_count)*1.0/128) AS [internal object space in MB]
FROM sys.dm_db_file_space_usage;

-- Determining the Amount of Space Used by User Objects
SELECT SUM(user_object_reserved_page_count) AS [user object pages used],
(SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB]
FROM tempdb.sys.dm_db_file_space_usage;

-- Determining the Total Amount of Space (Free and Used)
SELECT SUM(size)*1.0/128 AS [size in MB]
FROM tempdb.sys.database_files

select * FROM tempdb.sys.all_objects
where is_ms_shipped = 0

SELECT (SUM(internal_object_reserved_page_count)*1.0/128) AS [internal object space in MB],
(SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB],
(SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB]
FROM tempdb.sys.dm_db_file_space_usage;

