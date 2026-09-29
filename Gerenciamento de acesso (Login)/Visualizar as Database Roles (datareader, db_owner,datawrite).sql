--	Query para visualizar as Database Roles (datareader, db_owner,datawrite). Deve executar em cada database separadamente.

SELECT p.name, p.type_desc, pp.name, pp.type_desc, pp.is_fixed_role 
FROM sys.database_role_members roles  
	JOIN sys.database_principals p ON roles.member_principal_id = p.principal_id 
	JOIN sys.database_principals pp ON roles.role_principal_id = pp.principal_id 
ORDER BY 1