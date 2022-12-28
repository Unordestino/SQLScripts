--Query para conferir o histórico de Backups que foram executados
SELECT	database_name, name,backup_start_date, datediff(mi, backup_start_date, backup_finish_date) [tempo (min)], 
		position, server_name, recovery_model, isnull(logical_device_name, ' ') logical_device_name, device_type,  
		type, cast(backup_size/1024/1024 as numeric(15,2)) [Tamanho (MB)] 
FROM msdb.dbo.backupset B 
	  INNER JOIN msdb.dbo.backupmediafamily BF ON B.media_set_id = BF.media_set_id 
where backup_start_date >=  dateadd(hh, -24 ,getdate()  ) 
--  and type in ('D','I') 
order by backup_start_date desc 
--	Guardem muito bem essa query que utilizaram uma infinidade de vezes como DBA para conferir Backups!!! 
--	D = FULL, I = Diferencial, L = Log