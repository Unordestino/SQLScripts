/************************************************************
 Autor: Landry Duailibe

 Hands On: Cria alerta Evento Deadlock no SQL Server Agent
*************************************************************/
use msdb
go

/***********************************
 Cria Alerta Evento 1205 - Deadlock
************************************/
EXEC msdb.dbo.sp_add_alert @name=N'Ocorrencia de Deadlock', @message_id=1205--, @delay_between_responses=1800
EXEC msdb.dbo.sp_add_notification @alert_name=N'Ocorrencia de Deadlock', @operator_name=N'DBA', @notification_method = 1

-- 1205 está com is_event_logged ZERO, não vai conseguir desparar o alerta!
SELECT * FROM sys.messages WHERE message_id = 1205

-- Altera is_event_logged para 1
EXEC sp_altermessage 1205, 'WITH_LOG', 'true' 




-- Exclui Alerta
EXEC msdb.dbo.sp_delete_alert @name=N'Ocorrencia de Deadlock'
EXEC sp_altermessage 1205, 'WITH_LOG', 'false'