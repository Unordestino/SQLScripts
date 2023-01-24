-----------------------------------------------------------------------------------------------------------------------------
1º Execute o script "MaintenanceSolution"

-----------------------------------------------------------------------------------------------------------------------------
2º Adicione o script abaixo em um job para finalizar a rotina

	--B. Rebuild or reorganize all indexes with fragmentation and update modified statistics on all user databases

	EXECUTE dbo.IndexOptimize
		@Databases = 'USER_DATABASES',
		@FragmentationLow = NULL,
		@FragmentationMedium = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
		@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
		@FragmentationLevel1 = 5,
		@FragmentationLevel2 = 30,
		@UpdateStatistics = 'ALL',
		@OnlyModifiedStatistics = 'Y',
		@LogToTable = 'Y',
		@TimeLimit = 5 
	--segundos ****** parâmetro muito importante!!!! Defina em até quanto tempo essa rotina vai executar

-----------------------------------------------------------------------------------------------------------------------------		
	   
3º Verifique o log para visualizar os logs da rotina		 		
	-- Tabela de Log dessa rotina
	SELECT StartTime,* 
	FROM [dbo].[CommandLog]
	ORDER BY 1 DESC

-----------------------------------------------------------------------------------------------------------------------------		

4º Lembrar de criar um script para delete limpa os logs de uma semana

