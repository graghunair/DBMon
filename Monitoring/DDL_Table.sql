SET NOCOUNT ON
GO
USE [master]
GO
CREATE DATABASE [DBA_DBMon]
GO
ALTER DATABASE [DBA_DBMon] SET RECOVERY SIMPLE
GO
BACKUP DATABASE [DBA_DBMon] TO DISK = 'nul' WITH COMPRESSION
GO
ALTER DATABASE [DBA_DBMon] MODIFY FILE ( NAME = N'DBA_DBMon', SIZE = 2GB , FILEGROWTH = 64MB )
GO
ALTER DATABASE [DBA_DBMon] MODIFY FILE ( NAME = N'DBA_DBMon_log', SIZE = 1GB , FILEGROWTH = 64MB )
GO
USE [DBA_DBMon]
GO
ALTER AUTHORIZATION ON DATABASE::[DBA_DBMon] TO [sa]
GO
DROP SCHEMA IF EXISTS [load]
GO
CREATE SCHEMA [load] AUTHORIZATION [dbo]
GO

DROP TABLE IF EXISTS [load].[tblDBMon_TLog_Space_Usage]
GO
CREATE TABLE [load].[tblDBMon_TLog_Space_Usage](
	[Server_Name] [sysname] NULL,
	[Database_Name] [sysname] NOT NULL,
	[Log_Size_MB] [decimal](12, 2) NULL,
	[Log_Space_Used_Percent] [decimal](8, 2) NULL,
	[Log_Reuse_Wait_Desc] [nvarchar](60) NULL,
	[Recovery_Model] [nvarchar](60) NULL,
	[TLog_Backup_Mins_Ago] BIGINT NULL,
	[Date_Captured] [datetime]
)
GO

DROP TABLE IF EXISTS [load].[tblDBMon_Database_State]
GO
CREATE TABLE [load].[tblDBMon_Database_State](
	[Server_Name] [sysname] NULL,
	[Database_Name] [sysname] NOT NULL,
	[State] [nvarchar](60) NULL,
	[User_Access] [nvarchar](60) NULL,
	[Is_Read_Only] [bit] NULL,
	[Date_Captured] [datetime] NOT NULL
)
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Servers_Connection_Failed]
GO
CREATE TABLE [dbo].[tblDBMon_Servers_Connection_Failed](
	[ID] [smallint] IDENTITY(1,1),
	[Server_Name] [sysname] NULL,
	[Date_Captured] [datetime] DEFAULT GETDATE() NOT NULL
)
GO

DROP TABLE IF EXISTS [load].[tblDBMon_Disk_Space_Usage]
GO
CREATE TABLE [load].[tblDBMon_Disk_Space_Usage](
	[Server_Name] [sysname] NULL,
	[Drive] [nvarchar](5) NULL,
	[Volume_Name] [nvarchar](256) NULL,
	[Total_Size_GB] [decimal](20, 2) NULL,
	[Free_Space_GB] [decimal](20, 2) NULL,
	[Percent_Free] [decimal](5, 2) NULL,
	[Date_Captured] [datetime] DEFAULT GETDATE() NOT NULL
)
GO

SELECT * FROM [load].[tblDBMon_TLog_Space_Usage]
GO
SELECT * FROM [load].[tblDBMon_Database_State]
GO
SELECT * FROM [load].[tblDBMon_Disk_Space_Usage]
GO
SELECT * FROM [dbo].[tblDBMon_Servers_Connection_Failed]
GO

