/*******************************************************
 Hands On
 Autor: Landry Duailibe

 Hands On: gera atividade no banco Adventure Works
*******************************************************/
use AdventureWorks
go

-- Gera Atividade
SELECT count(*) FROM AdventureWorks.Person.Person
go

SELECT * FROM AdventureWorks.Person.Person WHERE LastName = 'Abbas'
go


