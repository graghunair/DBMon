/*
	The below values need to be modified:
		1. @Database_Name SYSNAME = '<dbname>',
		2. @Mail_Recipients VARCHAR(MAX) = '<default-email-address>'
		3. @profile_name = N'SBS Mail'
*/

USE [dba_local]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_DM_HADR_Database_Replica_States]
GO
CREATE TABLE [dbo].[tblDBMon_DM_HADR_Database_Replica_States](
	[Date_Captured] [datetime] NOT NULL,
	[Server_Name] [nvarchar](256) NULL,
	[Database_Name] [sysname] NULL,
	[AG_Name] [sysname] NULL,
	[Synchronization_State] [nvarchar](60) NULL,
	[Synchronization_Health] [nvarchar](60) NULL,
	[Last_Sent_Time] [datetime] NULL,
	[Last_Sent_Time_Delay(Mins)] [int] NULL,
	[Last_Received_Time] [datetime] NULL,
	[Last_Received_Time_Delay(Mins)] [int] NULL,
	[Last_Hardened_Time] [datetime] NULL,
	[Last_Hardened_Time_Delay(Mins)] [int] NULL,
	[Last_Redone_Time] [datetime] NULL,
	[Last_Redone_Time_Delay(Mins)] [int] NULL,
	[Last_Commit_Time] [datetime] NULL,
	[Last_Commit_Time_Delay(Mins)] [int] NULL,
	[Log_Send_Queue_Size(KB)] [bigint] NULL,
	[Redo_Queue_Size(KB)] [bigint] NULL
)
GO

CREATE PROCEDURE [dbo].[uspDBMon_rptGetAOAGLatency]
@Database_Name SYSNAME = '<dbname>',
@Mail BIT = 0,
@Mail_Subject VARCHAR(2000) = 'AOAG latency between replicas',
@Mail_Recipients VARCHAR(MAX) = '<default-email-address>',
@Delay_Minutes TINYINT = 10
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	15th June 2020
		Purpose	:	This Stored Procedure is used to report latency in timestamps for AlwaysOn Synchronization
		Version	:	1.0
		License:
					This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[uspDBMon_rptGetAOAGLatency] 
									@Database_Name = 'AJS_SBS',
									@Mail = 1,
									@Mail_Subject = '[SBS]: AOAG latency between replicas',
									@Mail_Recipients = 'gohara@bein.net',
									@Delay_Minutes = 0

		Modification History
		----------------------
		June	15th, 2020	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
	*/

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

--Variable declarations
DECLARE @tableHTML	VARCHAR(MAX)
DECLARE @Output		TINYINT

SELECT		TOP 1 @Output = 1
FROM		[sys].[dm_hadr_database_replica_states]				AS drs
INNER JOIN	[sys].[availability_databases_cluster]				AS adc 
		ON	drs.group_id = adc.group_id 
		AND drs.group_database_id = adc.group_database_id
WHERE	adc.[database_name]		= @Database_Name
AND		drs.[is_local]	= 0
AND		(drs.[synchronization_health] <> 2 OR 
		DATEDIFF(mi, drs.[last_sent_time], GETDATE()) >= @Delay_Minutes OR 
		DATEDIFF(mi, drs.[last_received_time], GETDATE()) >= @Delay_Minutes OR 
		DATEDIFF(mi, drs.[last_hardened_time], GETDATE()) >= @Delay_Minutes OR 
		DATEDIFF(mi, drs.[last_redone_time]	, GETDATE()) >= @Delay_Minutes OR 
		DATEDIFF(mi, drs.[last_commit_time]	, GETDATE()) >= @Delay_Minutes)

