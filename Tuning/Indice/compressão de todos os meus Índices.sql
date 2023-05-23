/**************************** Script para compressão de todos os meus Índices ********************************/

/****************** MUITO IMPORTANTE 

- Mudar o recovery da base para SIMPLE e fazer o processo de voltar para FULL depois e continuar com bkp do log 

- REBUILD usa muito log e se não mudar seu log vai explodir de tamanho quando comprimir a base inteira.

--Curso onde falo sobre recovery FULL/SIMPLE e backup e Restore em geral:
https://cursos.powertuning.com.br/course?courseid=tarefas-do-dia-a-dia-de-um-dba

****************/

	-- Index compression (clustered index or non-clustered index)
	SELECT [t].[name] AS [Table], 
		   [i].[name] AS [Index],  
		   [p].[partition_number] AS [Partition],
		   [p].[data_compression_desc] AS [Compression], 
		   [i].[fill_factor],
		   [p].[rows],
		'ALTER INDEX [' + [i].[name] + '] ON [' + [s].[name] + '].[' + [t].[name] + 
		'] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE' +
		CASE WHEN [i].[fill_factor] BETWEEN 1 AND 89 THEN ', FILLFACTOR = 90' ELSE '' END + ' )'
	FROM [sys].[partitions] AS [p]
	INNER JOIN sys.tables AS [t] 
		 ON [t].[object_id] = [p].[object_id]
	INNER JOIN sys.indexes AS [i] 
		 ON [i].[object_id] = [p].[object_id] AND i.index_id = p.index_id
	INNER JOIN sys.schemas AS [s]
	   ON [t].[schema_id] = [s].[schema_id]
	WHERE [p].[index_id] > 0
	   AND [i].[name] IS NOT NULL
	   AND [p].[rows] > 10000
	   AND [p].[data_compression_desc] = 'NONE'
	Order by t.name
 
	-- Data (table) compression (heap)
	SELECT DISTINCT 
		[t].[name] AS [Table],
		   [p].[data_compression_desc] AS [Compression], 
		   [i].[fill_factor],
		   'ALTER TABLE [' + [s].[name] + '].[' + [t].[name] + '] REBUILD WITH (DATA_COMPRESSION = PAGE)'
	FROM [sys].[partitions] AS [p]
	INNER JOIN sys.tables AS [t] 
		 ON [t].[object_id] = [p].[object_id]
	INNER JOIN sys.indexes AS [i] 
		 ON [i].[object_id] = [p].[object_id]
	INNER JOIN sys.schemas AS [s]
	   ON [t].[schema_id] = [s].[schema_id]
	WHERE [p].[index_id]  = 0
	   AND [p].[rows] > 10000
	   AND [p].[data_compression_desc] = 'NONE'