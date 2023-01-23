--Retorna apenas colunas não repetidads 
SELECT COUNT(*), COUNT(DISTINCT COLUM_NAME) FROM TABLE_NAME (NOLOCK)
-----------------------------------------------------

-- Criar indice

CREATE NONCLUSTERED INDEX NAME_INDEX ON Sales.SalesOrderHeader 
(CustomerID, SalesOrderID)
WITH(FILLFACTOR=90, DATA_COMPRESSION=PAGE)


-----------------------------------------------------