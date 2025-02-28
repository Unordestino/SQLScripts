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


SET NOCOUNT ON

DECLARE @NomeBanco varchar(2000), @state_desc varchar(200) 
DECLARE @command varchar(4000)
DECLARE @Empresa varchar(1000) = 'SEBRAE'
DECLARE @ProfileDatabaseMail varchar(2000) = 'SQLProfile'
DECLARE @Operador varchar(2000) = 'DBA'
DECLARE @QtdPaginas int = 0

-- ENVIA EMAIL
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

CREATE TABLE #tmp_ErroLog (
LogDate datetime null,
ProcessInfo nvarchar(200) null,
Msg nvarchar(max))


INSERT #tmp_ErroLog
EXEC sys.xp_readerrorlog 0,1,N'I/O requests taking longer than 15 seconds to complete',null,null,null,N'desc'

DELETE #tmp_ErroLog WHERE LogDate < (GETDATE()-2)

if exists (select * from  #tmp_ErroLog) begin

	Set @TableJOB = '<P style=font-size:14pt;" ><B>Quantidade de ocorrências de latência de IO por dia</B></P>' +
				'<table cellpadding=0 cellspacing=0 border=0>' +
				'<tr bgcolor=#87CEEB>' + 
				'<td align=center><b>Data</b></td>' + 
				'<td align=center><b>Quantidade</b></td></tr>';

	Select @BodyJOB = (select Row_Number() Over(Order By cast(LogDate as date) desc) % 2 As [TRRow],
	cast(LogDate as date) as [TD], sum(cast(substring(Msg,27,CHARINDEX ('occurrence',Msg)-28) as bigint)) as [TD]
	from #tmp_ErroLog
	GROUP BY cast(LogDate as date)
	ORDER BY 1 desc
	FOR XML raw('tr'),elements)

	Set @BodyJOB = Replace(@BodyJOB, '_x0020_', space(1))
	Set @BodyJOB = Replace(@BodyJOB, '_x003D_', '=')
	Set @BodyJOB = Replace(@BodyJOB, '<tr><TRRow>1</TRRow>', '<tr bgcolor=#F0F0F0>')
	Set @BodyJOB = Replace(@BodyJOB, '<TRRow>0</TRRow>', '')
	Set @BodyJOB = @BodyJOB + '</table><p> </p><br>'
	set @Body = @Body + @TableJOB + @BodyJOB

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
end
DROP TABLE #tmp_ErroLog
go

