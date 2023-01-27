
/*
	-- Instruções para criar essa demo

	--Alterar o SSMS para ignorar o Result SET
	
	-- Abrir uma nova query para rodar o script com os selects no final desse arquivo (*******************)

	-- Validar qual o SPID dessa conexão

	-- Abrir o profile e verificar o log

	-- Após concluir, salvar o resultado em uma tabela. Ex: _Profile_CustoMedio_20200919

	-- *** somente para deixar essa demo mais real ****
	
		-- Excluir os registros com a string "WAITFOR" que simulam o tempo que a rotina fica processando na APP
		delete from _Profile_CustoMedio_20200919 where TextData like '%WAITFOR%'

		--Excluir lixo do log
		delete from _Profile_CustoMedio_20200919 where Duration is null

	-- Fazer uma análise no resultado do Profile



	-- drop table _Profile_CustoMedio_20200919
*/


	--Tempo de coleta do profile e tempo de processamento no BD
	select min(StartTime) [Inicio Processamento], max(EndTime) [Final Processamento],  
			datediff( s, min(StartTime), max(EndTime))/60.00 [Tempo Minutos Processando],
			datediff( s, min(StartTime), max(EndTime)) [Tempo Segundos Processando],
		sum(Duration/1000.00/1000.00) [Tempo processado no banco em segundos], count(*) Qtd_Queries
	from [dbo]._Profile_CustoMedio_20200919

	-- TOP 50 execuções mais demoradas
	select top 50 Duration/1000.00/1000.00 [Tempo em Segundos],*
	from [dbo]._Profile_CustoMedio_20200919
	order by Duration desc

	--Esse substring 15 voce pode variar de acordo com o número de registros para ver mais ou menos linhas sumarizadas
	select substring(TextData,1,40), count(*) [Quantidade], sum(Duration/1000.00/1000.00) [Tempo em Segundos]
	from [dbo]._Profile_CustoMedio_20200919
	group by substring(TextData,1,40)
	order by 3 DESC
    

	-- Se quiser conferir a query completa use esse like
	select Duration/1000.00/1000.00,*
	from [dbo]._Profile_CustoMedio_20200919
	where TextData  like '%SELECT%SA1010%A1_CGC%'
	order by Duration desc
	   
	-- Se quiser conferir a query completa use esse like
	select Duration/1000.00/1000.00,*
	from [dbo]._Profile_CustoMedio_20200919
	where TextData  like '%SELECT%SA1010%A1_CEP%'
	order by Duration desc
	    	  

	--Resolver query 1
	SELECT *  FROM SA1010   WHERE A1_CGC = 'jyujndjidwfyqi'  

	CREATE NONCLUSTERED INDEX SA1010W98 ON SA1010(A1_CGC)WITH(DATA_COMPRESSION=PAGE,FILLFACTOR=90)

	--Resolver query 2
	SELECT *  FROM SA1010   WHERE A1_CEP = '29.156.368'  
		
	CREATE NONCLUSTERED INDEX SA1010W99 ON SA1010(A1_CEP)WITH(DATA_COMPRESSION=PAGE,FILLFACTOR=90)


	-- Rodar novamente a rotina e salvar em uma outra tabela _Profile_CustoMedio_20200919_Melhorada
	-- drop table _Profile_CustoMedio_20200919_Melhorada

	-- Excluir os registros com a string "WAITFOR" que simulam o tempo que a rotina fica processando na APP
		delete from _Profile_CustoMedio_20200919_Melhorada where TextData like '%WAITFOR%'
				
		--Excluir lixo do log
		delete from _Profile_CustoMedio_20200919_Melhorada where Duration is NULL
        
	--Comparar os 2 resultados
	
	select min(StartTime) [Inicio Processamento], max(EndTime) [Final Processamento],  
			datediff( s, min(StartTime), max(EndTime))/60.00 [Tempo Minutos Processando],
			datediff( s, min(StartTime), max(EndTime)) [Tempo Segundos Processando],
		sum(Duration/1000.00/1000.00) [Tempo processado no banco em segundos], count(*) Qtd_Queries
	from [dbo]._Profile_CustoMedio_20200919
	
	SELECT min(StartTime) [Inicio Processamento], max(EndTime) [Final Processamento],  
			datediff( s, min(StartTime), max(EndTime))/60.00 [Tempo Minutos Processando],
			datediff( s, min(StartTime), max(EndTime)) [Tempo Segundos Processando],
		sum(Duration/1000.00/1000.00) [Tempo processado no banco em segundos], count(*) Qtd_Queries
	from [dbo]._Profile_CustoMedio_20200919_Melhorada


	select substring(TextData,1,40), count(*) [Quantidade], sum(Duration/1000.00/1000.00) [Tempo em Segundos]
	from [dbo]._Profile_CustoMedio_20200919
	group by substring(TextData,1,40)
	order by 3 DESC

	select substring(TextData,1,40), count(*) [Quantidade], sum(Duration/1000.00/1000.00) [Tempo em Segundos]
	from [dbo]._Profile_CustoMedio_20200919_Melhorada
	group by substring(TextData,1,40)
	order by 3 DESC
	   

	-- No final da demo excluir os indices
	DROP INDEX SA1010.SA1010W98
	DROP INDEX SA1010.SA1010W99



-- ************************* -- Abrir uma nova query para rodar o script com os selects no final desse arquivo  ****************************************
SET NOCOUNT ON

	GO
	SELECT *
	FROM SA1010 
	WHERE A1_CGC = 'jyujndjidwfyqi'
	GO 123
	SELECT A1_NOME,A1_CGC
	FROM SA1010 
	WHERE A1_NOME = 'Fabricio'
	GO 56984
	WAITFOR DELAY '00:00:00:200'
	GO 100
	SELECT A1_CEP,A1_NOME,A1_CGC
	FROM SA1010 
	WHERE A1_NOME = 'Fabricio'
	GO 25654
	SELECT *
	FROM SA1010 
	WHERE A1_CEP = '29.156.368'
	GO 36
	SELECT A1_CGC,A1_CEP,A1_NOME
	FROM SA1010 
	WHERE A1_NOME = 'Fabricio'
	GO 75565
	WAITFOR DELAY '00:00:00:100'
	GO 1000
	SELECT *
	FROM SA1010 
	WHERE A1_NOME = 'Fabricio'
	GO 152835
