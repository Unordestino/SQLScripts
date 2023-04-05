
SELECT *
FROM (
	SELECT TableName = t.TABLE_SCHEMA + '.' + t.TABLE_NAME
		,[RowCount] = SUM(sp.[rows])
		,Megabytes = (
			8 * SUM(CASE 
					WHEN sau.type != 1
						THEN sau.used_pages
					WHEN sp.index_id < 2
						THEN sau.data_pages
					ELSE 0
					END)
			) / 1024
	FROM INFORMATION_SCHEMA.TABLES t
	JOIN sys.partitions sp ON sp.object_id = OBJECT_ID(t.TABLE_SCHEMA + '.' + t.TABLE_NAME)
	JOIN sys.allocation_units sau ON sau.container_id = sp.partition_id
	WHERE TABLE_TYPE = 'BASE TABLE'
	GROUP BY t.TABLE_SCHEMA + '.' + t.TABLE_NAME
	) A
ORDER BY TableName