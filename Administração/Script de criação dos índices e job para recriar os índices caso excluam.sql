/*
-- Para rodar esse Script tem que alterar o nome da base no Job e no in�cio do script.

-- Essa procedure deve ficar na base que deseja ter os �ndices customizados criados.

-- Esse Script cria uma procedure chamada stpCreate_Custom_Index e um Job chamado DBA - Recreate Deleted Indexes

-- Se quiser criar em v�rias bases, pode gerar a procedure nessa nova base e acrescentar manualmente no job. 

-- Se a vers�o n�o permitir compress�o de p�gina, retirar ", DATA_COMPRESSION=PAGE" essa parte do c�digo que gera o script de cria��o do �ndice.


*/

USE Curso_Protheus


IF OBJECT_ID('stpCreate_Custom_Index') is not null
	DROP PROCEDURE stpCreate_Custom_Index
GO

DECLARE @Query NVARCHAR(MAX)

SET @Query = '
CREATE PROCEDURE stpCreate_Custom_Index 
				AS
				BEGIN 
							
				'

SELECT 
	@Query = ' ' + @Query +
	
	' IF NOT EXISTS (SELECT I.name FROM sys.indexes I JOIN sys.tables T ON T.Object_id = I.Object_id ' +
	'WHERE I.name = ''' + I.name + ''' and T.name = ''' + T.name + ''')' +
	'BEGIN CREATE ' + 
    CASE WHEN I.is_unique = 1 THEN ' UNIQUE ' ELSE '' END  +  
    I.type_desc COLLATE DATABASE_DEFAULT +' INDEX ' +   
    I.name  + ' ON '  +  
    Schema_name(T.Schema_id)+'.'+T.name + ' ( ' + 
    KeyColumns + ' )  ' + 
    ISNULL(' INCLUDE ('+IncludedColumns+' ) ','') + 
    ISNULL(' WHERE  '+I.Filter_definition,'') + ' WITH (' +  
    'FILLFACTOR = '+CONVERT(VARCHAR(5),CASE WHEN I.Fill_factor = 0 THEN 100 ELSE I.Fill_factor END) + 
    ', DATA_COMPRESSION=PAGE ) ON [' + 
   DS.name + ' ] END '   
FROM sys.indexes I   
 JOIN sys.tables T ON T.Object_id = I.Object_id    
 JOIN sys.sysindexes SI ON I.Object_id = SI.id AND I.index_id = SI.indid   
 JOIN (SELECT * FROM (  
    SELECT IC2.object_id , IC2.index_id ,  
        STUFF((SELECT ' , ' + C.name + CASE WHEN MAX(CONVERT(INT,IC1.is_descending_key)) = 1 THEN ' DESC ' ELSE ' ASC ' END 
    FROM sys.index_columns IC1  
    JOIN sys.columns C   
       ON C.object_id = IC1.object_id   
       AND C.column_id = IC1.column_id   
       AND IC1.is_included_column = 0  
    WHERE IC1.object_id = IC2.object_id   
       AND IC1.index_id = IC2.index_id   
    GROUP BY IC1.object_id,C.name,index_id  
    ORDER BY MAX(IC1.key_ordinal)  
       FOR XML PATH('')), 1, 2, '') KeyColumns   
    FROM sys.index_columns IC2   
    --WHERE IC2.Object_id = object_id('Person.Address') --Comment for all tables  
    GROUP BY IC2.object_id ,IC2.index_id) tmp3 )tmp4   
  ON I.object_id = tmp4.object_id AND I.Index_id = tmp4.index_id  
 JOIN sys.stats ST ON ST.object_id = I.object_id AND ST.stats_id = I.index_id   
 JOIN sys.data_spaces DS ON I.data_space_id=DS.data_space_id   
 JOIN sys.filegroups FG ON I.data_space_id=FG.data_space_id   
 LEFT JOIN (SELECT * FROM (   
    SELECT IC2.object_id , IC2.index_id ,   
        STUFF((SELECT ' , ' + C.name  
    FROM sys.index_columns IC1   
    JOIN sys.columns C    
       ON C.object_id = IC1.object_id    
       AND C.column_id = IC1.column_id    
       AND IC1.is_included_column = 1   
    WHERE IC1.object_id = IC2.object_id    
       AND IC1.index_id = IC2.index_id    
    GROUP BY IC1.object_id,C.name,index_id   
       FOR XML PATH('')), 1, 2, '') IncludedColumns    
   FROM sys.index_columns IC2    
   --WHERE IC2.Object_id = object_id('Person.Address') --Comment for all tables   
   GROUP BY IC2.object_id ,IC2.index_id) tmp1   
   WHERE IncludedColumns IS NOT NULL ) tmp2    
ON tmp2.object_id = I.object_id AND tmp2.index_id = I.index_id   
WHERE I.is_primary_key = 0 AND I.is_unique_constraint = 0 

/*************   AQUI TEM QUE COLOCAR O PADRAO DE NOMES QUE UTILIZOU  *************/
	AND (I.name LIKE '%SK__[_]%' OR I.name LIKE 'W__%')
        AND I.name NOT IN ('TOP_VIEW01','TOP_VIEW02') --indices existentes no Protheus
/*************   AQUI TEM QUE COLOCAR O PADRAO DE NOMES QUE UTILIZOU  *************/

		SET @Query = @Query + ' 
		END'


EXEC sp_executesql @Query



GO
USE [msdb]
GO
IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'DBA - Recreate Deleted Indexes')
EXEC msdb.dbo.sp_delete_job @job_name=N'DBA - Recreate Deleted Indexes'   , @delete_unused_schedule=1

GO


BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 01/04/2018 10:44:00 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Recreate Deleted Indexes', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
	--	@notify_email_operator_name=N'DBA_Operator', 
		@job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CRIA �NDICES PROTHEUS]    Script Date: 01/04/2018 10:44:00 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'CRIA �NDICES PROTHEUS', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec stpCreate_Custom_Index', 
		@database_name=N'Curso_Protheus', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DI�RIO - 03:00', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180401, 
		@active_end_date=99991231, 
		@active_start_time=30000, 
		@active_end_time=235959, 
		@schedule_uid=N'2170cda3-ffd6-462e-bd54-565d450cfd3a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO