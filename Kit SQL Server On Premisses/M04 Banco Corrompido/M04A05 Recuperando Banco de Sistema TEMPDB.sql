/**********************************************************************
 Autor: Landry Duailibe

 Hands On: Recuperando Banco de Sistema TEMPDB
***********************************************************************/
use tempdb
go

CREATE TABLE Teste (col1 int)
-- Reiniciar para mostrar que a tabela n�o existe mais

use master
go

-- Mover a TEMPDB para pasta "MSSQL_TEMPDB"
exec sp_helpdb tempdb

ALTER DATABASE tempdb MODIFY FILE (name = 'tempdev', filename = 'C:\MSSQL_TEMPDB\tempdb.mdf')
ALTER DATABASE tempdb MODIFY FILE (name = 'temp2', filename = 'C:\MSSQL_TEMPDB\tempdb_mssql_2.ndf')
ALTER DATABASE tempdb MODIFY FILE (name = 'templog', filename = 'C:\MSSQL_TEMPDB\templog.ldf')

-- Renomear a pasta e mostrar o erro na inicializa��o
-- Iniciar o SQL Server com -f -m e alterar a localiza��o da TEMPDB

/*************************************
 Retornando para localiza��o original
**************************************/
ALTER DATABASE tempdb MODIFY FILE (name = 'tempdev', filename = 'F:\tempDb\DATA\tempdb.mdf')
ALTER DATABASE tempdb MODIFY FILE (name = 'templog', filename = 'F:\tempDb\DATA\templog.ldf')



