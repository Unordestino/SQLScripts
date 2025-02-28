/*********************************************************
 Data: 05/05/2006	Ultima Alteração: 13/12/2018
 Autor: Landry D Salles Filho
 
 Descricao:
 Rebuild ou Reorganize dos indices de acordo com o 
 percentual de fragmentacao.
 
 OBS: Alterar o valor da variavel @Online para selecionar
      REBUILD ou REORGANIZE:
      - 'N' utiliza REBUILD (Offline)
      - 'S' utiliza REORGANIZE (Online) 

SELECT OBJECT_NAME(object_id) as Tabela,index_id,partition_number,avg_fragmentation_in_percent,forwarded_record_count 
FROM SYS.dm_db_index_physical_stats(DB_ID('Westcon'),null,null,null,'DETAILED')
order by avg_fragmentation_in_percent desc
**********************************************************/

/********************* Criar JOB com REBUILD **********************************/
declare @NomeBanco varchar(2000), @state_desc varchar(200)

if object_id('dbo.tmpBancosReindex') is not null
   drop table dbo.tmpBancosReindex

select db_name(database_id) as name,state_desc 
into dbo.tmpBancosReindex 
from sys.databases 
where source_database_id is null
and state_desc = 'ONLINE' 
and is_read_only = 0
and name not in ('tempdb','ReportServerTempDB','model','master','msdb') 
and not exists (select * from DBA.dbo.DBA_BackupExcluir where Nomebanco = name)

DECLARE vCursorBancos CURSOR FOR 
select name,state_desc from dbo.tmpBancosReindex order by name

open vCursorBancos
fetch next from vCursorBancos into @NomeBanco, @state_desc
WHILE @@FETCH_STATUS <> -1
begin
   waitfor delay '00:00:05'
   
   if db_id(@NomeBanco) is null begin
      print '*** ERRO: DB_ID retornou NULL para o banco ' + @NomeBanco + CHAR(13)+CHAR(10)
      fetch next from vCursorBancos into @NomeBanco, @state_desc
      continue
   end

   if @state_desc <> 'ONLINE' begin
     print '*** Banco: ' +  @NomeBanco + ' está: ' + @state_desc
   FETCH NEXT FROM vCursorBancos INTO @NomeBanco, @state_desc
     continue
  end

   print '- Banco: ' + @NomeBanco + ' ****************************************************************' + CHAR(13)+CHAR(10)
   exec('use [' + @NomeBanco + '] exec sp_ManutencaoIndices')
  
   if @@ERROR <> 0 begin
      print '*** ERRO: indexação do banco ' + @NomeBanco + ' - Código de erro: ' + ltrim(str(@@error)) + CHAR(13)+CHAR(10)
      fetch next from vCursorBancos into @NomeBanco, @state_desc
      continue
   end   
   FETCH NEXT FROM vCursorBancos INTO @NomeBanco, @state_desc
END 
CLOSE vCursorBancos 
DEALLOCATE vCursorBancos

if object_id('dbo.tmpBancosReindex') is not null
   drop table dbo.tmpBancosReindex  
go
/*************************** FIM JOB **********************************/


/********************* Criar JOB com REORGANIZE **********************************/
declare @NomeBanco varchar(2000), @state_desc varchar(200)

if object_id('dbo.tmpBancosReindex') is not null
   drop table dbo.tmpBancosReindex

select db_name(database_id) as name,state_desc 
into dbo.tmpBancosReindex 
from sys.databases 
where source_database_id is null
and state_desc = 'ONLINE' 
and is_read_only = 0
and name not in ('tempdb','ReportServerTempDB','model','master','msdb','WebPortal','_MONITORA_SQL','DBA') 
and not exists (select * from DBA.dbo.DBA_BackupExcluir where Nomebanco = name)

DECLARE vCursorBancos CURSOR FOR 
select name,state_desc from dbo.tmpBancosReindex order by name

