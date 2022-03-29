cls

#Variable Declarations and Initiations
    [string]$varInventory_Server_Name ="<server-name>"
    [string]$varInventory_Database_Name = "DBA_Inventory"
    
    [string]$varDBMon_Server_Name ="<server-name>"
    [string]$varDBMon_Database_Name = "DBA_DBMon"

    [string]$varTarget_Database_Name = "master"

#T-SQL Queries
    $varTruncate_Query =
@"
    TRUNCATE TABLE [load].[tblDBMon_TLog_Utilization]
    GO
    TRUNCATE TABLE [load].[tblDBMon_Database_State]
    GO
    TRUNCATE TABLE [load].[tblDBMon_Disk_Space_Usage]
    GO
    TRUNCATE TABLE [dbo].[tblDBMon_Servers_Connection_Failed]
    GO
"@

    $varIs_Alive = 
@"
    SET NOCOUNT ON
    GO
    SELECT 1 AS [Is_Alive]
    GO
"@
    $varGetSQL_Servers =
@"
    SET NOCOUNT ON
    GO
    SELECT	[SQL_Server_Instance]
    FROM	[inventory].[tblSQL_Servers]
    WHERE	[Is_Active] = 1
    GO
"@

    $varGetTLog_Utilization = 
@"
    SET NOCOUNT ON
    GO

    --Table variable to store the output of DBCC SQLPERF(LOGSPACE)
    DECLARE	@tblTLogUtilization TABLE	(
			    [ID]						SMALLINT,
			    [Database_Name]				SYSNAME, 
			    [Log_Size_MB]				DECIMAL(12,2), 
			    [Log_Space_Used_Percent]	DECIMAL(10,2), 
			    [Status]			BIT)

    --Capture the value of Transaction Log usage
    INSERT INTO @tblTLogUtilization([Database_Name], [Log_Size_MB], [Log_Space_Used_Percent], [Status])
    EXEC('dbcc sqlperf(logspace) with no_infomsgs')

    ;WITH cteTLogBackup AS
    (
        SELECT        d.[name] AS [Database_Name],
                        MAX(b.[backup_finish_date]) AS [TLog_Backup_Timestamp]
        FROM          sys.databases d
        LEFT OUTER JOIN [msdb].[dbo].[backupset] b
        ON            d.[name] = b.[database_name] COLLATE database_default
        WHERE         [type] = 'l'
        GROUP BY      d.[name]
    )

    SELECT			SERVERPROPERTY('servername') AS [Server_Name],
				    d.[name] AS [Database_Name],
				    u.[Log_Size_MB],
				    u.[Log_Space_Used_Percent],
				    d.log_reuse_wait_desc AS [Log_Reuse_Wait_Desc],
				    d.[recovery_model_desc] AS [Recovery_Model],
				    ISNULL(DATEDIFF(mi, [TLog_Backup_Timestamp], GETDATE()), -1) AS [TLog_Backup_Mins_Ago],
				    GETDATE() AS [Date_Captured]
    FROM			@tblTLogUtilization u
    INNER JOIN		sys.databases d
		    ON		u.[Database_Name] = d.[name] COLLATE database_default
    LEFT OUTER JOIN cteTLogBackup b
		    ON		u.[Database_Name] = b.[Database_Name] COLLATE database_default
    GO
"@
    
    $varGetDatabase_State = 
@"
    SET NOCOUNT ON
    GO
    SELECT	SERVERPROPERTY('servername') AS [Server_Name],
		    [name] AS [Database_Name], 
		    [state_desc] AS [State],
		    [user_access_desc] AS [User_Access],
		    [is_read_only] AS [Is_Read_Only],
		    GETDATE() AS [Date_Captured]
    FROM	[sys].[databases]
    GO
"@

    $varGetDisk_Space_Usage = 
@"
    SET NOCOUNT ON
    GO
    SELECT		DISTINCT 
			    SERVERPROPERTY('servername') AS [Server_Name],
			    [volume_mount_point] as [Drive], 
			    [logical_volume_name] as [Volume_Name],
			    CAST([total_bytes]/1024./1024./1024. as decimal(20,0)) as [Total_Size_GB], 
			    CAST([available_bytes]/1024./1024./1024. as decimal(20,0)) as [Free_Space_GB],
			    CAST((CAST([available_bytes] as decimal(20,2))*100/[total_bytes]) as decimal(5,0)) as [Percent_Free],
			    GETDATE() AS [Date_Captured]
    FROM		[sys].[master_files] AS f
    CROSS APPLY [sys].[dm_os_volume_stats](f.database_id, f.[file_id])
    GO
"@

#Tuncate existing old data before fresh capture
    Invoke-Sqlcmd -ServerInstance $varDBMon_Server_Name -Database $varDBMon_Database_Name -Query $varTruncate_Query

#Get a list of SQL Servers
    $varSQL_Servers = Invoke-Sqlcmd -ServerInstance $varInventory_Server_Name -Database $varInventory_Database_Name -Query $varGetSQL_Servers

