/**************************************************************************************
 Autor: Landry Duailibe

 Hands On: JOB Monitora Blocking
**************************************************************************************/

/******************************************************
 Cria Tabela para incluir informações de Blocking
*******************************************************/
USE DBA
go

-- TRUNCATE TABLE DBA.dbo.DBA_Monitora_Hist_Blocking
DROP TABLE IF exists DBA.dbo.DBA_Monitora_Hist_Blocking
go
CREATE TABLE dbo.DBA_Monitora_Hist_Blocking (
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

SELECT * FROM dbo.DBA_Monitora_Hist_Blocking

/***********************************************************************
 Função formata ID JOB para identificar JOB envolvido no Blocking
************************************************************************/
go
CREATE FUNCTION [dbo].[udf_sysjobs_getprocessid](@job_id uniqueidentifier)
RETURNS varchar(8)
as
BEGIN
return (substring(left(@job_id,8),7,2) +
substring(left(@job_id,8),5,2) +
substring(left(@job_id,8),3,2) +
substring(left(@job_id,8),1,2))
END
go

/***********************************************************************
 SP identifica Blocking e alimenta tabela "DBA_Monitora_Hist_Bloking"
 - Criar JOB executando a cada 30 minutos "_DBA - Monitora Blocking"
 exec DBA_sp_Admin_BlockingHTML @Empresa = 'SQL Server Expert', @ProfileDatabaseMail = 'Profile_SMTP', @Operador = 'DBA', @LockWaitLimite = 60
************************************************************************/
go
CREATE or ALTER PROC dbo.DBA_sp_Admin_BlockingHTML
@Empresa varchar(1000) = 'SQL Server Expert',
@LockWaitLimite bigint = 60, -- em segundos

@ProfileDatabaseMail varchar(2000) = 'Profile_SMTP',
@Operador varchar(2000) = 'DBA'
as
set nocount on

Declare @TableHead varchar(max),@TableTail varchar(max), @Subject varchar(2000), @QtdLinhas int 
Declare @TableJOB varchar(max)
Declare @Body varchar(max), @BodyJOB varchar(max)
Declare @SQLversion varchar(max), @Email_TO varchar(2000)

select @Email_TO = email_address from msdb.dbo.sysoperators where name = @Operador

SELECT @SQLversion = left(@@VERSION,25) + ' - Build '
+ CAST(SERVERPROPERTY('productversion') AS VARCHAR) + ' - ' 
+ CAST(SERVERPROPERTY('productlevel') AS VARCHAR) + ' (' 
+ CAST(SERVERPROPERTY('edition') AS VARCHAR) + ')'

Set @TableTail = '</body></html>';
Set @TableHead = '<html><head>' +
			'<style>' +
			'td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:9pt;} ' +
			'</style>' +
			'</head>' +
			'<body>' + 
			'<P style=font-size:18pt;" ><B>Servidor ' + @@SERVERNAME + '</B></P>' +
			'<P style=font-size:12pt;" >' + @SQLversion + '</P><br>'

set @Body = @TableHead

declare @DataHora datetime
set @DataHora = getdate()

-- Inclui em tabela com Historico de Blocking
insert dbo.DBA_Monitora_Hist_Blocking 

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

FROM sys.sysprocesses sp 
LEFT JOIN sys.dm_exec_sessions s ON s.session_id = sp.spid
OUTER APPLY sys.dm_exec_sql_text(sp.sql_handle) AS qt
WHERE spid IN (SELECT distinct blocked FROM sys.sysprocesses where blocked > 0) AND blocked = 0

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

FROM sys.sysprocesses sp 
LEFT JOIN sys.dm_exec_sessions s ON s.session_id = sp.spid
OUTER APPLY sys.dm_exec_sql_text(sp.sql_handle) AS qt
WHERE  spid > 50 and blocked > 0 and waittime > (@LockWaitLimite * 1000) -- 6 segundos em milisegundos
-- FIM Inclui



if (select max(TempoEspera_Seg) from dbo.DBA_Monitora_Hist_Blocking where Email = 'N') >= @LockWaitLimite begin
	Set @TableJOB = '<P style=font-size:14pt;" ><B>- Processos em Blocking</B></P>' +
				'<table cellpadding=0 cellspacing=0 border=0>' +
				'<tr bgcolor=#87CEEB>' + 
				'<td align=center><b>DataHora_Coleta</b></td>' + 
				'<td align=center><b>SPID</b></td>' + 
				'<td align=center><b>Status</b></td>' + 
				'<td align=center><b>Tempo Espera Seg</b></td>' + 
				'<td align=center><b>SPID Blocking</b></td>' + 
				'<td align=center><b>Banco</b></td>' + 
				'<td align=center><b>Computador</b></td>' + 
				'<td align=center><b>Usuario Windows</b></td>' + 
				'<td align=center><b>Login SQL</b></td>' + 
				'<td align=center><b>Aplicacao</b></td>' + 
				'<td align=center><b>App Interface</b></td>' + 
				'<td align=center><b>Qtd Transacoes</b></td>' + 
				'<td align=center><b>Tipo Comando</b></td>' + 
				'<td align=center><b>UltimoTSQL</b></td></tr>';				

	Select @BodyJOB = (SELECT Row_Number() Over(Order By SPID_Blocking, SPID) % 2 As [TRRow], convert(varchar(10), DataHora_Coleta,103) + ' ' + convert(varchar(8), DataHora_Coleta,114) as [TD], 
	SPID as [TD], Status as [TD], TempoEspera_Seg as [TD], SPID_Blocking as [TD], Banco as [TD], Computador as [TD], UsuarioWindows as [TD], LoginSQL as [TD], Aplicacao as [TD], AppInterface as [TD], 
	QtdTransacoes as [TD], TipoComando as [TD], convert(varchar(10), UltimoTSQL,103) + ' ' + convert(varchar(8), UltimoTSQL,114) as [TD]
	FROM dbo.DBA_Monitora_Hist_Blocking WHERE Email = 'N'
	ORDER BY SPID_Blocking, SPID
	FOR XML raw('tr'),elements)

	Set @BodyJOB = Replace(@BodyJOB, '_x0020_', space(1))
	Set @BodyJOB = Replace(@BodyJOB, '_x003D_', '=')
	Set @BodyJOB = Replace(@BodyJOB, '<tr><TRRow>1</TRRow>', '<tr bgcolor=#F0F0F0>')
	Set @BodyJOB = Replace(@BodyJOB, '<TRRow>0</TRRow>', '')
	Set @BodyJOB = @BodyJOB + '</table><p> </p><br>'
	set @Body = @Body + @TableJOB + @BodyJOB
	
	set @Body = @Body + @TableTail
	set @Subject = @Empresa + ': BLOCKING Servidor ' + @@SERVERNAME + ' do dia ' + CONVERT(varchar(30),getdate(),103)

	EXEC msdb.dbo.sp_send_dbmail
	@recipients=@Email_TO,
	@subject = @Subject,
	@body = @Body,
	@body_format = 'HTML' ,
	@profile_name=@ProfileDatabaseMail

	UPDATE dbo.DBA_Monitora_Hist_Blocking SET Email = 'S' WHERE Email = 'N' 
end
else
	delete dbo.DBA_Monitora_Hist_Blocking where Email = 'N'
go
/********************************************* FIM SP ****************************************************************/
