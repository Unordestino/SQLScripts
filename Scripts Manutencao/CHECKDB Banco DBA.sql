/*********************************************************
 Data: 05/03/2006
 Autor: Landry D Salles Filho
 
 Descricao:
 Verifica a integridade de todos os bancos de dados de 
 uma instancia.
 
 OBS: executa o comando DBCC CHECKDB
 DBCC CHECKDB 
[
    [ ( database_name | database_id | 0
        [ , NOINDEX 
        | , { REPAIR_ALLOW_DATA_LOSS | REPAIR_FAST | REPAIR_REBUILD } ]
        ) ]
    [ WITH 
        {
            [ ALL_ERRORMSGS ]
            [ , EXTENDED_LOGICAL_CHECKS ] 
            [ , NO_INFOMSGS ]
            [ , TABLOCK ]
            [ , ESTIMATEONLY ]
            [ , { PHYSICAL_ONLY | DATA_PURITY } ]
        }
    ]
]

DBCC CHECKDB('PageRestoreDB') WITH TABLERESULTS,NO_INFOMSGS

restore filelistonly from disk = 'D:\CONSULTORIA\Scripts SQL Server\Contrato Manutencao - Scripts\PageRestoreDB_Corrupt.bak'

restore database PageRestoreDB from disk = 
'D:\CONSULTORIA\Scripts SQL Server\Contrato Manutencao - Scripts\PageRestoreDB_Corrupt.bak' with recovery,stats=5,
move 'PageRestoreDB_Data' to 'D:\Bancos\PageRestoreDB.mdf',
move 'PageRestoreDB_Log' to 'D:\Bancos\PageRestoreDB_Log.ldf'

-- Estimar uso da TEMPDB
dbcc checkdb('xxxxxx') with ESTIMATEONLY
**********************************************************/
use DBA
go
-- DROP TABLE DBA_Monitora_Hist_CheckDB
CREATE TABLE DBA_Monitora_Hist_CheckDB (
DataHora datetime not null,
Servidor varchar(128) not null default (@@SERVERNAME),
Banco varchar(128) not null,
Error int null, -- Error
Level int null, -- Level
State int null, -- State
Mensagem varchar(7000) null, -- MessageText
NivelReparo varchar(7000) null, -- RepairLevel
Arquivo int null, -- File
Pagina bigint null, -- Page
Objeto bigint null, -- ObjectID
Notificacao char(1) not null default ('N'))
go
-- select * from msdb.dbo.DBA_Monitora_Hist_CheckDB


/****************************** Inicio JOB *************************************/
SET NOCOUNT ON

DECLARE @NomeBanco varchar(2000), @state_desc varchar(200) 
DECLARE @command varchar(4000)
DECLARE @Empresa varchar(1000) = 'BONDINHO'
DECLARE @ProfileDatabaseMail varchar(2000) = 'SQLProfile'
DECLARE @Operador varchar(2000) = 'DBA_Alerta'

if object_id('dbo.tmpBancosCHECKDB') is not null
   drop table dbo.tmpBancosCHECKDB

select name,state_desc 
into dbo.tmpBancosCHECKDB 
from sys.databases 
where source_database_id is null
and state_desc = 'ONLINE' 
and name not in ('tempdb','model') 
--and name not in (SELECT Nomebanco FROM DBA.dbo.DBA_BackupExcluir)
--and name not in (select secondary_database from msdb.dbo.log_shipping_secondary_databases)
order by name

--DROP TABLE #CheckDBResult
CREATE TABLE #CheckDBResult(
ServerName varchar(100),
Error int NULL,
Level int NULL,
State int NULL,
MessageText varchar(7000) null,
RepairLevel varchar(7000) NULL,
Status int NULL,
DbId int NULL,
ObjectID bigint null,
indexid bigint null,
IndId bigint NULL,
PartitionId bigint NULL,
AllocUnitId bigint NULL,
[File] int NULL,
Page bigint NULL,
Slot int NULL,
RefFile bigint NULL,
RefPage bigint NULL,
RefSlot bigint NULL,
Allocation bigint NULL,
insert_date datetime NOT NULL CONSTRAINT DF_CheckDBResult_insert_date  DEFAULT (getdate()))

-- Cria Cursor com a lista de bancos ONLINE da instancia
DECLARE vCursor CURSOR FOR 
select name,state_desc from dbo.tmpBancosCHECKDB order by name

OPEN vCursor
FETCH NEXT FROM vCursor INTO @NomeBanco,@state_desc 

