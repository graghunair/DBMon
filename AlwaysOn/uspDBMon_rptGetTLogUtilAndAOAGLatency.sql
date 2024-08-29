USE [dba_local]
GO

DROP PROC IF EXISTS [dbo].[uspDBMon_rptGetTLogUtilAndAOAGLatency]
GO
CREATE PROCEDURE [dbo].[uspDBMon_rptGetTLogUtilAndAOAGLatency]
@Mail BIT = 0,
@Mail_Subject VARCHAR(2000) = 'TLog Utilization and AOAG latency between Replicas',
@Mail_Recipients VARCHAR(MAX) = 'email@domain.com',
@TLog_Util_Threshold TINYINT = 60,
@AOAG_Queue_Size_KB SMALLINT = 1024
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	27th August 2024
		Purpose	:	This Stored Procedure is used to report latency in timestamps for AlwaysOn Synchronization
		Version	:	1.0
		License:
					This script is provided "AS IS" with no warranties, and confers no rights.

					EXEC [dbo].[uspDBMon_rptGetTLogUtilAndAOAGLatency] 
									@Mail = 1,
									@Mail_Subject = 'AOAG Latency Between Replicas',
									@Mail_Recipients = 'email@domain.com',
									@TLog_Util_Threshold = 0,
									@AOAG_Queue_Size_KB = 0

		Modification History
		----------------------
		Aug	27th, 2024	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
	*/

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

--Variable declarations
	DECLARE @tableHTML_TLog	VARCHAR(MAX) = NULL
	DECLARE @tableHTML_AOAG	VARCHAR(MAX) = NULL
	DECLARE @tableHTML	VARCHAR(MAX) = NULL
	DECLARE @Mail_Flag_TLog	TINYINT = 0
	DECLARE @Mail_Flag_AOAG	TINYINT = 0

	DECLARE @tblTLog_Space TABLE (
			[Database_Name] SYSNAME,
			[Log_Size_MB] DECIMAL(20,2),
			[Log_Space_Used (%)] DECIMAL(5,2),
			[Status] TINYINT)

	DECLARE @tblAOAG_Latency TABLE (
			[Replica_Name] SYSNAME,
			[Database_Name] SYSNAME,
			[AG_Name] SYSNAME,
			[Synchronization_State] NVARCHAR(60),
			[Synchronization_Health] NVARCHAR(60),
			[Last_Sent_Time] DATETIME,
			[Last_Redone_Time] DATETIME,
			[Log_Send_Queue_Size(KB)] BIGINT,
			[Redo_Queue_Size(KB)] BIGINT,
			[Date_Captured] DATETIME)


--Capture and report Transaction Log Utilization exceeding threshold
	INSERT INTO @tblTLog_Space([Database_Name], [Log_Size_MB], [Log_Space_Used (%)], [Status])
	EXEC('dbcc sqlperf(logspace) with no_infomsgs')

	IF EXISTS (SELECT TOP 1 1 FROM @tblTLog_Space WHERE	sys.fn_hadr_is_primary_replica([Database_Name]) = 1 AND	[Log_Space_Used (%)] > @TLog_Util_Threshold)
	BEGIN
		SELECT	@Mail_Flag_TLog = 1

		SELECT	CAST(SERVERPROPERTY('servername') AS SYSNAME) AS [SQL_Server_Name],
				[Database_Name],	
				[Log_Size_MB],
				[Log_Space_Used (%)],
				GETDATE() AS [Date_Captured]
		FROM	@tblTLog_Space
		WHERE	sys.fn_hadr_is_primary_replica([Database_Name]) = 1
		AND		[Log_Space_Used (%)] > @TLog_Util_Threshold
	END

