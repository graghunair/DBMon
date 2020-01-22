USE [dba_local]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--Drop the table before creating it.
IF  EXISTS (SELECT TOP 1 1 FROM [sys].[tables] WHERE [name] = 'tblDBMon_Table_Sizes' AND SCHEMA_NAME([schema_id]) = 'dbo')
	BEGIN
		DROP TABLE [dbo].[tblDBMon_Table_Sizes]
		PRINT 'Table: [dbo].[tblDBMon_Table_Sizes] dropped.'
	END
GO

--Create the table to store the data
CREATE TABLE [dbo].[tblDBMon_Table_Sizes](
					[Date_Captured] [datetime] NULL CONSTRAINT [DF_tblDBMon_Table_Sizes_Date_Captured]  DEFAULT (getdate()),
					[Database_Name] [sysname] NULL,
					[Table_Name] [sysname] NOT NULL,
					[Row_Count] [varchar](20) NULL,
					[Reserved] [varchar](50) NULL,
					[Data] [varchar](50) NULL,
					[Index_Size] [varchar](50) NULL,
					[UnUsed] [varchar](50) NULL)
GO
CREATE CLUSTERED INDEX [IDX_tblDBMon_Table_Sizes] ON [dbo].[tblDBMon_Table_Sizes] ([Date_Captured])
GO

IF  EXISTS (SELECT TOP 1 1 FROM [sys].[tables] WHERE [name] = 'tblDBMon_Table_Sizes' AND SCHEMA_NAME([schema_id]) = 'dbo')
	BEGIN
		PRINT 'Table: [dbo].[tblDBMon_Table_Sizes] created.'
	END
GO

IF  EXISTS (SELECT TOP 1 1 FROM [sys].[procedures] WHERE [name] = 'uspDBMon_GetTableSizes' AND SCHEMA_NAME([schema_id]) = 'dbo')
	BEGIN
		PRINT 'SP: [dbo].[uspDBMon_GetTableSizes] dropped.'
		DROP PROCEDURE [dbo].[uspDBMon_GetTableSizes]
	END
GO

CREATE PROCEDURE [dbo].[uspDBMon_GetTableSizes]
@Database_Name SYSNAME
AS
/*
	Author	:	Raghu Gopalakrishnan
	Date	:	22 January 2020
	Purpose	:	This Stored Procedure is used by the DBMon tool to capture Table sizes with a database
	Version	:	1.0 GTS
	License:
	This script is provided "AS IS" with no warranties, and confers no rights.
	https://github.com/graghunair/DBMon
				
				EXEC [dbo].[uspDBMon_GetTableSizes] @Database_Name = 'dba_local'
				SELECT * FROM [tblDBMon_Table_Sizes]

	Modification History
	----------------------
	Jan  22nd, 2020	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
*/
	SET NOCOUNT ON

	--Variable declarations
	DECLARE @varID			INT
	DECLARE @varTable_Name	VARCHAR(300)
	DECLARE @varSQL_Text	VARCHAR(4000)

	--Temporary table creation
	CREATE TABLE [dbo].[#tblList](
							[ID]	INT IDENTITY(1,1)	NOT NULL, 
							[Name]	VARCHAR(300)		NOT NULL)

	CREATE TABLE [dbo].[#tblDBMon_Table_Sizes](
							[Database_Name]		[sysname]		NULL,
							[Table_Name]		[sysname]		NOT NULL,
							[Row_Count]			[varchar] (20)	NULL,
							[Reserved]			[varchar] (50)	NULL,
							[Data]				[varchar] (50)	NULL,
							[Index_Size]		[varchar] (50)	NULL,
							[UnUsed]			[varchar] (50)	NULL,
							[Date_Captured]		[datetime]		NOT NULL DEFAULT GETDATE())

	--Capture list of tables in the database, passed as parameter to this SP
	SELECT @varSQL_Text = 
			'USE [' + @Database_Name + '] ' + 
			'INSERT INTO [dbo].[#tblList]([Name])
			SELECT ''['' + SCHEMA_NAME([schema_id]) + ''].['' +  [name] + '']''
			FROM [sys].[tables] '

	EXEC ( @varSQL_Text )

	--Loop trough each tables to capture the space details
	SELECT	@varID = MIN([ID]) 
	FROM	[dbo].[#tblList]

	WHILE(@varID IS NOT NULL)
		BEGIN
			SELECT	@varTable_Name = [Name] 
			FROM	[dbo].[#TblList] 
			WHERE	[ID] = @varID 

			SELECT @varTable_Name = REPLACE(@varTable_Name, '''', '''''')
			
			SELECT @varSQL_Text = 
			'USE [' + @Database_Name + '] ' +
			'INSERT INTO [dbo].[#tblDBMon_Table_Sizes] ([Table_Name], [Row_Count], [Reserved], [Data], [Index_Size], [UnUsed] )
			EXEC sp_spaceused ''' + @varTable_Name + ''''
			
			EXEC ( @varSQL_Text )

			SELECT @varID = MIN([ID]) FROM [dbo].[#tblList] WHERE [ID] > @varID	
		END
	
	--Purge date older than 31 days. We will retain data for Wednesdays and Sundays for date older than 1 month.	
	DELETE FROM [dba_local].[dbo].[tblDBMon_Table_Sizes]
	WHERE		Date_Captured < (GETDATE() - 31)
	AND			DATEPART(dw, Date_Captured) NOT IN (1,4)

	INSERT INTO [dba_local].[dbo].[tblDBMon_Table_Sizes] ([Database_Name], [Table_Name], [Row_Count], [Reserved], [Data], [Index_Size], [UnUsed], [Date_Captured])
	SELECT	@Database_Name, [Table_Name], [Row_Count], [Reserved], [Data], [Index_Size], [UnUsed], [Date_Captured] 
	FROM	[dbo].[#tblDBMon_Table_Sizes]
GO


IF EXISTS (SELECT 1 FROM fn_listextendedproperty('Version','SCHEMA','dbo','PROCEDURE', 'uspDBMon_GetTableSizes', NULL, NULL))
	BEGIN
		exec sp_dropextendedproperty 
			@name = 'Version',
			@level0type = 'Schema', @level0name = 'dbo', 
			@level1type = 'PROCEDURE', @level1name = 'uspDBMon_GetTableSizes'
			
		exec sp_addextendedproperty 
			@name = 'Version', @value = '1.0 GTS', 
			@level0type = 'SCHEMA', @level0name = 'dbo', 
			@level1type = 'PROCEDURE', @level1name = 'uspDBMon_GetTableSizes'
	END
ELSE
	BEGIN
		exec sp_addextendedproperty 
			@name = 'Version', @value = '1.0 GTS', 
			@level0type = 'SCHEMA', @level0name = 'dbo', 
			@level1type = 'PROCEDURE', @level1name = 'uspDBMon_GetTableSizes'
	END
GO

IF  EXISTS (SELECT TOP 1 1 FROM [sys].[procedures] WHERE [name] = 'uspDBMon_GetTableSizes' AND SCHEMA_NAME([schema_id]) = 'dbo')
	BEGIN
		PRINT 'SP: [dbo].[uspDBMon_GetTableSizes] created.'
	END
GO