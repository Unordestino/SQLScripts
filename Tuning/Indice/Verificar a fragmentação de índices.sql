--	Query para verificar a fragmenta��o de �ndices


SELECT index_Type_desc,avg_page_space_used_in_percent 
	,avg_fragmentation_in_percent	 
	,index_level 
	,record_count 
	,page_count 
	,fragment_count 
	,avg_record_size_in_bytes 
FROM sys.dm_db_index_physical_stats(DB_ID('TreinamentoDBA'),OBJECT_ID('TestesIndices'),NULL,NULL,'DETAILED')