--Capture and report database where AOAG synchronization is not healthy or latency exceeds threshold
	INSERT INTO @tblAOAG_Latency
	SELECT	ar.[replica_server_name]										AS [Replica_Name], 
			adc.[database_name]												AS [Database_Name], 
			ag.[name]														AS [AG_Name], 
			drs.[synchronization_state_desc]								AS [Synchronization_State],
			drs.[synchronization_health_desc]								AS [Synchronization_Health], 
			drs.[last_sent_time]											AS [Last_Sent_Time],  
			drs.[last_redone_time]											AS [Last_Redone_Time], 
			drs.[log_send_queue_size]										AS [Log_Send_Queue_Size(KB)], 
			drs.[redo_queue_size]											AS [Redo_Queue_Size(KB)],
			GETDATE()														AS [Date_Captured]	
	FROM		[sys].[dm_hadr_database_replica_states]			AS drs
	INNER JOIN	[sys].[availability_databases_cluster]			AS adc 
			ON	drs.group_id = adc.group_id 
	AND			drs.group_database_id = adc.group_database_id
	INNER JOIN	[sys].[availability_groups]						AS ag
			ON	ag.group_id = drs.group_id
	INNER JOIN	[sys].[availability_replicas]					AS ar 
			ON	drs.group_id = ar.group_id 
	AND			drs.replica_id = ar.replica_id
	WHERE		1=1
	AND			drs.[is_local]	= 0
	AND			sys.fn_hadr_is_primary_replica(adc.[database_name]) = 1
	AND			(drs.[log_send_queue_size] >= @AOAG_Queue_Size_KB OR drs.[redo_queue_size] >= @AOAG_Queue_Size_KB OR drs.[synchronization_health] <> 2)

	IF EXISTS (SELECT TOP 1 1 FROM @tblAOAG_Latency)
		BEGIN
			SELECT	@Mail_Flag_AOAG = 1

			SELECT		*
			FROM		@tblAOAG_Latency
			ORDER BY	[Replica_Name], [Database_Name]
		END

	IF (@Mail = 1 AND @Mail_Recipients IS NOT NULL AND @Mail_Flag_TLog = 1)
		BEGIN			
			SET @tableHTML_TLog = 
								N'<H3>Transaction Log Utilization</H3>' +
								N'<table border="1";padding-left:50px>' +
								N'<div style="margin-left: 50px"></div>' + 
								N'<tr><th>Server Name</th>' + 
								N'<th>Database Name</th>' + 
								N'<th>Log Size (MB)</th>' + 
								N'<th>Log Space Used (%)</th>' +							
								N'<th>Date Captured</th></tr>' +
								CAST ( (	SELECT	 
														td = CAST(SERVERPROPERTY('servername') AS SYSNAME), '',
														td = [Database_Name], '',
														td = [Log_Size_MB], '',
														td = [Log_Space_Used (%)], '',
														td = REPLACE(GETDATE(),' ','_')
											FROM		@tblTLog_Space
											WHERE		sys.fn_hadr_is_primary_replica([Database_Name]) = 1
											AND			[Log_Space_Used (%)] > @TLog_Util_Threshold
											ORDER BY	[Database_Name]
											FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +	N'</table>'		
		END
			
	IF (@Mail = 1 AND @Mail_Recipients IS NOT NULL AND @Mail_Flag_AOAG = 1)
		BEGIN
			SET @tableHTML_AOAG =	
								N'<H3>AlwaysOn Availability Group Latency</H3>' +
								N'<table border="1";padding-left:50px>' +
								N'<div style="margin-left:50px"></div>' + 
								N'<tr><th>Replica</th>' + 
								N'<th>Database Name</th>' + 
								N'<th>AG Name</th>' + 
								N'<th>Sync State</th>' + 
								N'<th>Sync Health</th>' +
								N'<th>Last Sent Time</th>' +
								N'<th>Last Redone Time</th>' +
								N'<th>Log Send Queue (KB)</th>' +
								N'<th>Redo Queue (KB)</th>' +
								N'<th>Date Captured</th></tr>' +
								CAST ( (	SELECT	 
														td = [Replica_Name], '',
														td = [Database_Name], '',
														td = [AG_Name], '',
														td = [Synchronization_State], '',
														td = [Synchronization_Health], '',
														td = REPLACE([Last_Sent_Time],' ','_'), '',
														td = REPLACE([Last_Redone_Time],' ','_'), '',
														td = [Log_Send_Queue_Size(KB)], '',
														td = [Redo_Queue_Size(KB)], '',
														td = REPLACE([Date_Captured],' ','_')
											FROM		@tblAOAG_Latency
											ORDER BY 
														[Replica_Name], 
														[Database_Name]
											FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +	N'</table>'
		END


	IF (@Mail = 1 AND @Mail_Recipients IS NOT NULL AND (@Mail_Flag_TLog = 1 OR @Mail_Flag_AOAG = 1))
		BEGIN
			SELECT @tableHTML = @tableHTML_TLog + @tableHTML_AOAG
			EXEC	msdb.dbo.sp_send_dbmail @recipients = @Mail_Recipients,
			@subject = @Mail_Subject,
			--@profile_name = N'<profile-name>',
			@body = @tableHTML,
			@body_format = 'HTML'
		END
	ELSE
		BEGIN
			PRINT 'No latency identified beyond the threshold specified.'
		END
GO

