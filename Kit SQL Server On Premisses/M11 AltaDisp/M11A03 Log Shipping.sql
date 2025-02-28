/*************************************************
 Autor: Landry Duailibe
 
 Hands On: LogShipping Restabelecendo a Sincronia
**************************************************/
use master
go

BACKUP DATABASE HandsOn TO DISK = 'C:\LogShipping\Sinc\HandsOn.bak'
WITH format,compression,stats=5

RESTORE DATABASE HandsOn FROM DISK = 'C:\LogShipping\Sinc\HandsOn.bak'
WITH norecovery, replace,
MOVE 'HandsOn' TO 'C:\MSSQL_Data\HandsOn.mdf',
MOVE 'HandsOn_Log' TO 'C:\MSSQL_Data\HandsOn_Log.ldf'


