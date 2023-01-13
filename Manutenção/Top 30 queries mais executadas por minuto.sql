-- Esse script retorna as queries que mais tiveram execução no tempo de 1 minuto.

if object_id('tempdb..#Temp_Trace') is not null drop table #Temp_Trace

SELECT TOP 30   Execution_countcase when datediff(mi,creation_time, getdate()) = 0 then 1 else datediff(mi,creation_time, getdate()) end  ExecuçõesPorMin,
	creation_time,sql_handle,execution_count,last_execution_time,last_worker_time,total_worker_time,total_physical_reads , total_logical_reads ,total_logical_writes 
into #Temp_Trace
FROM sys.dm_exec_query_stats A
order by  Execution_countcase when datediff(mi,creation_time, getdate()) = 0 then 1 else datediff(mi,creation_time, getdate()) end desc

select text,
from #Temp_Trace A
cross apply sys.dm_exec_sql_text (sql_handle)
order by 2 desc