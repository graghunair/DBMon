cls

#Variable Declarations and Initiations
    [string]$varDBA_Server_Name ="SQLDBAInventory"
    [string]$varDBA_Database_Name = "DBA_DBMon"
    [string]$varTarget_Database_Name = "master"
    [string[]]$varSQL_Servers_Succeeded = New-Object System.Collections.ArrayList
    [string[]]$varSQL_Servers_Failed = New-Object System.Collections.ArrayList
    [int]$varCount_Succeeded = 1
    [int]$varCount_Failed = 1
    [string]$varSQL_Server_Name
    [string]$varIns_SQL_Text

#T-SQL Queries
    $varTruncate_Query =
@"
    TRUNCATE TABLE [dbo].[tblDBMon_Sys_Logins]
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
    $varGetSys_Logins =
@"
    SET NOCOUNT ON
    GO
    SELECT	'127.0.0.1' AS [IP_Address],
		    1433 AS [Port],
		    CAST(SERVERPROPERTY('servername') AS SYSNAME) AS [SQL_Server_Name],
		    [name] AS [Login_Name],
		    [createdate] AS [Date_Created],
		    [updatedate] AS [Date_Updated],
		    [denylogin] AS [Deny_Login],
		    [hasaccess] AS [Has_Access],
		    [isntname] AS [Is_Windows_Login],
		    [isntgroup] AS [Is_Windows_Group],
		    [isntuser] AS [Is_Windows_User],
		    [sysadmin] AS [SYSADMIN],
		    [securityadmin] AS [SECURITYADMIN],
		    [serveradmin] AS [SERVERADMIN],
		    [setupadmin] AS [SETUPADMIN],
		    [processadmin] AS [PROCESSADMIN],
		    [diskadmin] AS [DISKADMIN],
		    [dbcreator] AS [DBCREATOR],
		    [bulkadmin] AS [BULKADMIN],
		    GETDATE() AS [Date_Captured]
    FROM	[sys].[syslogins]
    WHERE	[name] NOT LIKE '##%##'
    GO

"@

#Tuncate existing old data before fresh capture
    Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varTruncate_Query

#Get a list of SQL Servers
    $varSQL_Servers = Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varGetSQL_Servers

#Loop through each SQL Server
    ForEach ($varSQL_Server in $varSQL_Servers)
        {
            try
                {
                    $varSys_Logins = Invoke-Sqlcmd -ServerInstance $varSQL_Server.SQL_Server_Instance -Database $varTarget_Database_Name -Query $varGetSys_Logins -ConnectionTimeout 5
                    $varSQ_Server_Name = $varCount_Succeeded.ToString() + ". " + $varSQL_Server.SQL_Server_Instance
                    $varSQL_Servers_Succeeded += $varSQ_Server_Name
                    $varCount_Succeeded += 1
                    
                    foreach ($varSys_Login in $varSys_Logins)
                        {
                            $varIns_SQL_Text = "INSERT INTO	[dbo].[tblDBMon_Sys_Logins](" +
				                                "[IP_Address], " +
                                                "[Port], " +
                                                "[SQL_Server_Name], " +
                                                "[Login_Name], " +
				                                "[Date_Created], " +
				                                "[Date_Updated], " +
                                                "[Deny_Login], " +
                                                "[Has_Access], " +
                                                "[Is_Windows_Login], " +
                                                "[Is_Windows_Group], " +
                                                "[Is_Windows_User], " +
                                                "[SYSADMIN], " +
                                                "[SECURITYADMIN], " +
                                                "[SERVERADMIN], " +
                                                "[SETUPADMIN], " +
                                                "[PROCESSADMIN], " +
                                                "[DISKADMIN], " +
                                                "[DBCREATOR], " +
                                                "[BULKADMIN], " +
				                                "[Date_Captured]) " +
                                                "VALUES " +
                                                "('" +
                                                    $varSys_Login.IP_Address + "', '" +
                                                    $varSys_Login.Port + "', '" +
                                                    $varSys_Login.SQL_Server_Name + "', '" +
                                                    $varSys_Login.Login_Name + "', '" +
                                                    $varSys_Login.Date_Created + "', '" +
                                                    $varSys_Login.Date_Updated + "', '" +
                                                    $varSys_Login.Deny_Login + "', '" +
                                                    $varSys_Login.Has_Access + "', '" +
                                                    $varSys_Login.Is_Windows_Login + "', '" +
                                                    $varSys_Login.Is_Windows_Group + "', '" +
                                                    $varSys_Login.Is_Windows_User + "', '" +
                                                    $varSys_Login.SYSADMIN + "', '" +
                                                    $varSys_Login.SECURITYADMIN + "', '" +
                                                    $varSys_Login.SERVERADMIN + "', '" +
                                                    $varSys_Login.SETUPADMIN + "', '" +
                                                    $varSys_Login.PROCESSADMIN + "', '" +
                                                    $varSys_Login.DISKADMIN + "', '" +
                                                    $varSys_Login.DBCREATOR + "', '" +
                                                    $varSys_Login.BULKADMIN + "', '" +
                                                    $varSys_Login.Date_Captured +
                                                "')"      
                
                            #Insert AOAG Primary Replica Details into [DBA_Admin].[dbo].[tblDBMon_AOAG_Primary_Replica]
                            Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varIns_SQL_Text                                              
                        }
                }
            catch
                {
                    $varError_Text = "********** Error connecting to: " + $varSQL_Server.SQL_Server_Instance + " **********"
                    Write-Host $varError_Text -ForegroundColor Yellow
                    $varSQ_Server_Name = $varCount_Failed.ToString() + ". " + $varSQL_Server.SQL_Server_Instance
                    $varSQL_Servers_Failed += $varSQ_Server_Name
                    $varCount_Failed += 1
                }
        }

cls
Write-Host " "
Write-Host "************************" -ForegroundColor Green
Write-Host "| SQL Server Succeeded |" -BackgroundColor Green
Write-Host "************************" -ForegroundColor Green
$varSQL_Servers_Succeeded
Write-Host "------------------------" -ForegroundColor Green

Write-Host " "
Write-Host " "
Write-Host " "

Write-Host "*********************" -ForegroundColor Red
Write-Host "| SQL Server Failed |" -BackgroundColor Red
Write-Host "*********************" -ForegroundColor Red
$varSQL_Servers_Failed
Write-Host "---------------------" -ForegroundColor Red
