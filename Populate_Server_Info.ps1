cls

#Variable Declarations and Initiations
    [string]$varDBA_Server_Name ="sqlserver-0"
    [string]$varDBA_Database_Name = "dba_local"
    [string]$varTarget_Database_Name = "master"

#T-SQL Queries
    $varGetSQL_Servers =
@"
    SELECT	[Server_Name] 
    FROM	[dbo].[tblSQL_Servers]
    WHERE	[Is_Active] = 1
    GO
"@

    $varGetSQLServer_Info = 
@"
    DECLARE	@varService_Account NVARCHAR(256)
    DECLARE @varinstant_file_initialization_enabled NVARCHAR(1)
    DECLARE @varIP_Address VARCHAR(255)
    DECLARE @varPort INT

    SELECT	@varService_Account = [service_account],
		    @varinstant_file_initialization_enabled = [instant_file_initialization_enabled]
    FROM	[sys].[dm_server_services]
    WHERE	[filename] LIKE '%sqlservr.exe%'

    SELECT	TOP 1 @varPort = [local_tcp_port],
		    @varIP_Address = [local_net_address]
    FROM	[sys].[dm_exec_connections] 
    WHERE	[local_tcp_port] IS NOT NULL
    AND		[session_id] IS NOT NULL

    SELECT	SERVERPROPERTY('servername') AS [Server_Name], 
		    @varIP_Address AS [IP_Address],
		    @varPort AS [Port],
		    SERVERPROPERTY('IsClustered') AS [FCI_Cluster],
		    SERVERPROPERTY('IsHadrEnabled') AS [HADR_Enabled],
		    SERVERPROPERTY('ProductVersion') AS [Build],
		    SUBSTRING(CAST(@@VERSION AS VARCHAR(500)), 0, CHARINDEX(' ',CAST(@@VERSION AS VARCHAR(500)), 22)) AS [Version],	
		    SERVERPROPERTY('ProductLevel') AS [Product_Level],
		    SERVERPROPERTY('ProductUpdateLevel') AS [Product_Update_Level],
		    SERVERPROPERTY('ProductBuildType') AS [Product_Build_Type],
		    SERVERPROPERTY('ProductUpdateReference') AS [Product_Update_Reference],
		    SERVERPROPERTY('ResourceLastUpdateDateTime') AS [SQL_Patch_Install_Timestamp],
		    SERVERPROPERTY('Edition') AS [Edition],
		    [cpu_count] AS [CPU_Count],
		    CAST([physical_memory_kb]/1024./1024. AS DECIMAL(20,2)) AS [Physical_Memory (GB)],
		    CAST([committed_target_kb]/1024./1024. AS DECIMAL(20,2))  AS [Committed (GB)],
		    CAST([visible_target_kb]/1024./1024. AS DECIMAL(20,2))  AS [Visible (GB)],
		    [sqlserver_start_time] AS [SQL_Server_Start_Time],
		    [sql_memory_model_desc] AS [Memory_Model],
		    @varService_Account AS [Service_Account],
		    @varinstant_file_initialization_enabled AS [Instant_File_Initialization_Enabled],
            GETDATE() AS [Date_Updated],
            SUSER_SNAME() AS [Updated_By]
    FROM	[sys].[dm_os_sys_info]
    GO
"@

#Get a list of SQL Servers
    $varSQL_Servers = Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varGetSQL_Servers

#Loop through each Subscription
    ForEach ($varSQL_Server in $varSQL_Servers)
        {
            #$varSQLServer
            $varSQLServer_Info = Invoke-Sqlcmd -ServerInstance $varSQL_Server.Server_Name -Database $varTarget_Database_Name -Query $varGetSQLServer_Info

            $varUpdServerInfo = "UPDATE [dbo].[tblSQL_Servers]
                                SET [IP_Address] = '" + $varSQLServer_Info.IP_Address + "', 
                                [Port] = " + $varSQLServer_Info.Port + ", 
                                [FCI_Cluster] = " + $varSQLServer_Info.FCI_Cluster + ", 
                                [HADR_Enabled] = " + $varSQLServer_Info.HADR_Enabled + ",
                                [Build] = '" + $varSQLServer_Info.Build + "', 
                                [Version] = '" + $varSQLServer_Info.Version + "',
                                [Product_Level] = '" + $varSQLServer_Info.Product_Level + "',
                                [Product_Update_Level] = '" + $varSQLServer_Info.Product_Update_Level + "',
                                [Product_Build_Type] = '" + $varSQLServer_Info.Product_Build_Type + "',
                                [Product_Update_Reference] = '" + $varSQLServer_Info.Product_Update_Reference + "',
                                [SQL_Patch_Install_Timestamp] = '" + $varSQLServer_Info.SQL_Patch_Install_Timestamp + "',
                                [Edition] = '" + $varSQLServer_Info.Edition + "',
                                [CPU_Count] = " + $varSQLServer_Info.CPU_Count + ",
                                [Physical_Memory (GB)] = '" + $varSQLServer_Info.'Physical_Memory (GB)' + "',
                                [Committed (GB)] = '" + $varSQLServer_Info.'Committed (GB)' + "',
                                [Visible (GB)] = '" + $varSQLServer_Info.'Visible (GB)' + "',
                                [SQL_Server_Start_Time] = '" + $varSQLServer_Info.SQL_Server_Start_Time + "',
                                [Memory_Model] = '" + $varSQLServer_Info.Memory_Model + "',
                                [Service_Account] = '" + $varSQLServer_Info.Service_Account + "',
                                [Instant_File_Initialization_Enabled] = '" + $varSQLServer_Info.Instant_File_Initialization_Enabled + "',
                                [Date_Updated] = '" + $varSQLServer_Info.Date_Updated + "',
                                [Updated_By] = '" + $varSQLServer_Info.Updated_By + "'
                                WHERE [Server_Name] = '" + $varSQLServer_Info.Server_Name + "'"

            #$varSQLServer_Info
            #$varUpdServerInfo 
            Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name.Server_Name -Database $varDBA_Database_Name -Query $varUpdServerInfo 


        }
