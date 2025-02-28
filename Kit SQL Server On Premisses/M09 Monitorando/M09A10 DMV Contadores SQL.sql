/************************************************
 Autor: Landry Duailibe
 
 Hands On: sys.dm_os_performance_counters
 https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-performance-counters-transact-sql?view=sql-server-ver16
*************************************************/

select * from sys.dm_os_performance_counters

select distinct cntr_type  from sys.dm_os_performance_counters

select * from sys.dm_os_performance_counters
where counter_name  in ('Buffer cache hit ratio base','Buffer cache hit ratio')

/****************************************************
 Ultimo valor observado
 cntr_type = 65792
*****************************************************/
SELECT object_name,counter_name,instance_name,cntr_value
FROM sys.dm_os_performance_counters
WHERE cntr_type = 65792 -- last observed value directly
and instance_name in ('_Total','')
and counter_name in ('Page life expectancy',
'Total Server Memory (KB)','Target Server Memory (KB)')
ORDER BY 1,2

/****************************************************************
 Valor Acumulado
 cntr_type = 272696576

 - aferir dois valores, subtrair e dividir pelo tempo em segundos
   (V2 - V1) / Intervalo Seg
*****************************************************************/
SELECT object_name,counter_name,instance_name,cntr_value
FROM sys.dm_os_performance_counters
WHERE cntr_type = 272696576
and instance_name in ('_Total','')
and counter_name in ('Lock Waits/sec',
'Number of Deadlocks/sec','Transactions/sec',
'Log Flush Waits/sec','Latch Waits/sec',
'Full Scans/sec','Index Searches/sec',
'Forwarded Records/sec','Page Splits/sec',
'Batch Requests/sec')
ORDER BY 1,2

/****************************************************************
 Valor Acumulado
 cntr_type = 1073874176 (PERF_AVERAGE_BULK)
 cntr_type = 1073939712 (PERF_LARGE_RAW_BASE)

 - Aferir dois valores onde:
   A = PERF_AVERAGE_BULK
   B = PERF_LARGE_RAW_BASE 
   (A2 – A1) / (B2 – B1)
*****************************************************************/
SELECT object_name,counter_name,instance_name,cntr_value
FROM sys.dm_os_performance_counters
WHERE cntr_type in (1073874176,1073939712)
and instance_name in ('_Total','')
and object_name = 'SQLServer:Locks'
ORDER BY 1,2

/****************************************************************
 Valor Acumulado
 cntr_type = 1073939712 (PERF_LARGE_RAW_FRACTION)
 cntr_type = 537003264 (PERF_LARGE_RAW_BASE)

 - Aferir dois valores onde:
   A = PERF_LARGE_RAW_FRACTION
   B = PERF_LARGE_RAW_BASE 
   100 * (B / A)
*****************************************************************/
SELECT object_name,counter_name,instance_name,cntr_value
FROM sys.dm_os_performance_counters
WHERE cntr_type in (1073939712,537003264)
and instance_name in ('_Total','')
and object_name = 'SQLServer:Buffer Manager'
ORDER BY 1,2



-- Informações SQL e Windows
SELECT 
RIGHT(@@version, LEN(@@version)- 3 -charindex (' ON ', @@VERSION)) as Windows_Edicao, 
SERVERPROPERTY('Edition') AS SQL_Edicao,
SERVERPROPERTY('ProductVersion') AS SQL_Build,  
SERVERPROPERTY('ProductLevel') AS SQL_ServicePack, 
case when SERVERPROPERTY('IsIntegratedSecurityOnly') = 1 then 'Windows' else 'Misto' end as SQL_Autenticacao,
case when SERVERPROPERTY('IsHadrEnabled') = 1 then 'Sim' else 'Não' end as SQL_AlwaysOn,
case when SERVERPROPERTY('IsClustered') = 1 then 'Sim' else 'Não' end as SQL_Cluster,
SERVERPROPERTY('Collation') AS SQL_Collation

-- Informações Memória
select 
cast((total_physical_memory_kb/1024.00)/1024.00 as decimal(16,2)) as MEM_RAM_GB,
cast((available_physical_memory_kb/1024.00)/1024.00 as decimal(16,2)) as MEM_Livre_GB
from sys.dm_os_sys_memory

