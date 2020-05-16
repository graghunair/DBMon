/*
		Name		:		Periodically review accounts with sysadmin privileges
		Date		:		17th May 2020
		Purpose		:		Create database, user tables and stored procedure to help with the DBMon module
							to review accounts with sysadmin privileges across SQL Servers in the environment.
*/

SET NOCOUNT ON

/* 
	--Create a user database called 'DBA_DBMon' to host user objects used by DBMon module.
	CREATE DATABASE [DBA_DBMon]
	GO
	ALTER DATABASE [DBA_DBMon] SET RECOVERY SIMPLE
	GO
	USE [master]
	GO
	ALTER DATABASE [DBA_DBMon] MODIFY FILE ( NAME = N'DBA_DBMon', SIZE = 1GB , FILEGROWTH = 0)
	GO
	ALTER DATABASE [DBA_DBMon] MODIFY FILE ( NAME = N'DBA_DBMon_log', SIZE = 1GB , FILEGROWTH = 0)
	GO
*/

USE [DBA_DBMon]
GO
DROP TABLE IF EXISTS [dbo].[tblSysadmin_Accounts] 
GO
DROP TABLE IF EXISTS [dbo].[tblSQL_Servers] 
GO
CREATE TABLE [dbo].[tblSQL_Servers] (
				[Server_ID] TINYINT IDENTITY(1,1) NOT NULL, 
				[Server_Name] SYSNAME NOT NULL, 
				[Is_Active] BIT NOT NULL, 
				[IP_Address] VARCHAR(255) NULL,
				[Port] INT NULL,
				[FCI_Cluster] BIT NULL,
				[HADR_Enabled] BIT NULL,
				[Build] VARCHAR(20) NULL,
				[Version] VARCHAR(255) NULL,
				[Product_Level] VARCHAR(50) NULL,
				[Product_Update_Level] VARCHAR(50) NULL,
				[Product_Build_Type] VARCHAR(50) NULL,
				[Product_Update_Reference] VARCHAR(50) NULL,
				[SQL_Patch_Install_Timestamp] DATETIME NULL,
				[Edition] VARCHAR(255) NULL,
				[CPU_Count] TINYINT NULL,
				[Physical_Memory (GB)] DECIMAL(20,2) NULL,
				[Committed (GB)] DECIMAL(20,2) NULL,
				[Visible (GB)] DECIMAL(20,2) NULL,
				[SQL_Server_Start_Time] DATETIME NULL,
				[Memory_Model] NVARCHAR(60) NULL,
				[Service_Account] NVARCHAR(256) NULL,
				[Instant_File_Initialization_Enabled] NVARCHAR(1) NULL,
				[Date_Updated] DATETIME NULL,
				[Updated_By] SYSNAME NULL,
				[Server_Comments] VARCHAR(2000) NULL, 
				[Date_Captured] DATETIME NOT NULL, 
				[Captured_By] SYSNAME NOT NULL)
GO
ALTER TABLE [dbo].[tblSQL_Servers]  ADD CONSTRAINT [DF_tblSQL_Server_Is_Active] DEFAULT 1 FOR [Is_Active]
GO
ALTER TABLE [dbo].[tblSQL_Servers]  ADD CONSTRAINT [DF_tblSQL_Server_Date_Captured] DEFAULT GETDATE() FOR [Date_Captured]
GO
ALTER TABLE [dbo].[tblSQL_Servers]  ADD CONSTRAINT [DF_tblSQL_Server_Captured_By] DEFAULT SUSER_SNAME() FOR [Captured_By]
GO
ALTER TABLE [dbo].[tblSQL_Servers]  ADD CONSTRAINT [PK_tblSQL_Server_Server_ID] PRIMARY KEY CLUSTERED([Server_ID])
GO
--exec sp_help tblSQL_Servers 
GO
INSERT INTO [dbo].[tblSQL_Servers] ([Server_Name]) VALUES ('sqlserver-0')
INSERT INTO [dbo].[tblSQL_Servers] ([Server_Name]) VALUES ('sqlserver-1')
GO
SELECT * FROM [dbo].[tblSQL_Servers]
GO


