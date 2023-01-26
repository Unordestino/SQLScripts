/*
Tabelas temporárias
* O nome da tabela deve iniciar com o caractere #
* São visíveis somente para a sessão atual e nos níveis aninhados (por exemplo: procedures).
* Útil quando o usuário não tem permissão para criar tabelas na database atual, pois as tabelas temporárias são criadas na database 
"tempdb".

* São destruídas automaticamente pelo SQL Server quando termina o seu escopo.
*/


CREATE TABLE #Cliente (
ID_CLIENTE INT IDENTITY(1,1) NOT NULL,
NM_CLIENTE VARCHAR(100) NOT NULL,
DT_NASCIMENTO DATE NOT NULL,
FL_SEXO TINYINT NOT NULL
)

--------------------------------------------------------------------------------------------------------------------------------------------


/*
Tabelas globais
* O nome da tabela deve iniciar com o caractere "##"
* Utilizadas quando precisamos armazenar dados de forma temporária e compartilhar com outras sessões também.
* São visíveis para qualquer sessão do banco de dados.
* São destruídas automaticamente pelo SQL Server quando termina o seu escopo.

* São destruídas automaticamente pelo SQL Server quando termina o seu escopo.
*/


CREATE TABLE ##Cliente (
ID_CLIENTE INT IDENTITY(1,1) NOT NULL,
NM_CLIENTE VARCHAR(100) NOT NULL,
DT_NASCIMENTO DATE NOT NULL,
FL_SEXO TINYINT NOT NULL
)

--------------------------------------------------------------------------------------------------------------------------------------------

/*
Tebelas Temporárias - Variáveis:
* Utiliza o DECLARE @NomeTabela TABLE
* Utilizadas quando precisamos armazenar dados de forma temporária.
* São visíveis dentro do batch que está executando a query.
* NÃO são visíveis para os batches subsequentes na mesma sessão.
*/

DECLARE @Cliente2 TABLE (
ID_CLIENTE INT IDENTITY(1,1) NOT NULL,
NM_CLIENTE VARCHAR(100) NOT NULL,
DT_NASCIMENTO DATE NOT NULL,
FL_SEXO TINYINT NOT NULL
)

--------------------------------------------------------------------------------------------------------------------------------------------



