SET NOCOUNT ON
GO

USE [dba_local]
GO

DROP PROC IF EXISTS [dbo].[uspDBMon_rptMonitoring]
GO

CREATE PROCEDURE [dbo].[uspDBMon_rptMonitoring]
@TLog_Usage_Threshold TINYINT = 80,
@Disk_Usage_Threshold TINYINT = 80,
@Disk_Free_Space_GB TINYINT = 50,
@CPU_Threshold TINYINT = 80,
@Mail_Recepients VARCHAR(MAX) = NULL
AS

/*    
	Author	:    Raghu Gopalakrishnan    
	Date	:    20th Oct 2023
	Purpose	:    This Stored Procedure is monitor Transaction Log Utilization, Disk Free Space and CPU Utilization 
	Version :    1.0                              
	License	:	This script is provided "AS IS" with no warranties, and confers no rights.

			EXEC [dbo].[uspDBMon_rptMonitoring]
						@TLog_Usage_Threshold = 80,
						@Disk_Usage_Threshold = 80,
						@Disk_Free_Space_GB = 50,
						@CPU_Threshold = 4,
						@Mail_Recepients = '<email@domain.com'
			   			
	Modification History    
	-----------------------    
	Oct 20th, 2023    :    v1.0    :    Raghu Gopalakrishnan    :    Inception
*/

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL ON
	
--Variable declarations
	DECLARE @varPresent_Time	BIGINT 
	DECLARE @tableHTML			VARCHAR(MAX)
	DECLARE @mailSubject		NVARCHAR(255)
	DECLARE @mailFlag			BIT = 0

--Table variable to store the output of DBCC SQLPERF(LOGSPACE)
	DECLARE	@tblTLogUtilization TABLE	(
		[DB_Name]			NVARCHAR(128), 
		[Log_Size_MB]		DECIMAL(12,2), 
		[Log_Space_Used%]	DECIMAL(10,2), 
		[Status]			BIT)		

--Table variable to store Disk Utilization
	DECLARE @tblDiskUtilization TABLE(
		[Drive]			[nvarchar](256) NULL,
		[Volume_Name]	[nvarchar](256) NULL,
		[Total_Size_GB] [decimal](20,2) NULL,
		[Free_Space_GB] [decimal](20,2) NULL,
		[Percent_Free]	[decimal](5,2) NULL)

--Table variable to store CPU Utilization
	DECLARE	@tblCPUUtilization TABLE	(
		[EventTime]					DATETIME,
		[SQL_CPU_Utilization]		SMALLINT, 
		[Total_CPU_UtilizationB]	SMALLINT)
	
