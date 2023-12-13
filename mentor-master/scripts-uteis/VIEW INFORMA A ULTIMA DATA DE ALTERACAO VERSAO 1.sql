-- Informa a �ltima data de altera��o em uma view espec�fica

USE [AdventureWorks2019]
SELECT StartTime
       ,LoginName
       ,g.ObjectName
FROM   sys.traces t
       CROSS APPLY fn_trace_gettable(REVERSE(SUBSTRING(REVERSE(t.path),
                                                       CHARINDEX('\', REVERSE(t.path)), 
                                                       260)
                                             ) + N'log.trc', DEFAULT) g
WHERE  t.is_default = 1
       AND ObjectName LIKE '%vEmployee%'
       AND EventClass IN (46, -- Objeto Criado
                          47, --Objeto Apagado
                          164) --Objeto Alterado
-- Segunda parte
-- Lista a data de cria��o e altera��o dos objetos
-- Vamos precisar criar uma tabela no dbmanager e um job que rode diariamente e alimente essa tabela com essas informa��es.
SELECT [name]
      ,[id]
      ,[xtype]
      ,[crdate]
      ,[type]
      ,[userstat]
      ,[sysstat]
      ,[indexdel]
      ,[refdate]
      ,[deltrig]
      ,[instrig]
      ,[updtrig]
      ,[seltrig]
  FROM Master.[sys].[sysobjects]
  where type = 'V'
  ORDER BY 9 DESC;
GO