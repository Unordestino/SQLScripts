--	Conferindo os Backups realizados da database específica

SELECT database_name, name, backup_start_date, datediff(mi,backup_start_date,backup_finish_date) [tempo (min)], 
	  position, server_name, recovery_model, last_lsn, 
	  isnull(logical_device_name,' ') logical_device_name,device_type,type, cast(backup_size/1024/1024 as numeric(15,2)) [Tamanho (MB)],first_lsn 
FROM msdb.dbo.backupset B 
	  INNER JOIN msdb.dbo.backupmediafamily BF ON B.media_set_id = BF.media_set_id 
where backup_start_date >=  dateadd(hh, -24 ,getdate()  ) 
	and database_name = 'TreinamentoDBA' 
order by backup_start_date desc