-- Executa o comando DBCC CHECKDB para cada banco da instancia
WHILE @@FETCH_STATUS <> -1 BEGIN
  waitfor delay '00:00:05' 

  if db_id(@NomeBanco) is null begin
     print '*** ERRO: DB_ID retornou NULL para o banco ' + @NomeBanco
     FETCH NEXT FROM vCursor INTO @NomeBanco,@state_desc 
     continue
  end
  
  if @state_desc <> 'ONLINE' begin
     print '*** ERRO: Banco ' +  @NomeBanco + ' está: ' + @state_desc
     FETCH NEXT FROM vCursor INTO @NomeBanco,@state_desc 
     continue
  end
  
  PRINT 'Banco: ' + @NomeBanco
  SET @command = 'dbcc checkdb(''' + @NomeBanco + ''') with NO_INFOMSGS'
  
  INSERT #CheckDBResult (Error,[Level],[State],MessageText,RepairLevel,[Status],[DbId],ObjectID,
  indexid,PartitionId,AllocUnitId,[File],Page,Slot,RefFile,RefPage,RefSlot,Allocation)
  EXEC ('dbcc checkdb(''' + @NomeBanco + ''') with NO_INFOMSGS,TABLERESULTS')

  if @@ERROR <> 0 begin
      print '*** ERRO: CHECKDB banco ' + @NomeBanco + ' - Código de erro: ' + ltrim(str(@@error))
      FETCH NEXT FROM vCursor INTO @NomeBanco,@state_desc 
      continue
  end   

  INSERT DBA.dbo.DBA_Monitora_Hist_CheckDB
  (DataHora, Banco, Error, [Level], [State], Mensagem, NivelReparo, Arquivo, Pagina,Objeto)
  SELECT insert_date, @NomeBanco, Error, [Level], [State], MessageText, RepairLevel, [File], [Page],ObjectID
  FROM #CheckDBResult

  TRUNCATE TABLE #CheckDBResult

  FETCH NEXT FROM vCursor INTO @NomeBanco,@state_desc 
END 
CLOSE vCursor 
DEALLOCATE vCursor 

if object_id('dbo.tmpBancosCHECKDB') is not null
   drop table dbo.tmpBancosCHECKDB

DROP TABLE #CheckDBResult

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

if exists (select * from DBA.dbo.DBA_Monitora_Hist_CheckDB where Notificacao = 'N') begin

	Set @TableJOB = '<P style=font-size:14pt;" ><B>Relatório CHECKDB</B></P>' +
				'<table cellpadding=0 cellspacing=0 border=0>' +
				'<tr bgcolor=#87CEEB>' + 
				'<td align=center><b>DataHora</b></td>' + 
				'<td align=center><b>Banco de Dados</b></td>' + 
				'<td align=center><b>Arquivo</b></td>' + 
				'<td align=center><b>Pagina</b></td>' + 
				'<td align=center><b>Objeto</b></td>' + 
				'<td align=center><b>Nivel de Reparo</b></td>' + 
				'<td align=center><b>Mensagem</b></td></tr>';
				
	Select @BodyJOB = (select Row_Number() Over(Order By DataHora desc) % 2 As [TRRow],
	convert(varchar(10), DataHora,103) + ' ' + convert(varchar(8),DataHora,114) as [TD],isnull(Banco,'N/A') as [TD],
	isnull(Arquivo,0) as [TD],isnull(Pagina,0) as [TD],isnull(Objeto,0) as [TD],
	isnull(NivelReparo,'N/A') as [TD],isnull(left(Mensagem,90),'N/A') as [TD]
	from DBA.dbo.DBA_Monitora_Hist_CheckDB where Notificacao = 'N' order by DataHora
	FOR XML raw('tr'),elements)

--select convert(varchar(8),DataHora,112) Data, Banco, Arquivo, Pagina, NivelReparo,left(Mensagem,90) as Mensagem
--from DBA.dbo.DBA_Monitora_Hist_CheckDB
--where Notificacao = 'N'

    update DBA.dbo.DBA_Monitora_Hist_CheckDB set Notificacao = 'S' where Notificacao = 'N'

	Set @BodyJOB = Replace(@BodyJOB, '_x0020_', space(1))
	Set @BodyJOB = Replace(@BodyJOB, '_x003D_', '=')
	Set @BodyJOB = Replace(@BodyJOB, '<tr><TRRow>1</TRRow>', '<tr bgcolor=#F0F0F0>')
	Set @BodyJOB = Replace(@BodyJOB, '<TRRow>0</TRRow>', '')
	Set @BodyJOB = @BodyJOB + '</table><p> </p><br>'
	set @Body = @Body + @TableJOB + @BodyJOB

    /**************** Monta HTML Final e envia email ********************/
    set @Body = @Body + @TableTail
    --Select @Body

    set @Subject = @Empresa + ': Relatório CHECKDB - ' + @@SERVERNAME + ' do dia ' + CONVERT(varchar(30),getdate(),103)

	EXEC msdb.dbo.sp_send_dbmail
	@recipients=@Email_TO,
	@subject = @Subject,
	@body = @Body,
	@body_format = 'HTML' ,
	@profile_name=@ProfileDatabaseMail
end
go
/**************************** Fim JOB **************************************/



