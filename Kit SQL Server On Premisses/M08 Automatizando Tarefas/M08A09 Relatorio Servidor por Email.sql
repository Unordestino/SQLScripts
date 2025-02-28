/**************************************************************************************
 Autor: Landry Duailibe
 
 Relatório diário Servidor SQL Server em HTML
 
 Parâmetros
 
 **************************************************************************************/
use DBA
go

-- exec DBA_sp_RelatorioHTML @Empresa = 'SQL Server Expert', @ProfileDatabaseMail = 'Profile_SMTP', @Operador = 'DBA'
CREATE or ALTER PROC dbo.DBA_sp_RelatorioHTML
@Empresa varchar(1000) = 'SQL Server Expert',
@DiscoLimite bigint = 20000,
@MemLimite bigint = 2000,
@BancosSemBackupLimite int = 2,
@ProfileDatabaseMail varchar(2000) = 'Profile_SMTP',
@Operador varchar(2000) = 'DBA'
as
set nocount on

Declare @TableHead varchar(max),@TableTail varchar(max), @Subject varchar(2000), @QtdLinhas int 
Declare @TableJOB varchar(max), @TableManutBD varchar(max), @TableDivBD varchar(max)
Declare @TableDisco varchar(max), @TableMemoria varchar(max), @TableSemBackup varchar(max)
Declare @Body varchar(max), @BodyJOB varchar(max), @BodyManutBD varchar(max), @BodyDivBD varchar(max)
Declare @BodyDisco varchar(max), @BodyMemoria varchar(max)
Declare @SQLversion varchar(max), @Email_TO varchar(2000), @Servidor varchar(2000), @SQLNo varchar(2000)


select @Email_TO = email_address from msdb.dbo.sysoperators where name = @Operador

SELECT @SQLversion = left(@@VERSION,25) + ' - Build '
+ CAST(SERVERPROPERTY('productversion') AS VARCHAR) + ' - ' 
+ CAST(SERVERPROPERTY('productlevel') AS VARCHAR) + ' (' 
+ CAST(SERVERPROPERTY('edition') AS VARCHAR) + ')'

SELECT @Servidor = @@SERVERNAME

Set @TableTail = '</body></html>';
Set @TableHead = '<html><head>' +
			'<style>' +
			'td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:9pt;} ' +
			'</style>' +
			'</head>' +
			'<body>' + 
			'<P style=font-size:18pt;" ><B>Servidor ' + @Servidor +  '</B></P>' +
			'<P style=font-size:12pt;" >' + @SQLversion + '</P>'

set @Body = @TableHead

/*******************
 JOBs com falha
********************/
create table #Relat_JOBs (
JOB varchar(1000) NULL,
[DataHora Inicio] varchar(30) NULL,
[Status] varchar(20) NULL,
Duracao varchar(30) null,
Mensagem nvarchar(4000) NULL,
ProximaExecucao varchar(30) NULL)

insert into #Relat_JOBs
SELECT sJOB.name AS JOB,
CASE WHEN sJOBH.run_date IS NULL OR sJOBH.run_time IS NULL THEN NULL
     ELSE CAST(CAST(sJOBH.run_date AS CHAR(8)) + ' ' + STUFF(STUFF(RIGHT('000000' + CAST(sJOBH.run_time AS VARCHAR(6)),6),3,0,':'),6,0,':') AS DATETIME) END AS DataHora,
CASE sJOBH.run_status
     WHEN 0 THEN 'Falha'
     WHEN 1 THEN 'Sucesso'
     WHEN 2 THEN 'Retry'
     WHEN 3 THEN 'Cancelado'
     WHEN 4 THEN 'Em Execução' 
     ELSE 'N/A' END AS [Status],
STUFF(STUFF(RIGHT('000000' + CAST(sJOBH.run_duration AS VARCHAR(6)),6),3,0,':'),6,0,':') AS [Duracao (HH:MM:SS)],
sJOBH.message AS Mensagem,
CASE sJOBSCH.NextRunDate WHEN 0 THEN NULL
     ELSE CAST(CAST(sJOBSCH.NextRunDate AS CHAR(8)) + ' ' + STUFF(STUFF(RIGHT('000000' + CAST(sJOBSCH.NextRunTime AS VARCHAR(6)),6),3,0,':'),6,0,':') AS DATETIME) END AS ProximaExecucao
