cls

#Variable Declarations and Initiations
    [string]$varDBA_Server_Name ="sqlserver-0"
    [string]$varDBA_Database_Name = "DBA_DBMon"
    [string]$varTarget_Database_Name = "master"

#T-SQL Queries
    $varTruncate_Query =
@"
    TRUNCATE TABLE [load].[tblSysadmin_Accounts]
"@

    $varGetSQL_Servers =
@"
    SELECT	[Server_Name] 
    FROM	[dbo].[tblSQL_Servers]
    WHERE	[Is_Active] = 1
    GO
"@

    $varGetSysadmin_Account = 
@"
    SELECT	SERVERPROPERTY('servername') AS [Server_Name],
		    [name] AS [Login_Name]
    FROM	[sys].[syslogins]
    WHERE	[sysadmin] = 1
    GO
"@

    $varSend_Report = 
@"
    EXEC [dbo].[rptGetNonComplaintSysadminLogins]
"@

#Tuncate existing old data before fresh capture
    Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varTruncate_Query

#Get a list of SQL Servers
    $varSQL_Servers = Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varGetSQL_Servers

#Loop through each Subscription
    ForEach ($varSQL_Server in $varSQL_Servers)
        {
            #$varSQLServer
            $varSyadmin_Accounts = Invoke-Sqlcmd -ServerInstance $varSQL_Server.Server_Name -Database $varTarget_Database_Name -Query $varGetSysadmin_Account

            ForEach ($varSyadmin_Account in $varSyadmin_Accounts)
                {
                    $varInsSysadmin_Account = "INSERT INTO [load].[tblSysadmin_Accounts] ([Server_Name], [Sysadmin_Account_Name]) VALUES ('" + $varSyadmin_Account.Server_Name + "', '" + $varSyadmin_Account.Login_Name + "')"
                    #$varInsSysadmin_Account
                    Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varInsSysadmin_Account
                }

        }

#Send mail with non-compliant logins
    Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varSend_Report

