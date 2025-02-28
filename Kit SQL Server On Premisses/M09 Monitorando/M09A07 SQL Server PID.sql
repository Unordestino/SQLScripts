/**************************************
 Hands On
 Autor: Landry Duailibe

 - Gera atividade no SQL Server
***************************************/

/**********************************
 Windows TASKLIST.EXE
 https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/tasklist

 TASKLIST /FI "IMAGENAME eq sql*"
**********************************/


SELECT * FROM sys.dm_server_services

SELECT servicename, process_id, last_startup_time, service_account 
FROM sys.dm_server_services
