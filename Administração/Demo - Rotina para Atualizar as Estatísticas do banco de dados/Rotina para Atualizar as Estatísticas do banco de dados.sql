/*
Recomendado criar um job diário que executa as 22:40.
Seguindo a recomendação o script vai ser exexutado de 22:40 ~~ 23:50

Informação: Essa rotina apenas atualiza as estatísticas de uma base de dados banco de dados por job

*/


CREATE PROCEDURE [dbo].[stpAtualiza_Estatisticas]
As
BEGIN

SET NOCOUNT ON
-- Sai da rotina quando a janela de manutenção é finalizada
IF GETDATE()> dateadd(mi,+50,dateadd(hh,+23,cast(floor(cast(getdate()as float))as datetime)))-- hora > 23:50
BEGIN
RETURN
END

Create table #Atualiza_Estatisticas(
Id_Estatistica int identity(1,1),
Ds_Comando varchar(4000),
Nr_Linha int)

;WITH Tamanho_Tabelas AS (
SELECT obj.name, prt.rows
FROM sys.objects obj
JOIN sys.indexes idx on obj.object_id= idx.object_id
JOIN sys.partitions prt on obj.object_id= prt.object_id
JOIN sys.allocation_units alloc on alloc.container_id= prt.partition_id
WHERE obj.type= 'U' AND idx.index_id IN (0, 1)and prt.rows> 1000
GROUP BY obj.name, prt.rows)

insert into #Atualiza_Estatisticas(Ds_Comando,Nr_Linha)
SELECT 'UPDATE STATISTICS ' + B.name+ ' ' + A.name+ ' WITH FULLSCAN', D.rows
FROM sys.stats A
join sys.sysobjects B on A.object_id = B.id
join sys.sysindexes C on C.id = B.id and A.name= C.Name
join sys.sysusers U on U.uid = B.uid
JOIN Tamanho_Tabelas D on B.name= D.Name
WHERE U.name = 'dbo'
and C.rowmodctr > 100
and C.rowmodctr> D.rows*.005
and substring( B.name,1,3) not in ('sys','dtp')
ORDER BY D.rows

declare @Loop int, @Comando nvarchar(4000)
set @Loop = 1

while exists(select top 1 null from #Atualiza_Estatisticas)
begin

IF GETDATE()> dateadd(mi,+50,dateadd(hh,+23,cast(floor(cast(getdate()as float))as datetime)))-- hora > 23:50 am
BEGIN
BREAK -- Sai do loop quando acabar a janela de manutenção
END

select @Comando = Ds_Comando
from #Atualiza_Estatisticas
where Id_Estatistica = @Loop

EXECUTE sp_executesql @Comando

delete from #Atualiza_Estatisticas
where Id_Estatistica = @Loop

set @Loop= @Loop + 1
end
END