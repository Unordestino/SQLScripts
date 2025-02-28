/*******************************************************
 Hands On
 Autor: Landry Duailibe

 - Gera atividade no SQL Server

 SQLServer:Buffer Manager:Page life expectancy
 (Max Server Memory em GB) / 4 * 300

 SQL Server:Access Methods\Full Scans/sec
 SQL Server:Access Methods\Index Searches/sec
  (Index Searches/sec) / (Full Scans/sec) > 1000
*******************************************************/

-- Conexão 1 - SCAN
DECLARE @i int = 1
DECLARE @Result int
DECLARE @Result_MiddleName nvarchar(50)
WHILE @i > 0 BEGIN
SELECT @Result = count(*) FROM AdventureWorks.Person.Person
WAITFOR DELAY '00:00:00.002'
end
go

-- Conexão 2 - Seek
DECLARE @i int = 1
DECLARE @Result int
DECLARE @Result_MiddleName nvarchar(50)
WHILE @i > 0 BEGIN
SELECT @Result_MiddleName = MiddleName FROM AdventureWorks.Person.Person WHERE LastName = 'Abbas'
END
go


