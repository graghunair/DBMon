SET NOCOUNT ON
GO

--USE [dba_local]
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_ERRORLOG]
GO
CREATE TABLE [dbo].[tblDBMon_ERRORLOG](
			[Date_Captured] DATETIME DEFAULT GETDATE(), 
			[Source] SYSNAME, 
			[Database_Name] SYSNAME,
			[Message] VARCHAR(MAX), 
			[Alert_Flag] BIT DEFAULT 0)
GO
CREATE CLUSTERED INDEX IDX_tblDBMon_ERRORLOG ON [dbo].[tblDBMon_ERRORLOG]([Date_Captured])
GO

DROP PROC IF EXISTS [dbo].[uspDBMon_GetTLogUtilizationAndReport]
GO
CREATE PROC [dbo].[uspDBMon_GetTLogUtilizationAndReport]
@TLog_Usage_Threshold TINYINT = 1,
@Mail_Recepients VARCHAR(MAX) = '<>',
@Mail_Flag BIT = 1
AS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

--Variable declarations
DECLARE @tableHTML											VARCHAR(MAX)
DECLARE @mailSubject										NVARCHAR(255)
DECLARE @varCount											INT
DECLARE @varCounter											SMALLINT
DECLARE @varSPID											SMALLINT
DECLARE @varDBName											NVARCHAR(128)
DECLARE @varUserDBCnt										SMALLINT
DECLARE @varTLogBackupTimestamp								XML

--Table variable to store the output of DBCC SQLPERF(LOGSPACE)
DECLARE	@tblTLogUsage TABLE	(
	[DB_Name]			NVARCHAR(128), 
	[Log_Size_MB]		DECIMAL(12,2), 
	[Log_Space_Used%]	DECIMAL(10,2), 
	[Status]			BIT)
		
--Table variables to store Open Transaction details
DECLARE  @tblOpenTranInfo TABLE ( 
	C1 VARCHAR(200),
	C2 VARCHAR(2000) )
		
DECLARE @tblTranInfo TABLE (
	[SPID]			SMALLINT,
	[DB_Name]		NVARCHAR(128), 
	[Host_Name]		VARCHAR(128),
	[Login_Name]	VARCHAR(128), 
	[Last_Batch]	DATETIME,
	[CMD]			VARCHAR(16),
	[SQLText]		VARCHAR(2000) )

SELECT	@varUserDBCnt = COUNT(1) 
FROM	[sys].[databases] 
WHERE	[is_distributor] = 0 
AND		[database_id] > 4

--Capture the value of Transaction Log usage
INSERT INTO @tblTLogUsage([DB_Name], [Log_Size_MB], [Log_Space_Used%], [Status])
EXEC('dbcc sqlperf(logspace) with no_infomsgs')
	
