/*******************************************
 Autor: Landry Duailibe
 
 Hands On: AlwaysOn no Azure
********************************************/
USE master
go


/******************************************
 Configurando ReadOnly Intent Routing
*******************************************/
SELECT replica_server_name, read_only_routing_url, secondary_role_allow_connections_desc
FROM sys.availability_replicas

-- Replica: sql1-cursoadm
ALTER AVAILABILITY GROUP [AG-CursoAdm]
MODIFY REPLICA ON 'sql1-cursoadm' WITH
(SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL))
 
ALTER AVAILABILITY GROUP [AG-CursoAdm]
MODIFY REPLICA ON 'sql1-cursoadm' WITH
(SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://sql1-cursoadm.cursoadm.com:1433'))

-- Replica: sql2-cursoadm
ALTER AVAILABILITY GROUP [AG-CursoAdm]
MODIFY REPLICA ON 'sql2-cursoadm' WITH
(SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL))
 
ALTER AVAILABILITY GROUP [AG-CursoAdm]
MODIFY REPLICA ON 'sql2-cursoadm' WITH
(SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://sql2-cursoadm.cursoadm.com:1433'))

ALTER AVAILABILITY GROUP [AG-CursoAdm]
MODIFY REPLICA ON N'sql1-cursoadm' WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST = (N'sql2-cursoadm')))

-- Fazer o Failover e executar
ALTER AVAILABILITY GROUP [AG-CursoAdm]
MODIFY REPLICA ON N'sql2-cursoadm' WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST = (N'sql1-cursoadm')))

/***************************************************
 Testar
 - Tem que trocar o Default Database.
 - String de conexão: ApplicationIntent=ReadOnly
***************************************************/
select @@SERVERNAME

CREATE TABLE TESTE (col int)
DROP TABLE IF exists TESTE

