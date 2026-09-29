use DBA
go

-- Dias de retenção (ajuste conforme necessidade)
DECLARE @DiasRetencao INT = 30
DECLARE @DataLimite DATETIME = DATEADD(DAY, -@DiasRetencao, GETDATE())

DELETE DBA.dbo.DBA_Monitora_LatenciaIO WHERE LogDate < @DataLimite
DELETE DBA.dbo.DBA_Monitora_Hist_CheckDB WHERE DataHora < @DataLimite
DELETE DBA.dbo.DBA_Monitora_Hist_Blocking WHERE DataHora_Coleta < @DataLimite
DELETE DBA.dbo.DBA_Monitora_TempDB WHERE Data  < @DataLimite

/************************************
 Limpeza histórico envio de emails
*************************************/
USE msdb
go

-- Dias de retenção (ajuste conforme necessidade)
DECLARE @DiasRetencao INT = 30
DECLARE @DataLimite DATETIME = DATEADD(DAY, -@DiasRetencao, GETDATE())

-- Apagar mensagens enviadas
DELETE FROM sysmail_sentitems WHERE sent_date < @DataLimite

-- Apagar mensagens com falha
DELETE FROM sysmail_faileditems WHERE sent_date < @DataLimite

-- Apagar mensagens não enviadas
DELETE FROM sysmail_unsentitems WHERE sent_date < @DataLimite

-- Apagar eventos antigos do log
DELETE FROM sysmail_event_log WHERE log_date < @DataLimite

-- Apagar do histórico geral
DELETE FROM sysmail_allitems WHERE sent_date < @DataLimite
go

/************************************
 Limpeza histórico Backup e Restore
*************************************/
USE msdb
go

-- Número de dias a manter (altere conforme sua política)
DECLARE @DiasRetencao INT = 30
DECLARE @DataLimite DATETIME = DATEADD(DAY, -@DiasRetencao, GETDATE())

-- Limpar histórico de backup
EXEC sp_delete_backuphistory @oldest_date = @DataLimite;

-- Limpar histórico de restore (restorehistory + restorefile + restorefilegroup)
DELETE FROM restorefile WHERE restore_history_id IN (
    SELECT restore_history_id FROM restorehistory WHERE restore_date < @DataLimite
)

DELETE FROM restorefilegroup WHERE restore_history_id IN (
    SELECT restore_history_id FROM restorehistory WHERE restore_date < @DataLimite
)

DELETE FROM restorehistory WHERE restore_date < @DataLimite;
go


/********************************************
 Indices para evitar Deadlock na limpeza
 de tabelas histórico Backup e Restore
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
