use DBA
go
CREATE TABLE dbo.DBA_BackupExcluir (
Nomebanco sysname not null primary key)
go
INSERT dbo.DBA_BackupExcluir VALUES ('GovernancaHomol')
INSERT dbo.DBA_BackupExcluir VALUES ('Protheus11Teste')
INSERT dbo.DBA_BackupExcluir VALUES ('TAF_TSS_TESTE')
go
SELECT Nomebanco FROM dbo.DBA_BackupExcluir

/***************************************************
 Backup Master e MSDB
****************************************************/
DECLARE @Arquivo varchar(4000),@Caminho varchar(4000)
set @Caminho = 'D:\Backup\FULL\'

set @Arquivo = @Caminho + 'master_' + convert(char(8),getdate(),112)+ '_H' + replace(convert(char(8),getdate(),108),':','') + '.bak'
BACKUP DATABASE master TO DISK = @Arquivo WITH FORMAT, COMPRESSION

set @Arquivo = @Caminho + 'msdb_' + convert(char(8),getdate(),112)+ '_H' + replace(convert(char(8),getdate(),108),':','') + '.bak'
BACKUP DATABASE msdb TO DISK = @Arquivo WITH FORMAT, COMPRESSION
go

/****************************************************
 Backup de todos os bancos para uma pasta
 Autor: Landry D Salles Filho
 Data: 15/06/2006
*****************************************************/ 
declare @Caminho varchar(4000), @Banco varchar(500), @Compacta char(1),@Arquivo varchar(4000)
declare @state_desc varchar(200)
set @Caminho = 'D:\Backup\FULL\' 
set @Compacta = 'S'

if object_id('dbo.tmpBancosBackupFULL') is not null
   drop table dbo.tmpBancosBackupFULL

select name,state_desc 
into dbo.tmpBancosBackupFULL 
from sys.databases 
where source_database_id is null
and state_desc = 'ONLINE' 
and name not in ('tempdb','model','master','msdb') 
and name not in (SELECT Nomebanco FROM DBA.dbo.DBA_BackupExcluir)
--and name not in (select secondary_database from msdb.dbo.log_shipping_secondary_databases)
ORDER BY name

declare vCursor cursor for
select name,state_desc from dbo.tmpBancosBackupFULL order by name

open vCursor
fetch next from vCursor into @Banco, @state_desc
WHILE @@FETCH_STATUS = 0
begin
   waitfor delay '00:00:05' 

   if db_id(@Banco) is null begin
      print '*** ERRO: DB_ID retornou NULL para o banco ' + @Banco 
      fetch next from vCursor into @Banco, @state_desc
      continue
   end
   
   if @state_desc <> 'ONLINE' begin
     print '*** Banco: ' +  @Banco + ' est�: ' + @state_desc
     FETCH NEXT FROM vCursor INTO @Banco,@state_desc 
     continue
  end

   Print 'Backup do Banco de Dados: ' + @Banco 
   set @Arquivo = @Banco + '_' + convert(char(8),getdate(),112)+ '_H' + replace(convert(char(8),getdate(),108),':','')

   if @Compacta = 'S'
      exec('BACKUP DATABASE [' + @Banco + ']  TO DISK = ''' + @Caminho + @Arquivo + '.bak'' WITH FORMAT, COMPRESSION')
   else
      exec('BACKUP DATABASE [' + @Banco + ']  TO DISK = ''' + @Caminho + @Arquivo + '.bak'' WITH FORMAT')
   waitfor delay '00:00:01'

   if @@ERROR <> 0 begin
      print '*** ERRO: backup do banco ' + @Banco + ' - C�digo de erro: ' + ltrim(str(@@error))
      fetch next from vCursor into @Banco, @state_desc
      continue
   end   
   fetch next from vCursor into @Banco, @state_desc
end
CLOSE vCursor
DEALLOCATE vCursor

if object_id('dbo.tmpBancosBackupFULL') is not null
   drop table dbo.tmpBancosBackupFULL
go


/********************************************
 Exclui Hist�rico dos Backups
*********************************************/
declare @DelDate datetime
set @DelDate = DATEADD(wk,-1,getdate())

EXECUTE master.dbo.xp_delete_file 0,N'D:\Backup\FULL',N'bak',@DelDate,0
go

/********************************************
 Indices para evitar Deadlock
*********************************************/
USE msdb
GO
CREATE NONCLUSTERED INDEX NIX_BackupSet_Media_set_id
ON dbo.backupset (media_set_id)
--With (online=on)
GO

CREATE NONCLUSTERED INDEX NNX_BackupSet_Backup_set_id_Media_set_id
ON dbo.backupset
(backup_set_id, media_set_id)
--With (online=on)
GO

Create index IX_Backupset_Backup_set_uuid
on backupset(backup_set_uuid)
--With (online=on)
GO

Create index IX_Bbackupset_Media_set_id
on backupset(media_set_id)
--With (online=on)
GO

Create index IX_Backupset_Backup_finish_date_INC_Media_set_id
on backupset(backup_finish_date)
INCLUDE (media_set_id)
--With (online=on)
GO

Create index IX_backupset_backup_start_date_INC_Media_set_id
on backupset(backup_start_date)
INCLUDE (media_set_id)
--With (online=on)
GO

Create index IX_Backupmediaset_Media_set_id
on backupmediaset(media_set_id)
--With (online=on)
GO

Create index IX_Backupfile_Backup_set_id
on Backupfile(backup_set_id)
--With (online=on)
GO

Create index IX_Backupmediafamily_Media_set_id
on Backupmediafamily(media_set_id)
--With (online=on)
GO