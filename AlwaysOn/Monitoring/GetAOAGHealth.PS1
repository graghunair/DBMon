cls

<#
Install-Module sqlserver
Update-Module sqlserver 
#>

Import-Module sqlserver

#Variable Declarations and Initiations
    [string]$varDBA_Server_Name ="DBAInventory"
    [string]$varDBA_Database_Name = "DBA_Admin"
    [string[]]$varSQLServers = @('SQLServer01','SQLServer-02')
    [string]$varTarget_Database_Name = "master"

#T-SQL Queries
$varTruncate_Query =
@"
    TRUNCATE TABLE [dbo].[tblDBMon_AOAG_Primary_Replica]
    GO
    TRUNCATE TABLE [dbo].[tblDBMon_AOAG_Database_Details]
    GO
    TRUNCATE TABLE [dbo].[tblDBMon_Disk_Free_Space]
    GO
"@

$varGet_AOAG_Primary_Replicas =
@"
    SET NOCOUNT ON
    GO
    SELECT		agc.[name] AS [Availability_Group_Name],
			    ars.[role_desc] AS [Role],
			    rcs.[replica_server_name] AS [Replica_Name],
			    GETDATE() AS [Date_Captured]
    FROM		sys.availability_groups_cluster AS AGC
    INNER JOIN	sys.dm_hadr_availability_replica_cluster_states AS RCS ON RCS.group_id = AGC.group_id
    INNER JOIN	sys.dm_hadr_availability_replica_states AS ARS ON ARS.replica_id = RCS.replica_id
    WHERE		ARS.role_desc = 'PRIMARY'
    GO
"@

