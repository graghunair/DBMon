USE [dba_local]
GO

SET NOCOUNT ON
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

						SELECT	TOP 10 *
						FROM	[dbo].[tblDBMon_Track_Instance_Restarts]
						ORDER BY [ID] DESC
	Modification:
		
			Jan 25th, 2022	:	Raghu		:	Inception
*/

DECLARE @varOld_SQLServer_Start_Time DATETIME,
		@varNew_SQLServer_Start_Time DATETIME 

SELECT	TOP 1 @varOld_SQLServer_Start_Time = [sqlserver_start_time]
FROM	[dbo].[tblDBMon_Track_Instance_Restarts]
ORDER BY [ID] DESC

SELECT	@varNew_SQLServer_Start_Time = [sqlserver_start_time]
FROM	[sys].[dm_os_sys_info]

IF (@varOld_SQLServer_Start_Time = @varNew_SQLServer_Start_Time)
	BEGIN
		PRINT 'SQL Server Instance restart not detected.'
		UPDATE	[dbo].[tblDBMon_Track_Instance_Restarts]
		SET		[Last_Updated] = GETDATE()
		WHERE	[SQLServer_Start_Time] = @varOld_SQLServer_Start_Time
	END
ELSE
	BEGIN
		PRINT 'SQL Server Instance restart detected.'
		INSERT INTO [dbo].[tblDBMon_Track_Instance_Restarts] (Date_Captured, Last_Updated, SQLServer_Start_Time)
		SELECT GETDATE(), GETDATE(), [SQLServer_Start_Time] FROM [sys].[dm_os_sys_info] 
	END
GO

EXEC	[dbo].[uspDBMon_Track_SQLServer_Instance_Restarts]
GO