/*
vamos consultar os logs de transação através da função fn_dblog e validar se houve registro deletado em uma determinada tabela e se positivo encontrar qual login foi o executor.

Observe o código abaixo, estou chamando a função fn_dblog com uma condição aplicada no meu where Operation = ‘LOP_DELETE_ROWS’
*/

use DATABASE
go
SELECT
     [Transaction ID],Operation, Context, AllocUnitName,*
FROM
    fn_dblog(NULL, NULL)
WHERE
	Operation = 'LOP_DELETE_ROWS'


/*

Agora vamos descobrir quem de fato executou o delete, observe que na imagem acima de retorno tem a primeira coluna chamada Transaction ID, pois bem, vamos precisar dela para identificar o login que gerou essa transação, executando o script abaixo

*/

SELECT Operation, [Transaction ID],[Begin Time],
[Transaction Name],[Transaction SID],*
FROM fn_dblog(NULL, NULL)
WHERE [Transaction ID] = '0000:006288df' -- Cole o transaction ID aqui
AND
[Operation] = 'LOP_BEGIN_XACT'
GO


/*

Begin Time.: Hora que ocorreu a transação no Arquivo de Log;

Transaction Name.: Que tipo de transação ocorreu

Observe o script abaixo onde utilizo o retorno da coluna Transaction SID, para poder descobrir de fato quem foi o login executor do delete
*/


SELECT SUSER_SNAME(0x69C58416721B93428B322EDE04BC22DD) as LoginName