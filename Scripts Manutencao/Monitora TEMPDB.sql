/****************************************************************
 Monitora cresciemnto TEMPDB
 Autor: Landry Salles
 Data: 15/02/2010
*****************************************************************/

/****************************************
 Cria tabela histórico de crescimento
*****************************************/
USE DBA
GO
CREATE TABLE dbo.DBA_Monitora_TempDB(
PK_OcupacaoBD bigint IDENTITY(1,1) PRIMARY KEY NOT NULL,
Data datetime NOT NULL DEFAULT (getdate()),
Tamanho_MB decimal(12, 2) NULL,
EspacoUtil_MB decimal(12, 2) NULL,
EspacoLivreMB decimal(12, 2) NULL,
ObjetosUsuarioMB decimal(16, 4) NULL,
VersionStoreMB decimal(16, 4) NULL,
ObjetosInternosMB decimal(16, 4) NULL,
TransacoesXML xml NULL)
go

/****************************************
 Cria SP que alimenta tabela acima
*****************************************/
-- DROP PROCEDURE DBA_sp_MonitoraTempDB
IF OBJECT_ID('DBA_sp_MonitoraTempDB') IS NULL
    EXEC('CREATE PROCEDURE DBA_sp_MonitoraTempDB AS SET NOCOUNT ON;')
go
ALTER PROC dbo.DBA_sp_MonitoraTempDB
as
declare @nome sysname
create table #tab_tmp(Fileid int,FileGroup int,
                      TotalExtents bigint, UsedExtents bigint,
                      [Name] varchar(100),[FileName] varchar(260) )

insert #tab_tmp exec('use tempdb dbcc showfilestats')

declare @Tamanho_MB decimal(16,4), @EspacoUtil_MB decimal(16,4), @EspacoLivreMB decimal(16,4), @ObjetosUsuarioMB decimal(16,4)
declare @VersionStoreMB decimal(16,4), @ObjetosInternosMB  decimal(16,4)

select @Tamanho_MB = (sum(TotalExtents) * 64) / 1024, @EspacoUtil_MB = (sum(UsedExtents) * 64) / 1024 from #tab_tmp

SELECT @EspacoLivreMB = (SUM(unallocated_extent_page_count)*1.0/128) FROM tempdb.sys.dm_db_file_space_usage

SELECT @ObjetosUsuarioMB = (SUM(user_object_reserved_page_count)*1.0/128) FROM tempdb.sys.dm_db_file_space_usage

SELECT @VersionStoreMB = (SUM(version_store_reserved_page_count)*1.0/128) FROM tempdb.sys.dm_db_file_space_usage;

SELECT @ObjetosInternosMB = (SUM(internal_object_reserved_page_count)*1.0/128) FROM tempdb.sys.dm_db_file_space_usage;

declare @TransacoesXML xml
set @TransacoesXML =
(SELECT es.host_name , es.login_name , es.program_name,
st.dbid as QueryExecContextDBID, DB_NAME(st.dbid) as QueryExecContextDBNAME, st.objectid as ModuleObjectId,
SUBSTRING(st.text, er.statement_start_offset/2 + 1,(CASE WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max),st.text)) * 2 ELSE er.statement_end_offset 
END - er.statement_start_offset)/2) as Query_Text,
tsu.session_id ,tsu.request_id, tsu.exec_context_id, 
tsu.user_objects_alloc_page_count, tsu.user_objects_dealloc_page_count,
(tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count) as OutStanding_user_objects_page_counts,
tsu.internal_objects_alloc_page_count,tsu.internal_objects_dealloc_page_count,
(tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) as OutStanding_internal_objects_page_counts,
er.start_time, er.command, er.open_transaction_count, er.percent_complete, er.estimated_completion_time, er.cpu_time, er.total_elapsed_time, er.reads,er.writes, 
er.logical_reads, er.granted_query_memory
FROM sys.dm_db_task_space_usage tsu inner join sys.dm_exec_requests er 
 ON ( tsu.session_id = er.session_id and tsu.request_id = er.request_id) 
inner join sys.dm_exec_sessions es ON ( tsu.session_id = es.session_id ) 
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) st
WHERE (tsu.internal_objects_alloc_page_count+tsu.user_objects_alloc_page_count) > 0
ORDER BY (tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count)+(tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) 
DESC
for xml auto)

insert dbo.DBA_Monitora_TempDB (Tamanho_MB,EspacoUtil_MB,EspacoLivreMB,ObjetosUsuarioMB,VersionStoreMB,ObjetosInternosMB,TransacoesXML)
values (@Tamanho_MB, @EspacoUtil_MB,@EspacoLivreMB,@ObjetosUsuarioMB,@VersionStoreMB,@ObjetosInternosMB,@TransacoesXML)
   
drop table #tab_tmp
go
/******************************** Fim SP ******************************************/

/**************************************
 Criar JOB para capturar crescimento
 Executar a cada 5 min
***************************************/
declare @TamanhoAlertaMB decimal(20,6) = 50000.00
declare @TamanhoMB decimal(20,6)

SELECT @TamanhoMB = sum (size*1.0/128) 
FROM tempdb.sys.database_files

if @TamanhoMB > @TamanhoAlertaMB 
  EXEC dbo.DBA_sp_MonitoraTempDB
go

-- Limpeza periódica da tabela
DELETE FROM dbo.DBA_Monitora_TempDB
WHERE Data <= convert(varchar(8),dateadd(MM,-3,getdate()),112)

-- select * from dbo.DBA_Monitora_TempDB
