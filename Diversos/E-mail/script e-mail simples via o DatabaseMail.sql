--	1)	Envio de um e-mail simples via o DatabaseMail

EXEC msdb.dbo.sp_send_dbmail 
	@profile_name = 'MSSQLServer', 
	@recipients = 'davi.souza@davisilveira.com.br', 
	@body = 'Se você receber esse e-mail, o recurso Database Mail está funcionando', 
	@subject = 'Verificação do Recurso Database Mail'
