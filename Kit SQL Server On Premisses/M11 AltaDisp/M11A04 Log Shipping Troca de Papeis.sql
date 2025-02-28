/*******************************************
 Autor: Landry
 
 - LogShipping
********************************************/
use master
go

/***********************************
 Log Shipping 1

 SRVSQLAULA --> SRVSQL2022
************************************/
-- Executar no Prim�rio para ele virar Secund�rio
BACKUP LOG HandsOn TO DISK = 'C:\LogShipping\Sinc\HandsOn.trn' WITH format,compression,norecovery

-- Executar no Secund�rio para ele virar Prim�rio
RESTORE LOG HandsOn FROM DISK = 'C:\LogShipping\Sinc\HandsOn.trn' WITH recovery

-- Consultar na Instancia2
SELECT * FROM HandsOn.dbo.Clientes

/***********************************
 Log Shipping 2

 SRVSQLAULA <-- SRVSQL2022
************************************/


