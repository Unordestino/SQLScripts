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
-- Executar no Primário para ele virar Secundário
BACKUP LOG HandsOn TO DISK = 'C:\LogShipping\Sinc\HandsOn.trn' WITH format,compression,norecovery

-- Executar no Secundário para ele virar Primário
RESTORE LOG HandsOn FROM DISK = 'C:\LogShipping\Sinc\HandsOn.trn' WITH recovery

-- Consultar na Instancia2
SELECT * FROM HandsOn.dbo.Clientes

/***********************************
 Log Shipping 2

 SRVSQLAULA <-- SRVSQL2022
************************************/