DROP TABLE IF EXISTS [dbo].[tblSysadmin_Accounts] 
GO
CREATE TABLE [dbo].[tblSysadmin_Accounts] (
				[Server_ID] TINYINT NOT NULL, 
				[Sysadmin_Account_Name] SYSNAME NOT NULL,
				[Is_Active] BIT NOT NULL, 
				[Sysadmin_Account_Comments] VARCHAR(2000) NULL, 
				[Date_Captured] DATETIME NOT NULL, 
				[Captured_By] SYSNAME NOT NULL)
GO
ALTER TABLE [dbo].[tblSysadmin_Accounts] ADD CONSTRAINT [FK_tblSysadmin_Account_tblSQL_Servers] FOREIGN KEY ([Server_ID]) REFERENCES [dbo].[tblSQL_Servers]([Server_ID])
GO
ALTER TABLE [dbo].[tblSysadmin_Accounts]  ADD CONSTRAINT [DF_tblSysadmin_Accounts_Is_Active] DEFAULT 1 FOR [Is_Active]
GO
ALTER TABLE [dbo].[tblSysadmin_Accounts]  ADD CONSTRAINT [DF_tblSysadmin_Accounts_Date_Captured] DEFAULT GETDATE() FOR [Date_Captured]
GO
ALTER TABLE [dbo].[tblSysadmin_Accounts]  ADD CONSTRAINT [DF_tblSysadmin_Accounts_Captured_By] DEFAULT SUSER_SNAME() FOR [Captured_By]
GO
ALTER TABLE [dbo].[tblSysadmin_Accounts]  ADD CONSTRAINT [PK_tblSysadmin_Accounts_Server_ID] PRIMARY KEY CLUSTERED([Server_ID], [Sysadmin_Account_Name])
GO


DROP PROC IF EXISTS [dbo].[uspInsSysadmin_Accounts]
GO
CREATE PROC [dbo].[uspInsSysadmin_Accounts]
@Server_Name SYSNAME,
@Sysadmin_Account_Name SYSNAME
AS
SET NOCOUNT ON
DECLARE @varServer_ID AS TINYINT
SELECT	@varServer_ID = [Server_ID]
FROM	[dbo].[tblSQL_Servers]
WHERE	[Server_Name] = @Server_Name
IF (@varServer_ID IS NOT NULL AND @Sysadmin_Account_Name IS NOT NULL)
	BEGIN
		INSERT INTO [dbo].[tblSysadmin_Accounts] ([Server_ID], [Sysadmin_Account_Name])
		VALUES(@varServer_ID, @Sysadmin_Account_Name)
	END
ELSE
	BEGIN
		RAISERROR ('Please review the parameters passed.', 16, 1)
		RETURN
	END
GO

EXEC [dbo].[uspInsSysadmin_Accounts] @Server_Name = 'sqlserver-0', @Sysadmin_Account_Name = 'sa'
GO
--EXEC [dbo].[uspInsSysadmin_Accounts] @Server_Name = 'sqlserver-2', @Sysadmin_Account_Name = 'sa'
--GO
EXEC [dbo].[uspInsSysadmin_Accounts] @Server_Name = 'sqlserver-1', @Sysadmin_Account_Name = 'sa'
GO
EXEC [dbo].[uspInsSysadmin_Accounts] @Server_Name = 'sqlserver-1', @Sysadmin_Account_Name = 'saa'
GO
SELECT * FROM [dbo].[tblSysadmin_Accounts]
GO

