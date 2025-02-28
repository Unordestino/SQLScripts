/********************************************************************
 Autor: Landry Duailibe

 Hands On: Compress�o de Dados
*********************************************************************/
USE Aula
go

/**************************
 Cria 3 Tabelas:
 - Sem Compress�o
 - Compress�o de Linha
 - Compress�o de P�gina
***************************/
DROP TABLE IF exists dbo.TB_Teste
go
CREATE TABLE dbo.TB_Teste ( 
ID int identity not null, 
String char(100) null) 
go

set nocount on 
go
INSERT dbo.TB_Teste 
SELECT isnull(Title,'') + isnull(FirstName,'B') FROM AdventureWorks.Person.Person 
UNION
SELECT isnull(FirstName,'B') + isnull(MiddleName,'') FROM AdventureWorks.Person.Person
UNION
SELECT isnull(FirstName,'B') + isnull(MiddleName,'') + isnull(LastName,'') FROM AdventureWorks.Person.Person
UNION
SELECT isnull(Title,'') + isnull(FirstName,'B') + isnull(MiddleName,'') + isnull(LastName,'') FROM AdventureWorks.Person.Person 
go 60

INSERT dbo.TB_Teste VALUES ('Valor Pesquisa')

SELECT * INTO dbo.TB_Teste_ROW FROM dbo.TB_Teste
SELECT * INTO dbo.TB_Teste_PAGE FROM dbo.TB_Teste

ALTER TABLE dbo.TB_Teste_ROW REBUILD WITH (DATA_COMPRESSION = ROW) 
ALTER TABLE dbo.TB_Teste_PAGE REBUILD WITH (DATA_COMPRESSION = PAGE) 

CREATE INDEX ix_TB_Teste ON dbo.TB_Teste (String)
CREATE INDEX ix_TB_Teste_ROW ON dbo.TB_Teste_ROW (String) WITH (DATA_COMPRESSION = ROW)
CREATE INDEX ix_TB_Teste_PAGE ON dbo.TB_Teste_PAGE (String) WITH (DATA_COMPRESSION = PAGE)
/************************ FIM Prepara Hands On ************************************/


SELECT count(*) FROM dbo.TB_Teste -- 1.718.941 linhas
SELECT count(*) FROM dbo.TB_Teste_ROW -- 1.718.941 linhas
SELECT count(*) FROM dbo.TB_Teste_PAGE -- 1.718.941 linhas

/***********************************************
 Teste Sem Compress�o
************************************************/
set statistics io on

SELECT * FROM dbo.TB_Teste 
-- Paralelismo: Table 'TB_Teste'. Scan count 1, logical reads 24211

SELECT * FROM dbo.TB_Teste 
WHERE String = 'Valor Pesquisa'
-- Table 'TB_Teste'. Scan count 1, logical reads 5

/*************************************
 Compress�o de LINHA
**************************************/
SELECT * FROM dbo.TB_Teste_ROW 
-- Table 'TB_Teste'. Scan count 1, logical reads 4783

SELECT * FROM dbo.TB_Teste_ROW 
WHERE String = 'Valor Pesquisa'
-- Table 'TB_Teste'. Scan count 1, logical reads 4

/*************************************
 Compress�o de PAGINA
**************************************/
SELECT * FROM dbo.TB_Teste_PAGE 
-- Table 'TB_Teste'. Scan count 1, logical reads 4294

SELECT * FROM dbo.TB_Teste_PAGE 
WHERE String = 'Valor Pesquisa'
-- Table 'TB_Teste_PAGE'. Scan count 1, logical reads 4

/*
------------------------------------------
				Compress�o	Scan	Seek
------------------------------------------
TB_Teste		   -		24.211	 5
TB_Teste_ROW	  ROW		 4.783	 4
TB_Teste_PAGE	  PAGE		 4.294	 4
------------------------------------------
*/


-- Exclui tabelas
DROP TABLE IF exists dbo.TB_Teste
DROP TABLE IF exists dbo.TB_Teste_ROW
DROP TABLE IF exists dbo.TB_Teste_PAGE




