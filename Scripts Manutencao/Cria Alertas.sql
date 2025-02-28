/*********************************
 Cria Alertas
**********************************/
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
		@email_address=N'dsai.erro@gmail.com;informatica@bondinho.com.br', 
		@category_name=N'[Uncategorized]'
GO

EXEC msdb.dbo.sp_add_operator @name=N'DBA_Alerta', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'dsai.alertas@gmail.com;informatica@bondinho.com.br', 
		@category_name=N'[Uncategorized]'
GO
 
EXEC msdb.dbo.sp_add_operator @name=N'DBA_Block', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'dsai.block@gmail.com;informatica@bondinho.com.br', 
		@category_name=N'[Uncategorized]'
GO
-- Cria Alerta para codigo de erro
EXEC msdb.dbo.sp_add_alert @name=N'Suspect Pages Error', @message_id=824,@delay_between_responses=1800 
EXEC msdb.dbo.sp_add_alert @name=N'Transction Log FULL', @message_id=9002,@delay_between_responses=1800 
EXEC msdb.dbo.sp_add_alert @name=N'Transction Log nao esta disponivel', @message_id=9001,@delay_between_responses=1800 
--EXEC msdb.dbo.sp_add_alert @name=N'Acabou o espaco no Version Store', @message_id=3967,@delay_between_responses=1800 
--EXEC msdb.dbo.sp_add_alert @name=N'Ocorrencia de Deadlock', @message_id=1205,@delay_between_responses=1800 
--EXEC msdb.dbo.sp_add_alert @name=N'Memoria virtual baixa', @message_id=708,@delay_between_responses=1800 

-- Cria Alertas para Serverity 20 a 25 (erro fatal)
EXEC msdb.dbo.sp_add_alert @name=N'Erro Fatal Serverity 25', @severity=25,@delay_between_responses=1800 
EXEC msdb.dbo.sp_add_alert @name=N'Erro Fatal Serverity 24', @severity=24,@delay_between_responses=1800 
EXEC msdb.dbo.sp_add_alert @name=N'Erro Fatal Serverity 23', @severity=23,@delay_between_responses=1800 
EXEC msdb.dbo.sp_add_alert @name=N'Erro Fatal Serverity 22', @severity=22,@delay_between_responses=1800 
EXEC msdb.dbo.sp_add_alert @name=N'Erro Fatal Serverity 21', @severity=21,@delay_between_responses=1800 
EXEC msdb.dbo.sp_add_alert @name=N'Erro Fatal Serverity 20', @severity=20,@delay_between_responses=1800 
--EXEC msdb.dbo.sp_add_alert @name=N'Erro Fatal Serverity 19', @severity=19,@delay_between_responses=1800 
go
--select * from sysmessages where severity = 19 and msglangid = 1033


/******************************
 Criar operador DBA
*******************************/ 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Suspect Pages Error', @operator_name=N'DBA', @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Transction Log FULL', @operator_name=N'DBA', @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Transction Log nao esta disponivel', @operator_name=N'DBA', @notification_method = 1

EXEC msdb.dbo.sp_add_notification @alert_name=N'Erro Fatal Serverity 25', @operator_name=N'DBA', @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Erro Fatal Serverity 24', @operator_name=N'DBA', @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Erro Fatal Serverity 23', @operator_name=N'DBA', @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Erro Fatal Serverity 22', @operator_name=N'DBA', @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Erro Fatal Serverity 21', @operator_name=N'DBA', @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Erro Fatal Serverity 20', @operator_name=N'DBA', @notification_method = 1
GO

/************************************************
 Alertas para Mirror
*************************************************/
EXEC msdb.dbo.sp_add_alert @name=N'Mirror - Reparo de Pagina Corrompida (Sucesso)', @message_id=1461,@delay_between_responses=1800
EXEC msdb.dbo.sp_add_notification @alert_name=N'Mirror - Reparo de Pagina Corrompida (Sucesso)', @operator_name=N'DBA', @notification_method = 1

