	IF ( OBJECT_ID('tempdb..#Resultado_WhoisActive') IS NOT NULL )
		DROP TABLE #Resultado_WhoisActive
  
	CREATE TABLE #Resultado_WhoisActive (  
		[dd hh:mm:ss.mss]  VARCHAR(20),
		[database_name]   NVARCHAR(128),  
		[login_name]   NVARCHAR(128),
		[host_name]    NVARCHAR(128),
		[start_time]   DATETIME,
		[status]    VARCHAR(30),
		[session_id]   INT,
		[blocking_session_id] INT,
		[wait_info]    VARCHAR(MAX),
		[open_tran_count]  INT,
		[CPU]     VARCHAR(MAX),
		[reads]     VARCHAR(MAX),
		[writes]    VARCHAR(MAX),  
		[sql_command]   XML  
	)   
	
		---------------------------------------------------------------------------------------------------------------------------
	-- Carrega os Dados da sp_whoisactive
	--------------------------------------------------------------------------------------------------------------------------------
	-- Retorna todos os processos que estão sendo executados no momento
	EXEC [dbo].[sp_whoisactive]
		@get_outer_command = 1,
		@output_column_list = '[dd hh:mm:ss.mss][database_name][login_name][host_name][start_time][status][session_id][blocking_session_id]	[wait_info][open_tran_count][CPU][reads][writes][sql_command]',
		@destination_table = '#Resultado_WhoisActive'

		-- Altera a coluna que possui o comando SQL
		ALTER TABLE #Resultado_WhoisActive
		ALTER COLUMN [sql_command] VARCHAR(MAX)
 
		UPDATE #Resultado_WhoisActive
		SET [sql_command] = REPLACE( REPLACE( REPLACE( REPLACE( CAST([sql_command] AS VARCHAR(1000)), '<?query --', ''), '--?>', ''), '&gt;', 		'>'), '&lt;', '')  



	--Retorna a tabela temporaria
	select * from #Resultado_WhoisActive
	
	--Where na tabela temporaria
	select * from #Resultado_WhoisActive where sql_command like '%SELECT%'

	--------------------------------------------------------------------------------------------------------------------------------	
	-- Retorna o possível causador de um lock
		select * from #Resultado_WhoisActive where  blocking_session_id IS NULL AND session_id IN ( SELECT DISTINCT blocking_session_id 
		FROM #Resultado_WhoisActive WHERE blocking_session_id IS NOT NULL)
	--------------------------------------------------------------------------------------------------------------------------------