$varGet_AOAG_Details =
@"
    SET NOCOUNT ON
    GO
    SELECT			agl.[dns_name] AS [Listener_Name],
	                REPLACE(REPLACE(agl.[ip_configuration_string_from_cluster] , '(''IP Address: ',''), ''')','') AS [Listener_IP_Address],
	                agl.[port] AS [Listener_Port],
	                ag.[name] AS [Availability_Group_Name], 
	                DB_NAME(drs.[database_id]) AS [Database_Name],
	                [synchronization_state_desc] AS [Synchronization_State],
	                [synchronization_health_desc] AS [Synchronization_Health],
	                [log_send_queue_size] AS [Log_Send_Queue_Size],
	                [redo_queue_size] AS [Redo_Queue_Size],
	                GETDATE() AS [Date_Captured]
    FROM			sys.dm_hadr_database_replica_states drs
    INNER JOIN		sys.availability_groups ag on ag.[group_id] = drs.[group_id]
    INNER JOIN		sys.availability_group_listeners agl on agl.[group_id] = ag.[group_id]
    WHERE			[is_local] = 0
    GO
"@

$varGet_Disk_Free_Space =
@"
    SET NOCOUNT ON
    GO
    SELECT		DISTINCT CAST(SERVERPROPERTY('servername') AS SYSNAME) AS [SQL_Server_Name],
			    [volume_mount_point] AS [Drive], 
			    [logical_volume_name] AS [Volume_Name],
			    CAST([total_bytes]/1024./1024./1024. AS DECIMAL(20,2)) AS [Total_Size_GB], 
			    CAST([available_bytes]/1024./1024./1024. AS DECIMAL(20,2)) AS [Free_Space_GB],
			    CAST((CAST([available_bytes] AS DECIMAL(20,2))*100/[total_bytes]) AS DECIMAL(5,2)) AS [Percent_Free],
			    GETDATE() AS [Date_Captured]
    FROM		sys.master_files AS f
    CROSS APPLY sys.dm_os_volume_stats(f.[database_id], f.[file_id])
    ORDER BY	2
    GO
"@

Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varTruncate_Query -ConnectionTimeout 5

foreach ($varSQLServer in $varSQLServers)
    {
        $varAOAG_Primary_Replicas = Invoke-Sqlcmd -ServerInstance $varSQLServer -Database $varDBA_Database_Name -Query $varGet_AOAG_Primary_Replicas -ConnectionTimeout 5
        $varAOAG_Details =          Invoke-Sqlcmd -ServerInstance $varSQLServer -Database $varDBA_Database_Name -Query $varGet_AOAG_Details -ConnectionTimeout 5
        $varDisk_Free_Spaces =      Invoke-Sqlcmd -ServerInstance $varSQLServer -Database $varDBA_Database_Name -Query $varGet_Disk_Free_Space -ConnectionTimeout 5

        foreach ($varAOAG_Primary_Replica in $varAOAG_Primary_Replicas)
            {
                $varIns_SQL_Text = "INSERT INTO	[dbo].[tblDBMon_AOAG_Primary_Replica] (" +
				                    "[Availability_Group_Name], " +
				                    "[Role], " +
				                    "[Replica_Name], " +
				                    "[Date_Captured]) " +
                                    "VALUES " +
                                    "('" +
                                        $varAOAG_Primary_Replica.Availability_Group_Name + "', '" +
                                        $varAOAG_Primary_Replica.Role + "', '" +
                                        $varAOAG_Primary_Replica.Replica_Name + "', '" +
                                        $varAOAG_Primary_Replica.Date_Captured +
                                    "')"      
                
                #Insert AOAG Primary Replica Details into [DBA_Admin].[dbo].[tblDBMon_AOAG_Primary_Replica]
                Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varIns_SQL_Text                                              
            }

        foreach ($varAOAG_Detail in $varAOAG_Details)
            {
                $varIns_SQL_Text = "INSERT INTO	[dbo].[tblDBMon_AOAG_Database_Details] (" +
				                    "[Listener_Name], " +
				                    "[Listener_IP_Address], " +
				                    "[Listener_Port], " +
				                    "[Availability_Group_Name], " +
				                    "[Database_Name], " +
				                    "[Synchronization_State], " +
				                    "[Synchronization_Health], " +
				                    "[Log_Send_Queue_Size], " +
				                    "[Redo_Queue_Size], " +
				                    "[Date_Captured]) " +
                                    "VALUES " +
                                    "('" +
                                        $varAOAG_Detail.Listener_Name + "', '" +
                                        $varAOAG_Detail.Listener_IP_Address + "', '" +
                                        $varAOAG_Detail.Listener_Port + "', '" +
                                        $varAOAG_Detail.Availability_Group_Name + "', '" +
                                        $varAOAG_Detail.Database_Name + "', '" +
                                        $varAOAG_Detail.Synchronization_State + "', '" +
                                        $varAOAG_Detail.Synchronization_Health + "', '" +
                                        $varAOAG_Detail.Log_Send_Queue_Size + "', '" +
                                        $varAOAG_Detail.Redo_Queue_Size + "', '" +
                                        $varAOAG_Detail.Date_Captured +
                                    "')"
            
                #Insert AOAG Details into [DBA_Admin].[dbo].[tblDBMon_AOAG_Database_Details]
                Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varIns_SQL_Text
            }
            
        foreach ($varDisk_Free_Space in $varDisk_Free_Spaces)
            {
                $varIns_SQL_Text = "INSERT INTO	[dbo].[tblDBMon_Disk_Free_Space] (" +
				                    "[SQL_Server_Name], " +
				                    "[Drive], " +
                                    "[Volume_Name], " +
                                    "[Total_Size_GB], " +
                                    "[Free_Space_GB], " +
				                    "[Percent_Free], " +
				                    "[Date_Captured]) " +
                                    "VALUES " +
                                    "('" +
                                        $varDisk_Free_Space.SQL_Server_Name + "', '" +
                                        $varDisk_Free_Space.Drive + "', '" +
                                        $varDisk_Free_Space.Volume_Name + "', '" +
                                        $varDisk_Free_Space.Total_Size_GB + "', '" +
                                        $varDisk_Free_Space.Free_Space_GB + "', '" +
                                        $varDisk_Free_Space.Percent_Free + "', '" +
                                        $varDisk_Free_Space.Date_Captured +
                                    "')"   
                
                #Insert Disk Free Space Details into [DBA_Admin].[dbo].[tblDBMon_AOAG_Database_Details]
                Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varIns_SQL_Text                                                 
            }
    }
