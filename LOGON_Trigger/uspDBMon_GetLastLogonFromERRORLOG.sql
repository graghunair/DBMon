/*
	Date			:	11th May 2025
	Purpose			:	This script creates 1 User-Table, 1 Stored Procedure and 1 SQL Agent Job to 
						capture last successful and failed logon events logged in the SQL ERRORLOG.
	Prerequisite	:	"Both Failed and Successful Logins" should be enabled under Server Properties/Security Tab/Login Auditing
						Setup a SQL Agent Job to enable execute sp_cycle_errorlog nightly
						Increase the ERRORLOG file count to 35

	Version			:	1.0             
	License:
						This script is provided "AS IS" with no warranties, and confers no rights.	

						EXEC [dbo].[uspDBMon_GetLastLogonFromERRORLOG]           
						SELECT * FROM [dbo].[tblDBMon_Last_Logon_From_ERRORLOG]  
			
	Modification History    
	-----------------------    
	May 11th, 2025    :    v1.0    :    Raghu Gopalakrishnan    :    Inception
*/

SET NOCOUNT ON

USE [dba_local]
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Last_Logon_From_ERRORLOG]
GO
CREATE TABLE [dbo].[tblDBMon_Last_Logon_From_ERRORLOG](
	[Log_Date] DATETIME NOT NULL,
	[Status] VARCHAR(9) NOT NULL,
	[User] SYSNAME NULL,
	[Date_Updated] DATETIME)

CREATE CLUSTERED INDEX IDX_tblDBMon_Last_Logon_From_ERRORLOG_User ON [dbo].[tblDBMon_Last_Logon_From_ERRORLOG]([User])
GO

DROP PROC IF EXISTS [dbo].[uspDBMon_GetLastLogonFromERRORLOG]
GO
CREATE PROC [dbo].[uspDBMon_GetLastLogonFromERRORLOG]
AS
SET NOCOUNT ON
DECLARE @varCounter INT, @varSQL_Text VARCHAR(1000)
DECLARE @tblERRORLOG_Count TABLE([ID] INT, [Date] DATETIME, [LogFileSize] INT)
DECLARE @tblERRORLOG TABLE([Log_Date] DATETIME, [ProcessInfo] VARCHAR(200), [Text] VARCHAR(MAX))
DECLARE @tblLogin_Status TABLE([Log_Date] DATETIME, [Status] VARCHAR(9), [User] SYSNAME)

INSERT INTO @tblERRORLOG_Count 
EXEC xp_enumerrorlogs 

SELECT @varCounter = MIN([ID]) from @tblERRORLOG_Count

WHILE (@varCounter is not null)
	BEGIN
		SELECT @varSQL_Text = 'exec xp_readerrorlog ' + CAST(@varCounter AS VARCHAR) + ', 1, "Login succeeded for user"'
		--PRINT @varSQL_Text
		INSERT INTO @tblERRORLOG
		EXEC (@varSQL_Text)

		SELECT @varSQL_Text = 'exec xp_readerrorlog ' + cast(@varCounter AS VARCHAR) + ', 1, "Login failed for user"'
		--PRINT @varSQL_Text
		INSERT INTO @tblERRORLOG
		EXEC (@varSQL_Text)
		
		SELECT @varCounter = MIN([ID]) from @tblERRORLOG_Count WHERE [ID] > @varCounter 
	END

INSERT INTO @tblLogin_Status
SELECT	[Log_Date],
		'Succeeded' AS [Status],
		SUBSTRING(
					[Text],
					CHARINDEX('Login succeeded for user ''', [Text]) + 26,
					CHARINDEX('''.', [Text]) - 27
				) AS [User]
FROM	@tblERRORLOG
WHERE	[Text] LIKE 'Login succeeded for user%'

INSERT INTO @tblLogin_Status
SELECT	[Log_Date],
		'Failed' AS [Status],
		SUBSTRING(
					[Text],
					CHARINDEX('Login failed for user ''', [Text]) + 23,
					CHARINDEX('''.', [Text]) - 24
				) AS [User]
FROM	@tblERRORLOG
WHERE	[Text] LIKE 'Login failed for user%'

;WITH cteLogin_Status AS
	(
		SELECT		MAX([Log_Date]) AS [Log_Date], [Status], [User]
		FROM		@tblLogin_Status
		GROUP BY	[Status], [User]
	)

MERGE [dbo].[tblDBMon_Last_Logon_From_ERRORLOG] AS [Target]
USING cteLogin_Status AS [Source]
ON ([Target].[User] = [Source].[User]
AND [Target].[Status] = [Source].[Status] )
WHEN MATCHED 
	THEN
		UPDATE 
		SET 
			[Target].[Log_Date] = [Source].[Log_Date],
			[Target].[Date_Updated] = GETDATE()
WHEN NOT MATCHED BY TARGET 
	THEN
		INSERT ([Log_Date], [Status], [User], [Date_Updated])
		VALUES ([Source].[Log_Date], [Source].[Status], [Source].[User], GETDATE());
GO

EXEC [dbo].[uspDBMon_GetLastLogonFromERRORLOG]
GO
SELECT * FROM [dbo].[tblDBMon_Last_Logon_From_ERRORLOG] ORDER BY 1
GO

/*
	Create SQL Agent Job
*/

USE [msdb]
GO

IF EXISTS (SELECT TOP 1 1 FROM msdb.dbo.sysjobs WHERE [name] = N'DBA - DBMon - GetLastLogonFromERRORLOG')
	BEGIN
		EXEC msdb.dbo.sp_delete_job @job_name = N'DBA - DBMon - GetLastLogonFromERRORLOG'
	END
GO

/****** Object:  Job [DBA - DBMon - GetLastLogonFromERRORLOG]    ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [DBA]    ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'DBA' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'DBA'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - DBMon - GetLastLogonFromERRORLOG', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'DBA', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [uspDBMon_GetLastLogonFromERRORLOG]    ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'uspDBMon_GetLastLogonFromERRORLOG', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [dbo].[uspDBMon_GetLastLogonFromERRORLOG]', 
		@database_name=N'dba_local', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Nightly', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20250511, 
		@active_end_date=99991231, 
		@active_start_time=11010, 
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

USE [msdb]
GO
EXEC sp_start_job @job_name =  N'DBA - DBMon - GetLastLogonFromERRORLOG'
GO


