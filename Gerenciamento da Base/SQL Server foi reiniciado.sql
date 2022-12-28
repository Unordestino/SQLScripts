--	Última vez que o SQL Server foi reiniciado

select * from sys.databases where database_id = 2

SELECT sqlserver_start_time FROM sys.dm_os_sys_info