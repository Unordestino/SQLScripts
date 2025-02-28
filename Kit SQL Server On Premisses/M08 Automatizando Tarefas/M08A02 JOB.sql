/************************************************************
 Autor: Landry Duailibe

 Hands On: JOBs
*************************************************************/

/****************************************************
 1a Tarefa - Backup Bancos Sistema
****************************************************/
DECLARE @Path varchar(4000) = 'C:\_HandsOn_AdmSQL\Backup\'
DECLARE @Arquivo varchar(4000)

set @Arquivo = @Path + 'master_' + convert(char(8),getdate(),112)+ '_H' + replace(convert(char(8),getdate(),108),':','') + '.bak'
BACKUP DATABASE master TO DISK = @Arquivo WITH FORMAT, COMPRESSION

set @Arquivo = @Path + 'msdb_' + convert(char(8),getdate(),112)+ '_H' + replace(convert(char(8),getdate(),108),':','') + '.bak'
BACKUP DATABASE msdb TO DISK = @Arquivo WITH FORMAT, COMPRESSION

/********************************************
 2a Tarefa - Exclui Histórico dos Backups
*********************************************/
declare @DelDate datetime
set @DelDate = DATEADD(wk,-4,getdate())

EXECUTE master.dbo.xp_delete_file 0,N'C:\_HandsOn_AdmSQL\Backup',N'bak',@DelDate,0


/********************************************
 Indices para evitar Deadlock
*********************************************/
USE msdb
go
CREATE NONCLUSTERED INDEX NIX_BackupSet_Media_set_id
ON dbo.backupset (media_set_id)
--With (online=on)

CREATE NONCLUSTERED INDEX NNX_BackupSet_Backup_set_id_Media_set_id
ON dbo.backupset
(backup_set_id, media_set_id)
--With (online=on)

Create index IX_Backupset_Backup_set_uuid
on backupset(backup_set_uuid)
--With (online=on)

Create index IX_Bbackupset_Media_set_id
on backupset(media_set_id)
--With (online=on)

Create index IX_Backupset_Backup_finish_date_INC_Media_set_id
on backupset(backup_finish_date)
INCLUDE (media_set_id)
--With (online=on)

Create index IX_backupset_backup_start_date_INC_Media_set_id
on backupset(backup_start_date)
INCLUDE (media_set_id)
--With (online=on)

Create index IX_Backupmediaset_Media_set_id
on backupmediaset(media_set_id)
--With (online=on)

Create index IX_Backupfile_Backup_set_id
on Backupfile(backup_set_id)
--With (online=on)

Create index IX_Backupmediafamily_Media_set_id
on Backupmediafamily(media_set_id)
--With (online=on)
