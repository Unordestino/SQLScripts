/**********************************************************************
 Autor: Landry Duailibe

 Hands On: Instant File Initialization

 Configurar:
 - Abrir o Local Security Policy: secpol.msc;
 - Expandir "Local Policies" e selecionar "User Rights Assignment";
 - Abrir "Perform volume maintenance tasks";
 - Adicionar a conta de servi�o do SQL Server;
 - Reiniciar o servi�o.

 Para verificar:
 - Log do servi�o, pesquisar por "Instant File Initialization";
 - Consultar a View de sistema "sys.dm_server_services".
***********************************************************************/
use master
go

-- Verificando se o Instant File Initialization est� habilitado.
SELECT * FROM  sys.dm_server_services 

