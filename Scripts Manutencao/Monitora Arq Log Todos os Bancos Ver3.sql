USE [master]

GO
CREATE PROC [dbo].[sp_DBA_LogSpace]
AS
set nocount on

declare @id	int			-- The object id that takes up space
		,@dbname sysname
		,@logsize bigint


DECLARE @summary_tmp_table table(
database_name nvarchar(128),
log_size_MB decimal(20,2));

-- Atualiza informações estatísticas
--dbcc updateusage(0) with no_infomsgs

select @logsize = sum(convert(bigint,case when status & 64 <> 0 then size else 0 end))
from dbo.sysfiles

INSERT INTO @summary_tmp_table

SELECT db_name() as database_name,
(CONVERT (dec (20,2),@logsize)) * 8192.0 / 1048576.0 as log_size_MB

select * from @summary_tmp_table
go
/********************************** FIM SP ***********************************/

-- Definir SP com de sistema
EXEC sys.sp_MS_marksystemobject sp_DBA_LogSpace
go 



/*******************************************
 Limites para alerta por banco

SELECT b.name as Banco,a.name as NomeLogico,a.type_desc as TipoArquivo,a.physical_name as Localizacao,
(a.size * 8) / 1024 as TamanhoMB
FROM sys.master_files a
JOIN sys.databases b ON a.database_id = b.database_id
WHERE a.type_desc = 'LOG'
ORDER BY TamanhoMB desc
********************************************/
use DBA
go

CREATE TABLE dbo.DBA_Limite_ArqLog (NomeBanco sysname,Limite decimal(20,2))

-- Bancos com limites diferentes
INSERT dbo.DBA_Limite_ArqLog VALUES ('bottino', 100000.00)
INSERT dbo.DBA_Limite_ArqLog VALUES ('dbgemco70', 30000.00)
INSERT dbo.DBA_Limite_ArqLog VALUES ('corpore', 25000.00)
INSERT dbo.DBA_Limite_ArqLog VALUES ('Miro', 40000.00)
INSERT dbo.DBA_Limite_ArqLog VALUES ('NBT1XC_PRD', 20000.00)
INSERT dbo.DBA_Limite_ArqLog VALUES ('tempdb', 50000.00)
INSERT dbo.DBA_Limite_ArqLog VALUES ('AMOEDO_PROD', 40000.00)
INSERT dbo.DBA_Limite_ArqLog VALUES ('amoedo_documento', 30000.00)
go

UPDATE dbo.DBA_Limite_ArqLog SET Limite = 25000 WHERE NomeBanco = 'corpore'
go

/***************************************************
 Criar JOB
****************************************************/
DECLARE @Empresa varchar(1000) = 'Amoedo'
DECLARE @ProfileDatabaseMail varchar(2000) = 'SQLProfile'
DECLARE @Operador varchar(2000) = 'DBA'
DECLARE @LimitePadrao decimal(20,2) = 10000.00
DECLARE @DriveLog char(1) = 'Y'
set nocount on

/*****************************************************
 Identifica Discos destinados aos Arquivos de Log
******************************************************/
DECLARE @tb_Discos table (Drive varchar(10) null,[EspacoLivre MB] bigint null)

INSERT @tb_Discos (Drive, [EspacoLivre MB]) EXEC master.dbo.xp_fixeddrives

DELETE @tb_Discos WHERE Drive not in (@DriveLog) -- Drive com Logs

/*******************************************
 Limites para alerta por banco
********************************************/
-- Demais bancos limite padrão
INSERT DBA.dbo.DBA_Limite_ArqLog
SELECT a.name as NomeBanco,@LimitePadrao as Limite
FROM sys.databases a
WHERE not exists (select * from DBA.dbo.DBA_Limite_ArqLog b where b.NomeBanco = a.name)

/**************************************
 Inicio HTML
***************************************/ 
DECLARE @TableHead varchar(max),@TableTail varchar(max), @Subject varchar(2000), @Body varchar(max)
DECLARE @TableJOB varchar(max), @BodyJOB varchar(max)
DECLARE @TableDrive varchar(max), @BodyDrive varchar(max)
DECLARE @SQLversion varchar(max), @Email_TO varchar(2000), @Servidor varchar(2000)

SELECT @Email_TO = email_address FROM msdb.dbo.sysoperators WHERE name = @Operador

