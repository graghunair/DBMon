SET NOCOUNT ON
GO
USE [DBA_DBMon]
GO

DROP PROC IF EXISTS [dbo].[uspDBMon_rptAOAGDetails]
GO
CREATE PROCEDURE [dbo].[uspDBMon_rptAOAGDetails]
	@Mail_Flag BIT = 0,
	@Mail_Subject VARCHAR(2000) = '[Customer]: SQL Server AOAG Health Report',
	@Mail_Recipients VARCHAR(MAX) = '<emailaddress>',
	@TLog_Percent_Space_Used_Threshold TINYINT = 0,
	@Disk_Percent_Free_Threshold TINYINT = 0
AS
SET NOCOUNT ON

/*
		Date		:		1st December, 2022
		Purpose		:		Send an email with SQL Server AOAG status
		Version		:		1.0

		SELECT * FROM [dbo].[tblDBMon_AOAG_Primary_Replica]
		SELECT * FROM [dbo].[tblDBMon_AOAG_Database_Details]
		SELECT * FROM [dbo].[tblDBMon_Disk_Free_Space]
		SELECT * FROM [dbo].[tblDBMon_Transaction_Log_Free_Space]
		SELECT * FROM [dbo].[tblDBMon_SQL_Server_Info]

		EXEC [dbo].[uspDBMon_rptAOAGDetails]
		
		Modification History
		---------------------
		1st Dec, 2022	:	v1.0	:	Inception
*/

--Variable declarations
DECLARE @tableHTML	VARCHAR(MAX)

SELECT		* 
FROM		[dbo].[tblDBMon_AOAG_Primary_Replica]
ORDER BY	[Listener_Name], [Availability_Group_Name], [Replica_Name]

SELECT		* 
FROM		[dbo].[tblDBMon_AOAG_Database_Details]
ORDER BY	[Availability_Group_Name], [Database_Name]
		
SELECT		* 
FROM		[dbo].[tblDBMon_Disk_Free_Space] 
WHERE		[Percent_Free] > @Disk_Percent_Free_Threshold
ORDER BY	[SQL_Server_Name], [Drive]
		
SELECT		* 
FROM		[dbo].[tblDBMon_Transaction_Log_Free_Space]
WHERE		[Log_Space_Used_%] > @TLog_Percent_Space_Used_Threshold
ORDER BY	[Log_Space_Used_%], [SQL_Server_Name]

SELECT		* 
FROM		[dbo].[tblDBMon_SQL_Server_Info]
ORDER BY	[SQL_Server_Name]

IF (@Mail_Flag = 1)
	BEGIN
		SET @tableHTML = 
				N'<H3>Primary Replica</H3>' +
				N'<table border="1";padding-left:50px>' +
				N'<div style="margin-left:500px"></div>' + 
				N'<tr><th>Listener Name</th><th>Listener IP</th>' + 
				N'<th>Port</th><th>AG Name</th>' +
				N'<th>Role</th>' +
				N'<th>Replica Name</th>' +
				N'<th>Date Captured(Mins)</th></tr>' +
				CAST ( (	SELECT	 
										td = [Listener_Name], '',
										td = [Listener_IP_Address], '',
										td = [Listener_Port], '',
										td = [Availability_Group_Name], '',
										td = [Role], '',
										td = [Replica_Name], '',
										td = [Date_Captured]
							FROM		[dbo].[tblDBMon_AOAG_Primary_Replica]
							ORDER BY	[Listener_Name]
							FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +	N'</table>'

		SET @tableHTML = @tableHTML +
				N'<H3>Database Details</H3>' +
				N'<table border="1";padding-left:50px>' +
				N'<div style="margin-left:500px"></div>' + 
				N'<tr><th>AG Name</th><th>Database Name</th>' + 
				N'<th>Sync State</th><th>Sync Health</th>' +
				N'<th>Log Send Queue</th>' +
				N'<th>Redo Queue</th>' +
				N'<th>Date Captured</th></tr>' +
				CAST ( (	SELECT	 
										td = [Availability_Group_Name], '',
										td = [Database_Name], '',
										td = [Synchronization_State], '',
										td = [Synchronization_Health], '',
										td = [Log_Send_Queue_Size], '',
										td = [Redo_Queue_Size], '',
										td = [Date_Captured]
							FROM		[dbo].[tblDBMon_AOAG_Database_Details]
							ORDER BY	[Availability_Group_Name]
							FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +	N'</table>'

		SET @tableHTML = @tableHTML +
				N'<H3>Disk Space</H3>' +
				N'<table border="1";padding-left:50px>' +
				N'<div style="margin-left:500px"></div>' + 
				N'<tr><th>SQL Server</th><th>Drive</th>' + 
				N'<th>Volume Name</th><th>Total Size (GB)</th>' +
				N'<th>Free Space (GB)</th>' +
				N'<th>Percent Free</th>' +
				N'<th>Date Captured</th></tr>' +
				CAST ( (	SELECT	 
										td = [SQL_Server_Name], '',
										td = [Drive], '',
										td = [Volume_Name], '',
										td = [Total_Size_GB], '',
										td = [Free_Space_GB], '',
										td = [Percent_Free], '',
										td = [Date_Captured]
							FROM		[dbo].[tblDBMon_Disk_Free_Space]
							ORDER BY	[SQL_Server_Name]
							FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +	N'</table>'

		SET @tableHTML = @tableHTML +
				N'<H3>Transaction Log</H3>' +
				N'<table border="1";padding-left:50px>' +
				N'<div style="margin-left:500px"></div>' + 
				N'<tr><th>SQL Server</th><th>Database Name</th>' + 
				N'<th>Log Size(MB)</th><th>Log Space Used %</th>' +
				N'<th>Date Captured</th></tr>' +
				CAST ( (	SELECT	 
										td = [SQL_Server_Name], '',
										td = [Database_Name], '',
										td = [Log_Size_MB], '',
										td = [Log_Space_Used_%], '',
										td = [Date_Captured]
							FROM		[dbo].[tblDBMon_Transaction_Log_Free_Space]
							ORDER BY	[SQL_Server_Name]
							FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +	N'</table>'

		SET @tableHTML = @tableHTML +
				N'<H3>SQL Server Info</H3>' +
				N'<table border="1";padding-left:50px>' +
				N'<div style="margin-left:500px"></div>' + 
				N'<tr><th>SQL Server</th><th>UpTime Days</th>' + 
				N'<th>SQL Server Version</th><th>OS Version</th>' +
				N'<th>CPU Count</th><th>RAM</th>' +
				N'<th>RAM Committed</th>' +
				N'<th>Date Captured</th></tr>' +
				CAST ( (	SELECT	 
										td = [SQL_Server_Name], '',
										td = [UpTime_Days], '',
										td = [SQL_Server_Version], '',
										td = [OS_Version], '',
										td = [CPU_Count], '',
										td = [RAM], '',
										td = [RAM_Committed], '',
										td = [Date_Captured]
							FROM		[dbo].[tblDBMon_SQL_Server_Info]
							ORDER BY	[SQL_Server_Name]
							FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +	N'</table>'

		EXEC msdb.dbo.sp_send_dbmail @recipients = @Mail_Recipients,
						@subject = @Mail_Subject,
						@profile_name = N'<profile-name>',
						@body = @tableHTML,
						@body_format = 'HTML'
	END
GO

EXEC [dbo].[uspDBMon_rptAOAGDetails]
GO
