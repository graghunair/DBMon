SET NOCOUNT ON
GO

USE [dba_local]
GO

DROP PROC IF EXISTS [dbo].[uspDBMon_Track_SQLServer_Instance_Restarts]
GO
CREATE PROC [dbo].[uspDBMon_Track_SQLServer_Instance_Restarts]
AS
SET NOCOUNT ON
/*
	Date		:		Jan 25th, 2022
	Purpose		:		Track SQL Server instance restarts and record it in the table:
	Version		:		1.0
	Execute		:
						EXEC [dbo].[uspDBMon_Track_SQLServer_Instance_Restarts]

						SELECT	TOP 10 *, DATEDIFF(mi, [SQLServer_Start_Time], [Last_Updated]) AS UpTime_In_Minutes
						FROM	[dbo].[tblDBMon_Track_Instance_Restarts]
						ORDER BY [ID] DESC
	Modification:
		
			Jan 25th, 2022	:	Raghu		:	Inception
*/

DECLARE @varOld_SQLServer_Start_Time DATETIME,
		@varNew_SQLServer_Start_Time DATETIME 

SELECT	@varOld_SQLServer_Start_Time = [sqlserver_start_time]
FROM	[dbo].[tblDBMon_Track_Instance_Restarts]
WHERE	[Current] = 1

SELECT	@varNew_SQLServer_Start_Time = [sqlserver_start_time]
FROM	[sys].[dm_os_sys_info]

IF (@varOld_SQLServer_Start_Time = @varNew_SQLServer_Start_Time)
	BEGIN
		PRINT 'SQL Server Instance restart not detected.'
		UPDATE	[dbo].[tblDBMon_Track_Instance_Restarts]
		SET		[Last_Updated] = GETDATE()
		WHERE	[Current] = 1
	END
ELSE
	BEGIN
		PRINT 'SQL Server Instance restart detected.'

		UPDATE	[dbo].[tblDBMon_Track_Instance_Restarts] 
		SET		[Current] = 0
		WHERE	[Current] = 1

		INSERT INTO [dbo].[tblDBMon_Track_Instance_Restarts] ([Last_Updated], [SQLServer_Start_Time])
		SELECT GETDATE(), [SQLServer_Start_Time] FROM [sys].[dm_os_sys_info] 
	END
GO

EXEC	[dbo].[uspDBMon_Track_SQLServer_Instance_Restarts]
GO
