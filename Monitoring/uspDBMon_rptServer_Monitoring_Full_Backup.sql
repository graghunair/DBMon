SET NOCOUNT ON
GO

USE [DBA_DBMon]
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_rptServer_Monitoring_Full_Backup]
GO

CREATE PROCEDURE [dbo].[uspDBMon_rptServer_Monitoring_Full_Backup]
	@Mail_Subject VARCHAR(2000) = '[MOCI]: SQL Server Monitoring - Full Backup',
	@Mail_Recipients VARCHAR(MAX) = 'dkunnummal@moci.gov.qa',
	@Full_Backup_Hours_Threshold TINYINT = 24
AS
SET NOCOUNT ON

/*
		Date		:		29th March, 2022
		Purpose		:		Send an email with SQL Server Full Backup monitoring status
		Version		:		1.0

		SELECT * FROM [load].[tblDBMon_Database_Full_Backup_Timestamp]
		EXEC [dbo].[uspDBMon_rptServer_Monitoring_Full_Backup]

		Modification History
		---------------------
		29th March, 2022	:	v1.0	:	Inception
*/

--Variable declarations
DECLARE @tableHTML_Full_Backup				VARCHAR(MAX)
DECLARE @tableHTML_Server_Connection_Failed	VARCHAR(MAX)
DECLARE @tableHTML							VARCHAR(MAX)

IF EXISTS (SELECT TOP 1 1 FROM [load].[tblDBMon_Database_Full_Backup_Timestamp] WHERE ([Backup_Finish_Date] < DATEADD(hh, -@Full_Backup_Hours_Threshold, GETDATE())))
	BEGIN
		SET @tableHTML_Full_Backup = 
					N'<H3>Full Backups Missing</H3>' +
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
											td = REPLACE([Backup_Finish_Date], ' ', '_'), '',
											td = REPLACE([Date_Captured], ' ', '_')
								FROM		[load].[tblDBMon_Database_Full_Backup_Timestamp] 
								WHERE		([Backup_Finish_Date] < DATEADD(hh, -@Full_Backup_Hours_Threshold, GETDATE()))
								ORDER BY	[Server_Name], [Database_Name]
								FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +	N'</table>'
	END
ELSE
	BEGIN
		SET @tableHTML_Full_Backup = N'<H3>No database identified with full backup exceeding threshold - ' + CAST(@Full_Backup_Hours_Threshold AS VARCHAR(3)) + ' hours.</H3>'
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

SET @tableHTML = @tableHTML_Full_Backup + @tableHTML_Server_Connection_Failed

EXEC msdb.dbo.sp_send_dbmail 
			@recipients = @Mail_Recipients,
			@subject = @Mail_Subject,
			@body = @tableHTML,
			@body_format = 'HTML'
GO
