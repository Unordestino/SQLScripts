use msdb
go

	SELECT 
    destination_database_name ,rs.restore_date, *
FROM 
    dbo.restorehistory rs
    INNER JOIN dbo.backupset bs ON rs.backup_set_id = bs.backup_set_id
ORDER BY 
    rs.restore_date DESC;