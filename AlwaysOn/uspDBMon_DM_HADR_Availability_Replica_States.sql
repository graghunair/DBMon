SET NOCOUNT ON
GO

USE [dba_local]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_DM_HADR_Availability_Replica_States]
GO
CREATE TABLE [dbo].[tblDBMon_DM_HADR_Availability_Replica_States](
	[Date_Captured] [datetime] NOT NULL,
	[Replica_Server_Name] [nvarchar](256) NULL,
	[Connection_State] [nvarchar](60) NULL,
	[Date_Updated] [datetime] NOT NULL) 
GO

INSERT INTO [dbo].[tblDBMon_DM_HADR_Availability_Replica_States]
			(
				[Date_Captured],
				[Replica_Server_Name],
				[Connection_State],
				[Date_Updated]
			)
SELECT      GETDATE(),
			ar.[replica_server_name],
			ars.[connected_state_desc],
			GETDATE()
FROM		[sys].[dm_hadr_availability_replica_states] ars
INNER JOIN  [sys].[availability_replicas] ar 
		ON  ars.[group_id] = ar.[group_id] 
		AND ars.[replica_id] = ar.[replica_id]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_DM_HADR_Availability_Replica_States]
GO
CREATE PROCEDURE [dbo].[uspDBMon_DM_HADR_Availability_Replica_States]
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	6th August 2020
		Purpose	:	This Stored Procedure is used to detect replica connection state changes for AlwaysOn Synchronization
		Version	:	1.0
		License:
					This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[uspDBMon_DM_HADR_Availability_Replica_States] 
					SELECT TOP 100 * FROM [dbo].[tblDBMon_DM_HADR_Availability_Replica_States] ORDER By [Date_Captured] DESC

		Modification History
		----------------------
		Aug		06th, 2020	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
	*/
SET NOCOUNT ON

--Variable declarations
DECLARE @varDate_Captured DATETIME
DECLARE @varReplica_Server_Name SYSNAME
DECLARE @varConnection_State NVARCHAR(120)

--Add replica(s) if it does not already exist
INSERT INTO [dbo].[tblDBMon_DM_HADR_Availability_Replica_States]
			(
				[Date_Captured],
				[Replica_Server_Name],
				[Connection_State],
				[Date_Updated]
			)
SELECT      GETDATE(),
			ar.[replica_server_name],
			ars.[connected_state_desc],
			GETDATE()
FROM		[sys].[dm_hadr_availability_replica_states] ars
INNER JOIN  [sys].[availability_replicas] ar 
		ON  ars.[group_id] = ar.[group_id] 
		AND ars.[replica_id] = ar.[replica_id]
LEFT OUTER JOIN [dbo].[tblDBMon_DM_HADR_Availability_Replica_States] hars
		ON	hars.[Replica_Server_Name] = ar.[replica_server_name]
WHERE		hars.[Replica_Server_Name] IS NULL

--Pick the server name to start looping through each replica to check connection status
SELECT	@varReplica_Server_Name = MIN([replica_server_name])
FROM    [sys].[availability_replicas]

WHILE (@varReplica_Server_Name IS NOT NULL)
    BEGIN
		--Pick the datetime of the latest update for the replica
        SELECT		@varDate_Captured = MAX([Date_Captured])
        FROM		[dbo].[tblDBMon_DM_HADR_Availability_Replica_States]
        WHERE		[Replica_Server_Name] = @varReplica_Server_Name

		--Check the present connection state for the replica
		SELECT      @varConnection_State = ars.[connected_state_desc]
		FROM		[sys].[dm_hadr_availability_replica_states] ars
		INNER JOIN  [sys].[availability_replicas] ar 
				ON  ars.[group_id] = ar.[group_id] 
				AND ars.[replica_id] = ar.[replica_id]
		WHERE		ar.[replica_server_name] = @varReplica_Server_Name

		--If not changes in connection state, just update the Date_Updated column
		UPDATE [dbo].[tblDBMon_DM_HADR_Availability_Replica_States]
		SET		[Date_Updated] = GETDATE()
		WHERE	[Replica_Server_Name] = @varReplica_Server_Name
		AND		[Date_Captured] = @varDate_Captured
		AND		[Connection_State] = @varConnection_State

		--IF there are changes in connection state since last update, then insert new record with present status
		IF (@@ROWCOUNT = 0)
			BEGIN
				INSERT INTO	[dbo].[tblDBMon_DM_HADR_Availability_Replica_States]
							(
								[Date_Captured],
								[Replica_Server_Name],
								[Connection_State],
								[Date_Updated]
							)
				SELECT      GETDATE(),
							ar.[replica_server_name],
							ars.connected_state_desc,
							GETDATE()
				FROM		[sys].[dm_hadr_availability_replica_states] ars
				INNER JOIN  [sys].[availability_replicas] ar 
						ON  ars.[group_id] = ar.[group_id] 
						AND ars.[replica_id] = ar.[replica_id]
				WHERE		ar.[replica_server_name] = @varReplica_Server_Name
			END

		--Pick the next replica
        SELECT	@varReplica_Server_Name = MIN([replica_server_name])
        FROM	[sys].[availability_replicas]
        WHERE	[replica_server_name] > @varReplica_Server_Name
    END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.0', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_DM_HADR_Availability_Replica_States'
GO

EXEC [dbo].[uspDBMon_DM_HADR_Availability_Replica_States] 
GO
SELECT		TOP 100 * 
FROM		[dbo].[tblDBMon_DM_HADR_Availability_Replica_States] 
ORDER By	[Date_Captured] DESC
GO
