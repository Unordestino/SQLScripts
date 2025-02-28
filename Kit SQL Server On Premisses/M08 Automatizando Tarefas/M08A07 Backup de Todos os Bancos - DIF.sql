/****************************************************
 Autor: Landry Duailibe
 
 Backup de todos os bancos - DIF
*****************************************************/ 
use master
go

/*******************************
 Criar JOB
 Step 1) Backup todos os Bancos
********************************/
DECLARE @Caminho varchar(4000), @Banco varchar(500), @Compacta char(1),@Arquivo varchar(4000)
DECLARE @state_desc varchar(200)
SET @Caminho = 'C:\_HandsOn_AdmSQL\Backup\DIF\' 
SET @Compacta = 'S'

IF object_id('dbo.tmpBancosBackupDIF') is not null
   DROP TABLE dbo.tmpBancosBackupDIF

SELECT name,state_desc 
INTO dbo.tmpBancosBackupDIF 
FROM sys.databases 
WHERE source_database_id is null
and state_desc = 'ONLINE' 
and name not in ('tempdb','master','model','msdb') 
and name not in (SELECT Nomebanco FROM DBA.dbo.DBA_BackupExcluir)
ORDER BY name

DECLARE vCursor CURSOR FOR
SELECT name,state_desc FROM dbo.tmpBancosBackupDIF ORDER BY NAME

OPEN vCursor
FETCH NEXT FROM vCursor INTO @Banco,@state_desc

WHILE @@FETCH_STATUS = 0 BEGIN

   IF db_id(@Banco) is null BEGIN
      print '*** ERRO: DB_ID retornou NULL para o banco ' + @Banco 
      FETCH NEXT FROM vCursor INTO @Banco,@state_desc
      CONTINUE
   END

   IF @state_desc <> 'ONLINE' begin
     PRINT '*** Banco: ' +  @Banco + ' está: ' + @state_desc
     FETCH NEXT FROM vCursor INTO @Banco,@state_desc 
     CONTINUE
   END

   
   PRINT 'Backup do Banco de Dados: ' + @Banco 
   SET @Arquivo = @Banco + '_' + convert(char(8),getdate(),112)+ '_H' + replace(convert(char(8),getdate(),108),':','') + '.dif'

   IF @Compacta = 'S'
      EXEC('BACKUP DATABASE [' + @Banco + ']  TO DISK = ''' + @Caminho + @Arquivo + ''' WITH FORMAT, COMPRESSION, DIFFERENTIAL')
   ELSE
      EXEC('BACKUP DATABASE [' + @Banco + ']  TO DISK = ''' + @Caminho + @Arquivo + ''' WITH FORMAT, DIFFERENTIAL')

   IF @@ERROR <> 0 BEGIN
      PRINT '*** ERRO: backup do banco ' + @Banco + ' - Código de erro: ' + ltrim(str(@@error))
      FETCH NEXT FROM vCursor INTO @Banco,@state_desc
      CONTINUE
   END   
  
   FETCH NEXT FROM vCursor INTO @Banco,@state_desc
END

CLOSE vCursor
DEALLOCATE vCursor

IF object_id('dbo.tmpBancosBackupDIF') is not null
   DROP TABLE dbo.tmpBancosBackupDIF
go

/********************************************
 Step 2) Exclui Histórico dos Backups
*********************************************/
DECLARE @DelDate datetime
SET @DelDate = DATEADD(wk,-4,getdate())

EXECUTE master.dbo.xp_delete_file 0,N'C:\_HandsOn_AdmSQL\Backup\DIF',N'dif',@DelDate,0
go