--Transaction Log Utilization Logic
	--Capture the value of Transaction Log usage
	INSERT INTO @tblTLogUtilization([DB_Name], [Log_Size_MB], [Log_Space_Used%], [Status])
	EXEC('dbcc sqlperf(logspace) with no_infomsgs')
		
	IF EXISTS (SELECT TOP 1 1 FROM @tblTLogUtilization WHERE [Log_Space_Used%] >= @TLog_Usage_Threshold)
		BEGIN
			SET @mailFlag = 1

			SELECT * FROM @tblTLogUtilization WHERE [Log_Space_Used%] >= @TLog_Usage_Threshold
					
			--Build HTML string to send mail
			SET @tableHTML =
				N'<H1>Transaction Log Utilization</H1>' +
				N'<table border="1">' +
				N'<tr><th>Server_Name</th><th>DB_Name</th>' +
				N'<th>Log_Size_MB</th><th>Log_Space_Used%</th>' +
				N'<th>Log_Reuse_Wait_Desc</th><th>Recovery_Model</th></tr>' +
				CAST ( (	SELECT		td = [DB_Name], '' 
							, td = [Log_Size_MB], ''
							, td = [Log_Space_Used%], ''
							, td = [log_reuse_wait_desc], ''
							, td = [recovery_model_desc] 
							FROM		@tblTLogUtilization a
							INNER JOIN	sys.databases b
									ON	a.[DB_Name] = b.[name] COLLATE database_default
							WHERE		[Log_Space_Used%] >= @TLog_Usage_Threshold
							ORDER BY	[Log_Size_MB] DESC
				FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>' 		
		END		

--Disk Utilization Logic
	--Capture disk utilization for disks hosting SQL Server databases
	INSERT INTO @tblDiskUtilization([Drive], [Volume_Name], [Total_Size_GB], [Free_Space_GB], [Percent_Free])
	SELECT		DISTINCT volume_mount_point as Drive, 
				logical_volume_name as Volume_Name,
				CAST(total_bytes/1024./1024./1024. as decimal(20,2)) as Total_Size_GB, 
				CAST(available_bytes/1024./1024./1024. as decimal(20,2)) as Free_Space_GB,
				CAST((CAST(available_bytes as decimal(20,2))*100/total_bytes) as decimal(5,2)) as Percent_Free
	FROM		sys.master_files AS f
	CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id)
	WHERE		(CAST(available_bytes/1024./1024./1024. as decimal(20,2)) < @Disk_Free_Space_GB OR CAST((CAST(available_bytes as decimal(20,2))*100/total_bytes) as decimal(5,2)) > (100 - @Disk_Usage_Threshold))

	IF EXISTS (SELECT TOP 1 1 FROM @tblDiskUtilization)
		BEGIN
			SET @mailFlag = 1

			SELECT * FROM @tblDiskUtilization

			--Build HTML string to send mail
			SET @tableHTML = @tableHTML +
				N'<H1>Disk Space Utilization</H1>' +
				N'<table border="1">' +
				N'<tr><th>Server_Name</th><th>DB_Name</th>' +
				N'<th>Log_Size_MB</th><th>Log_Space_Used%</th>' +
				N'<th>Log_Reuse_Wait_Desc</th><th>Recovery_Model</th></tr>' +
				CAST ( (	SELECT	td = [Drive], '' 
							, td = [Volume_Name], ''
							, td = [Total_Size_GB], ''
							, td = [Free_Space_GB], ''
							, td = [Percent_Free] 
							FROM		@tblDiskUtilization
							ORDER BY	[Drive]
				FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>' 
		END

--CPU Utilization Logic
	SELECT	@varPresent_Time = ms_ticks 
	FROM    [sys].[dm_os_sys_info] 

	INSERT INTO @tblCPUUtilization([EventTime], [SQL_CPU_Utilization], [Total_CPU_UtilizationB])
	SELECT    
			DATEADD (ms, (B.[timestamp] - @varPresent_Time), GETDATE()) as EventTime,
			SQL_CPU_Utilization,  
			100 - SystemIdle
	FROM    ( 
				SELECT 
						record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') as SystemIdle, 
						record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') as SQL_CPU_Utilization,
						[timestamp] 
				FROM    ( 
							SELECT	[timestamp], CONVERT(xml, record) as record 
							FROM    [sys].[dm_os_ring_buffers]
							WHERE   ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
							AND     record like '%<SystemHealth>%') AS A
						)    AS B

	IF ((SELECT	AVG([Total_CPU_UtilizationB]) FROM	@tblCPUUtilization WHERE EventTime > DATEADD(mi, -15, GETDATE())) >= @CPU_Threshold)							
		BEGIN
			SET @mailFlag = 1

			SELECT	MIN([EventTime]) AS [Start_Time], 
					MAX([EventTime]) AS [End_Time], 
					AVG([SQL_CPU_Utilization]) AS [Average_SQL_CPU_Utilization], 
					AVG([Total_CPU_UtilizationB]) AS [Average_Total_CPU_Utilization]
			FROM	@tblCPUUtilization
			WHERE	EventTime > DATEADD(mi, -15, GETDATE())
			ORDER BY 1

			--Build HTML string to send mail
			SET @tableHTML = @tableHTML +
				N'<H1>CPU Utilization</H1>' +
				N'<table border="1">' +
				N'<tr><th>Server_Name</th><th>DB_Name</th>' +
				N'<th>Log_Size_MB</th><th>Log_Space_Used%</th>' +
				N'<th>Log_Reuse_Wait_Desc</th><th>Recovery_Model</th></tr>' +
				CAST ( (	SELECT	td = REPLACE([EventTime],'','_'), '' 
							, td = [SQL_CPU_Utilization], ''
							, td = [Total_CPU_UtilizationB]
							FROM		@tblCPUUtilization
							WHERE	EventTime > DATEADD(mi, -30, GETDATE())
							ORDER BY	[EventTime]
				FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>' 
		END

IF (@mailFlag = 1 AND @Mail_Recepients IS NOT NULL)
	BEGIN
		SELECT @mailSubject = '[DBMon]: ' + CAST(SERVERPROPERTY('servername') as varchar(255))

		EXEC msdb.dbo.sp_send_dbmail @recipients=@Mail_Recepients,
			@subject = @mailSubject,
			@body = @tableHTML,
			@body_format = 'HTML',
			@exclude_query_output = 1
	END
ELSE
	BEGIN
		PRINT 'All parameters within the threshold. No mail sent.'
	END
GO
