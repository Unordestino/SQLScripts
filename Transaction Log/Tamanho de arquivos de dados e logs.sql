--verificando tamanhos de arquivos de dados e log


select DB_NAME(dbid)bd, 
       CONVERT(VARCHAR, cast(cast(size*8 as decimal(10,2))/1024. as decimal(10,3))) + ' MB' AS Tamanho, 
	   STR (size * 8, 15, 0) + ' KB' tamanho_str, 
	   name,  
	   filename 
	   from sysaltfiles order by tamanho_str desc