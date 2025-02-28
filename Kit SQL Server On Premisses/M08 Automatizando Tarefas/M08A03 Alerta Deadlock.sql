/************************************************************
 Autor: Landry Duailibe

 Hands On: Alerta Evento Deadlock
*************************************************************/
use Aula
go

DROP TABLE If exists Funcionarios
go
create table Funcionarios (PK int Primary key, Nome varchar(50), Descricao varchar(100), Status char(1),Salario decimal(10,2))
insert Funcionarios values (1,'Fernando','Gerente','B',5600.00)
insert Funcionarios values (2,'Ana Maria','Diretor','A',7500.00)
insert Funcionarios values (3,'Lucia','Gerente','B',5600.00)
insert Funcionarios values (4,'Pedro','Operacional','C',2600.00)
insert Funcionarios values (5,'Carlos','Diretor','A',7500.00)
insert Funcionarios values (6,'Carol','Operacional','C',2600.00)
insert Funcionarios values (7,'Luana','Operacional','C',2600.00)
insert Funcionarios values (8,'Lula','Diretor','A',7500.00)
insert Funcionarios values (9,'Erick','Operacional','C',2600.00)
insert Funcionarios values (10,'Joana','Operacional','C',2600.00)
go

/***********************************
 Cria Alerta Evento 1205 - Deadlock
************************************/
EXEC msdb.dbo.sp_add_alert @name=N'Ocorrencia de Deadlock', @message_id=1205--, @delay_between_responses=1800
EXEC msdb.dbo.sp_add_notification @alert_name=N'Ocorrencia de Deadlock', @operator_name=N'DBA', @notification_method = 1

-- 1205 está com is_event_logged ZERO, não vai conseguir desparar o alerta!
SELECT * FROM sys.messages WHERE message_id = 1205

-- Altera is_event_logged para 1
EXEC sp_altermessage 1205, 'WITH_LOG', 'true' 


/**********************************
 Provoca Deadlock
***********************************/

/* Deadlock - A*/
set deadlock_priority normal
begin tran
  select Nome,PK from Funcionarios where PK = 1

  update Funcionarios set Nome = 'Fernando 1' where PK = 1

  select Nome,PK from Funcionarios where PK = 1

  waitfor delay '00:00:10'

  update Funcionarios set Nome = 'Ana Maria 2' where PK = 2

rollback tran



/* Deadlock - B*/

set deadlock_priority low
begin tran
  select Nome,PK from Funcionarios where PK = 2

  update Funcionarios set Nome = 'Ana Maria 2' where PK = 2

  select Nome,PK from Funcionarios where PK = 2

  update Funcionarios set Nome = 'Fernando 1' where PK = 1

rollback tran



-- Exclui Alerta
EXEC msdb.dbo.sp_delete_alert @name=N'Ocorrencia de Deadlock'
EXEC sp_altermessage 1205, 'WITH_LOG', 'false'

DROP TABLE If exists Funcionarios

