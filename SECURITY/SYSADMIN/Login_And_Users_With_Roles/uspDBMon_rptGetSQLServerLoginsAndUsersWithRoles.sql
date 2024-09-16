SET NOCOUNT ON
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_rptGetSQLServerLoginsAndUsersWithRoles]
GO
CREATE PROCEDURE [dbo].[uspDBMon_rptGetSQLServerLoginsAndUsersWithRoles]
@Mail TINYINT = 0,
@Mail_Recipients VARCHAR(2000) = NULL,
@SQL_Server_Instance SYSNAME = NULL
AS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	16th Sept 2024
		Purpose	:	This Stored Procedure is used to report SQL Server Logins and Database Users with their Role Membership
		Version	:	1.0
		License:
					This script is provided "AS IS" with no warranties, and confers no rights.

					EXEC [dbo].[uspDBMon_rptGetSQLServerLoginsAndUsersWithRoles] 
									@Mail = 1,
									@Mail_Recipients = 'email@domain.com',
									@SQL_Server_Instance = CAST(@@SERVERNAME AS SYSNAME)

		Modification History
		----------------------
		Sept 16th, 2024	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
	*/
DECLARE		@MailSubject VARCHAR(2000)
DECLARE		@HTMLTable1 VARCHAR(MAX),
			@HTMLTable2 VARCHAR(MAX),
			@HTMLTable VARCHAR(MAX)

SET @MailSubject = @SQL_Server_Instance + ' - SQL Server Logins and Roles'
IF EXISTS (SELECT TOP 1 1 FROM [load].[tblDBMon_Logins_With_Roles] WHERE [SQL_Server_Instance] = @SQL_Server_Instance)
	BEGIN
		SELECT	* 
		FROM	[load].[tblDBMon_Logins_With_Roles]

		SET @HTMLTable1 = 
					N'<H1>SQL Server Logins and Roles</H1>' +
					N'<table border="1";padding-left:50px>' +
					N'<div style="border-collapse:collapse;"></div>' +					
					N'<tr><th>SQL Server Instance</th>' +
					N'<th>Login Name</th>' +
					N'<th>Role Name</th>' + 
					N'<th>Date Captured</th></tr>' +
					CAST ( (	SELECT		td = [SQL_Server_Instance], '',
											td = [Login_Name], '',
											td = [Role_Name], '',										
											td = REPLACE([Date_Captured], ' ', '_')
								FROM		[load].[tblDBMon_Logins_With_Roles]
								WHERE		[SQL_Server_Instance] = @SQL_Server_Instance
								ORDER BY	[SQL_Server_Instance], [Role_Name], [Login_Name]
								FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +	N'</table>'
	END
ELSE
	BEGIN
		PRINT 'No SQL Server Login details for the SQL Server Instance: ' + @SQL_Server_Instance
	END

IF EXISTS (SELECT TOP 1 1 FROM [load].[tblDBMon_Database_Users_With_Roles] WHERE [SQL_Server_Instance] = @SQL_Server_Instance)
	BEGIN
		SELECT	* 
		FROM	[load].[tblDBMon_Database_Users_With_Roles]
		
		SET @HTMLTable2 = 
					N'<H1>SQL Server Database Users and Permissions</H1>' +
					N'<table border="1";padding-left:50px>' +
					N'<div style="border-collapse:collapse;"></div>' +					
					N'<tr><th>SQL Server Instance</th>' +
					N'<th>Database Name</th>' +
					N'<th>Database Role</th>' + 
					N'<th>Database User</th>' + 
					N'<th>Login Name</th>' + 
					N'<th>Type Desc</th>' + 
					N'<th>Date Captured</th></tr>' +
					CAST ( (	SELECT		td = [SQL_Server_Instance], '',
											td = [Database_Name], '',
											td = [Database_Role], '',
											td = [Database_User], '',
											td = [Login_Name], '',
											td = [Type_Desc], '',											
											td = REPLACE([Date_Captured], ' ', '_')
								FROM		[load].[tblDBMon_Database_Users_With_Roles]
								ORDER BY	[SQL_Server_Instance], [Database_Name], [Database_Role], [Database_User]
								FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +	N'</table>'
	END
ELSE
	BEGIN
		PRINT 'No Database User details for the SQL Server Instance: ' + @SQL_Server_Instance
	END

IF (@Mail = 1)
	BEGIN
		SET @HTMLTable = @HTMLTable1 + @HTMLTable2
		EXEC msdb.dbo.sp_send_dbmail    
		--@profile_name = 'DBAMail', 
		@recipients = @Mail_Recipients,
		@subject = @MailSubject,    
		@body = @HTMLTable,    
		@body_format = 'HTML'
	END
GO


DECLARE @varSQL_Server_Instance SYSNAME = CAST(SERVERPROPERTY('servername') AS SYSNAME)
EXEC [dbo].[uspDBMon_rptGetSQLServerLoginsAndUsersWithRoles] 
				@Mail = 1,
				@Mail_Recipients = 'Raghu.Gopalakrishnan@microsoft.com',
				@SQL_Server_Instance = @varSQL_Server_Instance
