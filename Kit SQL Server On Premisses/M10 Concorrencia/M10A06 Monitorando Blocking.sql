/**************************************************************************************
 Autor: Landry Duailibe

 Hands On: Monitora Blocking
**************************************************************************************/
use master
go
/***********************************************************************
 Função formata ID JOB para identificar JOB envolvido no Blocking
************************************************************************/
go
CREATE or ALTER FUNCTION dbo.udf_sysjobs_getprocessid(@job_id uniqueidentifier)
RETURNS varchar(8)
as
BEGIN
return (substring(left(@job_id,8),7,2) +
substring(left(@job_id,8),5,2) +
substring(left(@job_id,8),3,2) +
substring(left(@job_id,8),1,2))
END
go
/*************************** FIM Função *******************************/

/**********************************************************
 sys.dm_exec_sessions
 - Uma linha por conexão, incluindo conexões de sistema.

 https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-sessions-transact-sql?view=sql-server-ver16
***********************************************************/
SELECT * FROM sys.dm_exec_sessions
WHERE [session_id] > 50
ORDER BY [session_id]

/********************************************************************
 sys.dm_exec_connections
 - Uma linha por conexão de usuário, excluindo conexão de sistema.

 https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-connections-transact-sql?view=sql-server-ver16
*********************************************************************/
SELECT * FROM sys.dm_exec_connections
ORDER BY [session_id]

/**********************************************
 sys.dm_exec_requests
 - Uma linha por consulta em execução.

 https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-requests-transact-sql?view=sql-server-ver16
***********************************************/
SELECT * FROM sys.dm_exec_requests
WHERE [session_id] > 50


-- Conexões por aplicação
SELECT s.session_id, s.login_name, s.program_name, s.client_interface_name
FROM sys.dm_exec_sessions s
JOIN sys.dm_exec_connections c ON c.session_id = s.session_id

SELECT s.program_name as Aplicacao, count(*) as QtdConexoes
FROM sys.dm_exec_sessions s
JOIN sys.dm_exec_connections c ON c.session_id = s.session_id
GROUP BY s.program_name

-- Consiguração de sessão
SELECT s.session_id,s.login_name, db_name(s.database_id) as Banco,
s.date_format, s.quoted_identifier, s.ansi_nulls
FROM sys.dm_exec_sessions s
JOIN sys.dm_exec_connections c ON c.session_id = s.session_id
ORDER BY s.session_id

-- Em execução
SELECT *
FROM sys.dm_exec_sessions AS s
JOIN sys.dm_exec_connections AS c ON s.session_id = c.session_id
JOIN sys.dm_exec_requests AS r ON s.session_id = r.session_id
ORDER BY s.session_id

/**********************************************
 sys.sysprocesses
 - Uma linha por consulta em execução.
 - Visão de compatibilidade a versões anteriores

 https://learn.microsoft.com/pt-br/sql/relational-databases/system-compatibility-views/sys-sysprocesses-transact-sql?view=sql-server-ver16
***********************************************/
SELECT * FROM sys.sysprocesses

/******************************************
 Provoca Blocking
*******************************************/
DROP TABLE IF exists Aula.dbo.Funcionario
go
CREATE TABLE Aula.dbo.Funcionario (PK int, Nome varchar(50), Descricao varchar(100), Status char(1),Salario decimal(10,2))
INSERT Aula.dbo.Funcionario VALUES (9,'Erick','Operacional','C',2600.00)
INSERT Aula.dbo.Funcionario VALUES (10,'Joana','Operacional','C',2600.00)
go

BEGIN TRAN
  UPDATE Aula.dbo.Funcionario SET Salario = 3000.00 WHERE PK = 10
  SELECT * FROM Aula.dbo.Funcionario WHERE PK = 10 -- Salario = 2600.00

ROLLBACK

/*******************************************************
 Retorna Blocking identificando o(s) processo(s) raiz
********************************************************/
-- Processo(s) Raiz
SELECT getdate() as DataHora, spid as SPID, 'RAIZ' as Status, waittime/1000 as TempoEspera_Seg, blocked as SPID_Blocking,
db_name(sp.dbid) Banco,cast(rtrim(isnull(hostname,'N/A')) as varchar(50)) Computador,
case when sp.nt_domain is null or sp.nt_domain = '' then 'N/A' else rtrim(sp.nt_domain) + '/' + nt_username end as UsuarioWindows, 
cast(rtrim(loginame) as varchar(50)) as LoginSQL, 
case 
when s.program_name like 'SQLAgent - TSQL JobStep (Job%' 
then (select 'JOB: ' + MAX(name) + ' (' + replace( substring(s.program_name,CHARINDEX(': Step',s.program_name)+2,100) ,')','') + ')' 
FROM msdb.dbo.sysjobs WHERE dbo.udf_sysjobs_getprocessid(job_id) = substring(s.program_name,32,8) )
else s.program_name
end as Aplicacao, 
s.client_interface_name as AppInterface,
open_tran as QtdTransacoes, cmd as TipoComando, last_batch as UltimoTSQL,qt.text as InstrucaoTSQL

FROM sys.sysprocesses sp 
LEFT JOIN sys.dm_exec_sessions s ON s.session_id = sp.spid
OUTER APPLY sys.dm_exec_sql_text(sp.sql_handle) AS qt
WHERE spid in (SELECT distinct blocked FROM sys.sysprocesses where blocked > 0) AND blocked = 0

UNION 

-- Processo(s) que estão em Blocking
SELECT getdate(), spid as SPID, 'BLOCK' as Status, waittime/1000 as TempoEspera_Seg, blocked as SPID_Blocking,
db_name(sp.dbid) Banco,cast(rtrim(isnull(hostname,'N/A')) as varchar(50)) Computador,
case when sp.nt_domain is null or sp.nt_domain = '' then 'N/A' else rtrim(sp.nt_domain) + '/' + nt_username end as UsuarioWindows, 
cast(rtrim(loginame) as varchar(50)) as LoginSQL, 
case 
when s.program_name like 'SQLAgent - TSQL JobStep (Job%' 
then (select 'JOB: ' + MAX(name) + ' (' + replace( substring(s.program_name,CHARINDEX(': Step',s.program_name)+2,100) ,')','') + ')' FROM msdb.dbo.sysjobs WHERE dbo.udf_sysjobs_getprocessid(job_id) = substring(s.program_name,32,8) )
else s.program_name
end as Aplicacao, 
s.client_interface_name as AppInterface,
open_tran as QtdTransacoes, cmd as TipoComando, last_batch as UltimoTSQL,qt.text as InstrucaoTSQL

FROM sys.sysprocesses sp 
LEFT JOIN sys.dm_exec_sessions s ON s.session_id = sp.spid
OUTER APPLY sys.dm_exec_sql_text(sp.sql_handle) AS qt
WHERE  spid > 50 and blocked > 0


