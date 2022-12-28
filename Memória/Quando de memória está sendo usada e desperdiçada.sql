-- Memory loss, retorna quanto de memória está sendo usada e desperdiçada.

SELECT
 (CASE WHEN ([database_id] = 32767)
	THEN N'Resource Database'
	ELSE DB_NAME ([database_id] ) END) AS [DatabaseName],
 COUNT (*) * 8 / 1024 AS [MBUsed],
 SUM ([free_space_in_bytes]) / (1024 * 1024) AS [MBEmpty]
FROM sys.dm_os_buffer_descriptors
GROUP BY [database_id];
GO