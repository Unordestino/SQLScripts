Vamos iniciar a mudança de diretório por estes bancos. Para isso, utilizar a seguinte query para saber qual o diretório original dos mesmos.


select name, physical_name from sys.master_files where database_id = db_id('model')
 
GO
 
select name, physical_name from sys.master_files where database_id = db_id('msdb')
 
GO

---------------------------------------------------------------------------------------------------------------------------------------

Para movê-los, precisaremos trocar o apontamento para o diretório desejado.  podemos utilizar o seguinte script:


-------------MSDB--------------------------------
alter database msdb modify file 
    (name = MSDBData, filename = 'E:\SQLSERVER2016\System\MSDBData.mdf')
go
 
alter database msdb modify file 
    (name = MSDBLog, filename = 'E:\SQLSERVER2016\System\MSDBLog.ldf')
go

-------------------------------------------------------------------------------------------------------------------------------------

Após, devemos parar o serviço do SQL Server para conseguir trocar o arquivo físico de diretório. Feito isso, podemos copiar manualmente (ctrl + c do diretório antigo e ctrl + v para o novo) e reiniciar o serviço.