FROM msdb.dbo.sysjobs AS sJOB LEFT JOIN (
SELECT job_id,MIN(next_run_date) AS NextRunDate,MIN(next_run_time) AS NextRunTime
FROM msdb.dbo.sysjobschedules GROUP BY job_id) AS sJOBSCH ON sJOB.job_id = sJOBSCH.job_id
LEFT JOIN (
SELECT job_id,run_date,run_time,run_status,run_duration,[message],
ROW_NUMBER() OVER (PARTITION BY job_id ORDER BY run_date DESC, run_time DESC) AS RowNumber
FROM msdb.dbo.sysjobhistory WHERE step_id = 0) AS sJOBH ON sJOB.job_id = sJOBH.job_id AND sJOBH.RowNumber = 1
where 1=1
and sJOBH.run_status <> 1
and sJOB.enabled = 1
-- select * from #Relat_JOBs

if @@rowcount > 0 begin
	Set @TableJOB = '<P style=font-size:14pt;><B>- SQL Server JOBs</B></P>' +
				'<table cellpadding=0 cellspacing=0 border=0>' +
				'<tr bgcolor=#87CEEB>' + 
				'<td align=center><b>JOB</b></td>' + 
				'<td align=center><b>DataHora Inicio</b></td>' + 
				'<td align=center><b>Status</b></td>' + 
				'<td align=center><b>Duracao (HH:MM:SS)</b></td>' + 
				'<td align=center><b>Mensagem</b></td>' + 
				'<td align=center><b>Proxima Execucao</b></td></tr>';
				
	Select @BodyJOB = (select Row_Number() Over(Order By JOB) % 2 As [TRRow],
	JOB as [TD],isnull([DataHora Inicio],'N/A') as [TD],[Status] as [TD],isnull([Duracao],'N/A') as [TD],isnull(Mensagem,'N/A') as [TD],isnull(ProximaExecucao,'N/A') as [TD]
	FROM #Relat_JOBs ORDER BY JOB
	FOR XML raw('tr'),elements)

	Set @BodyJOB = Replace(@BodyJOB, '_x0020_', space(1))
	Set @BodyJOB = Replace(@BodyJOB, '_x003D_', '=')
	Set @BodyJOB = Replace(@BodyJOB, '<tr><TRRow>1</TRRow>', '<tr bgcolor=#F0F0F0>')
	Set @BodyJOB = Replace(@BodyJOB, '<TRRow>0</TRRow>', '')
	Set @BodyJOB = Replace(@BodyJOB, '<TD>Falha</TD>', '<TD align=center><font color = "#ff0000">Falha</font></TD>')
--	Set @BodyJOB = Replace(@BodyJOB, '<TD>Sucesso</TD>', '<TD align=center><font color = "#0000ff">Sucesso</font></TD>')

	Set @BodyJOB = @BodyJOB + '</table><p> </p><br>'
	set @Body = @Body + @TableJOB + @BodyJOB
end

drop table #Relat_JOBs

/**************************************
 Bancos sem Backup nos últimos X dias 
***************************************/
DECLARE @BancosSemBackup varchar(max)
/* TYPE:
D = Database 
I = Differential database 
L = Log 
F = File or filegroup 
G =Differential file 
P = Partial 
Q = Differential partial 
*/
;WITH BancosSemBackup as (
SELECT NAME as Banco FROM sys.databases
WHERE NAME not in ('TEMPDB','Model','DBA')  
and not exists (select * from dbo.DBA_BackupExcluir WHERE Nomebanco = NAME)
--and name not in (select secondary_database from msdb.dbo.log_shipping_secondary_databases)
and source_database_id is null 
and NAME not in (SELECT DISTINCT database_name 
FROM msdb..backupset
WHERE backup_start_date > DATEADD(DAY,(@BancosSemBackupLimite * -1),GETDATE()) AND  TYPE = 'D')
and state_desc = 'ONLINE' and source_database_id is null)

SELECT @BancosSemBackup = COALESCE(@BancosSemBackup + ', ', '') + Banco FROM BancosSemBackup
--select @BancosSemBackup

if @BancosSemBackup is not null begin
	Set @TableSemBackup = '<P style=font-size:14pt;><B>- Bancos sem backup nos últimos ' + 
	ltrim(str(@BancosSemBackupLimite)) + ' dias:</B> ' + @BancosSemBackup + '</P>' 
	
	set @Body = @Body + @TableSemBackup
end


/*********************************
 Analisa espaço livre nos Discos 
**********************************/
create table #RelatDrive (Drive varchar(10) null,[EspacoLivre MB] bigint null)

