--Habilitando o BPE
ALTER SERVER CONFIGURATION
SET BUFFER POOL EXTENSION ON
(FILENAME = 'F:\SSDBUFFERPOOL.BPE',
SIZE = 50 GB)

--Lista as configurações do BPE
SELECT *
FROM sys.dm_os_buffer_pool_extension_configuration;

--Verificando quais páginas estão alocadas no BPE
SELECT *
FROM sys.dm_os_buffer_descriptors
WHERE is_in_bpool_extension = 1;

--Desabilitando o BPE
ALTER SERVER CONFIGURATION
SET BUFFER POOL EXTENSION OFF