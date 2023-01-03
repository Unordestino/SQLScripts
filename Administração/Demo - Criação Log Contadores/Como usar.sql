/*
Execute o escript "Demo Procedure Criação Log Contadores"

--	Agora é só criar um JOB para rodar essa procedure a cada 1 minuto.
	Procedure: exec Traces.dbo.stpCarga_ContadoresSQL

	Tabelas criadas: [dbo].[Contador], [dbo].[Registro_Contador]

	Verificando
	SELECT Nm_Contador,Dt_Log,Valor
	FROM TRACES..Contador A 
	JOIN Traces..Registro_Contador B ON A.Id_Contador = B.Id_Contador
	ORDER BY 1,2

	Por fim, crie um job que apague os registros da tabela com mais de 60 dias.
	Executar o script "Deleta os registros da tabela com mais de 60 dias"

- BatchRequests: Transações por segundo no SQL Server
- User Connection: Quantidade de conexões no banco de dados
- CPU: Consumo de CPU do servidor
- Page Life Expectancy: Expectativa de vida em segundos de uma    página na memória do SQL Server
*/