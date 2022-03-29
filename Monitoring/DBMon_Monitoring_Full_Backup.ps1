cls

#Variable Declarations and Initiations    
    #[string]$varInventory_Server_Name ="<server-name>"
    [string]$varInventory_Server_Name ="GORAGHU-QATAR"
    [string]$varInventory_Database_Name = "DBA_Inventory"
    
    [string]$varDBMon_Server_Name ="GORAGHU-QATAR"
    [string]$varDBMon_Database_Name = "DBA_DBMon"

    [string]$varTarget_Database_Name = "master"

#T-SQL Queries
    $varTruncate_Query =
@"
    TRUNCATE TABLE [load].[tblDBMon_Database_Full_Backup_Timestamp]
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

    $varGetDatabase_Full_Backup_Timestamp = 
@"
    SET NOCOUNT ON
    GO
    WITH [cteDatabaseList] AS
			    (
				    SELECT		[database_name] AS [Database_Name], 
							    MAX([backup_finish_date]) AS [Backup_Finish_Date]
				    FROM		[msdb].[dbo].[backupset]
				    WHERE		is_snapshot = 0
				    AND			[type] = 'D'
				    GROUP BY	[database_name]
			    )

    SELECT			SERVERPROPERTY('servername') AS [Server_Name],
                    a.[name] AS [Database_Name],
				    ISNULL(b.[Backup_Finish_Date], -1) AS [Backup_Finish_Date],
                    GETDATE() AS [Date_Captured]
    FROM			[sys].[databases] a
    LEFT OUTER JOIN [cteDatabaseList] b
		    ON		a.[name] = b.[Database_Name]
    WHERE			a.[database_id] <> 2
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
                    $Database_Full_Backup_Timestamps = ''
                    $Database_Full_Backup_Timestamps = Invoke-Sqlcmd -ServerInstance $varSQL_Server.SQL_Server_Instance -Database $varTarget_Database_Name -Query $varGetDatabase_Full_Backup_Timestamp -ConnectionTimeout 5

                    ForEach ($Database_Full_Backup_Timestamp in $Database_Full_Backup_Timestamps)
                        {
                            #$Database_Full_Backup_Timestamp
                            $varIns_SQL_Text =  "INSERT INTO [load].[tblDBMon_Database_Full_Backup_Timestamp](" + 
                                                    "[Server_Name], " +
                                                    "[Database_Name], " + 
                                                    "[Backup_Finish_Date], " +
                                                    "[Date_Captured])" + 
                                                " VALUES " + 
                                                "('" + 
                                                    $Database_Full_Backup_Timestamp.Server_Name + "', '" + 
                                                    $Database_Full_Backup_Timestamp.Database_Name + "', '" + 
                                                    $Database_Full_Backup_Timestamp.Backup_Finish_Date + "', '" +
                                                    $Database_Full_Backup_Timestamp.Date_Captured +                                             
                                                "')" 
                            
                            #Insert Transaction log usage into [DBA_DBMon].[load].[tblDBMon_TLog_Space_Usage]
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
