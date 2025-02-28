/*********************************************************
 Autor: Landry Duailibe
 
 Descricao:
 Rebuild ou Reorganize dos indices de acordo com o 
 percentual de fragmentacao.
 
 OBS: Alterar o valor da variavel @Online para selecionar
      REBUILD ou REORGANIZE:
      - 'N' utiliza REBUILD (Offline)
      - 'S' utiliza REORGANIZE (Online) 

**********************************************************/

/********************************** 
 Criar JOB para REBUILD 
**********************************/
DECLARE @NomeBanco varchar(2000), @state_desc varchar(200)

IF object_id('dbo.tmpBancosReindex') is not null
   DROP TABLE dbo.tmpBancosReindex

SELECT db_name(database_id) as name,state_desc 
INTO dbo.tmpBancosReindex 
FROM sys.databases 
WHERE source_database_id is null
and state_desc = 'ONLINE' 
and is_read_only = 0
and name not in ('tempdb','ReportServerTempDB','model','master','msdb') 
and not exists (SELECT * FROM DBA.dbo.DBA_BackupExcluir WHERE Nomebanco = name)

DECLARE vCursorBancos CURSOR FOR 
SELECT name,state_desc FROM dbo.tmpBancosReindex ORDER BY name

OPEN vCursorBancos
FETCH NEXT FROM vCursorBancos INTO @NomeBanco, @state_desc

WHILE @@FETCH_STATUS <> -1 BEGIN
   
   IF db_id(@NomeBanco) is null begin
      PRINT '*** ERRO: DB_ID retornou NULL para o banco ' + @NomeBanco + CHAR(13)+CHAR(10)
      FETCH NEXT FROM vCursorBancos INTO @NomeBanco, @state_desc
      CONTINUE
   END

   IF @state_desc <> 'ONLINE' BEGIN
     PRINT '*** Banco: ' +  @NomeBanco + ' está: ' + @state_desc
     FETCH NEXT FROM vCursorBancos INTO @NomeBanco, @state_desc
     CONTINUE
   END

   PRINT '- Banco: ' + @NomeBanco + ' ****************************************************************' + CHAR(13)+CHAR(10)
   EXEC('use [' + @NomeBanco + '] exec sp_ManutencaoIndices')
  
   IF @@ERROR <> 0 begin
      PRINT '*** ERRO: indexação do banco ' + @NomeBanco + ' - Código de erro: ' + ltrim(str(@@error)) + CHAR(13)+CHAR(10)
      FETCH NEXT FROM vCursorBancos INTO @NomeBanco, @state_desc
      CONTINUE
   END   
   FETCH NEXT FROM vCursorBancos INTO @NomeBanco, @state_desc
END 

CLOSE vCursorBancos 
DEALLOCATE vCursorBancos

IF object_id('dbo.tmpBancosReindex') is not null
   DROP TABLE dbo.tmpBancosReindex  
go
/*************************** FIM JOB **********************************/


/*********************************
 Criar JOB para REORGANIZE 
**********************************/
DECLARE @NomeBanco varchar(2000), @state_desc varchar(200)

IF object_id('dbo.tmpBancosReindex') is not null
   DROP TABLE dbo.tmpBancosReindex

SELECT db_name(database_id) as name,state_desc 
INTO dbo.tmpBancosReindex 
FROM sys.databases 
WHERE source_database_id is null
and state_desc = 'ONLINE' 
and is_read_only = 0
and name not in ('tempdb','ReportServerTempDB','model','master','msdb','WebPortal','_MONITORA_SQL','DBA') 
and not exists (SELECT * FROM DBA.dbo.DBA_BackupExcluir WHERE Nomebanco = name)

DECLARE vCursorBancos CURSOR FOR 
SELECT name,state_desc FROM dbo.tmpBancosReindex ORDER BY name

OPEN vCursorBancos
FETCH NEXT FROM vCursorBancos INTO @NomeBanco, @state_desc

WHILE @@FETCH_STATUS <> -1 BEGIN
   
   IF db_id(@NomeBanco) is null BEGIN
      PRINT '*** ERRO: DB_ID retornou NULL para o banco ' + @NomeBanco + CHAR(13)+CHAR(10)
      FETCH NEXT FROM vCursorBancos INTO @NomeBanco, @state_desc
      CONTINUE
   END

   IF @state_desc <> 'ONLINE' BEGIN
     PRINT '*** Banco: ' +  @NomeBanco + ' está: ' + @state_desc
     FETCH NEXT FROM vCursorBancos INTO @NomeBanco, @state_desc
     CONTINUE
   END

   PRINT '- Banco: ' + @NomeBanco + ' ****************************************************************' + CHAR(13)+CHAR(10)
   EXEC('use [' + @NomeBanco + '] exec sp_ManutencaoIndices @Online = ''S''')
  
   IF @@ERROR <> 0 BEGIN
      PRINT '*** ERRO: indexação do banco ' + @NomeBanco + ' - Código de erro: ' + ltrim(str(@@error)) + CHAR(13)+CHAR(10)
      FETCH NEXT FROM vCursorBancos INTO @NomeBanco, @state_desc
      CONTINUE
   END   
   FETCH NEXT FROM vCursorBancos INTO @NomeBanco, @state_desc
