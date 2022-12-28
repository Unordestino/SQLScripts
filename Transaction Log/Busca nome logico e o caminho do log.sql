-- Busca o nome logico e o caminho dos arquivos de dados e log associados a database:

SELECT name, physical_name 
FROM sys.master_files 
WHERE database_id = DB_ID('DF');