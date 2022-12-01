SET NOCOUNT ON
GO
USE [DBA_Admin]
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
		SELECT 'Send Mail'
	END
GO

EXEC [dbo].[uspDBMon_rptAOAGDetails]
GO
