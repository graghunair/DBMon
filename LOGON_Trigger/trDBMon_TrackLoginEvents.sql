/*
	
	Author  :	Raghu Gopalakrishnan
	Date	:	5th December 2018
	Purpose	:	This script is to enable logon trigger and log login name, client hostname and last successful login timestamp
	Version	:	1.0
	License	:	This script is provided "AS IS" with no warranties, and confers no rights.
  
 */

SET NOCOUNT ON
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE [master]
GO

IF EXISTS (SELECT 1 FROM sys.server_triggers WHERE [name] = 'trDBMon_TrackLoginEvents')
    BEGIN
        PRINT 'Trigger: [trDBMon_TrackLoginEvents] already exists. Dropping it first.'
        DROP TRIGGER [trDBMon_TrackLoginEvents] ON ALL SERVER
    END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE [name] = 'tblDBMon_Track_Logins' AND SCHEMA_NAME(schema_id) = 'dbo')
    BEGIN
        PRINT 'Table: [dbo].[tblDBMon_Track_Logins] already exists. Dropping it first.'
        DROP TABLE [dbo].[tblDBMon_Track_Logins]
    END
GO

-- The table where the information will be stored historically
CREATE TABLE [dbo].[tblDBMon_Track_Logins](
    [Login_Name]    NVARCHAR(128) NOT NULL,
    [Host_Name]        NVARCHAR(128) NULL,
    [Login_Time]    DATETIME)
GO
ALTER TABLE [dbo].[tblDBMon_Track_Logins] ADD CONSTRAINT [UQ_tblDBMon_Track_Logins] UNIQUE CLUSTERED ([Login_Name], [Host_Name])
GO

--Grant permissions on the table so that all logins can insert/update records into the table
GRANT SELECT,INSERT,UPDATE ON [dbo].[tblDBMon_Track_Logins] TO public
GO

-- Create the trigger to track login
CREATE TRIGGER [trDBMon_TrackLoginEvents]
ON ALL SERVER
FOR LOGON
AS
/*
    Author  :    Raghu Gopalakrishnan
    Date    :    5th December 2018
    Purpose    :    This script is to enable a LOGON trigger to track Login Names, Client Hosts and last successful login attempt.
    Version    :    1.0
    License    :    This script is provided "AS IS" with no warranties, and confers no rights.
*/
    BEGIN
        SET NOCOUNT ON
        DECLARE @varEvent_Data XML,
                @varLogin_Time DATETIME,
                @varLogin_Name NVARCHAR(128)

        SET        @varEvent_Data = EVENTDATA()
        SET        @varLogin_Time = @varEvent_Data.value('(/EVENT_INSTANCE/PostTime)[1]', 'DATETIME')
        SET        @varLogin_Name = @varEvent_Data.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(128)')

        UPDATE    [dbo].[tblDBMon_Track_Logins]
        SET        [Login_Time] = @varLogin_Time
        WHERE    [Login_Name] = @varLogin_Name
        AND        [Host_Name] = HOST_NAME()
        
        IF @@ROWCOUNT = 0
            BEGIN
                INSERT INTO [dbo].[tblDBMon_Track_Logins]([Login_Name], [Host_Name], [Login_Time])
                SELECT @varLogin_Name, HOST_NAME(), @varLogin_Time
            END
    END
GO

ENABLE TRIGGER [trDBMon_TrackLoginEvents] ON ALL SERVER
GO

SELECT * FROM [dbo].[tblDBMon_Track_Logins]
