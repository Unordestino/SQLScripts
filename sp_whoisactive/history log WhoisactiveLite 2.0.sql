select * from Resultado_WhoisActiveLite
drop table Resultado_WhoisActiveLite
-- CRIAR A TABELA

CREATE TABLE Resultado_WhoisActiveLite  ( 
	  Dt_log DATETIME DEFAULT GETDATE() ,
      [dd:hh:mm:ss:mss] VARCHAR(255) , 
	  [session_id] SMALLINT NOT NULL , 
	  [command] VARCHAR(255) NULL , 
	  [Transactions_Status] VARCHAR(60) NULL,
	  [sql_text] XML NULL , 
	  [sql_command] XML NULL , 
	  [login_name] VARCHAR(255) , 
	  [wait_info] VARCHAR(255) , 
	  [last_wait_type] VARCHAR(255),
	  [CPU] VARCHAR(100) ,
	  [tempdb_allocations] int,
	  [tempdb_current] int,
	  [reads] VARCHAR(100) ,
	  [writes] VARCHAR(100), 
	  [phisical_reads] VARCHAR(100) ,
	  [used_memory] VARCHAR(100) ,
	  [blocking_session_id] int,
	  [blocking_session_count] int,
	  [kill_command] VARCHAR(255) ,
	  [deadlock_priorty] VARCHAR(100) ,
	  [row_count] int,
	  [open_tran_count] int,
	  [transaction_isolation_level] VARCHAR(255) ,
	  [status] VARCHAR(255) ,
	  [percent_complet] VARCHAR(100) ,
	  [host_name]  VARCHAR(255) ,
	  protocol_type  VARCHAR(100) ,
	  auth_scheme  VARCHAR(100) ,
	  [net_packet_size] int,
	  [client_net_address] VARCHAR(255) ,
	  [cliet_tcp_port] VARCHAR(100) ,
	  [database_name] VARCHAR(255) ,
	  [program_name] VARCHAR(255) ,
	  resource_governo_group VARCHAR(255) ,
	  [request_id] int,
	  [query_plan] XML NULL )



-- ADICIONE TODO O CODIGO ABAIXO EM UM JOB 
-- PARA FAZER O INSET DOS DADOS

INSERT INTO Resultado_WhoisActiveLite 
([dd:hh:mm:ss:mss], [session_id], [command], [Transactions_Status], [sql_text],[sql_command], [login_name], [wait_info],  [last_wait_type],[CPU], [tempdb_allocations],
[tempdb_current], [reads],[writes],[phisical_reads], [used_memory],[blocking_session_id], [blocking_session_count], 
[kill_command],  [deadlock_priorty],
[row_count],
[open_tran_count],
[transaction_isolation_level],
[status],
[percent_complet],
[host_name],
protocol_type,
auth_scheme,
[net_packet_size],
[client_net_address],
[cliet_tcp_port],
[database_name],
[program_name],
resource_governo_group,
[request_id],
[query_plan]
) 

