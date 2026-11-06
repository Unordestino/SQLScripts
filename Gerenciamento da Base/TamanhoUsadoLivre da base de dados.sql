USE
[NomeBanco]
GO

SELECT
    DB_NAME() AS NomeBanco,
    CAST(SUM(size) * 8.0 / 1024 / 1024 AS DECIMAL(18,2)) AS TamanhoTotalGB,
    CAST(SUM(FILEPROPERTY(name, 'SpaceUsed')) * 8.0 / 1024 / 1024 AS DECIMAL(18,2)) AS TotalUsedGB,
    CAST(
        (SUM(size) - SUM(FILEPROPERTY(name, 'SpaceUsed'))) * 8.0 / 1024 / 1024
        AS DECIMAL(18,2)
    ) AS TotalFreeGB,
    CAST(SUM(size) * 8.0 / 1024 / 1024 AS DECIMAL(18,2)) AS TamanhoTotalGB
FROM sys.database_files;
