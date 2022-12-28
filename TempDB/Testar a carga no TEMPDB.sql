 ----- Arquivo para testar a carga no TEMPDB
--drop table #StressTempDB
 
 
 SELECT TOP 1000000000
        IDENTITY(INT,1,1) AS RowNum
   INTO #StressTempDB
   FROM master.sys.all_columns ac1,
        master.sys.all_columns ac2,
        master.sys.all_columns ac3;
GO