--Generate the output only on the Primary Replica
IF ([sys].[fn_hadr_is_primary_replica] (@Database_Name)=1)
	BEGIN
		INSERT INTO [dbo].[tblDBMon_DM_HADR_Database_Replica_States]
					(	[Date_Captured],
						[Server_Name],
						[Database_Name],
						[AG_Name],
						[Synchronization_State],
						[Synchronization_Health],
						[Last_Sent_Time],
						[Last_Sent_Time_Delay(Mins)],
						[Last_Received_Time],
						[Last_Received_Time_Delay(Mins)],
						[Last_Hardened_Time],
						[Last_Hardened_Time_Delay(Mins)],
						[Last_Redone_Time],
						[Last_Redone_Time_Delay(Mins)],
						[Last_Commit_Time],
						[Last_Commit_Time_Delay(Mins)],
						[Log_Send_Queue_Size(KB)],
						[Redo_Queue_Size(KB)])
		SELECT		GETDATE(),
					ar.[replica_server_name]							AS [Server_Name], 
					adc.[database_name]									AS [Database_Name], 
					ag.[name]											AS [AG_Name], 
					drs.[synchronization_state_desc]					AS [Synchronization_State],
					drs.[synchronization_health_desc]					AS [Synchronization_Health], 
					drs.[last_sent_time]								AS [Last_Sent_Time], 
					DATEDIFF(mi, drs.[last_sent_time], GETDATE())		AS [Last_Sent_Time_Delay(Mins)],
					drs.[last_received_time]							AS [Last_Received_Time], 
					DATEDIFF(mi, drs.[last_received_time], GETDATE())	AS [Last_Received_Time_Delay(Mins)],
					drs.[last_hardened_time]							AS [Last_Hardened_Time], 
					DATEDIFF(mi, drs.[last_hardened_time], GETDATE())	AS [Last_Hardened_Time_Delay(Mins)],
					drs.[last_redone_time]								AS [Last_Redone_Time], 
					DATEDIFF(mi, drs.[last_redone_time]	, GETDATE())	AS [Last_Redone_Time_Delay(Mins)],
					drs.[last_commit_time]								AS [Last_Commit_Time],
					DATEDIFF(mi, drs.[last_commit_time]	, GETDATE())	AS [Last_Commit_Time_Delay(Mins)],
					drs.[log_send_queue_size]							AS [Log_Send_Queue_Size(KB)], 
					drs.[redo_queue_size]								AS [Redo_Queue_Size(KB)]
		FROM		[sys].[dm_hadr_database_replica_states]				AS drs
		INNER JOIN	[sys].[availability_databases_cluster]				AS adc 
				ON	drs.group_id = adc.group_id 
				AND drs.group_database_id = adc.group_database_id
		INNER JOIN	[sys].[availability_groups]							AS ag
				ON	ag.group_id = drs.group_id
		INNER JOIN	[sys].[availability_replicas]						AS ar 
				ON	drs.group_id = ar.group_id 
				AND drs.replica_id = ar.replica_id
		WHERE	adc.[database_name]		= @Database_Name
		AND		drs.[is_local]	= 0
		ORDER BY 
					ar.[replica_server_name], 
					adc.[database_name]

		IF (@Mail = 1 AND @Mail_Recipients IS NOT NULL AND @Output = 1)
			BEGIN
				SET @tableHTML = 
									N'<H3>AlwaysOn Availability Group Latency Report</H3>' +
									N'<table border="1";padding-left:50px>' +
									N'<div style="margin-left:500px"></div>' + 
									N'<tr><th>Server_Name</th><th>Database_Name</th>' + 
									N'<th>Synchronization_State</th><th>Synchronization_Health</th>' +
									N'<th>Last_Sent_Delay(Mins)</th>' +
									N'<th>Last_Received_Delay(Mins)</th>' +
									N'<th>Last_Hardened_Delay(Mins)</th>' +
									N'<th>Last_Redone_Delay(Mins)</th>' +
									N'<th>Last_Commit_Delay(Mins)</th></tr>' +
									CAST ( (	SELECT	 
															td = ar.[replica_server_name], '',
															td = adc.[database_name], '',
															td = drs.[synchronization_state_desc], '',
															td = drs.[synchronization_health_desc], '',
															td = DATEDIFF(mi, drs.[last_sent_time], GETDATE()), '',
															td = DATEDIFF(mi, drs.[last_received_time], GETDATE()), '',
															td = DATEDIFF(mi, drs.[last_hardened_time], GETDATE()), '',
															td = DATEDIFF(mi, drs.[last_redone_time], GETDATE()), '',
															td = DATEDIFF(mi, drs.[last_commit_time], GETDATE())
												FROM		[sys].[dm_hadr_database_replica_states]				AS drs
												INNER JOIN	[sys].[availability_databases_cluster]				AS adc 
														ON	drs.group_id = adc.group_id 
														AND drs.group_database_id = adc.group_database_id
												INNER JOIN	[sys].[availability_replicas]						AS ar 
														ON	drs.group_id = ar.group_id 
														AND drs.replica_id = ar.replica_id
														WHERE	adc.[database_name]		= @Database_Name
														AND		drs.[is_local]	= 0
																AND		(drs.[synchronization_health] <> 2 OR 
																		DATEDIFF(mi, drs.[last_sent_time], GETDATE()) >= @Delay_Minutes OR 
																		DATEDIFF(mi, drs.[last_received_time], GETDATE()) >= @Delay_Minutes OR 
																		DATEDIFF(mi, drs.[last_hardened_time], GETDATE()) >= @Delay_Minutes OR 
																		DATEDIFF(mi, drs.[last_redone_time]	, GETDATE()) >= @Delay_Minutes OR 
																		DATEDIFF(mi, drs.[last_commit_time]	, GETDATE()) >= @Delay_Minutes)
												ORDER BY 
															ar.[replica_server_name], 
															adc.[database_name]
												FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +	N'</table>'

				EXEC	msdb.dbo.sp_send_dbmail @recipients = @Mail_Recipients,
				@subject = @Mail_Subject,
				@profile_name = N'<profile-name>',
				@body = @tableHTML,
				@body_format = 'HTML'
			END
		ELSE
			BEGIN
				PRINT 'No latency identified beyond the threshold specified.'
			END
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.0', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_rptGetAOAGLatency'
GO