DROP FUNCTION IF EXISTS [dbo].[udfGetSQLServer_Name]
GO
CREATE FUNCTION [dbo].[udfGetSQLServer_Name]
(
	@Server_ID TINYINT
)
RETURNS SYSNAME
AS
BEGIN
	DECLARE @varServer_Name SYSNAME

	SELECT	@varServer_Name = [Server_Name]
	FROM	[dbo].[tblSQL_Servers]
	WHERE	[Server_ID] = @Server_ID

	RETURN	@varServer_Name
END
GO

DROP FUNCTION IF EXISTS [dbo].[udfGetSQLServer_ID]
GO
CREATE FUNCTION [dbo].[udfGetSQLServer_ID]
(
	@Server_Name SYSNAME
)
RETURNS SYSNAME
AS
BEGIN
	DECLARE @varServer_ID TINYINT

	SELECT	@varServer_ID = [Server_ID]
	FROM	[dbo].[tblSQL_Servers]
	WHERE	[Server_Name] = @Server_Name

	RETURN	@varServer_ID
END
GO

SELECT [dbo].[udfGetSQLServer_ID]('sqlserver-0') AS [Server_ID]
GO
SELECT [dbo].[udfGetSQLServer_Name](1) AS [Server_Name]
GO

DROP VIEW IF EXISTS [dbo].[vwSysadmin_Accounts]
GO
CREATE VIEW [dbo].[vwSysadmin_Accounts]
AS
SELECT	[dbo].[udfGetSQLServer_Name]([Server_ID]) AS [Server_Name],
		[Sysadmin_Account_Name]
FROM	[dbo].[tblSysadmin_Accounts]
WHERE	[Is_Active] = 1
GO

SELECT	*
FROM	[dbo].[vwSysadmin_Accounts]
GO

DROP TABLE IF EXISTS [load].[tblSysadmin_Accounts]
GO
DROP SCHEMA IF EXISTS [load]
GO
CREATE SCHEMA [load]
GO
CREATE TABLE [load].[tblSysadmin_Accounts](
				[Server_Name] SYSNAME NOT NULL, 
				[Sysadmin_Account_Name] SYSNAME NOT NULL,
				[Date_Captured] DATETIME NOT NULL, 
				[Captured_By] SYSNAME NOT NULL)
GO
ALTER TABLE [load].[tblSysadmin_Accounts]  ADD CONSTRAINT [DF_tblSysadmin_Accounts_Date_Captured] DEFAULT GETDATE() FOR [Date_Captured]
GO
ALTER TABLE [load].[tblSysadmin_Accounts]  ADD CONSTRAINT [DF_tblSysadmin_Accounts_Captured_By] DEFAULT SUSER_SNAME() FOR [Captured_By]
GO
ALTER TABLE [load].[tblSysadmin_Accounts]  ADD CONSTRAINT [PK_tblSysadmin_Accounts_Server_ID] PRIMARY KEY CLUSTERED([Server_Name], [Sysadmin_Account_Name])
GO
SELECT * FROM [load].[tblSysadmin_Accounts]
GO

SELECT			ROW_NUMBER() OVER(ORDER BY t.[Server_Name] ASC, t.[Sysadmin_Account_Name]) AS [Sl. No.],
				t.[Server_Name],
				t.[Sysadmin_Account_Name]
FROM			[load].[tblSysadmin_Accounts] t
LEFT OUTER JOIN	[dbo].[vwSysadmin_Accounts] s
ON				t.[Server_Name] = s.[Server_Name]
AND				t.[Sysadmin_Account_Name] = s.[Sysadmin_Account_Name]
WHERE			s.[Server_Name] IS NULL
GO

SELECT			s.[Server_Name],
				s.[Sysadmin_Account_Name]
FROM			[dbo].[vwSysadmin_Accounts] s
LEFT OUTER JOIN	[load].[tblSysadmin_Accounts] t
ON				s.[Server_Name] = t.[Server_Name]
AND				s.[Sysadmin_Account_Name] = t.[Sysadmin_Account_Name]
WHERE			t.[Server_Name] IS NULL
GO

