/*******************************************************************
 Autor: Landry Duailibe

 Hands On: Monitorando Deadlock com Extende Event
********************************************************************/

/*******************************************
 Extended Event
********************************************/
CREATE EVENT SESSION MonitoraDeadlock ON SERVER 
ADD EVENT sqlserver.xml_deadlock_report(
ACTION(package0.collect_system_time,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.session_id,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.username))

ADD TARGET package0.event_file(SET filename=N'C:\_HandsOn_AdmSQL\_DBA_Monitora\DeadLock.xel')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
go

ALTER EVENT SESSION MonitoraDeadlock ON SERVER	STATE=START
go

/*******************************************************
 Salvar XML com a extensão .XDL e abrir no SSMS
********************************************************/
DECLARE @Arquivo sysname
 
SELECT @Arquivo = REPLACE( CAST(f.[value] AS sysname), '.xel', '*xel' )
FROM sys.server_event_sessions as s
JOIN sys.server_event_session_targets as t ON s.event_session_id = t.event_session_id
JOIN sys.server_event_session_fields as f ON f.event_session_id = t.event_session_id
AND f.object_id = t.target_id	
WHERE f.[name] = 'filename' and s.name= N'MonitoraDeadlock'
 
SELECT Deadlock.*
FROM sys.fn_xe_file_target_read_file ( @Arquivo, null, null, null) as arq
CROSS APPLY ( SELECT CAST(arq.[event_data] as xml) ) as f ([xml])
CROSS APPLY (SELECT 
f.[xml].value('(event/@name)[1]', 'varchar(100)') as Evento,
f.[xml].value('(event/@timestamp)[1]', 'datetime') as Data_Evento,
f.[xml].query('//event/data/value/deadlock') as Deadlock) as Deadlock
--WHERE Deadlock.Evento = 'xml_deadlock_report'
ORDER BY Data_Evento DESC



-- Remove Evento 
ALTER EVENT SESSION MonitoraDeadlock ON SERVER STATE = STOP
DROP EVENT SESSION MonitoraDeadlock ON SERVER

