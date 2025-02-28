/*******************************************
 Autor: Landry Duailibe
 
 Hands On: AlwaysOn no Azure
********************************************/
USE master
go

-- 1) Desabilitar Failover Autom�tico

-- 2) Interromper movimento de dados para o Secund�rio
ALTER DATABASE HandsOn SET HADR SUSPEND

-- 3) Aplicar a atualiza��o no secund�rio

-- 4) Retornar o movimento de dados no Secund�rio
ALTER DATABASE HandsOn SET HADR RESUME

-- 5) Verificar se est� 100% sincronizado
SELECT b.replica_server_name, a.synchronization_state_desc, a.synchronization_health_desc, a.is_suspended
FROM sys.dm_hadr_database_replica_states a
JOIN sys.availability_replicas b on b.replica_id = a.replica_id
WHERE a.database_id = db_id('HandsOn')

-- 6) Fazer failover para o secund�rio e refazer o procedimento no outro servidor
ALTER AVAILABILITY GROUP [AG-CursoAdm] FAILOVER
