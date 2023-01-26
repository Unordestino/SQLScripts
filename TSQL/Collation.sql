/*
Pode ser utilizado para alterar explicitamente a COLLATION de alguma coluna em uma query 

*/

SELECT * FROM Cliente 
WHERE Nm_Cliente COLLATE Latin1_General_CI_AS = 'luiz lima'