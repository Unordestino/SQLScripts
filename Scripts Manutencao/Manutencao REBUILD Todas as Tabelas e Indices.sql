/*********************************************************************
 Autor: Landry
 Data: 30/10/2019

 REBUILD de todas as tabelas do DW
**********************************************************************/

use DW_BBRK
go

DECLARE @Tabela sysname, @Comando nvarchar(4000)

DECLARE vCursorTabelas CURSOR FOR 
SELECT b.[name] + '.' + a.[name] as Tabela 
FROM sys.tables a JOIN sys.schemas b on a.schema_id = b.schema_id
WHERE b.[name] in ('Pub','Venda')
ORDER BY Tabela

OPEN vCursorTabelas
FETCH NEXT FROM vCursorTabelas INTO @Tabela

WHILE @@FETCH_STATUS <> -1
BEGIN
   WAITFOR DELAY '00:00:10'
   SET @Comando = N'ALTER INDEX ALL ON ' + @Tabela + N' REBUILD'
   EXEC(@Comando)

   FETCH NEXT FROM vCursorTabelas INTO @Tabela
END
CLOSE vCursorTabelas 
DEALLOCATE vCursorTabelas
go