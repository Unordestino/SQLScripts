--Para ativar o Service Broker em um banco de dados, use o seguinte comando:

USE master ;
GO
ALTER DATABASE DatabaseName SET ENABLE_BROKER ;
GO
-- Caso der erro utilize 
ALTER DATABASE msdb  SET NEW_BROKER
-- Caso der erro utilize 
alter database msdb set enable_broker with rollback immediate;

--Se o Service Broker estiver habilitado, confirme se o Database Mail está habilitado ou não executando as consultas abaixo no SQL Server Management Studio:

sp_configure 'show advanced', 1
GO
RECONFIGURE
GO
sp_configure
GO


--Se o conjunto de resultados mostrar run_value como 1, o Database Mail está habilitado.
--Se a opção Database Mail estiver desabilitada, execute as consultas abaixo para habilitá-la:

sp_configure 'Database Mail XPs', 1; 
GO
RECONFIGURE;
GO
sp_configure 'show advanced', 1; 
GO
RECONFIGURE;
GO

--Caso dê erro na atividade acima, é necessário usar a opção.
EXEC sp_configure 'database mail XPs', 1;
GO
RECONFIGURE WITH OVERRIDE;
GO


--Assim que o Database Mail estiver habilitado, para iniciar o Programa Externo do Database Mail, use a consulta mencionada abaixo no banco de dados msdb:

USE msdb ;       
EXEC msdb.dbo.sysmail_start_sp;

--Para confirmar se o Programa Externo do Database Mail foi iniciado, execute a consulta mencionada abaixo:

EXEC msdb.dbo.sysmail_help_status_sp;

--Se o programa externo do Database Mail for iniciado, verifique o status da fila de mensagens usando a instrução abaixo:

EXEC msdb.dbo.sysmail_help_queue_sp @queue_type = 'mail';