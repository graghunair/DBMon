SET NOCOUNT ON

USE [master]
GO

IF EXISTS(SELECT TOP 1 1 FROM [sys].[tables] WHERE [name] = 'tblDBMon_DBA_Audit_Log' AND SCHEMA_NAME([schema_id]) = 'dbo')
	BEGIN
		DROP TABLE [dbo].[tblDBMon_DBA_Audit_Log]
		PRINT 'Table: [dbo].[tblDBMon_DBA_Audit_Log] dropped.'
	END

CREATE TABLE [dbo].[tblDBMon_DBA_Audit_Log](
					[Post_Time] [datetime] NOT NULL,
					[Login_Name] [sysname] NULL,
					[Event_Type] [nvarchar](256) NULL,
					[Schema_Name] [sysname] NULL,
					[Object_Name] [sysname] NULL,
					[Object_Type] [nvarchar](120) NULL,
					[Database_Name] [sysname] NULL,
					[TSQL_Command] [varchar](5000) NULL)
GO

USE [master]
GO
CREATE CLUSTERED INDEX [IDX_tblDBMon_master_Log] ON [dbo].[tblDBMon_DBA_Audit_Log] ([Post_Time] ASC)
GO

USE [master]
GO
GRANT INSERT ON [dbo].[tblDBMon_DBA_Audit_Log] TO [public]
GO
 
IF EXISTS(SELECT TOP 1 1 FROM [sys].[server_triggers] WHERE [name] = 'trDBMon_TrackServerSecurityEvents')
BEGIN
	DROP TRIGGER [trDBMon_TrackServerSecurityEvents] ON ALL SERVER
	PRINT 'TRIGGER: [dbo].[trDBMon_TrackServerSecurityEvents] dropped.'
END
GO

--Create the server level trigger to track security events
CREATE TRIGGER [trDBMon_TrackServerSecurityEvents]   
ON ALL SERVER 
FOR DDL_SERVER_SECURITY_EVENTS,
DDL_DATABASE_SECURITY_EVENTS
AS  
/*
	Author	:	Raghu Gopalakrishnan
	Date	:	10 February 2020
	Purpose	:	This is a server level trigger to track security events on the server.
				Information is updated to the table: [master].[dbo].[tblDBMon_DBA_Audit_Log]
	Version :	1.0
				
	Modification History
	-----------------------
	Feb 10th, 2020	:	v1.0	:	Raghu Gopalakrishnan	:	Inception

*/
	SET NOCOUNT ON
	DECLARE @varEvent XML  
	SET		@varEvent = EventData()  
	INSERT	[master].[dbo].[tblDBMon_DBA_Audit_Log] ([Post_Time], [Login_Name], [Event_Type], 
			[Schema_Name], [Object_Name], [Object_Type], [Database_Name], [TSQL_Command])   
	VALUES	(GETDATE(), CONVERT(sysname, ORIGINAL_LOGIN()),   
		@varEvent.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(256)'),   
		@varEvent.value('(/EVENT_INSTANCE/SchemaName)[1]', 'sysname'),
		@varEvent.value('(/EVENT_INSTANCE/ObjectName)[1]', 'sysname'), 
		@varEvent.value('(/EVENT_INSTANCE/ObjectType)[1]', 'nvarchar(120)') ,
		@varEvent.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'sysname') ,
		@varEvent.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'varchar(5000)'))
GO

ENABLE TRIGGER [trDBMon_TrackServerSecurityEvents] ON ALL SERVER
GO

USE [master]
GO
CREATE LOGIN [Login_DBMon_Test] WITH PASSWORD=N'Login_DBMon_Test', 
DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
ALTER SERVER ROLE [securityadmin] ADD MEMBER [Login_DBMon_Test]
GO
ALTER SERVER ROLE [securityadmin] DROP MEMBER [Login_DBMon_Test]
GO
DROP LOGIN [Login_DBMon_Test]
GO

SELECT * FROM [master].[dbo].[tblDBMon_DBA_Audit_Log] 