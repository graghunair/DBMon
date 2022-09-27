/*
		Date	:	27th Sept 2022
		Purpose	:	This script creates 1 User-Table and 1 Stored Procedure to sys.dm_os_wait_stats into tables for analysis
		Version	:	1.0
		License:
					This script is provided "AS IS" with no warranties, and confers no rights.

				EXEC [dbo].[uspDBMon_GetWaitStats]
				SELECT * FROM [dbo].[tblDBMon_DM_OS_Wait_Stats]

				Reference: https://www.sqlskills.com/blogs/paul/wait-statistics-or-please-tell-me-where-it-hurts/
				
	Modification History
	-----------------------
	Sept 27th, 2022	:	v1.0	:	Raghu	:	Inception
*/

SET NOCOUNT ON
GO

USE [dba_local]
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_DM_OS_Wait_Stats]
GO
CREATE TABLE [dbo].[tblDBMon_DM_OS_Wait_Stats](
	[Date_Captured] [datetime] NOT NULL,
	[Wait_Type] [nvarchar](60) NULL,
	[Wait_Seconds] [decimal](16, 2) NULL,
	[Resource_Seconds] [decimal](16, 2) NULL,
	[Signal_Seconds] [decimal](16, 2) NULL,
	[Wait_Count] [bigint] NULL,
	[Percentage] [decimal](5, 2) NULL)
GO

ALTER TABLE [dbo].[tblDBMon_DM_OS_Wait_Stats] 
ADD CONSTRAINT [DF_tblDBMon_DM_OS_Wait_Stats_Date_Captured]
DEFAULT GETDATE() FOR [Date_Captured]
GO

CREATE CLUSTERED INDEX [IDX_tblDBMon_DM_OS_Wait_Stats_Date_Captured]
ON [dbo].[tblDBMon_DM_OS_Wait_Stats]([Date_Captured])
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_GetWaitStats]
GO
CREATE PROCEDURE [dbo].[uspDBMon_GetWaitStats]
AS

/*
	Author	:	Raghu Gopalakrishnan
	Date	:	27 September 2022
	Purpose	:	This Stored Procedure is used by the DBMon tool to capture Wait Stats
	Version :	1.0
				
				exec [dbo].[uspDBMon_GetWaitStats]
				SELECT * FROM [dbo].[tblDBMon_DM_OS_Wait_Stats]

				Reference: https://www.sqlskills.com/blogs/paul/wait-statistics-or-please-tell-me-where-it-hurts/
				
	Modification History
	-----------------------
	Sept 27th, 2022	:	v1.0	:	Raghu	:	Inception
*/

SET NOCOUNT ON

