-- TOP 50 queries executadas mais vezes

if object_id('tempdb..#Temp_Trace') is not null drop table #Temp_Trace

SELECT TOP 50  execution_count, sql_handle,last_execution_time,last_worker_time,total_worker_time
into #Temp_Trace
FROM sys.dm_exec_query_stats A
where last_elapsed_time > 20
ORDER BY A.execution_count DESC

select distinct *
from #Temp_Trace A
cross apply sys.dm_exec_sql_text (sql_handle)
order by 1 DESC