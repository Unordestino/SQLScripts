SELECT
    C.[name] AS TableName,
    B.[name] AS IndexName,
    A.index_type_desc AS IndexType,
	A.PAGE_COUNT,
    A.avg_fragmentation_in_percent,
	script = case 
	when avg_fragmentation_in_percent > 30 then 'ALTER INDEX [' +  B.[name] + '] ON [' + D.[name] + '].[' + C.[name] + '] REBUILD' 
    when avg_fragmentation_in_percent >= 5 and avg_fragmentation_in_percent <= 30 then 'ALTER INDEX [' + B.[name]  + '] ON [' + D.[name] + '].[' + C.[name] + ']  REORGANIZE' 
	end
    --'ALTER INDEX [' + B.[name] + '] ON [' + D.[name] + '].[' + C.[name] + '] REBUILD' AS CmdRebuild
FROM
    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED')	A
    JOIN sys.indexes B ON B.[object_id] = A.[object_id] AND B.index_id = A.index_id
    JOIN sys.objects C ON B.[object_id] = C.[object_id]
    JOIN sys.schemas D ON D.[schema_id] = C.[schema_id]
WHERE
    A.avg_fragmentation_in_percent > 5
    AND OBJECT_NAME(B.[object_id]) NOT LIKE '[_]%'
    AND A.index_type_desc != 'HEAP'
	--AND A.PAGE_COUNT > 1000
ORDER BY
    A.avg_fragmentation_in_percent DESC

