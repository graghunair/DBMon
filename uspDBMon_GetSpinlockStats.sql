/*
	License	:	This script is provided "AS IS" with no warranties, and confers no rights.
	Author	:	Raghu Gopalakrishnan
	Date	:	25th February 2019
	Purpose	:	This Stored Procedure is used by the DBMon tool to capture Spinlock stats periodically
	Version	:	1.0
*/

SET NOCOUNT ON
GO

USE [dba_local]
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE [name] = 'tblDBMon_DM_OS_Spinlock_Stats' AND SCHEMA_NAME([schema_id]) = 'dbo')
	BEGIN
		PRINT 'Table [dbo].[tblDBMon_DM_OS_Spinlock_Stats] already exists. Dropping it first.'
		DROP TABLE [dbo].[tblDBMon_DM_OS_Spinlock_Stats]
	END
GO

CREATE TABLE [dbo].[tblDBMon_DM_OS_Spinlock_Stats](
	[Date_Captured]			[datetime] NOT NULL CONSTRAINT [DF_tblDBMon_DM_OS_Spinlock_Stats_Date_Captured] DEFAULT GETDATE(),
	[Lock_Type]				[nvarchar] (256) NOT NULL,
	[Collisions]			[bigint] NULL,
	[Spins]					[bigint] NULL,
	[Spins_Per_Collision]	[real] NULL,
	[Sleep_Time]			[bigint] NULL,
	[Backoffs]				[int] NULL)
GO

CREATE CLUSTERED INDEX [IDX_tblDBMon_DM_OS_Spinlock_Stats_Date_Captured] ON [dbo].[tblDBMon_DM_OS_Spinlock_Stats]([Date_Captured])
GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE [name] = 'uspDBMon_GetSpinlockStats' AND SCHEMA_NAME(schema_id) = 'dbo')
	BEGIN
		PRINT 'SP [dbo].[uspDBMon_GetSpinlockStats] already exists. Dropping it first.'
		DROP PROC [dbo].[uspDBMon_GetSpinlockStats]
	END
GO

CREATE PROCEDURE [dbo].[uspDBMon_GetSpinlockStats]
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	25th February 2019
		Purpose	:	This Stored Procedure is used by the DBMon tool to capture Spinlock stats periodically
		Version	:	1.0
		License:
		This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[uspDBMon_GetSpinlockStats]
					SELECT * FROM [dbo].[tblDBMon_DM_OS_Spinlock_Stats]

		Modification History
		----------------------
		Feb	25th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
	*/
	SET NOCOUNT ON

	--Capture the spinlock stats
	INSERT INTO [dbo].[tblDBMon_DM_OS_Spinlock_Stats]([Date_Captured], [Lock_Type], [Collisions], [Spins], [Spins_Per_Collision], [Sleep_Time], [Backoffs])
	SELECT	GETDATE(), [name], [collisions], [spins], [spins_per_collision], [sleep_time], [backoffs]
	FROM	sys.dm_os_spinlock_stats
	WHERE	collisions > 0

	--Clear the stats to reset the counter post capture
	DBCC SQLPERF('sys.dm_os_spinlock_stats', CLEAR) WITH NO_INFOMSGS

	--Purge data older than 3 months
	DELETE TOP (10000)
	FROM [dbo].[tblDBMon_DM_OS_Spinlock_Stats]
	WHERE Date_Captured < DATEADD(d, -100, GETDATE())
GO

EXEC sys.sp_addextendedproperty 
			@name=N'Version', 
			@value=N'1.0', 
			@level0type=N'SCHEMA', 
			@level0name=N'dbo', 
			@level1type=N'PROCEDURE', 
			@level1name=N'uspDBMon_GetSpinlockStats'
GO

EXEC [dbo].[uspDBMon_GetSpinlockStats]
GO