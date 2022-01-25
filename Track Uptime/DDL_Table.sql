SET NOCOUNT ON
GO

--Change the database name if necessary
USE [dba_local]
GO

--Drop the table if already exists to accomodate any schema changes and start fresh
DROP TABLE IF EXISTS [dbo].[tblDBMon_Track_Instance_Restart]
GO

--Create the table to store historical information about SQL Server Instance restarts
CREATE TABLE [dbo].[tblDBMon_Track_Instance_Restart](
	[ID]					INT IDENTITY(1,1),
	[SQLServer_Start_Time]	DATETIME,
	[Last_Updated]			DATETIME,
	[Host]					NVARCHAR(128),
	[Current]				BIT)
GO

--Created clustered index on the ID column to sort it
CREATE CLUSTERED INDEX [IDX_tblDBMon_Track_Instance_Restart]
ON [dbo].[tblDBMon_Track_Instance_Restart]([ID])
GO

--Add the default constraint to auto-populate 1 for the column Current
ALTER TABLE [dbo].[tblDBMon_Track_Instance_Restart] 
ADD CONSTRAINT [DF_tblDBMon_Track_Instance_Restart_Currect] 
DEFAULT 1 FOR [Current]
GO

--Insert the first record into the table
INSERT INTO [dbo].[tblDBMon_Track_Instance_Restart] ([Last_Updated], [SQLServer_Start_Time], [Host], [Current])
SELECT	GETDATE(), [sqlserver_start_time], CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS NVARCHAR(128)), 1 
FROM	[sys].[dm_os_sys_info] 

--Select from the table
SELECT	*, DATEDIFF(mi, [SQLServer_Start_Time], [Last_Updated]) AS UpTime_In_Minutes
FROM	[dbo].[tblDBMon_Track_Instance_Restart]
GO
