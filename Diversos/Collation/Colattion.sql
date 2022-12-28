--	1)	Retorna a collation de uma database
SELECT DATABASEPROPERTYEX('SUA_DATABASE', 'Collation') SQLCollation

--	2)	Retorna a collation da inst‚ncia do SQL Server
select SERVERPROPERTY(N'Collation')

--	Verificando a collation de todas as databases
select name, collation_name 
from sys.databases


------	Curiosidade. Convers„o para retirar todos os acentos de uma string.

Declare @cExpressao varchar(30)
Set @cExpressao = 'aeiou·ÈÌÛ˙‡ËÏÚÚ‚ÍÓÙ˚„ı‰ÎÔˆ¸Á'
Select @cExpressao ANTES,@cExpressao collate sql_latin1_general_cp1251_ci_as DEPOIS


------------------ Collation pode impactar na PERFORMANCE! ----------------------------------

-- Aumentando a velocidade de uma consulta com LIKE utilizando uma collation sql

SELECT COUNT(*) 
FROM Teste_Collation 
WHERE DescriÁ„o COLLATE SQL_Latin1_General_CP1_CI_AI LIKE '%Davi%'

/* 
----Utilizar para para realizar um tuning de uma consulta com LIKE, pois a funÁ„o like n„o utiliza indices.
	Consultas CS_AS utilizar:    COLLATE  Latin1_General_BIN2
	Consultas CI_AI utilizar:    COLLATE SQL_Latin1_General_CP1_CI_AI 
*/