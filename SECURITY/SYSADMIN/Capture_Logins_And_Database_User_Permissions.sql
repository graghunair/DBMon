/*
		Date	:	10th Sept 2024
		Purpose	:	This script is used to capture Logins and Database User Permissions.
		Version	:	1.0
		License:
					This script is provided "AS IS" with no warranties, and confers no rights.

		Modification History
		----------------------
		Sept	10th, 2024	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
*/

SET NOCOUNT ON
GO

DECLARE		@MailRecipients VARCHAR(2000) = 'Raghu.Gopalakrishnan@microsoft.com'
DECLARE		@MailSubject VARCHAR(2000) = CAST(SERVERPROPERTY('servername') AS SYSNAME) + '- SQL Server Logins and Roles'
DECLARE		@HTMLTable VARCHAR(MAX) = NULL
DECLARE		@varDatabase_Name SYSNAME
DECLARE		@varSQL_String VARCHAR(MAX)

DECLARE		@tblLogins TABLE (	[SQL_Server_Instance] SYSNAME, 
								[Login_Name] SYSNAME, 
								[Role_Name] SYSNAME, 
								[Date_Captured] DATETIME)

DECLARE		@tblDatabase_Users TABLE (	[SQL_Server_Instance] SYSNAME, 
										[Database_Name] SYSNAME,
										[Database_Role] SYSNAME,
										[Database_User] SYSNAME,
										[Login_Name] SYSNAME,
										[Type_Desc] NVARCHAR(60),
										[Date_Captured] DATETIME)

INSERT INTO @tblLogins (SQL_Server_Instance, Login_Name, Role_Name, Date_Captured)
SELECT		CAST(SERVERPROPERTY('servername') AS SYSNAME) AS SQL_Server_Instance,
			l.[name] AS Login_Name,    
			r.[name] AS Role_Name,
			GETDATE()
FROM		sys.server_principals l
INNER JOIN	sys.server_role_members rm 
		ON	l.principal_id = rm.member_principal_id
INNER JOIN	sys.server_principals r 
		ON	rm.role_principal_id = r.principal_id
WHERE		l.[type] IN ('S', 'U', 'G') -- SQL logins, Windows logins, and Windows groups
ORDER BY	r.[name],l.[name];

SELECT		[SQL_Server_Instance], 
			[Login_Name], 
			[Role_Name], 
			[Date_Captured] 
FROM		@tblLogins
ORDER BY	[Role_Name], [Login_Name]

SET @HTMLTable = 
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
								FROM		@tblLogins
								ORDER BY	[Role_Name], [Login_Name]
								FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +	N'</table>'

SELECT		@varDatabase_Name = MIN([name])
FROM		sys.databases 
WHERE		[database_id] <> 2
AND			[state] = 0

WHILE(@varDatabase_Name IS NOT NULL)
	BEGIN
		--PRINT @varDatabase_Name

		SELECT	@varSQL_String = 'USE [' + @varDatabase_Name + '];'
		SELECT	@varSQL_String = @varSQL_String +
								'SELECT 
											CAST(SERVERPROPERTY(''servername'') AS SYSNAME) AS [SQL_Server_Instance],
											DB_NAME() AS [Database_Name],
											r.[name] AS [Database_Role], 
											p.[name] AS [Database_User],
											sl.loginname AS [Login_Name],
											p.[type_desc] AS [Type_Desc],
											GETDATE() AS [Date_Captured]
								FROM		sys.database_role_members m
								INNER JOIN	sys.database_principals r 
										ON	m.role_principal_id = r.principal_id
								INNER JOIN	sys.database_principals p 
										ON	m.member_principal_id = p.principal_id
								INNER JOIN	sys.syslogins sl
										ON	sl.[sid]=p.[sid]
								WHERE		sl.loginname NOT LIKE ''##%##'''

		INSERT INTO @tblDatabase_Users
		EXEC (@varSQL_String)

		SELECT		@varDatabase_Name = MIN([name])
		FROM		sys.databases 
		WHERE		[database_id] <> 2
		AND			[state] = 0
		AND			@varDatabase_Name < [name]
	END

SELECT	[SQL_Server_Instance], 
		[Database_Name],
		[Database_Role],
		[Database_User],
		[Login_Name],
		[Type_Desc],
		[Date_Captured]
FROM	@tblDatabase_Users

SET @HTMLTable = @HTMLTable + 
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
								FROM		@tblDatabase_Users
								ORDER BY	[Database_Name], [Database_Role], [Database_User]
								FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +	N'</table>'

EXEC msdb.dbo.sp_send_dbmail    
@profile_name = 'DBAMail', 
@recipients = @MailRecipients,
@subject = @MailSubject,    
@body = @HTMLTable,    
@body_format = 'HTML'

GO
