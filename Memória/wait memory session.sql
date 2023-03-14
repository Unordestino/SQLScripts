SELECT er.session_id,
SUBSTRING(st.text, (er.statement_start_offset/2)+1,
((CASE er.statement_end_offset
WHEN -1 THEN DATALENGTH(st.text)
ELSE er.statement_end_offset
END - er.statement_start_offset)/2) + 1) AS statement_text,
er.wait_type, er.wait_time,
mg.requested_memory_kb/1024 AS requested_memory_MB,
mg.granted_memory_kb/1024 AS granted_memory_MB,
CONVERT(XML, qp.query_plan) AS query_plan
FROM sys.dm_exec_requests er CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) st
CROSS APPLY sys.dm_exec_text_query_plan(er.plan_handle, er.statement_start_offset, er.statement_end_offset) qp
INNER JOIN sys.dm_exec_query_memory_grants mg ON er.session_id = mg.session_id
ORDER BY mg.requested_memory_kb DESC