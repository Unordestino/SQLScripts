/********************************************************************************************************************
 Autor: Landry Duailibe

 Hands On: Blocking
*********************************************************************************************************************/
use Aula
go

-- Cria Tabela para demonstração Snapshot Isolation Level
DROP TABLE IF exists Funcionario
go
CREATE TABLE Funcionario (PK int primary key, Nome varchar(50), Descricao varchar(100), [Status] char(1),Salario decimal(10,2))
INSERT Funcionario VALUES (1,'Fernando','Gerente','B',5600.00)
INSERT Funcionario VALUES (2,'Ana Maria','Diretor','A',7500.00)
INSERT Funcionario VALUES (3,'Lucia','Gerente','B',5600.00)
INSERT Funcionario VALUES (4,'Pedro','Operacional','C',2600.00)
INSERT Funcionario VALUES (5,'Carlos','Diretor','A',7500.00)
INSERT Funcionario VALUES (6,'Carol','Operacional','C',2600.00)
INSERT Funcionario VALUES (7,'Luana','Operacional','C',2600.00)
INSERT Funcionario VALUES (8,'Lula','Diretor','A',7500.00)
INSERT Funcionario VALUES (9,'Erick','Operacional','C',2600.00)
INSERT Funcionario VALUES (10,'Joana','Operacional','C',2600.00)
go


/****************************************************************************************
 Hands On: READ_COMMITTED padrão
  - Escrita bloqueia Leitura
  - Leitura Suja
*****************************************************************************************/

/******************
 Conexão 1
*******************/
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

BEGIN TRAN
  UPDATE Funcionario SET Salario = 3000.00 WHERE PK = 10
  SELECT * FROM Funcionario WHERE PK = 10 -- Salario = 2600.00

ROLLBACK

/******************
 Conexão 2
*******************/
SELECT * FROM Aula.dbo.Funcionario -- with (nolock)
WHERE PK = 10 -- Salario = 3000.00


/******************
 Conexão 3
*******************/
-- SQL Server Versões 7.0 e 2000
exec sp_who2
exec sp_lock 53
exec sp_lock 54
DBCC INPUTBUFFER (53)
DBCC INPUTBUFFER (54)


-- SQL Server a partir 2008
SELECT * FROM sys.dm_exec_connections

-- Processos de usuário abertos
SELECT * FROM sys.dm_exec_sessions WHERE session_id > 50

-- Em execução
SELECT * FROM sys.dm_exec_requests WHERE session_id > 50 and session_id <> @@spid

-- Para pegar a instrução
-- Parâmetro coluna sql_handle do sys.dm_exec_requests
SELECT * FROM sys.dm_exec_sql_text(0x02000000B5BB8A0D52DAE74382B9972DFC292A98C6A63128)
SELECT * FROM sys.dm_exec_sql_text(0x02000000D0AF75072F185FB122718D72499D4E69233FD990)


