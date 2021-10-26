USE [DBA_Inventory]
GO

CREATE SCHEMA [load] AUTHORIZATION [dbo]
GO
CREATE TABLE [load].[tblSQL_Server_Details](
	[Server_IP] [varchar](15) NOT NULL,
	[SQL_Server_Port] [int] NOT NULL,
	[Server_Name] [sysname] NULL,
	[Server_Host] [sysname] NULL,
	[Server_Domain] [varchar](256) NULL,
	[SQL_Server_Edition] [nvarchar](128) NULL,
	[SQL_Server_Version] [nvarchar](128) NULL,
	[OS_Version] [nvarchar](128) NULL,
	[Is_Clustered] [bit] NULL,
	[Is_Hadr_Enabled] [bit] NULL,
	[User_Databases_Count] [smallint] NULL,
	[Databases_Data_Size_GB] [decimal](10, 2) NULL,
	[Databases_TLog_Size_GB] [decimal](10, 2) NULL,
	[File_System_Storage] [xml] NULL,
	[CPU_Count] [smallint] NULL,
	[Physical_Memory_GB] [decimal](10, 2) NULL,
	[Committed_Target_GB] [decimal](10, 2) NULL,
	[Collation] [nvarchar](128) NULL,
	[Ad_Hoc_Distributed_Queries] [bit] NULL,
	[Backup_Compression_Default] [bit] NULL,
	[CLR_Enabled] [bit] NULL,
	[Filestream_Access_Level] [tinyint] NULL,
	[MAXDOP] [tinyint] NULL,
	[Optimize_for_ad_hoc_Workloads] [bit] NULL,
	[Xp_Cmdshell] [bit] NULL,
	[SQL_Server_Services] [xml] NULL,
	[SQL_Server_Start_Time] [datetime] NULL,
	[Script_Version] [xml] NULL,
	[Date_Captured] [datetime] NOT NULL,
 CONSTRAINT [PK_Load_tblSQL_Server_Details] PRIMARY KEY NONCLUSTERED 
(
	[Server_IP] ASC,
	[SQL_Server_Port] ASC
))
GO

ALTER TABLE [load].[tblSQL_Server_Details] ADD  CONSTRAINT [DF_load_tblSQL_Servers_Details_Date_Created]  DEFAULT (getdate()) FOR [Date_Captured]
GO