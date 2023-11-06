SET NOCOUNT ON
GO

USE [dba_local]
GO

DROP PROC IF EXISTS [dbo].[uspDBMon_Smart_TLog_Backup_To_Disk]
GO

CREATE PROC [dbo].[uspDBMon_Smart_TLog_Backup_To_Disk]
@TLog_Utilization_Percentage_Threshold TINYINT = 40,
@TLog_Backup_Minutes_Ago_Threshold INT = 240,
@Backup_Directory NVARCHAR(128) = NULL
AS
/*    
	Author	:    Raghu Gopalakrishnan    
	Date	:    11th November 2023
	Purpose	:    This Stored Procedure is identify whether a TLog backup needs to be initiated or not  
	Version :    1.0                              
	License:	This script is provided "AS IS" with no warranties, and confers no rights.
					
			EXEC [dbo].[uspDBMon_Smart_TLog_Backup_To_Disk] 
						@TLog_Utilization_Percentage_Threshold = 40,
						@TLog_Backup_Minutes_Ago_Threshold = 230454,
						@Backup_Directory = NULL
			
	Modification History    
	-----------------------    
	Nov 11th, 2023    :    v1.0    :    Raghu Gopalakrishnan    :    Inception
*/

SET NOCOUNT ON

DECLARE		@Backup_File_Name VARCHAR(2000),
			@Database_Name SYSNAME,
			@Backup_Command VARCHAR(MAX)

DECLARE		@tblTLog_Utilization TABLE
			([Database_Name] SYSNAME,
			[Log_Size_MB] DECIMAL(12,2),
			[Log_Space_Used%] DECIMAL(6,2),
			[Status] BIT)

DECLARE		@tblDatabases_For_TLog_Backup TABLE
			([Database_Name] SYSNAME,
			[Backup_Command] VARCHAR(MAX))

--Capture the value of Transaction Log usage
INSERT INTO @tblTLog_Utilization([Database_Name], [Log_Size_MB], [Log_Space_Used%], [Status])
EXEC('dbcc sqlperf(logspace) with no_infomsgs')

IF (@Backup_Directory IS NULL)
	BEGIN
		SELECT @Backup_Directory = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(128))
		SELECT @Backup_File_Name = '_' + REPLACE(REPLACE(CAST(GETDATE() AS VARCHAR(25)),' ','_'),':','_') + '.trn'
	END

SELECT			d.[name] AS [Database_Name],
				CASE	
					WHEN	ls.[log_backup_time] = '1900-01-01 00:00:00.000' THEN '** SIMPLE Recovery Model **'
					ELSE	CAST(ls.[log_backup_time] AS VARCHAR(23))
				END [TLog_Backup_Time],
				CASE
					WHEN	d.[recovery_model_desc] = 'SIMPLE' THEN 0
					ELSE	DATEDIFF(mi, ls.[log_backup_time], GETDATE()) 
				END [TLog_Backup_Minutes_Ago],
				ls.[log_truncation_holdup_reason] AS [Log_Truncation_Holdup_Reason],
				ROUND(ls.[total_log_size_mb],0) AS [TLog_Size_MB],
				tlu.[Log_Space_Used%] AS [Log_Space_Used(%)],
				ls.[total_vlf_count] AS [VLF_Count],
				CAST(DATABASEPROPERTYEX (d.[name], 'Status') AS SYSNAME) + ' - ' + 
				CAST(DATABASEPROPERTYEX (d.[name], 'Updateability')  AS SYSNAME) AS [Database_State]
FROM			sys.databases AS d
LEFT OUTER JOIN @tblTLog_Utilization tlu
ON				d.[name] = tlu.[Database_Name]
OUTER APPLY		sys.dm_db_log_stats(d.database_id)  ls
WHERE			d.[recovery_model_desc] <> 'SIMPLE'
AND				(DATEDIFF(mi, ls.[log_backup_time], GETDATE()) >= @TLog_Backup_Minutes_Ago_Threshold
				OR
				tlu.[Log_Space_Used%] >= @TLog_Utilization_Percentage_Threshold)
ORDER BY		d.[name]

INSERT INTO		@tblDatabases_For_TLog_Backup
SELECT			d.[name] AS [Database_Name],
				'BACKUP LOG [' + d.[name] + '] TO DISK = N''' + @Backup_Directory + '\' + 
				d.[name] + @Backup_File_Name + ''' WITH COMPRESSION, STATS=10'
				AS [Backup_Command]
FROM			sys.databases AS d
LEFT OUTER JOIN @tblTLog_Utilization tlu
ON				d.[name] = tlu.[Database_Name]
OUTER APPLY		sys.dm_db_log_stats(d.database_id)  ls
WHERE			d.[recovery_model_desc] <> 'SIMPLE'
AND				(DATEDIFF(mi, ls.[log_backup_time], GETDATE()) >= @TLog_Backup_Minutes_Ago_Threshold
				OR
				tlu.[Log_Space_Used%] >= @TLog_Utilization_Percentage_Threshold)
ORDER BY		d.[name]

SELECT			@Database_Name = MIN([Database_Name])
FROM			@tblDatabases_For_TLog_Backup

WHILE (@Database_Name IS NOT NULL)
	BEGIN
		SELECT	@Backup_Command = Backup_Command
		FROM	@tblDatabases_For_TLog_Backup
		WHERE	[Database_Name] = @Database_Name

		PRINT	@Backup_Command
		EXEC	(@Backup_Command)

		SELECT	@Database_Name = MIN([Database_Name])
		FROM	@tblDatabases_For_TLog_Backup
		WHERE	@Database_Name < [Database_Name]
	END
GO

EXEC [dbo].[uspDBMon_Smart_TLog_Backup_To_Disk] 
			@TLog_Utilization_Percentage_Threshold = 40,
			@TLog_Backup_Minutes_Ago_Threshold = 240,
			@Backup_Directory = NULL
GO
