/* Pirmeiro vamos crias as tabelas */

------------------------------------------------------------------------------------------------------

USE [Traces]
GO

/****** Object:  Table [dbo].[CheckHistory_Backups_Executados]    Script Date: 2/9/2023 8:52:09 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[CheckHistory_Backups_Executados](
	[Database_Name] [varchar](128) NULL,
	[Name] [varchar](128) NULL,
	[Backup_Start_Date] [datetime] NULL,
	[Tempo_Min] [int] NULL,
	[Position] [int] NULL,
	[Server_Name] [varchar](128) NULL,
	[Recovery_Model] [varchar](60) NULL,
	[Logical_Device_Name] [varchar](128) NULL,
	[Device_Type] [tinyint] NULL,
	[Type] [char](1) NULL,
	[Tamanho_MB] [numeric](15, 2) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

------------------------------------------------------------------------------------------------------

/* Agora vamos cria a procedure */

------------------------------------------------------------------------------------------------------

USE [Traces]
GO

/****** Object:  StoredProcedure [dbo].[stpCheckHistory_Backups_Executados]    Script Date: 2/9/2023 8:54:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

	
/*******************************************************************************************************************************
--	5) Backups Executados
*******************************************************************************************************************************/
CREATE PROCEDURE [dbo].[stpCheckHistory_Backups_Executados]
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @Dt_Referencia DATETIME
	SELECT @Dt_Referencia = GETDATE()
	
	INSERT INTO [dbo].[CheckHistory_Backups_Executados] (	[Database_Name], [Name], [Backup_Start_Date], [Tempo_Min], [Position], [Server_Name],
														[Recovery_Model], [Logical_Device_Name], [Device_Type], [Type], [Tamanho_MB] )
	SELECT	[database_name], [name], [backup_start_date], DATEdiff(mi, [backup_start_date], [backup_finish_date]) AS [Tempo_Min], 
			[position], [server_name], [recovery_model], isnull([logical_device_name], ' ') AS [logical_device_name],
			[device_type], [type], CAST([backup_size]/1024/1024 AS NUMERIC(15,2)) AS [Tamanho (MB)]
	FROM [msdb].[dbo].[backupset] B
		JOIN [msdb].[dbo].[backupmediafamily] BF ON B.[media_set_id] = BF.[media_set_id]
	WHERE [backup_start_date] >= DATEADD(hh, -24 ,@Dt_Referencia) AND [type] in ('D','I')
		  
	IF (@@ROWCOUNT = 0)
	BEGIN
		INSERT INTO [dbo].[CheckHistory_Backups_Executados] (	[Database_Name], [Name], [Backup_Start_Date], [Tempo_Min], [Position], [Server_Name],
															[Recovery_Model], [Logical_Device_Name], [Device_Type], [Type], [Tamanho_MB] )
		SELECT 'Sem registro de Backup FULL ou Diferencial nas últimas 24 horas.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	END
END

GO


------------------------------------------------------------------------------------------------------

/* Realize alguns teste */

------------------------------------------------------------------------------------------------------
-- Execute a procedure de forma manual
EXEC [dbo].[stpCheckHistory_Backups_Executados]

-- Realize um select na tabela criada
SELECT TOP 100 * FROM CheckHistory_Backups_Executados ORDER BY Backup_Start_Date DESC

-- Agora é só criar um job para executar a procedure stpCheckHistory_Backups_Executados


------------------------------------------------------------------------------------------------------

/* Script limpa historico mais antigos que 3 meses */

------------------------------------------------------------------------------------------------------
--adicione esse script em um job

	use Traces
	declare  @CheckHistory_Backups_Executados int 
	select  
	@CheckHistory_Backups_Executados = 90 
	select * from CheckHistory_Backups_Executados
	where Backup_Start_Date <  DATEADD(dd,@CheckHistory_Backups_Executados*-1,getdate()) 