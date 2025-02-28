--verificando tamanhos de arquivos de dados e log


SELECT 
    DB_NAME(dbid) AS bd, 
    CONVERT(VARCHAR, CAST(CAST(CAST(size AS BIGINT) * 8 AS DECIMAL(19, 4)) / 1024.0 AS DECIMAL(19, 4))) + ' MB' AS Tamanho, 
    STR(CAST(size AS BIGINT) * 8, 15, 0) + ' KB' AS tamanho_str, 
    name,  
    filename 
FROM sysaltfiles 
ORDER BY CAST(size AS BIGINT) * 8 DESC;