SELECT @SQLversion = left(@@VERSION,25) + ' - Build '
+ CAST(SERVERPROPERTY('productversion') AS VARCHAR) + ' - ' 
+ CAST(SERVERPROPERTY('productlevel') AS VARCHAR) + ' (' 
+ CAST(SERVERPROPERTY('edition') AS VARCHAR) + ')'

SELECT @Servidor = @@SERVERNAME


-- Coleta tamanho do arquivo de Log de cada banco até SQL 2008
declare @spaceused table (
database_name nvarchar(128),
log_size_MB decimal(20,2))

insert @spaceused exec sp_MSforeachdb 'use [?]; exec sp_DBA_LogSpace;'

if exists (
select database_name,log_size_MB 
from @spaceused a 
join DBA.dbo.DBA_Limite_ArqLog b on b.NomeBanco = a.database_name
where a.log_size_MB > b.Limite)

BEGIN

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

	/*******************
	 Tabela Bancos 
	********************/
	Set @TableJOB = '<P style=font-size:14pt;" ><B>Banco(s) com Arquivo de Log Crescendo</B></P>' +
				'<table cellpadding=0 cellspacing=0 border=0>' +
				'<tr bgcolor=#87CEEB>' + 
				'<td align=center><b>Banco</b></td>' + 
				'<td align=center><b>Limite Log MB</b></td>' + 
				'<td align=center><b>Tamanho Log MB</b></td></tr>';

	
	Select top(12) @BodyJOB = (select Row_Number() Over(Order By a.database_name) % 2 As [TRRow],
	a.database_name as [TD],b.Limite as [TD],a.log_size_MB as [TD] 
	from @spaceused a 
	join DBA.dbo.DBA_Limite_ArqLog b on b.NomeBanco = a.database_name
	where a.log_size_MB > b.Limite
	order by a.database_name 
	FOR XML raw('tr'),elements)

	Set @BodyJOB = Replace(@BodyJOB, '_x0020_', space(1))
	Set @BodyJOB = Replace(@BodyJOB, '_x003D_', '=')
	Set @BodyJOB = Replace(@BodyJOB, '<tr><TRRow>1</TRRow>', '<tr bgcolor=#F0F0F0>')
	Set @BodyJOB = Replace(@BodyJOB, '<TRRow>0</TRRow>', '')
	Set @BodyJOB = @BodyJOB + '</table><p> </p><br>'
	set @Body = @Body + @TableJOB + @BodyJOB
	/*******************************************/

	/*******************
	 Tabela Bancos 
	********************/
	Set @TableDrive = '<P style=font-size:14pt;" ><B>Espaço Livre Volumes LOG</B></P>' +
				'<table cellpadding=0 cellspacing=0 border=0>' +
				'<tr bgcolor=#87CEEB>' + 
				'<td align=center><b>Volume</b></td>' + 
				'<td align=center><b>Espaço Livre MB</b></td></tr>';

	
	Select top(12) @BodyDrive = (select Row_Number() Over(Order By a.Drive) % 2 As [TRRow],
	a.Drive as [TD],a.[EspacoLivre MB] as [TD] 
	from @tb_Discos a
	order by a.Drive 
	FOR XML raw('tr'),elements)

	Set @BodyDrive = Replace(@BodyDrive, '_x0020_', space(1))
	Set @BodyDrive = Replace(@BodyDrive, '_x003D_', '=')
	Set @BodyDrive = Replace(@BodyDrive, '<tr><TRRow>1</TRRow>', '<tr bgcolor=#F0F0F0>')
	Set @BodyDrive = Replace(@BodyDrive, '<TRRow>0</TRRow>', '')
	Set @BodyDrive = @BodyDrive + '</table><p> </p><br>'
	set @Body = @Body + @TableDrive + @BodyDrive
	/*******************************************/



	/**************** Monta HTML Final e envia email ********************/
	set @Body = @Body + @TableTail
	--Select @Body

	set @Subject = @Empresa + ' URGENTE: Arquivo(s) LOG crescendo - ' + @@SERVERNAME + ' do dia ' + CONVERT(varchar(30),getdate(),103)

	EXEC msdb.dbo.sp_send_dbmail
	@recipients=@Email_TO,
	@subject = @Subject,
	@body = @Body,
	@body_format = 'HTML' ,
	@profile_name=@ProfileDatabaseMail
END
