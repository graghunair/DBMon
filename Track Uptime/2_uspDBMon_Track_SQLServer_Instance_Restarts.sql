SET NOCOUNT ON
GO

--Change the database name if necessary
USE [dba_local]
GO

--Drop the procedure if exists to accomodate the changes.
DROP PROC IF EXISTS [dbo].[uspDBMon_Track_SQLServer_Instance_Restart]
GO
CREATE PROC [dbo].[uspDBMon_Track_SQLServer_Instance_Restart]
AS
SET NOCOUNT ON
/*
	Date		:		Jan 25th, 2022
	Purpose		:		Track SQL Server instance restarts and record it in the table:[dbo].[tblDBMon_Track_Instance_Restart]
	Version		:		1.0
	Execute		:
						EXEC [dbo].[uspDBMon_Track_SQLServer_Instance_Restart]

						SELECT	TOP 10 *, DATEDIFF(mi, [SQLServer_Start_Time], [Last_Updated]) AS UpTime_In_Minutes
						FROM	[dbo].[tblDBMon_Track_Instance_Restart]
						ORDER BY [ID] DESC
	Modification:	
			Jan 25th, 2022	:	Raghu		:	Inception
*/

DECLARE @varOld_SQLServer_Start_Time DATETIME,
		@varNew_SQLServer_Start_Time DATETIME 

--Get the last time SQL Server instance restart was recorded
SELECT	@varOld_SQLServer_Start_Time = [SQLServer_Start_Time]
FROM	[dbo].[tblDBMon_Track_Instance_Restart]
WHERE	[Current] = 1

--Get the currect SQL Server instance restart from DMV
SELECT	@varNew_SQLServer_Start_Time = [sqlserver_start_time]
FROM	[sys].[dm_os_sys_info]

--Compare the 2 timestamp to identify whether an instance restart has occurred
IF (@varOld_SQLServer_Start_Time = @varNew_SQLServer_Start_Time)
	BEGIN
		PRINT 'SQL Server Instance restart not detected.'
		UPDATE	[dbo].[tblDBMon_Track_Instance_Restart]
		SET		[Last_Updated] = GETDATE()
		WHERE	[Current] = 1
	END
ELSE
	BEGIN
		PRINT 'SQL Server Instance restart detected.'

		UPDATE	[dbo].[tblDBMon_Track_Instance_Restart] 
		SET		[Current] = 0
		WHERE	[Current] = 1

		INSERT INTO [dbo].[tblDBMon_Track_Instance_Restart] ([Last_Updated], [SQLServer_Start_Time])
		SELECT	GETDATE(), [sqlserver_start_time]
		FROM	[sys].[dm_os_sys_info]
	END
GO

EXEC	[dbo].[uspDBMon_Track_SQLServer_Instance_Restart]
GO
