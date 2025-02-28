USE msdb
go

/**************************************
 Envio de E-mail por Script
***************************************/
EXEC msdb.dbo.sp_send_dbmail
@recipients = 'proflandry.sqlexpert@gmail.com',
@subject = 'Envio de E-Mail pelo SQL Server',
@body = 'Teste de envio',
@body_format = 'HTML' ,
@profile_name = 'Profile_SMTP'


/**************************************
 Limpa histórico
***************************************/

DECLARE @Data datetime
SET @Data = dateadd(MM,-3,getdate())

EXEC sysmail_delete_mailitems_sp @sent_before = @Data
EXEC sysmail_delete_log_sp @logged_before = @Data

