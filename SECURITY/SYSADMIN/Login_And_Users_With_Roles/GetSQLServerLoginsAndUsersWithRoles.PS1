<#
Install-Module -Name SqlServer -AllowClobber
Import-Module -Name SqlServer -Force
Get-Command -Module SqlServer
#>
cls

#Variable Declarations and Initiations
    [string]$varDBA_Server_Name = "DBAInventory"
    [string]$varDBA_Database_Name = "DBAInventory"
    [string]$varTarget_Database_Name = "master"
    [string[]]$varSQL_Servers_Succeeded = New-Object System.Collections.ArrayList
    [string[]]$varSQL_Servers_Failed = New-Object System.Collections.ArrayList
    [int]$varCount_Succeeded = 0
    [int]$varCount_Failed = 0
    [string]$varSQL_Server_Name = ""
    [string]$varIns_SQL_Server_Details = ""
    [string]$varIns_SQL_Server_AOAG_Details = ""
    [string]$varIns_SQL_Server_Disk_Drives = ""

#T-SQL Queries
    $varTruncate_Query =
@"
    TRUNCATE TABLE [load].[tblDBMon_Logins_With_Roles]
    TRUNCATE TABLE [load].[tblDBMon_Database_Users_With_Roles]
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

    $varGetSQL_Server_Logins_With_Roles = 
@"
    SET NOCOUNT ON
    GO
    SELECT		CAST(SERVERPROPERTY('servername') AS SYSNAME) AS SQL_Server_Instance,
			    l.[name] AS Login_Name,    
			    r.[name] AS Role_Name,
			    GETDATE() AS Date_Captured
    FROM		sys.server_principals l
    INNER JOIN	sys.server_role_members rm 
		    ON	l.principal_id = rm.member_principal_id
    INNER JOIN	sys.server_principals r 
		    ON	rm.role_principal_id = r.principal_id
    WHERE		l.[type] IN ('S', 'U', 'G') -- SQL logins, Windows logins, and Windows groups
    ORDER BY	r.[name],l.[name]
    GO
"@

    $varGetSQL_Server_Database_Users_With_Roles = 
@"
    SET NOCOUNT ON
    GO
    DECLARE		@varDatabase_Name SYSNAME
    DECLARE		@varSQL_String VARCHAR(MAX)

    DECLARE		@tblDatabase_Users TABLE (
				    [SQL_Server_Instance] SYSNAME, 
				    [Database_Name] SYSNAME,
				    [Database_Role] SYSNAME,
				    [Database_User] SYSNAME,
				    [Login_Name] SYSNAME,
				    [Type_Desc] NVARCHAR(60),
				    [Date_Captured] DATETIME)

    SELECT		@varDatabase_Name = MIN([name])
    FROM		sys.databases 
    WHERE		[database_id] <> 2
    AND			[state] = 0

    WHILE(@varDatabase_Name IS NOT NULL)
	    BEGIN
		    --PRINT @varDatabase_Name

		    SELECT	@varSQL_String = 'USE [' + @varDatabase_Name + '];'
		    SELECT	@varSQL_String = @varSQL_String +
								    'SELECT 
											    CAST(SERVERPROPERTY(''servername'') AS SYSNAME) AS [SQL_Server_Instance],
											    DB_NAME() AS [Database_Name],
											    r.[name] AS [Database_Role], 
											    p.[name] AS [Database_User],
											    sl.loginname AS [Login_Name],
											    p.[type_desc] AS [Type_Desc],
											    GETDATE() AS [Date_Captured]
								    FROM		sys.database_role_members m
								    INNER JOIN	sys.database_principals r 
										    ON	m.role_principal_id = r.principal_id
								    INNER JOIN	sys.database_principals p 
										    ON	m.member_principal_id = p.principal_id
								    INNER JOIN	sys.syslogins sl
										    ON	sl.[sid]=p.[sid]
								    WHERE		sl.loginname NOT LIKE ''##%##'''

		    INSERT INTO @tblDatabase_Users
		    EXEC (@varSQL_String)

		    SELECT		@varDatabase_Name = MIN([name])
		    FROM		sys.databases 
		    WHERE		[database_id] <> 2
		    AND			[state] = 0
		    AND			@varDatabase_Name < [name]
	    END

    SELECT	[SQL_Server_Instance], 
		    [Database_Name],
		    [Database_Role],
		    [Database_User],
		    [Login_Name],
		    [Type_Desc],
		    [Date_Captured]
    FROM	@tblDatabase_Users
    GO
"@


#Tuncate existing old data before fresh capture
    Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varTruncate_Query -TrustServerCertificate

#Get a list of SQL Servers
    $varSQL_Servers = Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varGetSQL_Servers -TrustServerCertificate

