USE [DBAInventory]
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
([SQL_Server_Instance] ASC))
GO

ALTER TABLE [inventory].[tblSQL_Servers] 
ADD  CONSTRAINT [DF_inventory_tblSQL_Servers_Is_Active]  
DEFAULT ((1)) FOR [Is_Active]
GO
ALTER TABLE [inventory].[tblSQL_Servers] 
ADD  CONSTRAINT [DF_inventory_tblSQL_Servers_Is_Production]  
DEFAULT ((1)) FOR [Is_Production]
GO
ALTER TABLE [inventory].[tblSQL_Servers] 
ADD  CONSTRAINT [DF_inventory_tblSQL_Servers_Date_Created]  
DEFAULT (getdate()) FOR [Date_Created]
GO

DROP TABLE IF EXISTS [load].[tblDBMon_Logins_With_Roles]
GO
CREATE TABLE [load].[tblDBMon_Logins_With_Roles](	
				[SQL_Server_Instance] SYSNAME, 
				[Login_Name] SYSNAME, 
				[Role_Name] SYSNAME, 
				[Date_Captured] DATETIME)

DROP TABLE IF EXISTS [load].[tblDBMon_Database_Users_With_Roles]
GO
CREATE TABLE [load].[tblDBMon_Database_Users_With_Roles](	
				[SQL_Server_Instance] SYSNAME, 
				[Database_Name] SYSNAME,
				[Database_Role] SYSNAME,
				[Database_User] SYSNAME,
				[Login_Name] SYSNAME,
				[Type_Desc] NVARCHAR(60),
				[Date_Captured] DATETIME)
GO
