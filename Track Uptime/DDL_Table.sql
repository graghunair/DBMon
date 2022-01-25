SET NOCOUNT ON
GO

USE [dba_local]
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Track_Instance_Restarts]
GO

CREATE TABLE [dbo].[tblDBMon_Track_Instance_Restarts](
	[ID]			BIGINT IDENTITY(1,1),
	[Date_Captured] DATETIME,
	[Last_Updated]	DATETIME,
	[SQLServer_Start_Time] DATETIME)

INSERT INTO [dbo].[tblDBMon_Track_Instance_Restarts] ([Date_Captured], [Last_Updated], [SQLServer_Start_Time])
SELECT	[sqlserver_start_time], GETDATE(), [sqlserver_start_time] FROM [sys].[dm_os_sys_info] 

SELECT	* 
FROM	[dbo].[tblDBMon_Track_Instance_Restarts]
GO
