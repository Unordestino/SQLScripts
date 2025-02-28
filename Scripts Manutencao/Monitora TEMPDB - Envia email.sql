/****************************************************************
 Monitora cresciemnto TEMPDB
 - Envio de email
 Autor: Landry Salles
 Data: 15/02/2010
*****************************************************************/
USE DBA
GO
/*
select Data, Tamanho_MB, EspacoUtil_MB, EspacoLivreMB, ObjetosUsuarioMB, VersionStoreMB, ObjetosInternosMB
from msdb.dbo.DSAI_MonitoraTempDB
order by Data desc
*/
/*
exec DBA_sp_MonitoraTempDB_Email @Empresa = 'BRASIL BROKERS', @ProfileDatabaseMail = 'SQLAdmin', @Operador = 'DBA'
*/
-- DROP PROCEDURE DBA_sp_MonitoraTempDB_Email
IF OBJECT_ID('DBA_sp_MonitoraTempDB_Email') IS NULL
    EXEC('CREATE PROCEDURE DBA_sp_MonitoraTempDB_Email AS SET NOCOUNT ON;')
go
ALTER PROC dbo.DBA_sp_MonitoraTempDB_Email
@Empresa varchar(1000) = 'BRASIL BROKERS',
@ProfileDatabaseMail varchar(2000) = 'SQLAdmin',
@Operador varchar(2000) = 'DBA'
as
set nocount on

Declare @TableHead varchar(max),@TableTail varchar(max), @Subject varchar(2000), @QtdLinhas int 
Declare @TableJOB varchar(max)
Declare @Body varchar(max), @BodyJOB varchar(max), @BodyManutBD varchar(max), @BodyDisco varchar(max), @BodyMemoria varchar(max)
Declare @SQLversion varchar(max), @Email_TO varchar(2000), @Servidor varchar(2000)


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
			'<P style=font-size:12pt;" >' + @SQLversion + '</P><br>'

set @Body = @TableHead

/*************** Tabela TempDB ********************/
	Set @TableJOB = '<P style=font-size:14pt;" ><B>Evolução da Ocupação TempDB</B></P>' +
				'<table cellpadding=0 cellspacing=0 border=0>' +
				'<tr bgcolor=#87CEEB>' + 
				'<td align=center><b>DataHora</b></td>' + 
				'<td align=center><b>Tamanho MB</b></td>' + 
				'<td align=center><b>EspacoUtil MB</b></td>' + 
				'<td align=center><b>EspacoLivre MB</b></td>' + 
				'<td align=center><b>ObjetosUsuario MB</b></td>' + 
				'<td align=center><b>VersionStore MB</b></td>' + 
				'<td align=center><b>ObjetosInternos MB</b></td></tr>';

	with CTE_tmp as (
	select top(12) max(Data) as Data,
	isnull(Tamanho_MB,0) as Tamanho_MB,max(EspacoUtil_MB) as EspacoUtil_MB,max(EspacoLivreMB) as EspacoLivreMB,
	max(ObjetosUsuarioMB) as ObjetosUsuarioMB,max(VersionStoreMB) as VersionStoreMB,max(ObjetosInternosMB) as ObjetosInternosMB
	FROM dbo.DBA_Monitora_TempDB 
        WHERE Data >= convert(varchar(8),getdate(),112)
	GROUP BY convert(varchar(8), Data,112),Tamanho_MB 
	ORDER BY convert(varchar(8), Data,112) DESC,Tamanho_MB)
				
	Select top(12) @BodyJOB = (select Row_Number() Over(Order By Data desc) % 2 As [TRRow],
	convert(varchar(10), Data,103) + ' ' + convert(varchar(8),Data,114) as [TD],
	isnull(Tamanho_MB,0) as [TD],isnull(EspacoUtil_MB,0) as [TD],isnull(EspacoLivreMB,0) as [TD],
	isnull(ObjetosUsuarioMB,0) as [TD],isnull(VersionStoreMB,0) as [TD],isnull(ObjetosInternosMB,0) as [TD]
	FROM CTE_tmp 
	ORDER BY Data DESC,Tamanho_MB
	FOR XML raw('tr'),elements)

	Set @BodyJOB = Replace(@BodyJOB, '_x0020_', space(1))
	Set @BodyJOB = Replace(@BodyJOB, '_x003D_', '=')
	Set @BodyJOB = Replace(@BodyJOB, '<tr><TRRow>1</TRRow>', '<tr bgcolor=#F0F0F0>')
	Set @BodyJOB = Replace(@BodyJOB, '<TRRow>0</TRRow>', '')
	Set @BodyJOB = @BodyJOB + '</table><p> </p><br>'
	set @Body = @Body + @TableJOB + @BodyJOB
/*******************************************/

/**************** Monta HTML Final e envia email ********************/
set @Body = @Body + @TableTail
--Select @Body

set @Subject = @Empresa + ': URGENTE Crescimento TEMPDB - ' + @@SERVERNAME + ' do dia ' + CONVERT(varchar(30),getdate(),103)

EXEC msdb.dbo.sp_send_dbmail
@recipients=@Email_TO,
@subject = @Subject,
@body = @Body,
@body_format = 'HTML' ,
@profile_name=@ProfileDatabaseMail
go
/************************* Fim SP ************************/

/**********************************
 Criar JOB para enviar email
 A cada 1h
***********************************/
declare @TamanhoAlertaMB decimal(20,6) = 50000.00
declare @TamanhoMB decimal(20,6)

SELECT @TamanhoMB = sum (size*1.0/128) 
FROM tempdb.sys.database_files

if @TamanhoMB > @TamanhoAlertaMB 
  exec DBA_sp_MonitoraTempDB_Email @Empresa = 'BRASIL BROKERS', @ProfileDatabaseMail = 'SQLAdmin', @Operador = 'DBA'
go

-- Limpeza periódica da tabela
DELETE FROM dbo.DBA_Monitora_TempDB
WHERE Data <= convert(varchar(8),dateadd(MM,-6,getdate()),112)
