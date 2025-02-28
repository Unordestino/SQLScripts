use DBA
go

/************************************
 Cria tabela de auditoria
*************************************/
DROP TABLE IF exists dbo.DBA_Audit_Login
go
CREATE TABLE dbo.DBA_Audit_Login (
DBA_Audit_Login_ID int not null identity constraint pk_DBA_Audit_Login primary key,
SPID smallint NOT NULL,
DataHora_Login datetime NOT NULL,
[Login] nvarchar(128) NULL,
Banco nvarchar(128) NULL,
Host nvarchar(128) NULL,
App nvarchar(128) NULL,
Interface nvarchar(32) NULL)
go

SELECT * FROM DBA.dbo.DBA_Audit_Login

/***************************************
 Criar JOB executando a cada 5 minutos
 - _DBA - Monitora Login SA
****************************************/
INSERT DBA.dbo.DBA_Audit_Login
(SPID, DataHora_Login, [Login], Banco, Host, App, Interface)

SELECT session_id as SPID,login_time as DataHora_Login,login_name as [Login],
db_name(database_id) as Banco,
host_name as Host,program_name as App, client_interface_name as Interface
FROM sys.dm_exec_sessions 
WHERE 1=1
and login_name = 'sa'
and session_id > 50
and is_user_process = 1


