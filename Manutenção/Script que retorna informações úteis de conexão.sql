-- Remova a condição where para verificar todos os resultados.
-- Altere a variável @session para consultar uma session única
-- Utilizando o comando netstat -p tcp | find "num_porta" você consehue visualizar o nome do host
-- netstat -natb -p tcp | find "num_porta" mostra os serviçoes que está estabelecendo a conexão

if object_id('tempdb..#Temp_Trace') is not null drop table #Temp_Trace

Declare @session int
SET @session = 62 -- Digite o valor da session da consulta

Declare @handle decimal 
select  dt.name as 'data_base' ,ss.session_id ,ss.login_name ,ss.host_name, ss.original_login_name, cc.client_net_address, 
client_tcp_port, cc.local_net_address, cc.local_tcp_port, cc.parent_connection_id 
,ss.login_time, cc.protocol_type,
ss.client_version, ss.client_interface_name,
 ss.cpu_time, ss.reads, ss.writes, ss.logical_reads,  cc.num_reads, rr.status, rr.wait_type,
rr.wait_time, percent_complete ,rr.command ,cc.num_writes, rr.sql_handle
into #Temp_Trace
from sys.dm_exec_sessions ss 
inner join sys.dm_exec_connections cc ON ss.session_id = cc.session_id
inner join sys.dm_exec_requests rr ON ss.session_id = rr.session_id
inner join sys.sysdatabases dt ON ss.database_id = dt.dbid
where ss.session_id = @session

select distinct *
from #Temp_Trace A
cross apply sys.dm_exec_sql_text (sql_handle)



-----------------------------------------------------------------------------
-- Retorna algumas informações de conexão

SELECT 
con.connection_id, ses.session_id, ses.login_name, ses.host_name, ses.host_process_id, ses.program_name,
ses.last_request_start_time, ses.last_request_end_time, 
req.status, req.command, Substring(st.TEXT,(req.statement_start_offset / 2) + 1, 
((CASE req.statement_end_offset WHEN -1 THEN Datalength(st.TEXT) ELSE req.statement_end_offset 
END - req.statement_start_offset) / 2) +1) AS statment_text

FROM sys.dm_exec_connections con
INNER JOIN sys.dm_exec_sessions ses ON con.[session_id] = ses.[session_id]
INNER JOIN sys.dm_exec_requests req ON req.[session_id] = con.[session_id]
CROSS APPLY sys.dm_exec_sql_text(req.sql_handle) AS st
order by ses.session_id asc