EXEC msdb.dbo.sp_add_alert @name=N'Mirror - Reparo de Pagina Corrompida (Falha)', @message_id=1481,@delay_between_responses=1800
EXEC msdb.dbo.sp_add_notification @alert_name=N'Mirror - Reparo de Pagina Corrompida (Falha)', @operator_name=N'DBA', @notification_method = 1

EXEC msdb.dbo.sp_add_alert @name=N'Mirror - Replica Inacessível', @message_id=35201,@delay_between_responses=1800
EXEC msdb.dbo.sp_add_notification @alert_name=N'Mirror - Replica Inacessível', @operator_name=N'DBA', @notification_method = 1

-- Codigos de erro uteis
SELECT 674, 'Exception occurred in destructor of RowsetNewSS 0x%p...' 
UNION ALL 
SELECT 708, 'Server is running low on virtual address space or machine is running low on virtual...' 
UNION ALL 
SELECT 806, 'audit failure (a page read from disk failed to pass basic integrity checks)...' 
UNION ALL 
SELECT 825, 'A read of the file %ls at offset %#016I64x succeeded after failing %d time(s) wi..' 
UNION ALL 
SELECT 973, 'Database %ls was started . However, FILESTREAM is not compatible with the READ_COM...' 
UNION ALL 
SELECT 3401, 'Errors occurred during recovery while rolling back a transaction...' 
UNION ALL 
SELECT 3410, 'Data in filegroup %s is offline, and deferred transactions exist...' 
UNION ALL 
SELECT 3414, 'An error occurred during recovery, preventing the database %.*ls (database ID %d)...' 
UNION ALL 
SELECT 3422, 'Database %ls was shutdown due to error %d in routine %hs.' 
UNION ALL 
SELECT 3452, 'Recovery of database %.*ls (%d) detected possible identity value inconsistency...' 
UNION ALL 
SELECT 3619, 'Could not write a checkpoint record in database ID %d because the log is out of space...' 
UNION ALL 
SELECT 3620, 'Automatic checkpointing is disabled in database %.*ls because the log is out of spac...' 
UNION ALL 
SELECT 3959, 'Version store is full. New version(s) could not be added.' 
UNION ALL 
SELECT 5029, 'Warning: The log for database %.*ls has been rebuilt.' 
UNION ALL 
SELECT 5144, 'Autogrow of file %.*ls in database %.*ls was cancelled by user or timed out...' 
UNION ALL 
SELECT 5145, 'Autogrow of file %.*ls in database %.*ls took %d milliseconds.' 
UNION ALL 
SELECT 5182, 'New log file %.*ls was created.' 
UNION ALL 
SELECT 8539, 'The distributed transaction with UOW %ls was forced to commit...' 
UNION ALL 
SELECT 8540, 'The distributed transaction with UOW %ls was forced to rollback. ' 
UNION ALL 
SELECT 9001, 'The log for database %.*ls is not available.' 
UNION ALL 
SELECT 14157, 'The subscription created by Subscriber %s to publication %s has expired...' 
UNION ALL 
SELECT 14161, 'The threshold [%s:%s] for the publication [%s] has been set.' 
UNION ALL 
SELECT 17173, 'Ignoring trace flag %d specified during startup' 
UNION ALL 
SELECT 17179, 'Could not use Address Windowing Extensions because the lock pages in mem...' 
UNION ALL 
SELECT 17883, 'Process %ld:%ld:%ld (0x%lx) Worker 0x%p appears to be non-yielding on Scheduler...' 
UNION ALL 
SELECT 17884, 'New queries assigned to process on Node %d have not been picked up by a worker...' 
UNION ALL 
SELECT 17887, 'IO Completion Listener (0x%lx) Worker 0x%p appears to be non-yielding...' 
UNION ALL 
SELECT 17888, 'All schedulers on Node %d appear deadlocked due to a large number of...' 
UNION ALL 
SELECT 17890, 'A significant part of sql server process memory has been paged out...' 
UNION ALL 
SELECT 17891, 'Resource Monitor (0x%lx) Worker 0x%p appears to be non-yielding on Node %ld...' 
UNION ALL 
SELECT 20572, 'Subscriber %s subscription to article %s in publication %s has been reinitiali...' 
UNION ALL 
SELECT 20574, 'Subscriber %s subscription to article %s in publication %s failed...'