SELECT
    RIGHT('00' + CAST(DATEDIFF(SECOND, COALESCE(B.start_time, A.login_time), GETDATE()) / 86400 AS VARCHAR), 2) + ' ' + 
    RIGHT('00' + CAST((DATEDIFF(SECOND, COALESCE(B.start_time, A.login_time), GETDATE()) / 3600) % 24 AS VARCHAR), 2) + ':' + 
    RIGHT('00' + CAST((DATEDIFF(SECOND, COALESCE(B.start_time, A.login_time), GETDATE()) / 60) % 60 AS VARCHAR), 2) + ':' + 
    RIGHT('00' + CAST(DATEDIFF(SECOND, COALESCE(B.start_time, A.login_time), GETDATE()) % 60 AS VARCHAR), 2) + '.' + 
    RIGHT('000' + CAST(DATEDIFF(SECOND, COALESCE(B.start_time, A.login_time), GETDATE()) AS VARCHAR), 3) 
    AS Duration,
    A.session_id AS session_id,
    B.command,
	ac.name as Transactions_Status,
    TRY_CAST('<?query --' + CHAR(10) + (
        SELECT TOP 1 SUBSTRING(X.[text], B.statement_start_offset / 2 + 1, ((CASE
                                                                          WHEN B.statement_end_offset = -1 THEN (LEN(CONVERT(NVARCHAR(MAX), X.[text])) * 2)
                                                                          ELSE B.statement_end_offset
                                                                      END
                                                                     ) - B.statement_start_offset
                                                                    ) / 2 + 1
                     )
    ) + CHAR(10) + '--?>' AS XML) AS sql_text,
    TRY_CAST('<?query --' + CHAR(10) + X.[text] + CHAR(10) + '--?>' AS XML) AS sql_command,
    A.login_name,
    '(' + CAST(COALESCE(E.wait_duration_ms, B.wait_time) AS VARCHAR(20)) + 'ms)' + COALESCE(E.wait_type, B.wait_type) + COALESCE((CASE 
        WHEN COALESCE(E.wait_type, B.wait_type) LIKE 'PAGE%LATCH%' THEN ':' + DB_NAME(LEFT(E.resource_description, CHARINDEX(':', E.resource_description) - 1)) + ':' + SUBSTRING(E.resource_description, CHARINDEX(':', E.resource_description) + 1, 999)
        WHEN COALESCE(E.wait_type, B.wait_type) = 'OLEDB' THEN '[' + REPLACE(REPLACE(E.resource_description, ' (SPID=', ':'), ')', '') + ']'
        ELSE ''
    END), '') AS wait_info, B.last_wait_type,
    FORMAT(COALESCE(B.cpu_time, 0), '###,###,###,###,###,###,###,##0') AS CPU,
    FORMAT(COALESCE(F.tempdb_allocations, 0), '###,###,###,###,###,###,###,##0') AS tempdb_allocations,
    FORMAT(COALESCE((CASE WHEN F.tempdb_allocations > F.tempdb_current THEN F.tempdb_allocations - F.tempdb_current ELSE 0 END), 0), '###,###,###,###,###,###,###,##0') AS tempdb_current,
    FORMAT(COALESCE(B.logical_reads, 0), '###,###,###,###,###,###,###,##0') AS reads,
    FORMAT(COALESCE(B.writes, 0), '###,###,###,###,###,###,###,##0') AS writes,
    FORMAT(COALESCE(B.reads, 0), '###,###,###,###,###,###,###,##0') AS physical_reads,
    FORMAT(COALESCE(B.granted_query_memory, 0), '###,###,###,###,###,###,###,##0') AS used_memory,
    NULLIF(B.blocking_session_id, 0) AS blocking_session_id,
    COALESCE(G.blocked_session_count, 0) AS blocked_session_count,
    'KILL ' + CAST(A.session_id AS VARCHAR(10)) AS kill_command,
    (CASE 
        WHEN B.[deadlock_priority] <= -5 THEN 'Low'
        WHEN B.[deadlock_priority] > -5 AND B.[deadlock_priority] < 5 AND B.[deadlock_priority] < 5 THEN 'Normal'
        WHEN B.[deadlock_priority] >= 5 THEN 'High'
    END) + ' (' + CAST(B.[deadlock_priority] AS VARCHAR(3)) + ')' AS [deadlock_priority],
    B.row_count,
    COALESCE(A.open_transaction_count, 0) AS open_tran_count,
    (CASE B.transaction_isolation_level
        WHEN 0 THEN 'Unspecified' 
        WHEN 1 THEN 'ReadUncommitted' 
        WHEN 2 THEN 'ReadCommitted' 
        WHEN 3 THEN 'Repeatable' 
        WHEN 4 THEN 'Serializable' 
        WHEN 5 THEN 'Snapshot'
    END) AS transaction_isolation_level,
    A.[status],
    NULLIF(B.percent_complete, 0) AS percent_complete,
    A.[host_name], C.protocol_type, C.auth_scheme, C.net_packet_size, C.client_net_address, C.client_tcp_port,
    COALESCE(DB_NAME(CAST(B.database_id AS VARCHAR)), 'master') AS [database_name],
    (CASE WHEN D.name IS NOT NULL THEN 'SQLAgent - TSQL Job (' + D.[name] + ' - ' + SUBSTRING(A.[program_name], 67, LEN(A.[program_name]) - 67) +  ')' ELSE A.[program_name] END) AS [program_name],
    H.[name] AS resource_governor_group,
    COALESCE(B.request_id, 0) AS request_id,
    W.query_plan
FROM
    sys.dm_exec_sessions AS A WITH (NOLOCK)
    LEFT JOIN sys.dm_exec_requests AS B WITH (NOLOCK) ON A.session_id = B.session_id
    JOIN sys.dm_exec_connections AS C WITH (NOLOCK) ON A.session_id = C.session_id AND A.endpoint_id = C.endpoint_id
	left join sys.dm_tran_session_transactions r ON B.session_id = r.session_id
	left join sys.dm_tran_active_transactions ac ON  r.transaction_id = ac.transaction_id
    LEFT JOIN msdb.dbo.sysjobs AS D ON RIGHT(D.job_id, 10) = RIGHT(SUBSTRING(A.[program_name], 30, 34), 10)
    LEFT JOIN (
        SELECT
            session_id, 
            wait_type,
            wait_duration_ms,
            resource_description,
            ROW_NUMBER() OVER(PARTITION BY session_id ORDER BY (CASE WHEN wait_type LIKE 'PAGE%LATCH%' THEN 0 ELSE 1 END), wait_duration_ms) AS Ranking
        FROM 
            sys.dm_os_waiting_tasks
    ) E ON A.session_id = E.session_id AND E.Ranking = 1
    LEFT JOIN (
        SELECT
            session_id,
            request_id,
            SUM(internal_objects_alloc_page_count + user_objects_alloc_page_count) AS tempdb_allocations,
            SUM(internal_objects_dealloc_page_count + user_objects_dealloc_page_count) AS tempdb_current
        FROM
            sys.dm_db_task_space_usage
        GROUP BY
            session_id,
            request_id
    ) F ON B.session_id = F.session_id AND B.request_id = F.request_id
    LEFT JOIN (
        SELECT 
            blocking_session_id,
            COUNT(*) AS blocked_session_count
        FROM 
            sys.dm_exec_requests
        WHERE 
            blocking_session_id != 0
        GROUP BY
            blocking_session_id
    ) G ON A.session_id = G.blocking_session_id
    OUTER APPLY sys.dm_exec_sql_text(COALESCE(B.[sql_handle], C.most_recent_sql_handle)) AS X
    OUTER APPLY sys.dm_exec_query_plan(B.plan_handle) AS W
    LEFT JOIN sys.dm_resource_governor_workload_groups H ON A.group_id = H.group_id
WHERE
    A.session_id > 50
    AND A.session_id <> @@SPID
    AND (A.[status] != 'sleeping' OR (A.[status] = 'sleeping' AND A.open_transaction_count > 0))