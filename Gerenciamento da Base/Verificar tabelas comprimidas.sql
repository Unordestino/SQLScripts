SELECT
    A.[partition_id],
    A.[object_id],
    object_name(A.[object_id]) AS [object_name],
    data_compression_desc
FROM
    sys.partitions A
    join sys.objects B on A.[object_id] = B.[object_id]
WHERE
    B.is_ms_shipped = 0 and  data_compression_desc not in ('NONE')