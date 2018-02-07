/*
	License	:	This script is provided "AS IS" with no warranties, and confers no rights.
	Author	:	Raghu Gopalakrishnan
	Date	:	6th February 2018
	Purpose	:	This Stored Procedure is used by the DBMon tool to report Errors and Warnings across servers
	Version	:	1.0
*/

SET NOCOUNT ON
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_WARNINGS OFF
GO

USE [dba_local]
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE [name] = 'tblDBMon_Errors_and_Warnings' AND SCHEMA_NAME([schema_id]) = 'dbo')
	BEGIN
		PRINT 'Table [dbo].[tblDBMon_Errors_and_Warnings] already exists. Dropping it first.'
		DROP TABLE [dbo].[tblDBMon_Errors_and_Warnings]
	END
GO

CREATE TABLE [dbo].[tblDBMon_Errors_and_Warnings](
	[Parameter_Name] [varchar](100) NOT NULL,
	[Parameter_Value] [bit] NOT NULL CONSTRAINT [DF_tblDBMon_Errors_and_Warnings_Parameter_Value] DEFAULT 0,
	[Is_Active] [bit]  NOT NULL CONSTRAINT [DF_tblDBMon_Errors_and_Warnings_Is_Active] DEFAULT 1,
	[Is_Active_Desc] [varchar](2000) NULL,
	[Date_Updated] [datetime]  NOT NULL CONSTRAINT [DF_tblDBMon_Errors_and_Warnings_Date_Captured] DEFAULT GETDATE(),
	[Updated_By] [nvarchar](128)  NOT NULL CONSTRAINT [DF_tblDBMon_Errors_and_Warnings_Updated_By] DEFAULT SUSER_SNAME(),
 CONSTRAINT [PK_tblDBMon_Errors_and_Warnings_Parameter_Name] PRIMARY KEY CLUSTERED ([Parameter_Name] ASC))
GO

INSERT INTO [dbo].[tblDBMon_Errors_and_Warnings] ([Parameter_Name]) VALUES ('Blocking')
INSERT INTO [dbo].[tblDBMon_Errors_and_Warnings] ([Parameter_Name]) VALUES ('DB_not_in_AG')
INSERT INTO [dbo].[tblDBMon_Errors_and_Warnings] ([Parameter_Name]) VALUES ('Deadlocks')
INSERT INTO [dbo].[tblDBMon_Errors_and_Warnings] ([Parameter_Name]) VALUES ('ERRORLOG')
INSERT INTO [dbo].[tblDBMon_Errors_and_Warnings] ([Parameter_Name]) VALUES ('File_System')
INSERT INTO [dbo].[tblDBMon_Errors_and_Warnings] ([Parameter_Name]) VALUES ('FileGroup_Free_Space')
INSERT INTO [dbo].[tblDBMon_Errors_and_Warnings] ([Parameter_Name]) VALUES ('Jobs_Backup')
INSERT INTO [dbo].[tblDBMon_Errors_and_Warnings] ([Parameter_Name]) VALUES ('Jobs_CheckDB')
INSERT INTO [dbo].[tblDBMon_Errors_and_Warnings] ([Parameter_Name]) VALUES ('Jobs_DBA')
INSERT INTO [dbo].[tblDBMon_Errors_and_Warnings] ([Parameter_Name]) VALUES ('Jobs_DBMon')
INSERT INTO [dbo].[tblDBMon_Errors_and_Warnings] ([Parameter_Name]) VALUES ('Jobs_Reindex')
INSERT INTO [dbo].[tblDBMon_Errors_and_Warnings] ([Parameter_Name]) VALUES ('LSN')
INSERT INTO [dbo].[tblDBMon_Errors_and_Warnings] ([Parameter_Name]) VALUES ('TLog_Free_Space')
GO

IF EXISTS (SELECT 1 FROM [dbo].[tblDBMon_Config_Details] WHERE [Config_Parameter] = 'Dashboard_FileGroup_Free_Space')
	BEGIN
		DELETE [dbo].[tblDBMon_Config_Details] WHERE [Config_Parameter] = 'Dashboard_FileGroup_Free_Space'
	END

	INSERT INTO [dbo].[tblDBMon_Config_Details]([Config_Parameter], [Config_Parameter_Value])
	VALUES('Dashboard_FileGroup_Free_Space', '80')

IF EXISTS (SELECT 1 FROM [dbo].[tblDBMon_Config_Details] WHERE [Config_Parameter] = 'Dashboard_TLog_Free_Space')
	BEGIN
		DELETE [dbo].[tblDBMon_Config_Details] WHERE [Config_Parameter] = 'Dashboard_TLog_Free_Space'
	END

	INSERT INTO [dbo].[tblDBMon_Config_Details]([Config_Parameter], [Config_Parameter_Value])
	VALUES('Dashboard_TLog_Free_Space', '60')

IF EXISTS (SELECT 1 FROM sys.procedures WHERE [name] = 'uspDBMon_GetErrorsAndWarnings' AND SCHEMA_NAME(schema_id) = 'dbo')
	BEGIN
		PRINT 'SP [dbo].[uspDBMon_GetErrorsAndWarnings] already exists. Dropping it first.'
		DROP PROC [dbo].[uspDBMon_GetErrorsAndWarnings]
	END
GO

CREATE PROCEDURE [dbo].[uspDBMon_GetErrorsAndWarnings]
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	6th February 2018
		Purpose	:	This Stored Procedure is used by the DBMon tool to report Errors and Warnings across servers.
		Version	:	1.0
		License:
		This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[uspDBMon_GetErrorsAndWarnings]
					SELECT * FROM [dbo].[tblDBMon_Errors_and_Warnings]

		Modification History
		----------------------
		Feb  6th, 2018	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
	*/
