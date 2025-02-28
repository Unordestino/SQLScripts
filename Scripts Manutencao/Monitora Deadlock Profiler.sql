/**********************************************************************
 Cria Trace no Servidor para monitorar Queries
 Data: 19/12/2001
 Autor: Landry D. Salles Filho
***********************************************************************/
use master
go

/***********************************************************
 Cria Stored Procedure na master para ativar trace em banco
************************************************************/
if object_id('spu_CriaTrace_Deadlock') is not null
   drop proc spu_CriaTrace_Deadlock
go
create proc dbo.spu_CriaTrace_Deadlock
@Banco varchar(1000), -- Nome do Banco de dados para capturar as consultas
@Caminho nvarchar(128), -- local de escrita do arquivo, finalizar com \
@TamArq bigint = 100 -- valor em MB, tamanho do arquivo para criar outro
as
declare @IDtrace int, @PathFile nvarchar(128), @Retorno int, @FiltroBanco int;
declare @Data nvarchar(128)
set @Data = convert(nvarchar(30),getdate(),112)

set @PathFile = @Caminho + N'Deadlock_' + @@SERVERNAME + ' ' + @Data;
set @FiltroBanco = db_id(@Banco)

-- Cria trace
exec @Retorno = sp_trace_create @traceid = @IDtrace OUTPUT, @options = 0, @tracefile = @PathFile, @maxfilesize = @TamArq, @stoptime = null;

if @Retorno <> 0 begin
   print 'Erro Criando Trace: ' + str(@Retorno)
   return
end
print 'ID Trace: ' + str(@IDtrace);

/* Retorno:
0 No error. 
1 Unknown error. 
10 Invalid options. Returned when options specified are incompatible. 
12 File not created. 
13 Out of memory. Returned when there is not enough memory to perform the specified action. 
14 Invalid stop time. Returned when the stop time specified has already happened. 
15 Invalid parameters. Returned when the user supplied incompatible parameters. 
*/

-- ************* Cria Eventos
-- 1 minuto = 60 segundos = 60.000 milesegundos = 60.000.000 microsegundos
-- Duration em microsegundos
-- CPU em milesegundos
declare @bit bit
set @bit = 1

-- Deadlock Graph
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 148, @columnid =  1, @on = @bit  -- TextData
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 148, @columnid =  41, @on = @bit -- 
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 148, @columnid =  4, @on = @bit  -- 
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 148, @columnid =  12, @on = @bit -- SPID
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 148, @columnid =  11, @on = @bit -- SQLSecurityLoginName
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 148, @columnid =  51, @on = @bit -- 
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 148, @columnid =  14, @on = @bit -- 
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 148, @columnid =  26, @on = @bit -- 
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 148, @columnid =  60, @on = @bit -- 
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 148, @columnid =  64, @on = @bit -- 

--exec sp_trace_setevent @traceid = @IDtrace, @eventid = 148, @columnid =  3, @on = @bit -- DatabaseID
--exec sp_trace_setevent @traceid = @IDtrace, @eventid = 148, @columnid = 35, @on = @bit -- DatabaseName

-- ****************** Cria FILTRO
-- Filtro do banco
--exec sp_trace_setfilter @traceid = @IDtrace, @columnid = 3,@logical_operator = 0,@comparison_operator = 0,@value = @FiltroBanco

/*
@logical_operator -> AND (0) or OR (1)

@comparison_operator :
0 = (Equal) 
1 <> (Not Equal) 
2 > (Greater Than) 
3 < (Less Than) 
4 >= (Greater Than Or Equal) 
5 <= (Less Than Or Equal) 
6 LIKE  
7 NOT LIKE  
*/

exec sp_trace_setstatus @traceid = @IDtrace, @status = 1 
-- exec sp_trace_setstatus @traceid = 1, @status = 2 

/* @status
0 Stops the specified trace. 
1 Starts the specified trace. 
2 Closes the specified trace and deletes its definition from the server. 
*/

/* Retorno:
0 No error. 
1 Unknown error. 
8 The specified Status is not valid. 
9 The specified Trace Handle is not valid. 
13 Out of memory. Returned when there is not enough memory to perform the specified action. 
*/
go
/******************************************
                      FIM 
*******************************************/


-- Ativa trace executando a SP (retorna o ID do trace)
exec spu_CriaTrace_Deadlock null,N'E:\'


-- Informações do Trace
SELECT * FROM sys.traces

SELECT ei.eventid EventID,e.name EventName,c.trace_column_id ColumnID,c.name ColumnName
FROM fn_trace_geteventinfo(2) ei JOIN sys.trace_events e ON ei.eventid = e.trace_event_id
JOIN sys.trace_columns c ON ei.columnid = c.trace_column_id

/* @status
0 Stops the specified trace. 
1 Starts the specified trace. 
2 Closes the specified trace and deletes its definition from the server. 
*/
go
declare @ID int
SELECT @ID = id FROM sys.traces where path like 'E:\%'
exec sp_trace_setstatus @traceid = @ID, @status = 0 
exec sp_trace_setstatus @traceid = @ID, @status = 2 
go
-- Importar Resultado para tabela
SELECT * INTO tmp_Trace FROM fn_trace_gettable('D:\Democode\Trace_QueryTempo 20071004.trc', default);

select * from tmp_Trace order by duration desc


/**************************************** Testa ***************************************************/
use tempdb
go
if object_id('Funcionarios') is not null
   drop table Funcionarios
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