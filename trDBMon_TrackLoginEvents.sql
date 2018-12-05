/*
	
	Author  :	Raghu Gopalakrishnan
	Date	:	5th December 2018
	Purpose	:	This script is to enable logon trigger and log login name, client hostname and last successful login timestamp
	Version	:	1.0
	License	:	This script is provided "AS IS" with no warranties, and confers no rights.
  
 */

USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS [dbo].[trDBMon_Track_Logins]
GO

-- The table where the information will be stored historically
CREATE TABLE [dbo].[trDBMon_Track_Logins](
	[Login_Name]	NVARCHAR(225) NOT NULL,
	[Host_Name]		NVARCHAR(225) NULL,
	[Login_Time]	DATETIME)
GO
ALTER TABLE [dbo].[trDBMon_Track_Logins] ADD CONSTRAINT [UQ_trDBMon_Track_Logins] UNIQUE CLUSTERED ([Login_Name], [Host_Name])
GO
GRANT INSERT ON [dbo].[trDBMon_Track_Logins] TO PUBLIC
GO

USE [master]
GO

DROP TRIGGER IF EXISTS [trDBMon_TrackLoginEvents] ON ALL SERVER
GO

CREATE TRIGGER [trDBMon_TrackLoginEvents]
ON ALL SERVER
FOR LOGON
AS
/*
	Author  :	Raghu Gopalakrishnan
	Date	:	5th December 2018
	Purpose	:	This script is to enable a LOGON trigger to track Login Names, Client Hosts and last successful login attempt.
	Version	:	1.0
	License	:	This script is provided "AS IS" with no warranties, and confers no rights.
*/
	BEGIN
		SET NOCOUNT ON
		DECLARE @varEvent_Data XML,
				@varLogin_Time DATETIME,
				@varLogin_Name NVARCHAR(256),
				@varHost_Name NVARCHAR(256)
 
		SET		@varEvent_Data = eventdata()
		SET		@varLogin_Time = @varEvent_Data.value('(/EVENT_INSTANCE/PostTime)[1]', 'DATETIME')
		SET		@varLogin_Name = @varEvent_Data.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(256)')
		SET		@varHost_Name = @varEvent_Data.value('(/EVENT_INSTANCE/ClientHost)[1]', 'NVARCHAR(256)')

		UPDATE	[dbo].[trDBMon_Track_Logins]
		SET		[Login_Time] = @varLogin_Time
		WHERE	[Login_Name] = @varLogin_Name
		AND		[Host_Name] = @varHost_Name

		IF @@ROWCOUNT = 0
			BEGIN
				INSERT INTO [dbo].[trDBMon_Track_Logins]([Login_Name], [Host_Name], [Login_Time])
				SELECT @varLogin_Name, @varHost_Name, @varLogin_Time
			END
	END
GO

ENABLE TRIGGER [trDBMon_TrackLoginEvents] ON ALL SERVER
GO

SELECT * FROM [dbo].[trDBMon_Track_Logins]