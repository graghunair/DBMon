USE [dba_local]
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_TempDB_Space_Usage]
GO
CREATE TABLE [dbo].[tblDBMon_TempDB_Space_Usage](
	[Date_Captured] [datetime] NOT NULL,
	[Total_Size_MB] [decimal](32, 2) NULL,
	[FreeSpace_MB] [decimal](32, 2) NULL,
	[User_Objects_MB] [decimal](32, 2) NULL,
	[Internal_Objects_MB] [decimal](32, 2) NULL,
	[Version_Store_MB] [decimal](32, 2) NULL,
	[Mixed_Extent_MB] [decimal](32, 2) NULL
) 
GO

CREATE CLUSTERED INDEX IDX_tblDBMon_TempDB_Space_Usage ON [dbo].[tblDBMon_TempDB_Space_Usage]([Date_Captured] DESC)
GO

DROP PROC IF EXISTS [dbo].[uspDBMon_GetTempDBSpaceUsage]
GO
CREATE PROC [dbo].[uspDBMon_GetTempDBSpaceUsage]
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	18th June 2024
		Purpose	:	This Stored Procedure is used to capture TempDB Space Usage breakup
		Version	:	1.0
		License:
					This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[dbo].[uspDBMon_GetTempDBSpaceUsage]
					GO
					SELECT * FROM [dbo].[tblDBMon_TempDB_Space_Usage]
					GO

		Modification History
		----------------------
		June	18th, 2024	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
	*/

SET NOCOUNT ON

INSERT INTO [dbo].[tblDBMon_TempDB_Space_Usage]
SELECT
		GETDATE() AS Date_Captured,
		CAST(SUM ((total_page_count)*8)/1024. AS DECIMAL(32,2)) as Total_Size_MB,
		CAST(SUM ((unallocated_extent_page_count)*8)/1024. AS DECIMAL(32,2)) as FreeSpace_MB,
		CAST(SUM ((user_object_reserved_page_count)*8)/1024. AS DECIMAL(32,2)) as User_Objects_MB,
		CAST(SUM ((internal_object_reserved_page_count)*8)/1024. AS DECIMAL(32,2)) as Internal_Objects_MB,
		CAST(SUM ((version_store_reserved_page_count)*8)/1024. AS DECIMAL(32,2))  as Version_Store_MB,
		CAST(SUM ((mixed_extent_page_count)*8)/1024. AS DECIMAL(32,2)) as Mixed_Extent_MB
FROM	tempdb.sys.dm_db_file_space_usage 
GO

EXEC [dbo].[uspDBMon_GetTempDBSpaceUsage]
GO
SELECT * FROM [dbo].[tblDBMon_TempDB_Space_Usage]
GO
