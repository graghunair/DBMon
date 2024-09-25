SET NOCOUNT ON
GO

USE [dba_local]
GO

DROP PROC IF EXISTS [dbo].[uspDBMon_GetTLogUtilization]
GO
CREATE PROC [dbo].[uspDBMon_GetTLogUtilization]
@Database_Name SYSNAME = NULL
AS
/*		
	Date	:	25th Sept 2024
	Purpose	:	This Stored Procedure is used to return TLog Utilization
	Version	:	1.0
	License:
				This script is provided "AS IS" with no warranties, and confers no rights.

				EXEC [dba_local].[dbo].[uspDBMon_GetTLogUtilization]
				EXEC [dba_local].[dbo].[uspDBMon_GetTLogUtilization] @Database_Name = 'tempdb'

	Modification History
	----------------------
	Sept	25th, 2024	:	v1.0	:	Inception
*/
SET NOCOUNT ON

DECLARE @tblTLogInfo TABLE(
		[Database_Name] SYSNAME,
		[Log Size (MB)] DECIMAL(32,2),
		[Log Space Used (%)] DECIMAL(5,2),
		[Status] INT)

DECLARE @tblDBInfo TABLE(
		[Database_Name] SYSNAME,
		[Log Size (MB)] DECIMAL(32,2),
		[Log Space Used (%)] DECIMAL(5,2),
		[Recovery_Mode] NVARCHAR(60),
		[Log_Reuse_Wait_Desc] NVARCHAR(60))

INSERT INTO @tblTLogInfo ([Database_Name], [Log Size (MB)], [Log Space Used (%)], [Status])
EXEC ('DBCC sqlperf(logspace) WITH NO_INFOMSGS')

INSERT INTO	@tblDBInfo
SELECT		[Database_Name],
			[Log Size (MB)],
			[Log Space Used (%)],
			[recovery_model_desc],
			[log_reuse_wait_desc] 
FROM		@tblTLogInfo tli
INNER JOIN	sys.databases sd
		ON	tli.[Database_Name] = sd.[name] 

IF (@Database_Name IS NULL)
	BEGIN
		SELECT		SERVERPROPERTY('servername') AS [SQL_Server_Instance_Name],
					[Database_Name],
					[Log Size (MB)],
					[Log Space Used (%)],
					[Recovery_Mode],
					[Log_Reuse_Wait_Desc],
					GETDATE() AS [Date_Captured]
		FROM		@tblDBInfo
		ORDER BY	[Database_Name]
	END
ELSE
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM sys.databases WHERE [name] = @Database_Name)
			BEGIN
				SELECT		SERVERPROPERTY('servername') AS [SQL_Server_Instance_Name],
							[Database_Name],
							[Log Size (MB)],
							[Log Space Used (%)],
							[Recovery_Mode],
							[Log_Reuse_Wait_Desc],
							GETDATE() AS [Date_Captured]
				FROM		@tblDBInfo
				WHERE		[Database_Name] = @Database_Name
			END
		ELSE
			BEGIN
				PRINT 'Database with name: [' + @Database_Name + '] not found in sys.databases.'
			END
	END
GO

EXEC [dbo].[uspDBMon_GetTLogUtilization]
EXEC [dbo].[uspDBMon_GetTLogUtilization] @Database_Name = 'tempdb' 
EXEC [dbo].[uspDBMon_GetTLogUtilization] @Database_Name = 'tempdb2'