open vCursorBancos
fetch next from vCursorBancos into @NomeBanco, @state_desc
WHILE @@FETCH_STATUS <> -1
begin
   waitfor delay '00:00:05'
   
   if db_id(@NomeBanco) is null begin
      print '*** ERRO: DB_ID retornou NULL para o banco ' + @NomeBanco + CHAR(13)+CHAR(10)
      fetch next from vCursorBancos into @NomeBanco, @state_desc
      continue
   end

   if @state_desc <> 'ONLINE' begin
     print '*** Banco: ' +  @NomeBanco + ' está: ' + @state_desc
   FETCH NEXT FROM vCursorBancos INTO @NomeBanco, @state_desc
     continue
  end

   print '- Banco: ' + @NomeBanco + ' ****************************************************************' + CHAR(13)+CHAR(10)
   exec('use [' + @NomeBanco + '] exec sp_ManutencaoIndices @Online = ''S''')
  
   if @@ERROR <> 0 begin
      print '*** ERRO: indexação do banco ' + @NomeBanco + ' - Código de erro: ' + ltrim(str(@@error)) + CHAR(13)+CHAR(10)
      fetch next from vCursorBancos into @NomeBanco, @state_desc
      continue
   end   
   FETCH NEXT FROM vCursorBancos INTO @NomeBanco, @state_desc
END 
CLOSE vCursorBancos 
DEALLOCATE vCursorBancos

if object_id('dbo.tmpBancosReindex') is not null
   drop table dbo.tmpBancosReindex  
go

/*************************** FIM JOB **********************************/


/****************************************************
 SP sistema reindex
*****************************************************/
use master
go
CREATE proc [dbo].[sp_ManutencaoIndices]
@Online char(1) = 'N', -- 'N' utiliza REBUILD (Offline) / 'S' utiliza REORGANIZE (Online)
@AtualizaEstatistica char(1) = 'S', -- 'S' roda SP_UPDATESTATS
@Percent_Frag smallint = 20
as
SET NOCOUNT ON; 

DECLARE @objectid int; 
DECLARE @indexid int; 
DECLARE @partitioncount bigint; 
DECLARE @schemaname nvarchar(130); 
DECLARE @objectname nvarchar(130); 
DECLARE @indexname nvarchar(130); 
DECLARE @partitionnum bigint; 
DECLARE @partitions bigint; 
DECLARE @frag float; 
DECLARE @command nvarchar(4000); 

-- Analisa fragmentacao e armazena resultado em tabela temporaria #TabTMP
SELECT [object_id] AS objectid, index_id AS indexid, partition_number AS partitionnum, 
avg_fragmentation_in_percent AS frag, page_count 
INTO #TabTMP 
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, N'DETAILED') 
WHERE 1=1
AND index_level =  0 -- Nível Folha
AND avg_fragmentation_in_percent >= @Percent_Frag  -- Seleciona indices com fragmentacao >= ???
AND index_id > 0 -- Ignora heaps 
AND page_count > 25 -- Ignora tabelas pequenas 

IF (select COUNT(*) from #TabTMP) = 0 BEGIN
    PRINT '- Atualizando SÓ Estatisticas no Banco: ' + DB_NAME() + ' ****************************************************************'
	EXEC sp_updatestats
    RETURN
END
    
-- Cria Cursor
DECLARE vCursorIndices CURSOR FOR SELECT objectid,indexid, partitionnum,frag FROM #TabTMP ORDER BY objectid; 
OPEN vCursorIndices; 

FETCH NEXT FROM vCursorIndices INTO @objectid, @indexid, @partitionnum, @frag; 

WHILE @@FETCH_STATUS = 0  BEGIN

  SELECT @objectname = QUOTENAME(o.name), @schemaname = QUOTENAME(s.name) 
  FROM sys.objects AS o JOIN sys.schemas as s ON s.schema_id = o.schema_id 
  WHERE o.object_id = @objectid; 

  SELECT @indexname = QUOTENAME(name) 
  FROM sys.indexes 
  WHERE object_id = @objectid AND index_id = @indexid; 

  SELECT @partitioncount = count (*) 
  FROM sys.partitions 
  WHERE object_id = @objectid AND index_id = @indexid; 

  print '- Tabela: ' + @objectname
  print '- Indice: ' + @indexname

  IF @Online = 'S' 
     SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE'; 
  ELSE
     SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD'; 

  IF @partitioncount > 1 
     SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS nvarchar(10)); 

  EXEC (@command); 

  PRINT N'Tabela: ' + ltrim(str(@objectid)) + ' - ' + @command; 
  FETCH NEXT FROM vCursorIndices INTO @objectid, @indexid, @partitionnum, @frag; 

END 

CLOSE vCursorIndices; 
DEALLOCATE vCursorIndices; 
DROP TABLE #TabTMP; 

IF @AtualizaEstatistica = 'S' BEGIN
    PRINT '- Atualizando Estatisticas no Banco: ' + DB_NAME() + ' ****************************************************************'
	EXEC sp_updatestats
END
GO 
/********************************** FIM SP ***********************************/

-- Definir SP com de sistema
EXEC sys.sp_MS_marksystemobject sp_ManutencaoIndices
go 