#Loop through each SQL Server
    ForEach ($varSQL_Server in $varSQL_Servers)
        {
            "Server: " + $varSQL_Server.SQL_Server_Instance
            $Is_Alive = ''
            $Is_Alive = Invoke-Sqlcmd -ServerInstance $varSQL_Server.SQL_Server_Instance -Database $varTarget_Database_Name -Query $varIs_Alive -ConnectionTimeout 5

            If ($Is_Alive.Is_Alive -eq 1)
                {
                    $TLog_Utilizations = ''
                    $TLog_Utilizations = Invoke-Sqlcmd -ServerInstance $varSQL_Server.SQL_Server_Instance -Database $varTarget_Database_Name -Query $varGetTLog_Utilization -ConnectionTimeout 5

                    $Database_States = ''
                    $Database_States = Invoke-Sqlcmd -ServerInstance $varSQL_Server.SQL_Server_Instance -Database $varTarget_Database_Name -Query $varGetDatabase_State -ConnectionTimeout 5

                    $Disk_Space_Usages = ''
                    $Disk_Space_Usages = Invoke-Sqlcmd -ServerInstance $varSQL_Server.SQL_Server_Instance -Database $varTarget_Database_Name -Query $varGetDisk_Space_Usage -ConnectionTimeout 5

                    ForEach ($TLog_Utilization in $TLog_Utilizations)
                        {
                            #$TLog_Space_Usage
                            $varIns_SQL_Text =  "INSERT INTO [load].[tblDBMon_TLog_Utilization](" + 
                                                    "[Server_Name], " +
                                                    "[Database_Name], " + 
                                                    "[Log_Size_MB], " + 
                                                    "[Log_Space_Used_Percent], " + 
                                                    "[Log_Reuse_Wait_Desc], " +
                                                    "[Recovery_Model], " +
                                                    "[TLog_Backup_Mins_Ago], " +
                                                    "[Date_Captured])" + 
                                                " VALUES " + 
                                                "('" + 
                                                    $TLog_Utilization.Server_Name + "', '" + 
                                                    $TLog_Utilization.Database_Name + "', " + 
                                                    $TLog_Utilization.Log_Size_MB + ", " + 
                                                    $TLog_Utilization.Log_Space_Used_Percent + ", '" + 
                                                    $TLog_Utilization.Log_Reuse_Wait_Desc + "', '" + 
                                                    $TLog_Utilization.Recovery_Model + "', " + 
                                                    $TLog_Utilization.TLog_Backup_Mins_Ago + ", '" +
                                                    $TLog_Utilization.Date_Captured +                                             
                                                "')" 
                            
                            #Insert Transaction log usage into [DBA_DBMon].[load].[tblDBMon_TLog_Space_Usage]
                            Invoke-Sqlcmd -ServerInstance $varDBMon_Server_Name -Database $varDBMon_Database_Name -Query $varIns_SQL_Text
                        }     

                    ForEach ($Database_State in $Database_States)
                       {
                            #$Database_State
                            $varIns_SQL_Text =  "INSERT INTO [load].[tblDBMon_Database_State](" + 
                                                    "[Server_Name], " +
                                                    "[Database_Name], " + 
                                                    "[State], " + 
                                                    "[User_Access], " + 
                                                    "[Is_Read_Only], " +
                                                    "[Date_Captured])" + 
                                                "VALUES " + 
                                                "('" + 
                                                    $Database_State.Server_Name + "', '" + 
                                                    $Database_State.Database_Name + "', '" + 
                                                    $Database_State.State + "', '" + 
                                                    $Database_State.User_Access + "', '" + 
                                                    $Database_State.Is_Read_Only + "', '" + 
                                                    $Database_State.Date_Captured +                                             
                                                "')" 

                            #Insert Database State details into [DBA_DBMon].[load].[tblDBMon_Database_State]
                            Invoke-Sqlcmd -ServerInstance $varDBMon_Server_Name -Database $varDBMon_Database_Name -Query $varIns_SQL_Text
                        }

                    ForEach ($Disk_Space_Usage in $Disk_Space_Usages)
                       {
                            #$Disk_Space_Usage
                            $varIns_SQL_Text =  "INSERT INTO [load].[tblDBMon_Disk_Space_Usage](" + 
                                                    "[Server_Name], " +
                                                    "[Drive], " + 
                                                    "[Volume_Name], " + 
                                                    "[Total_Size_GB], " + 
                                                    "[Free_Space_GB], " +
                                                    "[Percent_Free], " +
                                                    "[Date_Captured])" + 
                                                "VALUES " + 
                                                "('" + 
                                                    $Disk_Space_Usage.Server_Name + "', '" + 
                                                    $Disk_Space_Usage.Drive + "', '" + 
                                                    $Disk_Space_Usage.Volume_Name + "', '" + 
                                                    $Disk_Space_Usage.Total_Size_GB + "', '" + 
                                                    $Disk_Space_Usage.Free_Space_GB + "', '" + 
                                                    $Disk_Space_Usage.Percent_Free + "', '" + 
                                                    $Disk_Space_Usage.Date_Captured +                                             
                                                "')" 

                            #Insert Disk space utilization details into [DBA_DBMon].[load].[tblDBMon_Disk_Space_Usage]
                            Invoke-Sqlcmd -ServerInstance $varDBMon_Server_Name -Database $varDBMon_Database_Name -Query $varIns_SQL_Text
                        }
                }
            Else
                {
                    #$varSQL_Server.SQL_Server_Instance
                    $varIns_SQL_Text =  "INSERT INTO [dbo].[tblDBMon_Servers_Connection_Failed](" + 
                                                    "[Server_Name])" + 
                                                "VALUES " + 
                                                "('" + 
                                                    $varSQL_Server.SQL_Server_Instance +                                             
                                                "')" 
                    
                    #Insert SQL Server that failed to connect into [dbo].[tblDBMon_Servers_Connection_Failed]
                    Invoke-Sqlcmd -ServerInstance $varDBMon_Server_Name -Database $varDBMon_Database_Name -Query $varIns_SQL_Text
                }
        }
