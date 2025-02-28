/*********************************************************
 Monitora Atividade de conexões nos bancos de dados
**********************************************************/
use MSDB
go

CREATE TABLE msdb.dbo.DBA_AtividadeBancos(
Banco sysname NULL,QtdConexoes int NULL)
go

-- Criar JOB: _DBA - Atividade dos Bancos de Dados
;with tmp as ( select DB_NAME(dbid) Banco, COUNT(*) QtdConexoes 
from sys.sysprocesses where spid > 50
group by DB_NAME(dbid))

update a set a.QtdConexoes = a.QtdConexoes + t.QtdConexoes
from msdb.dbo.DBA_AtividadeBancos a join tmp t on a.Banco = t.Banco



SELECT Banco,QtdConexoes
FROM msdb.dbo.dba_AtividadeBancos
order by 2,1


/*********************************************************
 Monitora Atividade de conexões nos bancos de dados
**********************************************************/
use MSDB
go

CREATE TABLE msdb.dbo.DBA_ConexoesServidor (
DataHoraColeta datetime not null,
Banco sysname NULL,
Computador varchar(200) null,
Aplicacao varchar(500) null,
QtdConexoes int NULL)
go

-- Criar JOB
DECLARE @DataHoraColeta datetime
SELECT @DataHoraColeta = GETDATE()

--INSERT msdb.dbo.DBA_ConexoesServidor
SELECT @DataHoraColeta as DataHoraColeta,DB_NAME(dbid) Banco, hostname as Computador, program_name as Aplicacao,COUNT(*) QtdConexoes 
FROM sys.sysprocesses 
WHERE spid > 50 and dbid > 4 and DB_NAME(dbid) not like 'ReportServer%' 
and DB_NAME(dbid) <> 'ObjectAudit'
GROUP BY DB_NAME(dbid),hostname,program_name,Log

-- SELECT * FROM msdb.dbo.DBA_ConexoesServidor 

/*********************************************************
 Monitora Atividade de conexões de logins
 - DBA - Monitora Login QUANTUM
**********************************************************/
use MSDB
go

CREATE TABLE msdb.dbo.DBA_ConexoesServidor (
DataHoraColeta datetime not null,
Banco sysname NULL,
Computador varchar(200) null,
Aplicacao varchar(500) null,
LoginNome varchar(500) null,
QtdConexoes int NULL)
go

-- Criar JOB
DECLARE @DataHoraColeta datetime
SELECT @DataHoraColeta = GETDATE()

INSERT msdb.dbo.DBA_ConexoesServidor
SELECT @DataHoraColeta as DataHoraColeta,DB_NAME(dbid) Banco, hostname as Computador, 
program_name as Aplicacao,loginame as LoginNome, COUNT(*) QtdConexoes 
FROM sys.sysprocesses 
WHERE spid > 50 and dbid > 4 and DB_NAME(dbid) not like 'ReportServer%' 
and DB_NAME(dbid) <> 'ObjectAudit'
and loginame in ('quantum')
GROUP BY DB_NAME(dbid),hostname,program_name,loginame

SELECT * FROM sys.sysprocesses 
