USE [NewDiskDB]        
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_DM_OS_Performance_Counters]
GO
CREATE TABLE [dbo].[tblDBMon_DM_OS_Performance_Counters](
	[Date_Captured] [datetime] NOT NULL,
	[Object_Name] [nchar](128) NOT NULL,
	[Counter_Name] [nchar](128) NOT NULL,
	[Instance_Name] [nchar](128) NULL,
	[Counter_Value] [bigint] NOT NULL
)
GO

CREATE CLUSTERED INDEX [IDX_tblDBMon_DM_OS_Performance_Counters_Date_Captured] 
ON [dbo].[tblDBMon_DM_OS_Performance_Counters] ([Date_Captured] ASC)
GO

ALTER TABLE [dbo].[tblDBMon_DM_OS_Performance_Counters]
ADD CONSTRAINT DF_tblDBMon_DM_OS_Performance_Counters_Date_Captured
DEFAULT GETDATE() FOR [Date_Captured];
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_GetDMOSPerformanceCounters]
GO

CREATE PROCEDURE [dbo].[uspDBMon_GetDMOSPerformanceCounters]
AS

SET NOCOUNT ON

	INSERT INTO [dbo].[tblDBMon_DM_OS_Performance_Counters] ([Object_Name], [Counter_Name], [Instance_Name], [Counter_Value])
	SELECT	[object_name], [counter_name], [instance_name], [cntr_value] 
	FROM	[sys].[dm_os_performance_counters]
	WHERE	[object_name] LIKE '%Databases%'
	AND		[counter_name] = 'Transactions/sec'

	INSERT INTO [dbo].[tblDBMon_DM_OS_Performance_Counters] ([Object_Name], [Counter_Name], [Instance_Name], [Counter_Value])
	SELECT	[object_name], [counter_name], [instance_name], [cntr_value] 
	FROM	[sys].[dm_os_performance_counters]
	WHERE	[object_name] LIKE '%Buffer Manager%'
	AND		[counter_name] = 'Page life expectancy'

	INSERT INTO [dbo].[tblDBMon_DM_OS_Performance_Counters] ([Object_Name], [Counter_Name], [Instance_Name], [Counter_Value])
	SELECT	[object_name], [counter_name], [instance_name], [cntr_value] 
	FROM	[sys].[dm_os_performance_counters]
	WHERE	[object_name] LIKE '%Databases%'
	AND		[counter_name] = 'Log Bytes Flushed/sec'
	
	INSERT INTO [dbo].[tblDBMon_DM_OS_Performance_Counters] ([Object_Name], [Counter_Name], [Instance_Name], [Counter_Value])
	SELECT	[object_name], [counter_name], [instance_name], [cntr_value] 
	FROM	[sys].[dm_os_performance_counters]
	WHERE	[object_name] LIKE '%SQL Statistics%'
	AND		[counter_name] = 'Batch Requests/sec'

	INSERT INTO [dbo].[tblDBMon_DM_OS_Performance_Counters] ([Object_Name], [Counter_Name], [Instance_Name], [Counter_Value])
	SELECT	[object_name], [counter_name], [instance_name], [cntr_value] 
	FROM	[sys].[dm_os_performance_counters]
	WHERE	[object_name] LIKE '%SQL Statistics%'
	AND		[counter_name] = 'SQL Compilations/sec'  

	INSERT INTO [dbo].[tblDBMon_DM_OS_Performance_Counters] ([Object_Name], [Counter_Name], [Instance_Name], [Counter_Value])
	SELECT	[object_name], [counter_name], [instance_name], [cntr_value] 
	FROM	[sys].[dm_os_performance_counters]
	WHERE	[object_name] LIKE '%SQL Statistics%'
	AND		[counter_name] = 'SQL Re-Compilations/sec'

	DELETE TOP (10000)
	FROM		[dbo].[tblDBMon_DM_OS_Performance_Counters]
	WHERE		Date_Captured < GETDATE() - 100
GO

EXEC [dbo].[uspDBMon_GetDMOSPerformanceCounters]
GO
SELECT * FROM [dbo].[tblDBMon_DM_OS_Performance_Counters]
GO

--Create SQL Agent Job
USE [msdb]
GO

IF EXISTS (SELECT TOP 1 1 FROM msdb.dbo.sysjobs WHERE [name] = N'DBA - DBMon - Get DM_OS_Performance_Counters')
	BEGIN
		EXEC msdb.dbo.sp_delete_job @job_name=N'DBA - DBMon - Get DM_OS_Performance_Counters', @delete_unused_schedule=1
	END
GO


BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'DBMon' AND category_class=1)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'DBMon'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - DBMon - Get DM_OS_Performance_Counters', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'DBMon', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'[dbo].[uspDBMon_GetDMOSPerformanceCounters]', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [dbo].[uspDBMon_GetDMOSPerformanceCounters]', 
		@database_name=N'NewDiskDB', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 5 Mins', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20260429, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959		
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


