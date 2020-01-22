/*
	Please install the script 'uspDBMon_GetTableSizes.sql' under the same GitHub repository since it is a prerequisite for this script.
		https://github.com/graghunair/DBMon
*/

USE [dba_local]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS (SELECT TOP 1 1 FROM [sys].[tables] WHERE [name] = 'tblDBMon_Database_Sizes' AND SCHEMA_NAME([schema_id]) = 'dbo')
	BEGIN
		DROP TABLE [dbo].[tblDBMon_Database_Sizes]
		PRINT 'Table: [dbo].[tblDBMon_Database_Sizes] dropped.'
	END
GO
		
CREATE TABLE [dbo].[tblDBMon_Database_Sizes](
					[Date_Captured] [datetime] NOT NULL CONSTRAINT [DF_tblDBMon_DB_Sizes_Date_Captured]  DEFAULT (getdate()),
					[Database_Name] [nvarchar](128) NULL,
					[File_Name]		[sysname] NOT NULL,
					[File_Group]	[sysname] NOT NULL,
					[Type] [varchar](10) NOT NULL,
					[Current_Size_MB] [int] NULL,
					[Used_Space_MB] [int] NULL,
					[Free_Space_MB] [int] NULL,
					[Physical_Name] [nvarchar](260) NOT NULL)
GO

CREATE CLUSTERED INDEX IDX_tblDBMon_Database_Sizes_Date_Captured ON [dbo].[tblDBMon_Database_Sizes] ([Date_Captured])
GO

IF  EXISTS (SELECT TOP 1 1 FROM [sys].[tables] WHERE [name] = 'tblDBMon_Database_Sizes' AND SCHEMA_NAME([schema_id]) = 'dbo')
	BEGIN
		PRINT 'Table: [dbo].[tblDBMon_Database_Sizes] created.'
	END
GO

IF  EXISTS (SELECT TOP 1 1 FROM [sys].[procedures] WHERE [name] = 'uspDBMon_GetDatabaseSizes' AND SCHEMA_NAME([schema_id]) = 'dbo')
	BEGIN
		PRINT 'SP: [dbo].[uspDBMon_GetDatabaseSizes] dropped.'
		DROP PROCEDURE [dbo].[uspDBMon_GetDatabaseSizes]
	END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspDBMon_GetDatabaseSizes]
AS
/*
	Author	:	Raghu Gopalakrishnan
	Date	:	22 January 2020
	Purpose	:	This Stored Procedure is used by the DBMon tool to capture Database and Table sizes
	Version	:	1.0 GDBS
	License:
	This script is provided "AS IS" with no warranties, and confers no rights.
	https://github.com/graghunair/DBMon
				
				EXEC [dbo].[uspDBMon_GetDatabaseSizes]
				SELECT * FROM [dbo].[tblDBMon_Database_Sizes]

				EXEC [dbo].[uspDBMon_GetTableSizes] @DBName = 'dba_local'
				SELECT * FROM [tblDBMon_Table_Sizes]

	Modification History
	----------------------
	Jan  22nd, 2020	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
*/
	SET NOCOUNT ON

	--Variable declarations
	DECLARE @varDatabase_Name SYSNAME
	DECLARE @varSQL_Text VARCHAR(4000)

	--Loop trough each database to capture the space details
	SELECT	@varDatabase_Name = MIN([name]) 
	FROM	[sys].[databases]
	WHERE	[state] = 0
	
	
	WHILE(@varDatabase_Name IS NOT NULL)
		BEGIN		
			SELECT @varSQL_Text = 
			'USE [' + @varDatabase_Name + '] ' +
			'INSERT INTO [dba_local].[dbo].[tblDBMon_Database_Sizes]
							   ([Database_Name]
							   ,[File_Name]
							   ,[File_Group]
							   ,[Type]
							   ,[Current_Size_MB]
							   ,[Used_Space_MB]
							   ,[Free_Space_MB]
							   ,[Physical_Name]) 
            SELECT			''' + @varDatabase_Name + ''',
							a.[name],
							ISNULL(b.[name], ''TLOG'') ,
							a.[type] ,
							[size]/128.0,
							([size]/128.0) - ([size]/128.0 - CAST(FILEPROPERTY(a.[name] , ''SpaceUsed'') as int)/128.0),
							([size]/128.0) - (CAST(FILEPROPERTY(a.name , ''SpaceUsed'') as int)/128.0),
							[physical_Name] 
			FROM			[sys].[database_files] a
			LEFT OUTER JOIN [sys].[filegroups] b
						ON	a.[data_space_id] = b.[data_space_id] 
			ORDER BY		a.[type], b.[name]'
			
			--PRINT @SQLText
			
			EXEC ( @varSQL_Text )
			
			IF (@varDatabase_Name <> 'tempdb')
			BEGIN
				EXEC [dba_local].[dbo].[uspDBMon_GetTableSizes] @Database_Name = @varDatabase_Name
			END 

			SELECT	@varDatabase_Name = MIN([name]) 
			FROM	[sys].[databases]
			WHERE	[state] = 0
			AND		[name] > @varDatabase_Name	
		END

	--Purge date older than 31 days. We will retain data for Wednesdays and Sundays for date older than 1 month.	
	DELETE FROM [dba_local].[dbo].[tblDBMon_Database_Sizes]
	WHERE		Date_Captured < (GETDATE() - 31)
	AND			DATEPART(dw, Date_Captured) NOT IN (1,4)
GO

IF EXISTS (SELECT 1 FROM fn_listextendedproperty('Version','SCHEMA','dbo','PROCEDURE', 'uspDBMon_GetDatabaseSizes', NULL, NULL))
	BEGIN
		EXEC sp_dropextendedproperty 
			@name = 'Version',
			@level0type = 'Schema', @level0name = 'dbo', 
			@level1type = 'PROCEDURE', @level1name = 'uspDBMon_GetDatabaseSizes'
			
		EXEC sp_addextendedproperty 
			@name = 'Version', @value = '1.0 GDBS', 
			@level0type = 'SCHEMA', @level0name = 'dbo', 
			@level1type = 'PROCEDURE', @level1name = 'uspDBMon_GetDatabaseSizes'
	END
ELSE
	BEGIN
		EXEC sp_addextendedproperty 
			@name = 'Version', @value = '1.0 GDBS', 
			@level0type = 'SCHEMA', @level0name = 'dbo', 
			@level1type = 'PROCEDURE', @level1name = 'uspDBMon_GetDatabaseSizes'
	END
GO

IF  EXISTS (SELECT TOP 1 1 FROM [sys].[procedures] WHERE [name] = 'uspDBMon_GetDatabaseSizes' AND SCHEMA_NAME([schema_id]) = 'dbo')
	BEGIN
		PRINT 'SP: [dbo].[uspDBMon_GetDatabaseSizes] created.'
	END
GO