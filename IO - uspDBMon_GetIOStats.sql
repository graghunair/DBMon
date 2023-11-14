/*
		Date	:	27th Sept 2022
		Purpose	:	This script creates 1 User-Table and 1 Stored Procedure to capture disk IO metrics
		Version	:	1.0
		License:	This script is provided "AS IS" with no warranties, and confers no rights.

				EXEC [dbo].[uspDBMon_GetWaitStats]
				SELECT * FROM [dbo].[tblDBMon_DM_OS_Wait_Stats]

				Reference: https://www.sqlskills.com/blogs/paul/how-to-examine-io-subsystem-latencies-from-within-sql-server/
				
	Modification History
	-----------------------
	Sept 27th, 2022	:	v1.0	:	Raghu	:	Inception
*/

USE [dba_local]        
GO        

DROP TABLE IF EXISTS [dbo].[tblDBMon_DM_IO_Virtual_File_Stats]                
PRINT 'Table: [dbo].[tblDBMon_DM_IO_Virtual_File_Stats] dropped.'            
GO         

CREATE TABLE [dbo].[tblDBMon_DM_IO_Virtual_File_Stats](                            
	[Date_Captured]		[datetime] NOT NULL CONSTRAINT [DF_tblDBMon_DM_IO_Virtual_File_Stats_Date_Captured]  DEFAULT (getdate()),              
	[Database_Name]		[nvarchar](128) NULL,                            
	[Type]				[nvarchar](60) NULL,                            
	[Logical_Name]		[sysname] NOT NULL,                      
	[Reads]				[bigint] NOT NULL,                            
	[Reads_MB]			[bigint] NULL,                            
	[Reads_IO_Stalls_ms] [bigint] NOT NULL,                            
	[Writes]			[bigint] NOT NULL,                            
	[Writes_MB]			[bigint] NULL,                            
	[Writes_IO_Stalls_ms] [bigint] NOT NULL,                            
	[Total_IO_Stall_ms] [bigint] NOT NULL,                            
	[File_Size_MB]		[bigint] NULL,                            
	[Physical_Name]		[nvarchar](260) NOT NULL)       
GO

CREATE CLUSTERED INDEX [IDX_tblDBMon_DM_IO_Virtual_File_Stats_Date_Captured] 
ON [dbo].[tblDBMon_DM_IO_Virtual_File_Stats]([Date_Captured])
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_GetIOStats]    
PRINT 'Procedure: [dbo].[uspDBMon_GetIOStats] dropped.'            
GO

CREATE PROCEDURE [dbo].[uspDBMon_GetIOStats]
AS
/*    
	Author	:    Raghu Gopalakrishnan    
	Date	:    27th Sept 2022
	Purpose	:    This Stored Procedure is used to capture disk IO Stats.    
	Version :    1.0                              

			EXEC [dbo].[uspDBMon_GetIOStats]                
			SELECT * FROM [dbo].[tblDBMon_DM_IO_Virtual_File_Stats]      
			
	Modification History    
	-----------------------    
	Sept 27th, 2022    :    v1.0    :    Raghu Gopalakrishnan    :    Inception
*/
SET NOCOUNT ON  

--Capture the IO-stats
INSERT INTO [dbo].[tblDBMon_DM_IO_Virtual_File_Stats]
SELECT		GETDATE()												AS [Date_Captured],
			DB_NAME(v.[database_id])								AS [Database_Name],            
			[type_desc]												AS [Type], 
			[name]													AS [Logical_Name],            
			[num_of_reads]											AS [Reads],  
			CAST([num_of_bytes_read]/1024./1024. AS DECIMAL(20,0))	AS [Reads_MB], 
			[io_stall_read_ms]										AS [Reads_IO_Stalls_ms],            
			[num_of_writes]											AS [Writes], 
			CAST([num_of_bytes_written]/1024./1024. AS DECIMAL(20,0)) AS [Writes_MB], 
			[io_stall_write_ms]										AS [Writes_IO_Stalls_ms],            
			[io_stall]												AS [Total_IO_Stall_ms],            
			cast([size_on_disk_bytes]/1024./1024. AS DECIMAL(20,0))	AS [File_Size_MB],            
			[physical_name]											AS [Physical_Name]
FROM        sys.dm_io_virtual_file_stats(NULL, NULL) v
INNER JOIN  sys.master_files f        
	ON    	(v.[database_id] = f.[database_id] AND v.[file_id] = f.[file_id])

DELETE	TOP (10000)
FROM	[dbo].[tblDBMon_DM_IO_Virtual_File_Stats]
WHERE	[Date_Captured] < GETDATE() - 100
GO

EXEC sp_addextendedproperty            
@name = 'Version', @value = '1.0',           
@level0type = 'SCHEMA', 
@level0name = 'dbo',            
@level1type = 'PROCEDURE', 
@level1name = 'uspDBMon_GetIOStats'    
GO

EXEC [dbo].[uspDBMon_GetIOStats]    
SELECT * FROM [dbo].[tblDBMon_DM_IO_Virtual_File_Stats]
GO


SELECT	Date_Captured, 
		Reads, 
		Reads - LAG(Reads, 1) over(order by  Date_Captured) Reads_delta,
		Reads_IO_Stalls_ms, 
		Reads_IO_Stalls_ms - LAG(Reads_IO_Stalls_ms, 1) over(order by  Date_Captured) Delta_Reads_Stalls_ms,
		Writes,
		Writes - LAG(Writes, 1) over(order by  Date_Captured) Delta_Writes,
		Writes_IO_Stalls_ms,
		Writes_IO_Stalls_ms - LAG(Writes_IO_Stalls_ms, 1) over(order by  Date_Captured) Delta_Writes_Stalls_ms
FROM	[dba_local].[dbo].[tblDBMon_DM_IO_Virtual_File_Stats]
WHERE	[Database_Name] = '<Database-Name>'
AND		[Type] = 'ROWS'
