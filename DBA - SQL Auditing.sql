/*
	Author	:	Raghu Gopalakrishnan
	Date	:	10 February 2020
	Purpose	:	This is a script to enable SQL Auditing
	Version :	1.0
	License:	This script is provided "AS IS" with no warranties, and confers no rights.
*/


SET NOCOUNT ON

USE [master]
GO

--Variable declaration
DECLARE @tblRead_Errorlog TABLE (Log_Date DATETIME, ProcessInfo VARCHAR(50), Log_Text VARCHAR(MAX))
DECLARE @varFile_Path VARCHAR(2000)

--Locate the location of SQL Server ERRORLOG files so that we can point SQLAudit files too on the same log directly
INSERT INTO @tblRead_Errorlog
EXEC ('EXEC xp_readerrorlog 0,1, N''Logging SQL Server messages in file''')
SELECT @varFile_Path = SUBSTRING(Log_Text, 38, LEN(SUBSTRING(Log_Text, 38, 2000))-10)  FROM @tblRead_Errorlog

PRINT @varFile_Path
GO

CREATE SERVER AUDIT [DBA_SecurityAudit]
TO FILE 
(      --FILEPATH = '<Replace with file path here>',
       FILEPATH = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Log\',
	   MAXSIZE = 100 MB,
       MAX_ROLLOVER_FILES = 10,
       RESERVE_DISK_SPACE = OFF
)
WITH(      
		QUEUE_DELAY = 1000,
		ON_FAILURE = CONTINUE)

ALTER SERVER AUDIT [DBA_SecurityAudit] WITH (STATE = ON)
GO


CREATE SERVER AUDIT SPECIFICATION [DBA_ServerAuditSpecification]
FOR SERVER AUDIT [DBA_SecurityAudit]
ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),
ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),
ADD (AUDIT_CHANGE_GROUP),
ADD (DATABASE_PERMISSION_CHANGE_GROUP),
ADD (DATABASE_OBJECT_PERMISSION_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP),
ADD (SERVER_OBJECT_PERMISSION_CHANGE_GROUP),
ADD (SERVER_PERMISSION_CHANGE_GROUP),
ADD (FAILED_LOGIN_GROUP),
ADD (DATABASE_CHANGE_GROUP),
ADD (DATABASE_OBJECT_CHANGE_GROUP),
ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_CHANGE_GROUP),
ADD (SERVER_OBJECT_CHANGE_GROUP),
ADD (SERVER_PRINCIPAL_CHANGE_GROUP),
ADD (APPLICATION_ROLE_CHANGE_PASSWORD_GROUP),
ADD (LOGIN_CHANGE_PASSWORD_GROUP),
ADD (SERVER_STATE_CHANGE_GROUP),
ADD (DATABASE_OWNERSHIP_CHANGE_GROUP),
ADD (DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP),
ADD (TRACE_CHANGE_GROUP)
WITH (STATE = ON)
GO

SELECT * FROM [sys].[fn_get_audit_file] ('<Replace with file path here>*.sqlaudit',default,default);  
GO  