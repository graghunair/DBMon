SET NOCOUNT ON
GO

USE [DBA_DBMon]
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_rptServer_Monitoring]
GO

CREATE PROCEDURE [dbo].[uspDBMon_rptServer_Monitoring]
	@Mail_Subject VARCHAR(2000) = '[MOCI]: SQL Server Monitoring',
	@Mail_Recipients VARCHAR(MAX) = 'dkunnummal@moci.gov.qa',
	@TLog_Utilization_Threshold TINYINT = 60,
	@Disk_Free_Space_GB SMALLINT = 50,
	@Disk_Free_Space_Percent TINYINT = 10
AS
SET NOCOUNT ON

/*
		Date		:		28th March, 2022
		Purpose		:		Send an email with SQL Server monitoring status
		Version		:		1.1

		SELECT * FROM [load].[tblDBMon_TLog_Utilization]
		SELECT * FROM [load].[tblDBMon_Database_State]
		SELECT * FROM [load].[tblDBMon_Disk_Space_Usage]
		SELECT * FROM [dbo].[tblDBMon_Servers_Connection_Failed]

		Modification History
		---------------------
		28th March, 2022	:	v1.0	:	Inception
		29th March, 2022	:	v1.1	:	Added logic to report Disk Space Usage below the threshold
*/

--Variable declarations
DECLARE @tableHTML_TLog_Utilization			VARCHAR(MAX)
DECLARE @tableHTML_Database_State			VARCHAR(MAX)
DECLARE @tableHTML_Server_Connection_Failed	VARCHAR(MAX)
DECLARE @tableHTML_Disk_Space_Usage			VARCHAR(MAX)
DECLARE @tableHTML							VARCHAR(MAX)

IF EXISTS (SELECT TOP 1 1 FROM [load].[tblDBMon_TLog_Utilization] WHERE [Log_Space_Used_Percent] > @TLog_Utilization_Threshold)
	BEGIN
		SET @tableHTML_TLog_Utilization = 
					N'<H3>Transaction Log Utilization (AJS_SBS)</H3>' +
					N'<table border="1";padding-left:50px>' +
					N'<div style="margin-left:500px"></div>' + 
					N'<tr><th>Server Name</th>' +
					N'<th>Database Name</th>' +
					N'<th>Log Size(MB)</th>' + 
					N'<th>Log Used (%)</th>' +
					N'<th>Log Reuse Wait Desc</th>' +
					N'<th>Recovery Model</th>' +
					N'<th>Backup Minutes Ago</th>' +
					N'<th>Date Captured</th></tr>' +
					CAST ( (	SELECT		td = [Server_Name], '',
											td = [Database_Name], '',
											td = [Log_Size_MB], '',
											td = [Log_Space_Used_Percent], '',
											td = [Log_Reuse_Wait_Desc], '',
											td = [Recovery_Model], '',
											td = [TLog_Backup_Mins_Ago], '',
											td = REPLACE([Date_Captured], ' ', '_')
								FROM		[load].[tblDBMon_TLog_Utilization]
								WHERE		[Log_Space_Used_Percent] > @TLog_Utilization_Threshold
								ORDER BY	[Server_Name], [Database_Name]
								FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +	N'</table>'
	END
ELSE
	BEGIN
		SET @tableHTML_TLog_Utilization = N'<H3>No database identified with Transaction Log Utilization exceeding threshold - ' + CAST(@TLog_Utilization_Threshold AS VARCHAR(10)) + '.</H3>'
	END

IF EXISTS (SELECT TOP 1 1 FROM [load].[tblDBMon_Database_State] WHERE [State] <> 'ONLINE')
	BEGIN
		SET @tableHTML_Database_State = 
					N'<H3>Database State</H3>' +
					N'<table border="1";padding-left:50px>' +
					N'<div style="margin-left:500px"></div>' + 
					N'<tr><th>Server Name</th>' + 
					N'<th>Database Name</th>' +
					N'<th>State</th>' +
					N'<th>User Access</th>' +
					N'<th>Is Read Only</th>' +
					N'<th>Date Captured</th></tr>' +
					CAST ( (	SELECT	 
											td = [Server_Name], '',
											td = [Database_Name], '',
											td = [State], '',
											td = [User_Access], '',
											td = [Is_Read_Only], '',
											td = REPLACE([Date_Captured], ' ', '_')
								FROM		[load].[tblDBMon_Database_State]
								WHERE		[State] <> 'ONLINE'
								ORDER BY	[Server_Name], [Database_Name]
								FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) + N'</table>'
	END
ELSE
	BEGIN
		SET @tableHTML_Database_State = N'<H3>All database reported state as ONLINE.</H3>'
	END

IF EXISTS (SELECT TOP 1 1 FROM [load].[tblDBMon_Disk_Space_Usage] WHERE ([Percent_Free] < @Disk_Free_Space_Percent OR [Free_Space_GB] < @Disk_Free_Space_GB))
	BEGIN
		SET @tableHTML_Disk_Space_Usage = 
					N'<H3>Disk Space Usage</H3>' +
					N'<table border="1";padding-left:50px>' +
					N'<div style="margin-left:500px"></div>' + 
					N'<tr><th>Server Name</th>' + 
					N'<th>Drive</th>' +
					N'<th>Volume Name</th>' +
					N'<th>Total Size (GB)</th>' +
					N'<th>Free_Space (GB)</th>' +
					N'<th>Percent Free</th>' +
					N'<th>Date Captured</th></tr>' +
					CAST ( (	SELECT	 
											td = [Server_Name], '',
											td = [Drive], '',
											td = [Volume_Name], '',
											td = [Total_Size_GB], '',
											td = [Free_Space_GB], '',
											td = [Percent_Free], '',
											td = REPLACE([Date_Captured], ' ', '_')
								FROM		[load].[tblDBMon_Disk_Space_Usage]
								WHERE		([Percent_Free] < @Disk_Free_Space_Percent OR [Free_Space_GB] < @Disk_Free_Space_GB)
								ORDER BY	[Server_Name], [Drive]
								FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) + N'</table>'
	END
ELSE
	BEGIN
		SET @tableHTML_Disk_Space_Usage = N'<H3>All disks reported free space greater than the threshold.</H3>'
	END

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_Servers_Connection_Failed])
	BEGIN
		SET @tableHTML_Server_Connection_Failed = 
					N'<H3>SQL Server Connection Failed</H3>' +
					N'<table border="1";padding-left:50px>' +
					N'<div style="margin-left:500px"></div>' + 
					N'<tr><th>ID</th>' + 
					N'<th>Server Name</th>' +
					N'<th>Date Captured</th></tr>' +
					CAST ( (	SELECT		
											td = [ID], '',
											td = [Server_Name], '',
											td = REPLACE([Date_Captured], ' ', '_')
								FROM		[dbo].[tblDBMon_Servers_Connection_Failed]
								ORDER BY	[ID]
								FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +	N'</table>'
	END
ELSE
	BEGIN
		SET @tableHTML_Server_Connection_Failed = N'<H3>Connection to all SQL Servers successful.</H3>'
	END

SET @tableHTML = @tableHTML_TLog_Utilization + @tableHTML_Database_State + @tableHTML_Disk_Space_Usage + @tableHTML_Server_Connection_Failed

EXEC msdb.dbo.sp_send_dbmail 
			@recipients = @Mail_Recipients,
			@subject = @Mail_Subject,
			@body = @tableHTML,
			@body_format = 'HTML'
GO