IF EXISTS (SELECT 1 FROM @tblTLogUsage WHERE [Log_Space_Used%] >= @TLog_Usage_Threshold)
	BEGIN
		--Database(s) exceed the threshold. Need to Alert!.					
			SELECT		@varCounter = MIN(b.database_id)
			FROM		@tblTLogUsage a
			INNER JOIN	[sys].[databases] b
					ON	a.[DB_Name] = b.[name] COLLATE database_default
			WHERE		[Log_Space_Used%] >= @TLog_Usage_Threshold  
			AND			b.[log_reuse_wait_desc] = 'ACTIVE_TRANSACTION'
					
			WHILE (@varCounter IS NOT NULL)
				BEGIN
					SELECT	@varDBName = [name]
					FROM	[sys].[databases]
					WHERE	database_id = @varCounter 
							
					DELETE FROM @tblOpenTranInfo
	
					INSERT INTO @tblOpenTranInfo 
					EXEC ('dbcc opentran(''' + @varDBName + ''') WITH TABLERESULTS, NO_INFOMSGS')
							
					SELECT	@varSPID = C2  
					FROM	@tblOpenTranInfo 
					WHERE	C1 = 'OLDACT_SPID'
							
					INSERT INTO @tblTranInfo ([SPID], [DB_Name], [Host_Name],[Login_Name], [Last_Batch], [CMD], [SQLText])
					SELECT		a.spid, DB_NAME(a.[dbid]), a.hostname, a.loginame, a.last_batch , a.cmd, SUBSTRING(b.[text],0,2000)
					FROM		[sys].[sysprocesses] a
					CROSS APPLY	[sys].[dm_exec_sql_text]([sql_handle]) b
					WHERE		spid = @varSPID
							
					SELECT		@varCounter = MIN(b.database_id)
					FROM		@tblTLogUsage a
					INNER JOIN	[sys].[databases] b
							ON	a.[DB_Name] = b.[name] COLLATE database_default
					WHERE		[Log_Space_Used%] >= @TLog_Usage_Threshold  
					AND			b.[log_reuse_wait_desc] = 'ACTIVE_TRANSACTION'
					AND			b.database_id > @varCounter 
				END

			INSERT INTO [dbo].[tblDBMon_ERRORLOG]([Source], [Database_Name], [Message], [Alert_Flag]) 
			SELECT		CAST(OBJECT_NAME(@@PROCID) AS SYSNAME), [DB_Name], 'DB:' + [DB_Name]
						+ '; Log_Size_MB:' + CAST([Log_Size_MB] AS VARCHAR(20))  
						+ '; Log_Space_Used%:' + CAST([Log_Space_Used%] AS VARCHAR(7)) 
						+ '; Log Reuse Wait Desc:' + [log_reuse_wait_desc] 
						+ '; Recovery Model:' + [recovery_model_desc] COLLATE database_default,
						1
			FROM		@tblTLogUsage a
			INNER JOIN	[sys].[databases] b
					ON	a.[DB_Name] = b.[name] COLLATE database_default
			WHERE		[Log_Space_Used%] >= @TLog_Usage_Threshold  
			ORDER BY	[Log_Space_Used%] DESC
					
			--Build HTML string to send mail
			SET @tableHTML =
				N'<H1>Monitor Transaction Log</H1>' +
				N'<table border="1">' +
				N'<tr><th>SQL Server Instance</th>'+
				N'<th>Database Name</th>' +
				N'<th>Log Size(MB)</th>' + 
				N'<th>Log Space Used(%)</th>' +
				N'<th>Log Reuse Wait Desc</th>' + 
				N'<th>Recovery Model</th></tr>' +
				CAST ( (	SELECT		td = SERVERPROPERTY('servername'), ''
							, td = [DB_Name], '' 
							, td = [Log_Size_MB], ''
							, td = [Log_Space_Used%], ''
							, td = [log_reuse_wait_desc], ''
							, td = [recovery_model_desc] 
							FROM @tblTLogUsage a
							INNER JOIN [sys].[databases] b
							ON a.[DB_Name] = b.[name] COLLATE database_default
							WHERE [Log_Space_Used%] >= @TLog_Usage_Threshold
							ORDER BY [Log_Size_MB] DESC
				FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>' 

				SELECT		a.[DB_Name],
							a.[Log_Size_MB],
							a.[Log_Space_Used%],
							b.log_reuse_wait_desc AS [Log Reuse Wait Desc]
				FROM		@tblTLogUsage a
				INNER JOIN [sys].[databases] b
						ON a.[DB_Name] = b.[name] COLLATE database_default
				WHERE		[Log_Space_Used%] >= @TLog_Usage_Threshold
				ORDER BY	[Log_Size_MB] DESC
						
				IF EXISTS (SELECT TOP 1 1 FROM @tblTranInfo)
					BEGIN
						SET @tableHTML = @tableHTML + 
							N'<H2>Active Transaction Details</H2>' +
							N'<table border="1">' +
							N'<tr><th>Session ID</th>' +
							N'<th>Database Name</th>' +
							N'<th>Host Name</th>' + 
							N'<th>Login Name</th>' +
							N'<th>Last Batch</th>' +
							N'<th>Command</th>' + 
							N'<th>SQL Text</th></tr>' +
							CAST ( (	SELECT		td = [SPID], ''
										, td = [DB_Name], '' 
										, td = [Host_Name], ''
										, td = [Login_Name], ''
										, td = REPLACE([Last_Batch],' ','_'), ''
										, td = [CMD], ''
										, td = [SQLText] 
										FROM @tblTranInfo
										ORDER BY [DB_Name]
							FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>' 
						
						SELECT	*
						FROM	@tblTranInfo
						ORDER BY [DB_Name]
					END

				IF (@Mail_Flag <> 0)
					BEGIN
						SELECT @mailSubject = '[TLog_SpaceUsage]: ' + CAST(SERVERPROPERTY('servername') as varchar(255)) + ' Transaction Log utilization exceeds threshold of ' + CAST(@TLog_Usage_Threshold AS VARCHAR(5)) + '%'
						EXEC msdb.dbo.sp_send_dbmail @recipients=@Mail_Recepients,
							@subject = @mailSubject,
							@body = @tableHTML,
							@body_format = 'HTML',
							@exclude_query_output = 1
					END
	END
ELSE
	BEGIN
		--All Databases within the threshold. No Alert to be sent.
			--PRINT 'Transaction log usage of all database within threshold specified.'
			INSERT INTO [dbo].[tblDBMon_ERRORLOG]([Source], [Database_Name], [Message])
			VALUES (CAST(OBJECT_NAME(@@PROCID) AS SYSNAME), NULL, 'Transaction log usage of all databases are within threshold specified.') 
	END
GO

EXEC [dbo].[uspDBMon_GetTLogUtilizationAndReport] @TLog_Usage_Threshold = 25
GO
SELECT * FROM [dbo].[tblDBMon_ERRORLOG]
GO

