--	Query para retornar as permissões que são dadas a nível de objetos (Mt bacana!)
SELECT	STATE_DESC,prmssn.permission_name AS [Permission], sp.type_desc, sp.name, 
		grantor_principal.name AS [Grantor], grantee_principal.name AS [Grantee] 
FROM sys.all_objects AS sp 
	INNER JOIN sys.database_permissions AS prmssn ON prmssn.major_id = sp.object_id AND prmssn.minor_id = 0 AND prmssn.class = 1 
	INNER JOIN sys.database_principals AS grantor_principal ON grantor_principal.principal_id = prmssn.grantor_principal_id 
	INNER JOIN sys.database_principals AS grantee_principal ON grantee_principal.principal_id = prmssn.grantee_principal_id 
WHERE grantee_principal.name = 'Fabricio'