#Loop through each SQL Server
    ForEach ($varSQL_Server in $varSQL_Servers)
        {
            $varProgress = 'Succeeded: ' + $varCount_Succeeded + ', Failed: ' + $varCount_Failed
            Write-Progress -Activity 'SQL Server Count' -Status $varProgress

            try
                {
                    $varSQL_Server_Logins_With_Roles = ''
		            $varSQL_Server_Logins_With_Roles = Invoke-Sqlcmd -ServerInstance $varSQL_Server.SQL_Server_Instance -Database $varTarget_Database_Name -Query $varGetSQL_Server_Logins_With_Roles -ConnectionTimeout 10 -TrustServerCertificate
                    #$varSQL_Server_Logins_With_Roles

                    $varSQL_Server_Database_Users_With_Roles = ''
                    $varSQL_Server_Database_Users_With_Roles = Invoke-Sqlcmd -ServerInstance $varSQL_Server.SQL_Server_Instance -Database $varTarget_Database_Name -Query $varGetSQL_Server_Database_Users_With_Roles -ConnectionTimeout 10 -TrustServerCertificate
                    #$varSQL_Server_Database_Users_With_Roles

                    $varCount_Succeeded += 1  
                    $varSQ_Server_Name = $varCount_Succeeded.ToString() + ". " + $varSQL_Server.SQL_Server_Instance
                    $varSQL_Servers_Succeeded += $varSQ_Server_Name
                }
            catch
                {
                    $varError_Text = "********** Error connecting to: " + $varSQL_Server.SQL_Server_Instance + " **********"
                    Write-Host $varError_Text -ForegroundColor Yellow

                    $varCount_Failed += 1
                    $varSQ_Server_Name = $varCount_Failed.ToString() + ". " + $varSQL_Server.SQL_Server_Instance
                    $varSQL_Servers_Failed += $varSQ_Server_Name   
                }
 
             ForEach ($varSQL_Server_Logins_With_Role in $varSQL_Server_Logins_With_Roles)
                {
                    $varInsSQL_Server_Logins_With_Roles =  "INSERT INTO [load].[tblDBMon_Logins_With_Roles](" + 
                                                    "[SQL_Server_Instance], " +
                                                    "[Login_Name], " + 
                                                    "[Role_Name], " +                                                                                    
                                                    "[Date_Captured]) " + 
                                                "VALUES " + 
                                                "('" + 
                                                    $varSQL_Server_Logins_With_Role.SQL_Server_Instance + "', '" + 
                                                    $varSQL_Server_Logins_With_Role.Login_Name + "', '" + 
                                                    $varSQL_Server_Logins_With_Role.Role_Name +"', '" +                                                
                                                    $varSQL_Server_Logins_With_Role.Date_Captured +                                             
                                                "')" 
            
                    #$varInsSQL_Server_Logins_With_Roles
                    #Insert into the load table - [load].[tblDBMon_Logins_With_Roles]
                    Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varInsSQL_Server_Logins_With_Roles -TrustServerCertificate
                }
 
 
              ForEach ($varSQL_Server_Database_Users_With_Role in $varSQL_Server_Database_Users_With_Roles)
                {
                    $varInsSQL_Server_Database_Users_With_Roles =  "INSERT INTO [load].[tblDBMon_Database_Users_With_Roles](" + 
                                                    "[SQL_Server_Instance], " +
                                                    "[Database_Name], " + 
                                                    "[Database_Role], " + 
                                                    "[Database_User], " + 
                                                    "[Login_Name], " + 
                                                    "[Type_Desc], " +                                                                                   
                                                    "[Date_Captured]) " + 
                                                "VALUES " + 
                                                "('" + 
                                                    $varSQL_Server_Database_Users_With_Role.SQL_Server_Instance + "', '" + 
                                                    $varSQL_Server_Database_Users_With_Role.Database_Name + "', '" + 
                                                    $varSQL_Server_Database_Users_With_Role.Database_Role + "', '" + 
                                                    $varSQL_Server_Database_Users_With_Role.Database_User + "', '" + 
                                                    $varSQL_Server_Database_Users_With_Role.Login_Name + "', '" + 
                                                    $varSQL_Server_Database_Users_With_Role.Type_Desc +"', '" +                                                
                                                    $varSQL_Server_Database_Users_With_Role.Date_Captured +                                             
                                                "')" 
            
                    #$varInsSQL_Server_Database_Users_With_Roles
                    #Insert into the load table - [load].[tblDBMon_Database_Users_With_Roles]
                    Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varInsSQL_Server_Database_Users_With_Roles -TrustServerCertificate
                }                        
        }

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
