--	Tabelas vazias ainda
select *
from Traces..vwHistorico_Fragmentacao_Indice
order by avg_fragmentation_in_percent desc

--	Executar a procedure que acabamos de criar e que guarda as informações de fragmentação de índices nas tabelas 
exec Traces..stpCarga_Fragmentacao_Indice

--	Coloquem essa procedure em um Job no servidor

--	View onde vemos as informações dos índices fragmentados
select *
from Traces..vwHistorico_Fragmentacao_Indice
where Page_count > 1000
order by avg_fragmentation_in_percent desc

/******************************************************************************************************************************
--	Informações importantes dessa rotina de fragmentação de índices:
--	É com essas informações que crio minha rotina de REBUILD e REORGANIZE
--	Com essas informações diárias, conseguimos validar se um índice está se fragmentando muito rapidamente 
	e analisar uma possível alteração do FILLFACTOR desse índice.
*******************************************************************************************************************************/
