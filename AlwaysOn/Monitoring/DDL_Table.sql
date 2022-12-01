SET NOCOUNT ON
GO

USE [DBA_Admin]
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_AOAG_Database_Details]
GO
CREATE TABLE [dbo].[tblDBMon_AOAG_Database_Details](
	[Availability_Group_Name] [sysname] NULL,
	[Database_Name] [sysname] NULL,
	[Synchronization_State] [nvarchar](60) NULL,
	[Synchronization_Health] [nvarchar](60) NULL,
	[Log_Send_Queue_Size] [bigint] NULL,
	[Redo_Queue_Size] [bigint] NULL,
	[Date_Captured] [datetime] NULL)
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_AOAG_Primary_Replica]
GO
CREATE TABLE [dbo].[tblDBMon_AOAG_Primary_Replica](
	[Listener_Name] [sysname] NULL,
	[Listener_IP_Address] [varchar](15) NULL,
	[Listener_Port] [int] NULL,
	[Availability_Group_Name] [sysname] NULL,
	[Role] [nvarchar](60) NULL,
	[Replica_Name] [sysname] NULL,
	[Date_Captured] [datetime] NULL)
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Disk_Free_Space]
GO
CREATE TABLE [dbo].[tblDBMon_Disk_Free_Space](
	[SQL_Server_Name] [sysname] NULL,
	[Drive] [nvarchar](5) NULL,
	[Volume_Name] [nvarchar](256) NULL,
	[Total_Size_GB] [decimal](20, 2) NULL,
	[Free_Space_GB] [decimal](20, 2) NULL,
	[Percent_Free] [decimal](5, 2) NULL,
	[Date_Captured] [datetime] NULL) 
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Transaction_Log_Free_Space]
GO
CREATE TABLE [dbo].[tblDBMon_Transaction_Log_Free_Space](
	[SQL_Server_Name] [sysname] NULL,
	[Database_Name] [sysname] NOT NULL,
	[Log_Size_MB] [decimal](20, 2) NULL,
	[Log_Space_Used_%] [decimal](5, 2) NULL,
	[Date_Captured] [datetime] NULL)
GO
