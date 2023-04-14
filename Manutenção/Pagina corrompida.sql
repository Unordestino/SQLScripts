
-- Essa tabela mostra quantas vezes tentaram realizar uma consulta nessa página corrompida
SELECT	* FROM	[msdb].[dbo].[suspect_pages];
--A partir do SQL 2012
SELECT DB_NAME(susp.database_id) DatabaseName,
	OBJECT_SCHEMA_NAME(ind.object_id, ind.database_id) ObjectSchemaName,
	OBJECT_NAME(ind.object_id, ind.database_id) ObjectName, *
FROM msdb.dbo.suspect_pages susp
CROSS APPLY SYS.DM_DB_DATABASE_PAGE_ALLOCATIONS(susp.database_id,null,null,null,null) ind
WHERE allocated_page_file_id = susp.file_id
	AND allocated_page_page_id = susp.page_id