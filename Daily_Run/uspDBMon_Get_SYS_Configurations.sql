SET NOCOUNT ON

--Drop the procedure if it already exists
USE [dba_local]
GO

--Create the use table to host data
SET QUOTED_IDENTIFIER ON
GO
IF EXISTS (SELECT 1 FROM [sys].[tables] WHERE [name] = 'tblDBMon_SYS_Configurations' AND schema_id = schema_id('dbo'))
BEGIN
	PRINT 'The procedure: [dbo].[uspDBMon_Get_SYS_Configurations] already exists. Dropping it first.'
	DROP TABLE [dbo].[tblDBMon_SYS_Configurations]
END

CREATE TABLE [dbo].[tblDBMon_SYS_Configurations](
	[Date_Captured] [datetime] NOT NULL CONSTRAINT [DF_tblDBMon_SYS_Configurations_Date_Captured] DEFAULT GETDATE(),
	[Config_Name] [nvarchar](35) NOT NULL,
	[Value] [varchar](1000) NULL,
	[Value_in_Use] [varchar](1000) NULL
) 
GO
CREATE CLUSTERED INDEX IDX_tblDBMon_SYS_Configurations_Date_Captured ON [dbo].[tblDBMon_SYS_Configurations](Date_Captured)
GO

INSERT INTO [dbo].[tblDBMon_SYS_Configurations](Config_Name, [Value], Value_in_Use)
SELECT	[name] Config_Name, 
		CAST([value] AS VARCHAR(1000)) [Value], 
		CAST(value_in_use  AS VARCHAR(1000)) Value_in_Use
FROM	sys.configurations
GO

IF EXISTS (SELECT 1 FROM [sys].[procedures] WHERE [name] = 'uspDBMon_Get_SYS_Configurations' AND schema_id = SCHEMA_ID('dbo'))
	BEGIN
		PRINT 'The procedure: [dbo].[uspDBMon_Get_SYS_Configurations] already exists. Dropping it first.'
		DROP PROC [dbo].[uspDBMon_Get_SYS_Configurations]
	END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_WARNINGS OFF
GO

--Create the procedure
CREATE PROCEDURE [dbo].[uspDBMon_Get_SYS_Configurations]
AS
/*
	Author	:	Raghu Gopalakrishnan
	Date	:	28th November 2017
	Purpose	:	This Stored Procedure is used by the DBMon tool to capture server configuration changes
				so that we have historical data to review changes over a period of time.
	Version	:	1.0

	License:
	This script is provided "AS IS" with no warranties, and confers no rights.

				EXEC [dbo].[uspDBMon_Get_SYS_Configurations]
				SELECT * FROM [dbo].[tblDBMon_SYS_Configurations]

	Modification History
	----------------------
	Nov  28th, 2017	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
*/
	SET NOCOUNT ON
	DECLARE @varConfig_Name NVARCHAR(35)
	DECLARE @varDate_Captured DATETIME

	SELECT  @varConfig_Name = MIN ([name])
	FROM	[sys].[configurations]

	WHILE (@varConfig_Name IS NOT NULL)
		BEGIN
			SELECT  @varDate_Captured = MAX(Date_Captured)
			FROM	[dbo].[tblDBMon_SYS_Configurations]
			WHERE	Config_Name = @varConfig_Name

			INSERT INTO		[dbo].[tblDBMon_SYS_Configurations](Config_Name, [Value], Value_in_Use)
			SELECT			A.[name],
							CAST(A.[value] AS VARCHAR(1000)),
							CAST(A.value_in_use AS VARCHAR(1000))
			FROM			[sys].[configurations] A
			LEFT OUTER JOIN [dbo].[tblDBMon_SYS_Configurations] B
			ON				A.[name] = B.Config_Name
			WHERE			A.[name] = @varConfig_Name
			AND				B.Date_Captured = @varDate_Captured
			AND				(CAST(A.value AS VARCHAR(1000)) <> B.Value OR CAST(A.value_in_use AS VARCHAR(1000)) <> B.Value_in_Use)

			SELECT  @varConfig_Name = MIN ([name])
			FROM	[sys].[configurations]
			WHERE	[name] > @varConfig_Name
		END
GO
