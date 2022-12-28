-- Verificar se existe alguma conexão na database. Se existir, deve fazer matar com o KILL.

USE master  
Declare @SpId as varchar(5) 
if(OBJECT_ID('tempdb..#Processos') is not null) drop table #Processos 
select Cast(spid as varchar(5))SpId 
into #Processos 
from master.dbo.sysprocesses A 
 join master.dbo.sysdatabases B on A.DbId = B.DbId 
where B.Name ='TreinamentoDBA' 
-- Mata as conexões 
while (select count(*) from #Processos) >0 
begin 
 set @SpId = (select top 1 SpID from #Processos) 
   exec ('Kill ' +  @SpId) 
 delete from #Processos where SpID = @SpId 
end
-------------------------------------------------------------------------------------------------

-- Altera o status da database para OFFLINE:
ALTER DATABASE TreinamentoDBA SET OFFLINE

-------------------------------------------------------------------------------------------------

-- Busca o nome logico e o caminho dos arquivos de dados e log associados a database:
SELECT name, physical_name  
FROM sys.master_files  
WHERE database_id = DB_ID('TreinamentoDBA'); 
-- *.mdf 
ALTER DATABASE TreinamentoDBA MODIFY FILE ( NAME = TreinamentoDBA, FILENAME = 'C:\TEMP\TreinamentoDBA.mdf') 
-- *.ldf 
ALTER DATABASE TreinamentoDBA MODIFY FILE ( NAME = TreinamentoDBA_log, FILENAME = 'C:\TEMP\TreinamentoDBA_log.ldf')

-------------------------------------------------------------------------------------------------

--Altera o status da database para ONLINE:
ALTER DATABASE TreinamentoDBA SET ONLINE

-------------------------------------------------------------------------------------------------

----Deixa OFFLINE e derruba todos as conexões
USE MASTER 
GO 
ALTER DATABASE TreinamentoDBA SET OFFLINE WITH ROLLBACK IMMEDIATE

-------------------------------------------------------------------------------------------------

--BD modo único usuário 
USE MASTER; 
GO 
ALTER DATABASE TreinamentoDBA SET SINGLE_USER WITH ROLLBACK IMMEDIATE; 
GO

-------------------------------------------------------------------------------------------------

--BD modo apenas leitura
ALTER DATABASE TreinamentoDBA SET READ_ONLY; 
GO

-------------------------------------------------------------------------------------------------

--BD modo multiusuário
ALTER DATABASE TreinamentoDBA SET MULTI_USER; 
GO

-------------------------------------------------------------------------------------------------

--BD leitura e gravação
ALTER DATABASE TreinamentoDBA SET READ_WRITE; 
GO

-------------------------------------------------------------------------------------------------

--Verifica o tamanho dos logs nas bases de dados
DBCC SQLPERF(LOGSPACE)

-------------------------------------------------------------------------------------------------

-- Verifica o motivo do log não reduzir
SELECT name, log_reuse_wait_desc FROM sys.databases WHERE name = 'TABELA'

-------------------------------------------------------------------------------------------------