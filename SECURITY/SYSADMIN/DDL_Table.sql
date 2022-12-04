USE [DBA_DBMon]
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Sys_Logins]
GO
CREATE TABLE [dbo].[tblDBMon_Sys_Logins](
	[IP_Address] [varchar](20) NULL,
	[Port] [int] NULL,
	[SQL_Server_Name] [sysname] NULL,
	[Login_Name] [sysname] NOT NULL,
	[Date_Created] [datetime] NULL,
	[Date_Updated] [datetime] NULL,
	[Deny_Login] [int] NULL,
	[Has_Access] [int] NULL,
	[Is_Windows_Login] [int] NULL,
	[Is_Windows_Group] [int] NULL,
	[Is_Windows_User] [int] NULL,
	[SYSADMIN] [int] NULL,
	[SECURITYADMIN] [int] NULL,
	[SERVERADMIN] [int] NULL,
	[SETUPADMIN] [int] NULL,
	[PROCESSADMIN] [int] NULL,
	[DISKADMIN] [int] NULL,
	[DBCREATOR] [int] NULL,
	[BULKADMIN] [int] NULL,
	[Date_Captured] [datetime] NOT NULL
)
GO

DROP SCHEMA IF EXISTS [inventory]
GO
CREATE SCHEMA [inventory]
GO
DROP TABLE IF EXISTS [inventory].[tblSQL_Servers]
GO
CREATE TABLE [inventory].[tblSQL_Servers](
	[SQL_Server_Instance] [nvarchar](128) NOT NULL,
	[Is_Active] [bit] NOT NULL,
	[Is_Active_Desc] [varchar](2000) NULL,
	[Is_Production] [bit] NOT NULL,
	[Application] [varchar](100) NULL,
	[Owner] [varchar](100) NULL,
	[Date_Created] [datetime] NOT NULL,
 CONSTRAINT [PK_tblSQL_Servers] PRIMARY KEY CLUSTERED 
(
	[SQL_Server_Instance] ASC
))
GO

ALTER TABLE [inventory].[tblSQL_Servers] ADD  CONSTRAINT [DF_inventory_tblSQL_Servers_Is_Active]  DEFAULT ((1)) FOR [Is_Active]
GO
ALTER TABLE [inventory].[tblSQL_Servers] ADD  CONSTRAINT [DF_inventory_tblSQL_Servers_Is_Production]  DEFAULT ((1)) FOR [Is_Production]
GO
ALTER TABLE [inventory].[tblSQL_Servers] ADD  CONSTRAINT [DF_inventory_tblSQL_Servers_Date_Created]  DEFAULT (getdate()) FOR [Date_Created]
GO


