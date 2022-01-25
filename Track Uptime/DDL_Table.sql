SET NOCOUNT ON
GO

USE [dba_local]
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Track_Instance_Restarts]
GO

CREATE TABLE [dbo].[tblDBMon_Track_Instance_Restarts](
	[ID]			BIGINT IDENTITY(1,1),
	[SQLServer_Start_Time] DATETIME,
	[Last_Updated]	DATETIME,
	[Current]		BIT DEFAULT 1)

CREATE CLUSTERED INDEX IDX_tblDBMon_Track_Instance_Restarts ON [dbo].[tblDBMon_Track_Instance_Restarts]([ID])
GO

INSERT INTO [dbo].[tblDBMon_Track_Instance_Restarts] ([Last_Updated], [SQLServer_Start_Time], [Current])
SELECT	GETDATE(), [sqlserver_start_time], 1 FROM [sys].[dm_os_sys_info] 

SELECT	*, DATEDIFF(mi, [SQLServer_Start_Time], [Last_Updated]) AS UpTime_In_Minutes
FROM	[dbo].[tblDBMon_Track_Instance_Restarts]
GO