SELECT * FROM [dbo].[vwSysadmin_Accounts]
GO

DROP PROCEDURE IF EXISTS [dbo].[rptGetNonComplaintSysadminLogins]
GO
CREATE PROCEDURE [dbo].[rptGetNonComplaintSysadminLogins]
AS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

DECLARE @varHTML VARCHAR(MAX)
DECLARE @varFlag BIT = 0

IF EXISTS (SELECT TOP 1 1 FROM [load].[tblSysadmin_Accounts] t LEFT OUTER JOIN	[dbo].[vwSysadmin_Accounts] s ON t.[Server_Name] = s.[Server_Name] AND t.[Sysadmin_Account_Name] = s.[Sysadmin_Account_Name] WHERE s.[Server_Name] IS NULL)
	BEGIN
		SET @varFlag = 1
		PRINT 'Logins identified with Sysadmin Privileges not whitelisted in central repository.'
		SET @varHTML =
			N'<H1>Logins with Sysadmin Privileges not whitelisted in central repository</H1>' +
			N'<table border="1" style="margin-left:3em">' +
			N'<tr><th>Sl. No.</th><th>Server_Name</th><th>Login Name</th></tr>' +
			CAST ( (	SELECT			td = ROW_NUMBER() OVER(ORDER BY t.[Server_Name] ASC, t.[Sysadmin_Account_Name] ASC), '',
										td = t.[Server_Name], '',
										td = t.[Sysadmin_Account_Name]
						FROM			[load].[tblSysadmin_Accounts] t
						LEFT OUTER JOIN	[dbo].[vwSysadmin_Accounts] s
						ON				t.[Server_Name] = s.[Server_Name]
						AND				t.[Sysadmin_Account_Name] = s.[Sysadmin_Account_Name]
						WHERE			s.[Server_Name] IS NULL
			FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>'
	END

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[vwSysadmin_Accounts] s LEFT OUTER JOIN [load].[tblSysadmin_Accounts] t ON s.[Server_Name] = t.[Server_Name] AND s.[Sysadmin_Account_Name] = t.[Sysadmin_Account_Name] WHERE t.[Server_Name] IS NULL)
	BEGIN
		SET @varFlag = 1
		PRINT 'Logins identified with Sysadmin Privileges missing on target servers.'
		SET @varHTML = @varHTML +
			N'<H1>Logins with Sysadmin Privileges missing on target servers</H1>' +
			N'<table border="1" style="margin-left:3em">' +
			N'<tr><th>Sl. No.</th><th>Server_Name</th><th>Login Name</th></tr>' +
			CAST ( (	SELECT			td = ROW_NUMBER() OVER(ORDER BY s.[Server_Name] ASC, s.[Sysadmin_Account_Name] ASC), '',
										td = s.[Server_Name], '',
										td = s.[Sysadmin_Account_Name]
						FROM			[dbo].[vwSysadmin_Accounts] s
						LEFT OUTER JOIN	[load].[tblSysadmin_Accounts] t
						ON				s.[Server_Name] = t.[Server_Name]
						AND				s.[Sysadmin_Account_Name] = t.[Sysadmin_Account_Name]
						WHERE			t.[Server_Name] IS NULL
			FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>'
	END

IF (@varFlag = 1)
	BEGIN		
		EXEC	[msdb].[dbo].[sp_send_dbmail] @recipients='ragopa@microsoft.com',
										@subject = '[SYSADMIN Logins]:SQL Servers with non-compliant syadmin logins.',
										@body = @varHTML,
										@body_format = 'HTML',
										@exclude_query_output = 1
	END
ELSE
	BEGIN
		PRINT 'No non-compliant sysadmin logins identified.'
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.0 GNCSSL', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'rptGetNonComplaintSysadminLogins'

--EXEC [dbo].[rptGetNonComplaintSysadminLogins]
