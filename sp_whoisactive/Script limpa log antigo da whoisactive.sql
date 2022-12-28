/* 
Deleta todos os dados da tabela Resultado_WhoisActive que tenha mais de 10 dias
*/

create procedure stpExclui_Registros_Antigos 
AS 
BEGIN 
	declare  @Resultado_WhoisActive int 
	select  
	@Resultado_WhoisActive = 10	 

	delete from Resultado_WhoisActive 
	where Dt_Log <  DATEADD(dd,@Resultado_WhoisActive*-1,getdate())
END

----------------------------------------------------------------------------------------------
-- Procedure que deleta os dados de algumas demos

USE [Traces] 
GO 
/****** Object:  StoredProcedure [dbo].[stpDelete_Old_Data]    Script Date: 27/12/2022 07:59:28 ******/ 
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
create procedure [dbo].[stpDelete_Old_Data] 
AS 
BEGIN 
	declare @Log_Counter int, @Log_Whoisactive int, @Table_Size_History int, --@Acesso_A_Disco int, 
			@Index_Utilization_History int, @Index_Fragmentation_History int, @Queries_Profile INT, 
			@Waits_Stats_History int, @File_Utilization_History INT, @Log_DB_Error int,@Log_DB_Mirror int, 
			@Log_IO_Pending int,@Log_DeadLock int,@Log_AlwaysOn_AG int,@Log_Rebuild_Index int 
	--Parameterization	 
	select  
		@Log_Counter = 60, 
		@Log_Whoisactive = 7, 
		@Table_Size_History = 180, 
		@Index_Utilization_History = 90, 
		@Index_Fragmentation_History = 60, 
		@Queries_Profile = 60, 
		@File_Utilization_History = 45, 
		@Log_DB_Error = 7, 
		@Log_DB_Mirror = 45, 
		@Waits_Stats_History = 7, 
		@Log_IO_Pending = 45, 
		@Log_DeadLock = 45	, 
		@Log_AlwaysOn_AG = 45, 
		@Log_Rebuild_Index = 90 
	if OBJECT_ID('Log_Rebuild_Index') is not null 
		delete from Log_Rebuild_Index 
		where Dt_Operation < DATEADD(dd,@Log_Rebuild_Index*-1,getdate()) 
	if OBJECT_ID('Log_AlwaysOn_AG') is not null 
		delete from Log_AlwaysOn_AG 
		where Dt_Log < DATEADD(dd,@Log_AlwaysOn_AG*-1,getdate()) 
	if OBJECT_ID('Log_DeadLock') is not null 
		delete from Log_DeadLock 
		where eventDate < DATEADD(dd,@Log_DeadLock*-1,getdate()) 
	if OBJECT_ID('Log_DB_Error') is not null 
		delete from Log_DB_Error 
		where Dt_Error < DATEADD(dd,@Log_DB_Error*-1,getdate()) 
	if OBJECT_ID('Log_DB_Mirror') is not null 
		delete from Log_DB_Mirror 
		where Dt_Log < DATEADD(dd,@Log_DB_Mirror*-1,getdate()) 
	if OBJECT_ID('Index_Fragmentation_History') is not null 
		delete from Index_Fragmentation_History 
		where Dt_Log <  DATEADD(dd,@Index_Fragmentation_History*-1,getdate()) 
	if OBJECT_ID('Queries_Profile') is not null 
		delete from Queries_Profile 
		where StartTime <  DATEADD(dd,@Queries_Profile*-1,getdate()) 
	delete from Waits_Stats_History 
	where Dt_Log < DATEADD(dd,@Waits_Stats_History*-1,getdate())	 
	delete from Log_IO_Pending 
	where Dt_Log < DATEADD(dd,@Log_IO_Pending*-1,getdate())		 
	delete from Log_Counter 
	where Dt_Log <  DATEADD(dd,@Log_Counter*-1,getdate()) 
	delete from Log_Whoisactive 
	where Dt_Log <  DATEADD(dd,@Log_Whoisactive*-1,getdate()) 
	delete from Table_Size_History 
	where Dt_Log <  DATEADD(dd,@Table_Size_History*-1,getdate()) 
	delete from File_Utilization_History 
	where Dt_Log <  DATEADD(dd,@File_Utilization_History*-1,getdate())	 
END