--Capture dm_os_wait_stats
;WITH [Waits] AS
    (SELECT
        [wait_type],
        [wait_time_ms] / 1000.0 AS [WaitS],
        ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
        [signal_wait_time_ms] / 1000.0 AS [SignalS],
        [waiting_tasks_count] AS [WaitCount],
        100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
        ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
    FROM sys.dm_os_wait_stats
    WHERE [wait_type] NOT IN (
        -- These wait types are almost 100% never a problem and so they are
        -- filtered out to avoid them skewing the results. Click on the URL
        -- for more information.
        N'BROKER_EVENTHANDLER',
        N'BROKER_RECEIVE_WAITFOR',
        N'BROKER_TASK_STOP',
        N'BROKER_TO_FLUSH',
        N'BROKER_TRANSMITTER',
        N'CHECKPOINT_QUEUE',
        N'CHKPT',
        N'CLR_AUTO_EVENT',
        N'CLR_MANUAL_EVENT',
        N'CLR_SEMAPHORE',
        N'CXCONSUMER',
 
        -- Maybe comment these four out if you have mirroring issues
        N'DBMIRROR_DBM_EVENT',
        N'DBMIRROR_EVENTS_QUEUE',
        N'DBMIRROR_WORKER_QUEUE',
        N'DBMIRRORING_CMD',
 
        N'DIRTY_PAGE_POLL',
        N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC',
        N'FSAGENT',
        N'FT_IFTS_SCHEDULER_IDLE_WAIT',
        N'FT_IFTSHC_MUTEX',
 
        -- Maybe comment these six out if you have AG issues
        N'HADR_CLUSAPI_CALL',
        N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
        N'HADR_LOGCAPTURE_WAIT',
        N'HADR_NOTIFICATION_DEQUEUE',
        N'HADR_TIMER_TASK',
        N'HADR_WORK_QUEUE',

        N'KSOURCE_WAKEUP',
        N'LAZYWRITER_SLEEP',
        N'LOGMGR_QUEUE',
        N'MEMORY_ALLOCATION_EXT',
        N'ONDEMAND_TASK_QUEUE',
		
        N'PARALLEL_REDO_DRAIN_WORKER',
        N'PARALLEL_REDO_LOG_CACHE',
        N'PARALLEL_REDO_TRAN_LIST',
        N'PARALLEL_REDO_WORKER_SYNC',
        N'PARALLEL_REDO_WORKER_WAIT_WORK',
        
		N'PREEMPTIVE_OS_FLUSHFILEBUFFERS',
        N'PREEMPTIVE_XE_GETTARGETSTATE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED',
        N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
        N'QDS_ASYNC_QUEUE',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
        N'QDS_SHUTDOWN_QUEUE',
        N'REDO_THREAD_PENDING_WORK',
        N'REQUEST_FOR_DEADLOCK_SEARCH',
        N'RESOURCE_QUEUE',
        N'SERVER_IDLE_CHECK',
        N'SLEEP_BPOOL_FLUSH',
        N'SLEEP_DBSTARTUP',
        N'SLEEP_DCOMSTARTUP',
        N'SLEEP_MASTERDBREADY',
        N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED',
        N'SLEEP_MSDBSTARTUP',
        N'SLEEP_SYSTEMTASK',
        N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP',
        N'SNI_HTTP_ACCEPT',
        N'SOS_WORK_DISPATCHER',
        N'SP_SERVER_DIAGNOSTICS_SLEEP',
        N'SQLTRACE_BUFFER_FLUSH',
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
        N'SQLTRACE_WAIT_ENTRIES',
        N'WAIT_FOR_RESULTS',
        N'WAITFOR',
        N'WAITFOR_TASKSHUTDOWN',
        N'WAIT_XTP_RECOVERY',
        N'WAIT_XTP_HOST_WAIT',
        N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
        N'WAIT_XTP_CKPT_CLOSE',
        N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT',
        N'XE_TIMER_EVENT'
        )
    AND [waiting_tasks_count] > 0
    )

--Capture the wait-stats
INSERT INTO [dbo].[tblDBMon_DM_OS_Wait_Stats]
SELECT	
		GETDATE() AS Date_Captured,
	    MAX ([W1].[wait_type]) AS [WaitType],
		CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2)) AS [Wait_S],
		CAST (MAX ([W1].[ResourceS]) AS DECIMAL (16,2)) AS [Resource_S],
		CAST (MAX ([W1].[SignalS]) AS DECIMAL (16,2)) AS [Signal_S],
		MAX ([W1].[WaitCount]) AS [WaitCount],
		CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)) AS [Percentage]
FROM [Waits] AS [W1]
INNER JOIN [Waits] AS [W2] ON [W2].[RowNum] <= [W1].[RowNum]
GROUP BY [W1].[RowNum]
HAVING SUM ([W2].[Percentage]) - MAX( [W1].[Percentage] ) < 95; -- percentage threshold

--CLEAR EXISTING WAIT STAT INFORMATION
DBCC SQLPERF (N'sys.dm_os_wait_stats', CLEAR) WITH NO_INFOMSGS ;

--Purge old Data 
DELETE TOP (10000) 
FROM	[dbo].[tblDBMon_DM_OS_Wait_Stats] 
WHERE	[Date_Captured] < GETDATE() - 100
GO

EXEC sp_addextendedproperty            
@name = 'Version', @value = '1.0',           
@level0type = 'SCHEMA', 
@level0name = 'dbo',            
@level1type = 'PROCEDURE', 
@level1name = 'uspDBMon_GetWaitStats'    
GO

EXEC [dbo].[uspDBMon_GetWaitStats]    
SELECT * FROM [dbo].[tblDBMon_DM_OS_Wait_Stats]
GO
