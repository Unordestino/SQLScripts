/**********************************************************************
 Autor: Landry Duailibe

 Hands On: Plano de Execução
***********************************************************************/
USE AdventureWorks
go

/*******************
 Plano de Execução
********************/
-- Texto
SET STATISTICS IO ON
SET STATISTICS IO OFF

SET STATISTICS TIME ON
SET STATISTICS TIME OFF

SET STATISTICS PROFILE ON
SET STATISTICS PROFILE OFF

-- XML
SET STATISTICS XML ON
SET STATISTICS XML OFF

/*******************
 Plano Estimado
********************/
-- Texto
SET SHOWPLAN_ALL ON 
SET SHOWPLAN_ALL OFF

-- XML
SET SHOWPLAN_XML ON
SET SHOWPLAN_XML ON

/**************************
 Plano de Execução
***************************/
-- Texto
SET STATISTICS IO ON
SET STATISTICS IO OFF

SET STATISTICS TIME ON
SET STATISTICS TIME OFF

SET STATISTICS PROFILE ON
SET STATISTICS PROFILE OFF

-- XML
SET STATISTICS XML ON
SET STATISTICS XML OFF

/**************************
 Plano Estimado
***************************/
-- Texto
SET SHOWPLAN_ALL ON 
SET SHOWPLAN_ALL OFF

-- XML
SET SHOWPLAN_XML ON
SET SHOWPLAN_XML ON



SELECT h.SalesOrderID, h.OrderDate, h.[Status], 
h.CustomerID, p.FirstName, p.LastName
FROM AdventureWorks.Sales.Customer c
JOIN AdventureWorks.Sales.SalesOrderHeader h ON c.CustomerID = h.CustomerID
JOIN AdventureWorks.Person.Person p ON p.BusinessEntityID = c.PersonID
WHERE h.OrderDate = '20110531'
/*
Table 'Person'. Scan count 0, logical reads 140
Table 'Customer'. Scan count 0, logical reads 97
Table 'SalesOrderHeader'. Scan count 1, logical reads 142

Total IO: 379 x 8Kb = 3032 Kb = 2,96 MB
*/