insert #RelatDrive (Drive, [EspacoLivre MB]) EXEC master.dbo.xp_fixeddrives;


Set @TableDisco = '<P style=font-size:14pt;><B>- Drives com pouco espaco livre</B></P>' +
			'<table cellpadding=0 cellspacing=0 border=0>' +
			'<tr bgcolor=#87CEEB>' + 
			'<td align=center><b>Drive</b></td>' + 
			'<td align=center><b>Espaco Livre MB</b></td></tr>';

select @QtdLinhas = COUNT(*) from #RelatDrive where Drive not in ('M','Q') and [EspacoLivre MB] < @DiscoLimite 
if @QtdLinhas > 0 begin
			
	Select @BodyDisco = (select Drive as [TD],[EspacoLivre MB] as [TD] from #RelatDrive where Drive not in ('M','Q') and [EspacoLivre MB] < @DiscoLimite order by Drive FOR XML raw('tr'),elements)

	Set @BodyDisco = Replace(@BodyDisco, '_x0020_', space(1))
	Set @BodyDisco = Replace(@BodyDisco, '_x003D_', '=')
	Set @BodyDisco = Replace(@BodyDisco, '<tr><TRRow>1</TRRow>', '<tr bgcolor=#F0F0F0>')
	Set @BodyDisco = Replace(@BodyDisco, '<TRRow>0</TRRow>', '')
	Set @BodyDisco = @BodyDisco + '</table><p> </p>'
	set @Body = @Body + @TableDisco + @BodyDisco
end

drop table #RelatDrive


/*******************
 Analisa Memoria 
********************/
-- Cria tabela para relatório de JOBs de Backup
-- drop table ##RelatDrive
if left(@@VERSION,25) <> 'Microsoft SQL Server 2005' begin
	create table #RelatMemoria ([Memoria Total MB] bigint NULL,[Memoria Disponivel MB] bigint NULL,[% Livre] decimal(5,2) NULL)

	insert into #RelatMemoria
	SELECT total_physical_memory_kb/1024 as "Memoria Total MB",
		   available_physical_memory_kb/1024 as "Memoria Disponivel MB",
		   available_physical_memory_kb/(total_physical_memory_kb*1.0)*100 AS "% Livre"
	FROM sys.dm_os_sys_memory

	Set @TableMemoria = '<P style=font-size:14pt;><B>- Servidor pouca memoria livre</B></P>' +
				'<table cellpadding=0 cellspacing=0 border=0>' +
				'<tr bgcolor=#87CEEB>' + 
				'<td align=center><b>Memoria Total MB</b></td>' + 
				'<td align=center><b>Memoria Disponivel MB</b></td>' + 
				'<td align=center><b>% Livre</b></td></tr>';

	declare @MemLivre bigint  
	select @MemLivre = [Memoria Disponivel MB] from #RelatMemoria    

	if (@MemLivre < @MemLimite) begin

		Select @BodyMemoria = (SELECT [Memoria Total MB] as TD,[Memoria Disponivel MB] as TD,[% Livre] as TD FROM #RelatMemoria FOR XML raw('tr'),elements)

		Set @BodyMemoria = Replace(@BodyMemoria, '_x0020_', space(1))
		Set @BodyMemoria = Replace(@BodyMemoria, '_x003D_', '=')
		Set @BodyMemoria = Replace(@BodyMemoria, '<tr><TRRow>1</TRRow>', '<tr bgcolor=#F0F0F0>')
		Set @BodyMemoria = Replace(@BodyMemoria, '<TRRow>0</TRRow>', '')
		Set @BodyMemoria = @BodyMemoria + '</table><p> </p>'
		set @Body = @Body + @TableMemoria + @BodyMemoria
	end
	drop table #RelatMemoria
end


/***********************************
 Monta HTML Final e envia email 
************************************/
set @Body = @Body + @TableTail
--print @Body

if @Body not like '%<table%'
	SET @Body = '<br><P style=font-size:14pt;" ><B>Servidor sem ocorrências.</B></P>'

set @Subject = @Empresa + ': Relatório ' + @@SERVERNAME + ' do dia ' + CONVERT(varchar(30),getdate(),103)

EXEC msdb.dbo.sp_send_dbmail
@recipients=@Email_TO,
@subject = @Subject,
@body = @Body,
@body_format = 'HTML' ,
@profile_name=@ProfileDatabaseMail
go
/************************************* Fim SP ********************************************/

