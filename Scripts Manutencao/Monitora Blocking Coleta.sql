/**************************************************************************************
 Data: 11/10/2014
 Autor: Landry Duailibe Salles Filho
 Descrição: Email de Blocking em HTM
**************************************************************************************/

/******************************************************
 Cria Tabela para incluir informações de Blocking
*******************************************************/
USE MSDB
go

-- TRUNCATE TABLE DBA.dbo.DBA_Monitora_Hist_Bloking
-- DROP TABLE DBA.dbo.DBA_Monitora_Hist_Bloking
CREATE TABLE dbo.DBA_Monitora_Hist_Bloking (
DataHora_Coleta datetime NOT NULL,
SPID smallint NOT NULL,
Status varchar(5) NOT NULL,
TempoEspera_Seg bigint NULL,
SPID_Blocking smallint NULL,
Banco nvarchar(128) NULL,
Computador nchar(128) NULL,
UsuarioWindows nvarchar(257) NULL,
LoginSQL nchar(128) NULL,
Aplicacao nvarchar(128) NULL,
AppInterface nvarchar(32) NULL,
QtdTransacoes smallint NULL,
TipoComando nchar(16) NULL,
UltimoTSQL datetime NULL,
InstrucaoTSQL varchar(max) NULL,
Email char(1) NOT NULL,
encrypted bit null)
go


/***********************************************************************
 Função formata ID JOB para identificar JOB envolvido no Blocking
************************************************************************/
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

/***********************************************************************
 SP identifica Blocking e alimenta tabela "DBA_Monitora_Hist_Bloking"

************************************************************************/
select * from MSDB.dbo.DBA_Monitora_Hist_Bloking
/*
exec DBA_sp_Admin_Blocking @Empresa = 'SYM', @LockWaitLimite = 240
*/
go
CREATE PROC dbo.DBA_sp_Admin_Blocking
@Empresa varchar(1000) = 'SYM',
@LockWaitLimite bigint = 30 -- em segundos

as
set nocount on

Declare @TableHead varchar(max),@TableTail varchar(max), @Subject varchar(2000), @QtdLinhas int 
Declare @TableJOB varchar(max)
Declare @Body varchar(max), @BodyJOB varchar(max)
Declare @SQLversion varchar(max), @Email_TO varchar(2000)

declare @DataHora datetime
set @DataHora = getdate()

-- Inclui em tabela com Historico de Blocking
insert msdb.dbo.DBA_Monitora_Hist_Bloking 

SELECT @DataHora, spid as SPID, 'RAIZ' as Status, waittime/1000 as TempoEspera_Seg, blocked as SPID_Blocking,
db_name(sp.dbid) Banco,isnull(hostname,'N/A') Computador,
case when sp.nt_domain is null or sp.nt_domain = '' then 'N/A' else rtrim(sp.nt_domain) + '/' + nt_username end as UsuarioWindows, loginame as LoginSQL, 

case 
when s.program_name like 'SQLAgent - TSQL JobStep (Job%' 
then (select 'JOB: ' + MAX(name) + ' (' + replace( substring(s.program_name,CHARINDEX(': Step',s.program_name)+2,100) ,')','') + ')' FROM msdb.dbo.sysjobs WHERE dbo.udf_sysjobs_getprocessid(job_id) = substring(s.program_name,32,8) )
else s.program_name
end as Aplicacao, 

s.client_interface_name as AppInterface,
open_tran as QtdTransacoes, cmd as TipoComando, last_batch as UltimoTSQL,qt.text as InstrucaoTSQL, 'N' as Email
,qt.encrypted

FROM master.dbo.sysprocesses sp LEFT JOIN sys.dm_exec_sessions s ON s.session_id = sp.spid
OUTER APPLY sys.dm_exec_sql_text(sp.sql_handle) AS qt
WHERE spid IN (SELECT distinct blocked FROM master.sys.sysprocesses where blocked > 0) AND blocked = 0

UNION 

SELECT @DataHora, spid as SPID, 'BLOCK' as Status, waittime/1000 as TempoEspera_Seg, blocked as SPID_Blocking,
db_name(sp.dbid) Banco,isnull(hostname,'N/A') Computador,
case when sp.nt_domain is null or sp.nt_domain = '' then 'N/A' else rtrim(sp.nt_domain) + '/' + nt_username end as UsuarioWindows, loginame as LoginSQL, 

case 
when s.program_name like 'SQLAgent - TSQL JobStep (Job%' 
then (select 'JOB: ' + MAX(name) + ' (' + replace( substring(s.program_name,CHARINDEX(': Step',s.program_name)+2,100) ,')','') + ')' FROM msdb.dbo.sysjobs WHERE dbo.udf_sysjobs_getprocessid(job_id) = substring(s.program_name,32,8) )
else s.program_name
end as Aplicacao, 
 
s.client_interface_name as AppInterface,
open_tran as QtdTransacoes, cmd as TipoComando, last_batch as UltimoTSQL,qt.text as InstrucaoTSQL, 'N' as Email
,qt.encrypted

FROM master.dbo.sysprocesses sp LEFT JOIN sys.dm_exec_sessions s ON s.session_id = sp.spid
OUTER APPLY sys.dm_exec_sql_text(sp.sql_handle) AS qt
WHERE  spid > 50 and blocked > 0 --and waittime > (@LockWaitLimite * 1000) -- 6 segundos em milisegundos
-- FIM Inclui

go
/********************************************* FIM SP ****************************************************************/