END 

CLOSE vCursorBancos 
DEALLOCATE vCursorBancos

IF object_id('dbo.tmpBancosReindex') is not null
   DROP TABLE dbo.tmpBancosReindex  
go
/*************************** FIM JOB **********************************/


/****************************************************
 Criar como SP de Sistema sp_ManutencaoIndices
*****************************************************/
use master
go
CREATE or ALTER PROC dbo.sp_ManutencaoIndices
@Online char(1) = 'N', -- 'N' utiliza REBUILD (Offline) / 'S' utiliza REORGANIZE (Online)
@AtualizaEstatistica char(1) = 'S', -- 'S' roda SP_UPDATESTATS
@Percent_Frag smallint = 20
AS
set nocount on

DECLARE @objectid int
DECLARE @indexid int 
DECLARE @partitioncount bigint 
DECLARE @schemaname nvarchar(130) 
DECLARE @objectname nvarchar(130) 
DECLARE @indexname nvarchar(130) 
DECLARE @partitionnum bigint 
DECLARE @partitions bigint 
DECLARE @frag float 
DECLARE @command nvarchar(4000) 

IF object_id('dbo.DBA_ManutencaoIndices') is not null
	DROP TABLE dbo.DBA_ManutencaoIndices

CREATE TABLE dbo.DBA_ManutencaoIndices (
objectid int NULL,
indexid int NULL,
partitionnum int NULL,
frag float NULL,
page_count bigint NULL)

IF @Online = 'S' -- Analisa fragmentacao do nível folha para REORGANIZE
	INSERT dbo.DBA_ManutencaoIndices
	SELECT [object_id] AS objectid, index_id AS indexid, partition_number AS partitionnum, 
	avg_fragmentation_in_percent AS frag, page_count 
	FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, N'DETAILED') 
	WHERE 1=1
	AND index_level =  0 -- Nível Folha
	AND avg_fragmentation_in_percent >= @Percent_Frag  -- Seleciona indices com fragmentacao >= ???
	AND index_id > 0 -- Ignora heaps 
	AND page_count > 25 -- Ignora tabelas pequenas 

ELSE -- Analisa fragmentacao de todos os níveis para REBUILD

	INSERT dbo.DBA_ManutencaoIndices
	SELECT [object_id] AS objectid, index_id AS indexid, partition_number AS partitionnum, 
	avg_fragmentation_in_percent AS frag, page_count 
	FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, N'DETAILED') 
	WHERE 1=1	
	AND avg_fragmentation_in_percent >= @Percent_Frag  -- Seleciona indices com fragmentacao >= ???
	AND index_id > 0 -- Ignora heaps 
	AND page_count > 25 -- Ignora tabelas pequenas 


IF (select COUNT(*) from dbo.DBA_ManutencaoIndices) = 0 BEGIN
    PRINT '- Atualizando SÓ Estatisticas no Banco: ' + DB_NAME() + ' ****************************************************************'
	EXEC sp_updatestats
    RETURN
END
    
-- Cria Cursor
DECLARE vCursorIndices CURSOR FOR 
SELECT objectid,indexid, partitionnum,frag FROM dbo.DBA_ManutencaoIndices ORDER BY objectid

OPEN vCursorIndices 

FETCH NEXT FROM vCursorIndices INTO @objectid, @indexid, @partitionnum, @frag

WHILE @@FETCH_STATUS = 0  BEGIN

  SELECT @objectname = QUOTENAME(o.name), @schemaname = QUOTENAME(s.name) 
  FROM sys.objects AS o JOIN sys.schemas as s ON s.schema_id = o.schema_id 
  WHERE o.object_id = @objectid; 

  SELECT @indexname = QUOTENAME(name) 
  FROM sys.indexes 
  WHERE object_id = @objectid AND index_id = @indexid 

  SELECT @partitioncount = count (*) 
  FROM sys.partitions 
  WHERE object_id = @objectid AND index_id = @indexid

  print '- Tabela: ' + @objectname
  print '- Indice: ' + @indexname

  IF @Online = 'S' 
     SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE'
  ELSE
     SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD'

  IF @partitioncount > 1 
     SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS nvarchar(10)) 

  EXEC (@command) 

  PRINT N'Tabela: ' + ltrim(str(@objectid)) + ' - ' + @command; 
  FETCH NEXT FROM vCursorIndices INTO @objectid, @indexid, @partitionnum, @frag

END 

CLOSE vCursorIndices
DEALLOCATE vCursorIndices

IF object_id('dbo.DBA_ManutencaoIndices') is not null
	DROP TABLE dbo.DBA_ManutencaoIndices

IF @AtualizaEstatistica = 'S' BEGIN
    PRINT '- Atualizando Estatisticas no Banco: ' + DB_NAME() + ' ****************************************************************'
	EXEC sp_updatestats
END
GO 
/********************************** FIM SP ***********************************/

-- Definir SP com de sistema
EXEC sys.sp_MS_marksystemobject sp_ManutencaoIndices
go 
