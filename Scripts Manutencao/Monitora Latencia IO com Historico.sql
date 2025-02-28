/**************************************************************************************************
 Alerta para latência de IO no SQL Server
 
 Utiliza sys.xp_readerrorlog, parâmetros:
 1) Valor que identifica o Log que deve ser retornado - 0 = corrente, 1 = Arquivo #1, 2 = Arquivo #2, etc...
 2) Tipo do Log - 1 or NULL = Log SQL Server, 2 = Log SQL Agent
 3) Primeira pesquisa de string
 4) Segunda pesquisa de string
 5) Pesquisa a partir de uma data/hora
 6) Pesquisa até uma data/hora
 7) Ordem: N'asc' = ascending, N'desc' = descending

 Exemplo para retornar ocorrências de latência no Log corrente do SQL Server:

	EXEC sys.xp_readerrorlog 0,1,N'I/O requests taking longer than 15 seconds to complete',null,null,null,N'desc'
 
 Artigo que relata o problema:
 https://blogs.msdn.microsoft.com/sqlsakthi/2011/02/09/troubleshooting-sql-server-io-requests-taking-longer-than-15-seconds-io-stalls-disk-latency/

****************************************************************************************************/
use DBA
go

/**********************************************
 Cria tabela para´armazenar histórico detalhado
 de ocorrências de latência de IO
***********************************************/
-- DROP TABLE dbo.DBA_Monitora_LatenciaIO
CREATE TABLE dbo.DBA_Monitora_LatenciaIO (
LatenciaIO_ID bigint not null identity primary key,
LogDate datetime null,
ProcessInfo varchar(200) null,
Msg varchar(max) null,
Processado bit not null default (0))
go



/*********************************************************************
 Stored Procedure para armazenar ocorrências de latência de IO
 a partir do log do SQL Server, notificando por email

 - Criar JOB executando a cada 2 dias com 2 Steps:
   EXEC sp_cycle_errorlog
   EXEC DBA_sp_LatenciaIO @Empresa = 'BRASIL BROKERS', @ProfileDatabaseMail = 'SQLAdmin', @Operador = 'DBA'
**********************************************************************/
--EXEC DBA_sp_LatenciaIO @Empresa = 'IQVIA', @ProfileDatabaseMail = 'SQLProfile', @Operador = 'DBA'

-- DROP PROCEDURE DBA_sp_LatenciaIO
IF OBJECT_ID('DBA_sp_LatenciaIO') IS NULL
    EXEC('CREATE PROCEDURE DBA_sp_LatenciaIO AS SET NOCOUNT ON;')
go
ALTER PROC dbo.DBA_sp_LatenciaIO
@Empresa varchar(1000) = 'IQVIA',
@ProfileDatabaseMail varchar(2000) = 'SQLProfile',
@Operador varchar(2000) = 'DBA'
AS

SET NOCOUNT ON

DECLARE @NomeBanco varchar(2000), @state_desc varchar(200) 
DECLARE @command varchar(4000)

DECLARE @QtdPaginas int = 0

-- Coleta Informações sobre latência de IO
DECLARE @tmp_ErroLog table (
LogDate datetime null,
ProcessInfo nvarchar(200) null,
Msg nvarchar(max))

INSERT @tmp_ErroLog
EXEC sys.xp_readerrorlog 0,1,N'I/O requests taking longer than 15 seconds to complete',null,null,null,N'desc'

INSERT DBA_Monitora_LatenciaIO
(LogDate,ProcessInfo,Msg)
SELECT LogDate,ProcessInfo,Msg FROM @tmp_ErroLog

-- Se não existem ocorrências de latência abortar a execução da Stored Procedure
if not exists(select * from DBA_Monitora_LatenciaIO where Processado = 0)
   return

-- Notifica por email
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

declare @DataSinc datetime
set @DataSinc = dateadd(dd,-1,getdate())

Set @TableJOB = '<P style=font-size:14pt;" ><B>Quantidade de ocorrências de latência de IO por dia</B></P>' +
			'<table cellpadding=0 cellspacing=0 border=0>' +
			'<tr bgcolor=#87CEEB>' + 
			'<td align=center><b>Data</b></td>' + 
			'<td align=center><b>Quantidade</b></td></tr>';

SELECT @BodyJOB = (select Row_Number() Over(Order By cast(LogDate as date) desc) % 2 As [TRRow],
cast(LogDate as date) as [TD], sum(cast(substring(Msg,27,CHARINDEX ('occurrence',Msg)-28) as bigint)) as [TD]
FROM DBA_Monitora_LatenciaIO
WHERE Processado = 0
GROUP BY cast(LogDate as date)
ORDER BY 1 desc
FOR XML raw('tr'),elements)

Set @BodyJOB = Replace(@BodyJOB, '_x0020_', space(1))
Set @BodyJOB = Replace(@BodyJOB, '_x003D_', '=')
Set @BodyJOB = Replace(@BodyJOB, '<tr><TRRow>1</TRRow>', '<tr bgcolor=#F0F0F0>')
Set @BodyJOB = Replace(@BodyJOB, '<TRRow>0</TRRow>', '')
Set @BodyJOB = @BodyJOB + '</table><p> </p><br>'
set @Body = @Body + @TableJOB + @BodyJOB

UPDATE DBA_Monitora_LatenciaIO SET Processado = 1 WHERE Processado = 0

/**************** Monta HTML Final e envia email ********************/
set @Body = @Body + @TableTail
--Select @Body

set @Subject = @Empresa + ': Latência IO - ' + @@SERVERNAME + ' do dia ' + CONVERT(varchar(30),getdate(),103)

EXEC msdb.dbo.sp_send_dbmail
@recipients=@Email_TO,
@subject = @Subject,
@body = @Body,
@body_format = 'HTML' ,
@profile_name=@ProfileDatabaseMail
go
/*************************************** Fim SP ****************************************/




