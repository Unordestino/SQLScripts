/********************************************************************************************************************
 Autor: Landry Duailibe

 Hands On:
 - Tratamento de erro em Transações
 - XACT_ABORT
 - Blocking

 https://learn.microsoft.com/en-us/sql/t-sql/language-elements/transactions-transact-sql?view=sql-server-ver16
 https://learn.microsoft.com/pt-br/sql/t-sql/language-elements/begin-transaction-transact-sql?view=sql-server-ver16
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

/*************************************
 Transacao SEM tratamento de erro
**************************************/ 
SELECT * FROM Funcionario WHERE PK in (9,10)
SELECT @@TRANCOUNT

BEGIN TRAN
	UPDATE Funcionario SET Salario = 3000.00 WHERE PK = 9 -- 2600.00
	INSERT Funcionario VALUES (10,'Joana','Operacional','C',2600.00) -- ERRO PK
COMMIT
/*
Msg 2627, Level 14, State 1, Line 34
Violation of PRIMARY KEY constraint 'PK__TB_Trans__32150787A70B2D30'. Cannot insert duplicate key in object 'dbo.Funcionario'. The duplicate key value is (10).
The statement has been terminated.
*/


/***********************************************************************************************************
 Transacao XACT_ABORT
 https://learn.microsoft.com/en-us/sql/t-sql/statements/set-xact-abort-transact-sql?view=sql-server-ver16
************************************************************************************************************/ 
SELECT * FROM Funcionario WHERE PK in (9,10)
SELECT @@TRANCOUNT

SET XACT_ABORT ON
BEGIN TRAN
	UPDATE Funcionario SET Salario = 8500.00 WHERE PK = 9 -- 3000.00
	INSERT Funcionario VALUES (10,'Joana','Operacional','C',2600.00) --ERRO PK
COMMIT
SET XACT_ABORT OFF


/*************************************
 Transacao COM tratamento de erro
**************************************/ 
SELECT * FROM Funcionario WHERE PK in (8,10)

BEGIN TRY
	BEGIN TRAN
		UPDATE Funcionario SET Salario = 9000.00 WHERE PK = 8 -- 7500.00
		INSERT Funcionario VALUES (10,'Joana','Operacional','C',2600.00) --ERRO PK
	COMMIT
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER(),ERROR_MESSAGE()
	IF @@trancount > 0
	    	ROLLBACK
END CATCH
go

-- Exclui tabela
DROP TABLE IF exists Funcionario