SET NOCOUNT ON

			--Variable declarations
			DECLARE @varDatabase_ID SMALLINT
			DECLARE @varDatabase_Name SYSNAME
			DECLARE @SQLText VARCHAR(2000)
			DECLARE @varDashboard_Database_Free_Space TINYINT
			DECLARE @varDashboard_TLog_Free_Space TINYINT

			--Table variable to store the output of DBCC SQLPERF(LOGSPACE)
			DECLARE	@tblTLog_Space TABLE	(
				[DB_Name]			NVARCHAR(128), 
				[Log_Size_MB]		DECIMAL(12,2), 
				[Log_Space_Used%]	DECIMAL(10,2), 
				[Status]			BIT)

			CREATE TABLE #tblDatabase_Sizes
			(
				[Database_Name] [nvarchar](128) NULL,
				[File_Group] [sysname] NOT NULL,
				[Current_Size_MB] [DECIMAL](38,2) NULL,
				[Used_Space_MB] [DECIMAL](38,2) NULL
			)

			--Loop trough each database to capture the space details
			SELECT	@varDatabase_ID = MIN([database_id]) 
			FROM	sys.databases
			WHERE	[state] = 0
	
	
			WHILE(@varDatabase_ID IS NOT NULL)
				BEGIN
					SELECT @varDatabase_Name = [name] FROM sys.databases  WHERE [database_id] = @varDatabase_ID 
				
					SELECT @SQLText = 
					'use [' + @varDatabase_Name + '] ' +
					'INSERT INTO #tblDatabase_Sizes
				   ([Database_Name]
				   ,[File_Group]
				   ,[Current_Size_MB]
				   ,[Used_Space_MB]) 
					SELECT ''' + @varDatabase_Name + '''
					,b.name
					,SUM(size/128.0)
					,SUM((size/128.0) - (size/128.0 - CAST(FILEPROPERTY(a.name , ''SpaceUsed'') as int)/128.0))
					from			sys.database_files a
					left outer join sys.filegroups b
					on a.data_space_id = b.data_space_id 
					WHERE			a.[type] <> 1
					GROUP BY		b.name,b.data_space_id'
			
					--PRINT @SQLText
			
					EXEC ( @SQLText )
					--PRINT @DB
			
					SELECT	@varDatabase_ID = MIN([database_id]) 
					FROM	sys.databases 
					WHERE	[database_id] > @varDatabase_ID	
					AND		[state] = 0
				END

			SELECT	@varDashboard_Database_Free_Space = CAST([Config_Parameter_Value] AS TINYINT)
			FROM	[dbo].[tblDBMon_Config_Details]
			WHERE	[Config_Parameter] = 'Dashboard_FileGroup_Free_Space'

			IF EXISTS (SELECT 1 FROM #tblDatabase_Sizes WHERE ((Used_Space_MB/Current_Size_MB)*100)>= @varDashboard_Database_Free_Space)
				BEGIN
					INSERT INTO [dbo].[tblDBMon_ERRORLOG] ([Source], [Message], [Alert_Flag] ) 
					VALUES	('Dashboard','Filegroup running out of space identified.',1)

					UPDATE [dbo].[tblDBMon_Errors_and_Warnings] 
					SET [Parameter_Value] = 1
					WHERE [Parameter_Name] = 'FileGroup_Free_Space'
				END
			ELSE
				BEGIN
					INSERT INTO [dbo].[tblDBMon_ERRORLOG] ([Source], [Message], [Alert_Flag] ) 
					VALUES	('Dashboard','All filegroups free space within threshold.',0)

					UPDATE [dbo].[tblDBMon_Errors_and_Warnings] 
					SET [Parameter_Value] = 0
					WHERE [Parameter_Name] = 'FileGroup_Free_Space'
				END

			--Capture the value of Transaction Log usage
			INSERT INTO @tblTLog_Space([DB_Name], [Log_Size_MB], [Log_Space_Used%], [Status])
			EXEC('dbcc sqlperf(logspace) with no_infomsgs')

			SELECT	@varDashboard_TLog_Free_Space = CAST([Config_Parameter_Value] AS TINYINT)
			FROM	[dbo].[tblDBMon_Config_Details]
			WHERE	[Config_Parameter] = 'Dashboard_TLog_Free_Space'

			IF EXISTS(SELECT 1 FROM @tblTLog_Space WHERE [Log_Space_Used%] >= @varDashboard_TLog_Free_Space)
				BEGIN
					INSERT INTO [dbo].[tblDBMon_ERRORLOG] ([Source], [Message], [Alert_Flag] ) 
					VALUES	('Dashboard','TLog running out of space identified.',1)

					UPDATE [dbo].[tblDBMon_Errors_and_Warnings] 
					SET [Parameter_Value] = 1
					WHERE [Parameter_Name] = 'TLog_Free_Space'
				END
			ELSE
				BEGIN
					INSERT INTO [dbo].[tblDBMon_ERRORLOG] ([Source], [Message], [Alert_Flag] ) 
					VALUES	('Dashboard','All TLog utilization less than threshold.',0)

					UPDATE [dbo].[tblDBMon_Errors_and_Warnings] 
					SET [Parameter_Value] = 0
					WHERE [Parameter_Name] = 'TLog_Free_Space'
				END

GO

EXEC sys.sp_addextendedproperty 
@name=N'Version', @value=N'1.0', @level0type=N'SCHEMA', @level0name=N'dbo', 
@level1type=N'PROCEDURE', @level1name=N'uspDBMon_GetErrorsAndWarnings'
GO

EXEC [dbo].[uspDBMon_GetErrorsAndWarnings]
GO
SELECT * FROM [dbo].[tblDBMon_Errors_and_Warnings] 
GO
SELECT * FROM [dbo].[tblDBMon_ERRORLOG] 
