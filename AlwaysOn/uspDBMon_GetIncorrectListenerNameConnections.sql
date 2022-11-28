DROP PROC IF EXISTS [dbo].[uspDBMon_GetIncorrectListenerNameConnections]
GO
CREATE PROC [dbo].[uspDBMon_GetIncorrectListenerNameConnections]
AS
SET NOCOUNT ON
/*
              Date          :      28th Nov 2022
              Version		:      1.0
              Purpose       :      Get a list of distinct connections that are targetting a Listener Name belonging to a different availability group
              
              Execution:
                            EXEC [dbo].[uspDBMon_GetIncorrectListenerNameConnections]

              Modification History
              ----------------------
              28th Nov 2022 :      v1.0   :      Inception

*/
DECLARE @tblAG_And_DB TABLE
(
       [Listener_Name] SYSNAME,
       [Availability_Group_Name] SYSNAME,
       [Database_Name] SYSNAME
)

DECLARE @tblAGIP_And_DB TABLE
(
       [Targetted_IP] VARCHAR(48),
       [Targetted_Name] SYSNAME,
       [Client_IP] VARCHAR(48),
       [Program_Name] NVARCHAR(128),
       [Database_Name] SYSNAME
)

INSERT INTO		@tblAG_And_DB([Listener_Name], [Availability_Group_Name], [Database_Name])
SELECT			ln.dns_name AS [Listener_Name],
				ag.[name] AS [Availability_Group_Name], 
				DB_NAME(drs.[database_id]) AS [Database_Name]
FROM			sys.dm_hadr_database_replica_states drs
INNER JOIN		sys.availability_groups ag on ag.[group_id] = drs.[group_id]
INNER JOIN		sys.availability_group_listeners ln on ln.[group_id] = ag.[group_id]


INSERT INTO @tblAGIP_And_DB([Targetted_IP], [Targetted_Name], [Client_IP], [Program_Name], [Database_Name])
SELECT              [local_net_address] AS [Targetted_IP],
                    CASE   
                        WHEN [local_net_address] = '127.0.0.1' THEN 'local' --Review this 
                        ELSE [dns_name]
                    END AS [Targetted_Name],
                    [client_net_address] AS [Client_IP],
                    [program_name] AS [Program_Name],
                    DB_NAME(des.[database_id]) AS [Database_Name]
FROM                sys.dm_exec_sessions des 
INNER JOIN          sys.dm_exec_connections dec 
ON                  des.[session_id] = dec.[session_id]
LEFT OUTER JOIN		sys.availability_group_listeners agl
ON                  dec.local_net_address = REPLACE(REPLACE(agl.[ip_configuration_string_from_cluster] , '(''IP Address: ',''), ''')','')
WHERE               [local_net_address] IS NOT NULL 

SELECT               DISTINCT 
                             a.[Listener_Name],
                             a.[Database_Name],
                             b.[Targetted_Name] AS [Targetted_Listener_Name],
                             b.[Client_IP],
                             b.[Program_Name]
FROM                 @tblAG_And_DB a
FULL OUTER JOIN @tblAGIP_And_DB b
ON                          a.[Database_Name] = b.[Database_Name]
WHERE                a.Listener_Name <> b.Targetted_Name
ORDER BY             a.[Listener_Name], a.[Database_Name], b.[Client_IP]
GO

EXEC [dbo].[uspDBMon_GetIncorrectListenerNameConnections]
GO
