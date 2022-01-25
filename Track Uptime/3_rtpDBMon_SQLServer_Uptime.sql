SET NOCOUNT ON
GO

--Change the database name if necessary
USE [dba_local]
GO

--Drop the procedure if exists to accomodate the changes.
DROP PROC IF EXISTS [dbo].[rtpDBMon_SQLServer_Uptime]
GO
CREATE PROC [dbo].[rtpDBMon_SQLServer_Uptime]
AS
SET NOCOUNT ON
/*
	Date		:		Jan 25th, 2022
	Purpose		:		Calculate SQL Server Uptime based on historical capture of restart timestamps
	Version		:		1.0
	Execute		:
						EXEC [dbo].[rtpDBMon_SQLServer_Uptime]
						SELECT	TOP 10 *
						FROM	[dbo].[tblDBMon_Track_Instance_Restart]
						ORDER BY [ID] DESC

	Modification:	
			Jan 25th, 2022	:	Raghu		:	Inception
*/


DECLARE @varMax_ID INT, @varMin_ID INT
DECLARE @tblTemp TABLE(
	[ID] INT,
	[SQLServer_Start_Time]	DATETIME,
	[Last_Updated]			DATETIME,
	[SQLServer_Host]		NVARCHAR(128),
	[SQLServer_Instance]	NVARCHAR(128),
	[Downtime_Seconds]		INT)

DECLARE @tblOutput TABLE(
	[ID] INT,
	[SQLServer_Start_Time]				DATETIME,
	[Last_Recorded_Online_Timestamp]	DATETIME,
	[SQLServer_Host]					NVARCHAR(128),
	[SQLServer_Instance]				NVARCHAR(128),
	[Downtime_Seconds]					INT,
	[Downtime]							VARCHAR(8))

SELECT	@varMax_ID = MAX(ID), 
		@varMin_ID = MIN(ID) 
FROM	[dbo].[tblDBMon_Track_Instance_Restart]

WHILE	(@varMax_ID >= @varMin_ID + 1)
	BEGIN
		INSERT INTO @tblTemp
		SELECT		TIR2.*,
					DATEDIFF(ss, TIR2.[Last_Updated], TIR1.[SQLServer_Start_Time])
		FROM  
				( 
					SELECT		[SQLServer_Start_Time],
								[SQLServer_Instance]
					FROM		[dbo].[tblDBMon_Track_Instance_Restart]
					WHERE		[ID] = @varMax_ID
				)	AS TIR1  
		 INNER JOIN  
				( 
					SELECT		[ID] ,
								[SQLServer_Start_Time],
								[Last_Updated],
								[SQLServer_Host],
								[SQLServer_Instance]
					FROM		[dbo].[tblDBMon_Track_Instance_Restart]
					WHERE		[ID] = (@varMax_ID-1)
				 )	AS TIR2 
			ON TIR1.[SQLServer_Instance] = TIR2.[SQLServer_Instance]
		
			SELECT	@varMax_ID = @varMax_ID - 1
	END

INSERT INTO @tblOutput
SELECT	[ID], 
		[SQLServer_Start_Time], 
		[Last_Updated], 
		[SQLServer_Host], 
		[SQLServer_Instance],
		[Downtime_Seconds], 
		CAST( [Downtime_Seconds]/60 AS VARCHAR(2)) + 'm:' +  CAST( [Downtime_Seconds]%60 AS VARCHAR(2)) + 's' [Downtime]
FROM	@tblTemp

INSERT INTO @tblOutput
SELECT	[ID], 
		[SQLServer_Start_Time], 
		[Last_Updated], 
		[SQLServer_Host], 
		[SQLServer_Instance],
		NULL,
		NULL
FROM	[dbo].[tblDBMon_Track_Instance_Restart]
WHERE	[Current] = 1

SELECT	[ID], 
		[SQLServer_Start_Time], 
		[Last_Recorded_Online_Timestamp], 
		DATEDIFF(mi, [SQLServer_Start_Time], [Last_Recorded_Online_Timestamp]) AS [Online_Duration_Minutes],
		[SQLServer_Host], 
		[SQLServer_Instance],
		[Downtime_Seconds], 
		[Downtime]
FROM	@tblOutput
ORDER BY [ID]
GO

EXEC [dbo].[rtpDBMon_SQLServer_Uptime]
GO
