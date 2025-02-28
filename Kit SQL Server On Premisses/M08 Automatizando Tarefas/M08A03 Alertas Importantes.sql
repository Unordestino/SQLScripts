/************************************************************
 Autor: Landry Duailibe

 Hands On: Alertas Importantes
*************************************************************/
use msdb
go

/****************************
 Operadores
*****************************/
EXEC msdb.dbo.sp_add_operator @name=N'DBA', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'proflandry.sqlexpert@gmail.com', 
		@category_name=N'[Uncategorized]'
GO

-- Cria Alerta para codigo de erro
EXEC msdb.dbo.sp_add_alert @name=N'Suspect Pages Error', @message_id=824,@delay_between_responses=1800 
EXEC msdb.dbo.sp_add_alert @name=N'Transction Log FULL', @message_id=9002,@delay_between_responses=1800 
EXEC msdb.dbo.sp_add_alert @name=N'Transction Log nao esta disponivel', @message_id=9001,@delay_between_responses=1800 
EXEC msdb.dbo.sp_add_alert @name=N'Memoria virtual baixa', @message_id=708,@delay_between_responses=1800 

-- Cria Alertas para Serverity 20 a 25 (erro fatal)
EXEC msdb.dbo.sp_add_alert @name=N'Erro Fatal Serverity 25', @severity=25,@delay_between_responses=1800 
EXEC msdb.dbo.sp_add_alert @name=N'Erro Fatal Serverity 24', @severity=24,@delay_between_responses=1800 
EXEC msdb.dbo.sp_add_alert @name=N'Erro Fatal Serverity 23', @severity=23,@delay_between_responses=1800 
EXEC msdb.dbo.sp_add_alert @name=N'Erro Fatal Serverity 22', @severity=22,@delay_between_responses=1800 
EXEC msdb.dbo.sp_add_alert @name=N'Erro Fatal Serverity 21', @severity=21,@delay_between_responses=1800 
EXEC msdb.dbo.sp_add_alert @name=N'Erro Fatal Serverity 20', @severity=20,@delay_between_responses=1800 
EXEC msdb.dbo.sp_add_alert @name=N'Erro Fatal Serverity 19', @severity=19,@delay_between_responses=1800 
go
--select * from sysmessages where severity = 19 and msglangid = 1033


/******************************
 Associa a operador DBA
*******************************/ 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Suspect Pages Error', @operator_name=N'DBA', @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Transction Log FULL', @operator_name=N'DBA', @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Transction Log nao esta disponivel', @operator_name=N'DBA', @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Memoria virtual baixa', @operator_name=N'DBA', @notification_method = 1

EXEC msdb.dbo.sp_add_notification @alert_name=N'Erro Fatal Serverity 25', @operator_name=N'DBA', @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Erro Fatal Serverity 24', @operator_name=N'DBA', @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Erro Fatal Serverity 23', @operator_name=N'DBA', @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Erro Fatal Serverity 22', @operator_name=N'DBA', @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Erro Fatal Serverity 21', @operator_name=N'DBA', @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Erro Fatal Serverity 20', @operator_name=N'DBA', @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Erro Fatal Serverity 19', @operator_name=N'DBA', @notification_method = 1
GO
