--	1)	Envio de um e-mail simples via o DatabaseMail

EXEC msdb.dbo.sp_send_dbmail 
	@profile_name = 'MSSQLServer', 
	@recipients = 'davi.souza@davisilveira.com.br', 
	@body = 'Se voc� receber esse e-mail, o recurso Database Mail est� funcionando', 
	@subject = 'Verifica��o do Recurso Database Mail'
