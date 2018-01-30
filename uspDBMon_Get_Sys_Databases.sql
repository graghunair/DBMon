/*
	License	:	This script is provided "AS IS" with no warranties, and confers no rights.
	Author	:	Raghu Gopalakrishnan
	Date	:	28th January 2018
	Purpose	:	This Stored Procedure is used by the DBMon tool to capture database configuration changes
			so that we have historical data to review changes over a period of time.
	Version	:	1.0 2017
*/

SET NOCOUNT ON
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_WARNINGS OFF
GO

ALTER DATABASE [model] SET RECOVERY FULL
ALTER DATABASE [model] SET AUTO_CREATE_STATISTICS OFF
ALTER DATABASE [dba_local] SET RECOVERY FULL


USE [dba_local]
GO

--Drop the table if it already exists.
IF EXISTS (SELECT 1 FROM [sys].[tables] WHERE [name] = 'tblDBMon_Sys_Databases' AND schema_id = schema_id('dbo'))
BEGIN
	PRINT 'The table: [dbo].[tblDBMon_Sys_Databases] already exists. Dropping it first.'
	DROP TABLE [dbo].[tblDBMon_Sys_Databases]
END

--IF SQL 2017
IF ((SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(50)),0, CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))))) = 14)
    BEGIN
		DECLARE @varSQL_Text VARCHAR(MAX)

		SELECT @varSQL_Text = 
		'CREATE TABLE [dbo].[tblDBMon_Sys_Databases](
			[Date_Captured] [datetime] NOT NULL CONSTRAINT [DF_tblDBMon_Sys_Databases_Date_Captured] DEFAULT GETDATE(),
			[name] [sysname] NOT NULL,
			[database_id] [int] NOT NULL,
			[source_database_id] [int] NULL,
			[owner_sid] [varbinary](85) NULL,
			[create_date] [datetime] NOT NULL,
			[compatibility_level] [tinyint] NOT NULL,
			[collation_name] [sysname] NULL,
			[user_access] [tinyint] NULL,
			[user_access_desc] [nvarchar](60) NULL,
			[is_read_only] [bit] NULL,
			[is_auto_close_on] [bit] NOT NULL,
			[is_auto_shrink_on] [bit] NULL,
			[state] [tinyint] NULL,
			[state_desc] [nvarchar](60) NULL,
			[is_in_standby] [bit] NULL,
			[is_cleanly_shutdown] [bit] NULL,
			[is_supplemental_logging_enabled] [bit] NULL,
			[snapshot_isolation_state] [tinyint] NULL,
			[snapshot_isolation_state_desc] [nvarchar](60) NULL,
			[is_read_committed_snapshot_on] [bit] NULL,
			[recovery_model] [tinyint] NULL,
			[recovery_model_desc] [nvarchar](60) NULL,
			[page_verify_option] [tinyint] NULL,
			[page_verify_option_desc] [nvarchar](60) NULL,
			[is_auto_create_stats_on] [bit] NULL,
			[is_auto_create_stats_incremental_on] [bit] NULL,
			[is_auto_update_stats_on] [bit] NULL,
			[is_auto_update_stats_async_on] [bit] NULL,
			[is_ansi_null_default_on] [bit] NULL,
			[is_ansi_nulls_on] [bit] NULL,
			[is_ansi_padding_on] [bit] NULL,
			[is_ansi_warnings_on] [bit] NULL,
			[is_arithabort_on] [bit] NULL,
			[is_concat_null_yields_null_on] [bit] NULL,
			[is_numeric_roundabort_on] [bit] NULL,
			[is_quoted_identifier_on] [bit] NULL,
			[is_recursive_triggers_on] [bit] NULL,
			[is_cursor_close_on_commit_on] [bit] NULL,
			[is_local_cursor_default] [bit] NULL,
			[is_fulltext_enabled] [bit] NULL,
			[is_trustworthy_on] [bit] NULL,
			[is_db_chaining_on] [bit] NULL,
			[is_parameterization_forced] [bit] NULL,
			[is_master_key_encrypted_by_server] [bit] NOT NULL,
			[is_query_store_on] [bit] NULL,
			[is_published] [bit] NOT NULL,
			[is_subscribed] [bit] NOT NULL,
			[is_merge_published] [bit] NOT NULL,
			[is_distributor] [bit] NOT NULL,
			[is_sync_with_backup] [bit] NOT NULL,
			[service_broker_guid] [uniqueidentifier] NOT NULL,
			[is_broker_enabled] [bit] NOT NULL,
			[log_reuse_wait] [tinyint] NULL,
			[log_reuse_wait_desc] [nvarchar](60) NULL,
			[is_date_correlation_on] [bit] NOT NULL,
			[is_cdc_enabled] [bit] NOT NULL,
			[is_encrypted] [bit] NULL,
			[is_honor_broker_priority_on] [bit] NULL,
			[replica_id] [uniqueidentifier] NULL,
			[group_database_id] [uniqueidentifier] NULL,
			[resource_pool_id] [int] NULL,
			[default_language_lcid] [smallint] NULL,
			[default_language_name] [nvarchar](128) NULL,
			[default_fulltext_language_lcid] [int] NULL,
			[default_fulltext_language_name] [nvarchar](128) NULL,
			[is_nested_triggers_on] [bit] NULL,
			[is_transform_noise_words_on] [bit] NULL,
			[two_digit_year_cutoff] [smallint] NULL,
			[containment] [tinyint] NULL,
			[containment_desc] [nvarchar](60) NULL,
			[target_recovery_time_in_seconds] [int] NULL,
			[delayed_durability] [int] NULL,
			[delayed_durability_desc] [nvarchar](60) NULL,
			[is_memory_optimized_elevate_to_snapshot_on] [bit] NULL,
			[is_federation_member] [bit] NULL,
			[is_remote_data_archive_enabled] [bit] NULL,
			[is_mixed_page_allocation_on] [bit] NULL,
			[is_temporal_history_retention_enabled] [bit] NULL,
			[Updated_By] [nvarchar](128) NOT NULL CONSTRAINT [DF_tblDBMon_Sys_Databases_Updated_By] DEFAULT SUSER_SNAME()
		)
		CREATE CLUSTERED INDEX IDX_tblDBMon_Sys_Databases_Date_Captured ON [dbo].[tblDBMon_Sys_Databases](Date_Captured)'
		EXEC (@varSQL_Text)

		SELECT @varSQL_Text = 
		'INSERT INTO [dbo].[tblDBMon_Sys_Databases]
		SELECT	GETDATE(),
				[name],
				[database_id],
				[source_database_id],
				[owner_sid],
				[create_date],
				[compatibility_level],
				[collation_name],
				[user_access],
				[user_access_desc],
				[is_read_only],
				[is_auto_close_on],
				[is_auto_shrink_on],
				[state],
				[state_desc],
				[is_in_standby],
				[is_cleanly_shutdown],
				[is_supplemental_logging_enabled],
				[snapshot_isolation_state],
				[snapshot_isolation_state_desc],
				[is_read_committed_snapshot_on],
				[recovery_model],
				[recovery_model_desc],
				[page_verify_option],
				[page_verify_option_desc],
				[is_auto_create_stats_on],
				[is_auto_create_stats_incremental_on],
				[is_auto_update_stats_on],
				[is_auto_update_stats_async_on],
				[is_ansi_null_default_on],
				[is_ansi_nulls_on],
				[is_ansi_padding_on],
				[is_ansi_warnings_on],
				[is_arithabort_on],
				[is_concat_null_yields_null_on],
				[is_numeric_roundabort_on],
				[is_quoted_identifier_on],
				[is_recursive_triggers_on],
				[is_cursor_close_on_commit_on],
				[is_local_cursor_default],
				[is_fulltext_enabled],
				[is_trustworthy_on],
				[is_db_chaining_on],
				[is_parameterization_forced],
				[is_master_key_encrypted_by_server],
				[is_query_store_on],
				[is_published],
				[is_subscribed],
				[is_merge_published],
				[is_distributor],
				[is_sync_with_backup],
				[service_broker_guid],
				[is_broker_enabled],
				[log_reuse_wait],
				[log_reuse_wait_desc],
				[is_date_correlation_on],
				[is_cdc_enabled],
				[is_encrypted],
				[is_honor_broker_priority_on],
				[replica_id],
				[group_database_id],
				[resource_pool_id],
				[default_language_lcid],
				[default_language_name],
				[default_fulltext_language_lcid],
				[default_fulltext_language_name],
				[is_nested_triggers_on],
				[is_transform_noise_words_on],
				[two_digit_year_cutoff],
				[containment],
				[containment_desc],
				[target_recovery_time_in_seconds],
				[delayed_durability],
				[delayed_durability_desc],
				[is_memory_optimized_elevate_to_snapshot_on],
				[is_federation_member],
				[is_remote_data_archive_enabled],
				[is_mixed_page_allocation_on],
				[is_temporal_history_retention_enabled],
				SUSER_SNAME()
		FROM	[sys].[databases]'
		PRINT 'SQL Server Version identified as SQL Server 2017'
		EXEC (@varSQL_Text)

		--Stored Procedure code starts
		SELECT	@varSQL_Text = 
		'IF EXISTS (SELECT 1 FROM [sys].[procedures] WHERE [name] = ''uspDBMon_Get_SYS_Databases'' AND schema_id = SCHEMA_ID(''dbo''))
			BEGIN
				PRINT ''The procedure: [dbo].[uspDBMon_Get_SYS_Databases] already exists. Dropping it first.''
				DROP PROC [dbo].[uspDBMon_Get_SYS_Databases]
			END'
		EXEC (@varSQL_Text)

		--Create the procedure
		SELECT	@varSQL_Text = 
		'CREATE PROCEDURE [dbo].[uspDBMon_Get_SYS_Databases]
		AS
		/*
			Author	:	Raghu Gopalakrishnan
			Date	:	28th January 2018
			Purpose	:	This Stored Procedure is used by the DBMon tool to capture database configuration changes
						so that we have historical data to review changes over a period of time.
			Version	:	1.0 2017
			License:
			This script is provided "AS IS" with no warranties, and confers no rights.
						EXEC [dbo].[uspDBMon_Get_SYS_Databases]
						SELECT * FROM [dbo].[tblDBMon_Sys_Databases]
			Modification History
			----------------------
			Jan  28th, 2018	:	v1.0 2017	:	Raghu Gopalakrishnan	:	Inception
		*/
			SET NOCOUNT ON
			DECLARE @varDatabase_Name SYSNAME
			DECLARE @varSQL_Text VARCHAR(MAX)

			SELECT	@varDatabase_Name = MIN([name]) FROM [sys].[databases] 

			WHILE (@varDatabase_Name IS NOT NULL)
				BEGIN
					WITH cte_tblDBMon_Sys_Databases AS(
						SELECT TOP 1 * 
						FROM	[dbo].[tblDBMon_Sys_Databases]
						WHERE	[name] = @varDatabase_Name
						ORDER BY Date_Captured DESC
					)

					INSERT INTO		[dbo].[tblDBMon_Sys_Databases]
					SELECT			GETDATE(), A.*, SUSER_SNAME() 
					FROM			[sys].[databases] A
					LEFT OUTER JOIN cte_tblDBMon_Sys_Databases B
					ON				A.[name] = B.[name] 
					WHERE			(A.database_id <> B.database_id
					OR				A.[source_database_id] <> B.[source_database_id]
					OR				A.[owner_sid] <> B.[owner_sid]
					OR				A.[create_date] <> B.[create_date]
					OR				A.[compatibility_level] <> B.[compatibility_level]
					OR				A.[collation_name] <> B.[collation_name] COLLATE database_default
					OR				A.[user_access] <> B.[user_access]
					OR				A.[user_access_desc] <> B.[user_access_desc] COLLATE database_default
					OR				A.[is_read_only] <> B.[is_read_only]
					OR				A.[is_auto_close_on] <> B.[is_auto_close_on]
					OR				A.[is_auto_shrink_on] <> B.[is_auto_shrink_on]
					OR				A.[state] <> B.[state]
					OR				A.[state_desc] <> B.[state_desc] COLLATE database_default
					OR				A.[is_in_standby] <> B.[is_in_standby]
					OR				A.[is_cleanly_shutdown] <> B.[is_cleanly_shutdown]
					OR				A.[is_supplemental_logging_enabled] <> B.[is_supplemental_logging_enabled]
					OR				A.[snapshot_isolation_state] <> B.[snapshot_isolation_state]
					OR				A.[snapshot_isolation_state_desc] <> B.[snapshot_isolation_state_desc] COLLATE database_default
					OR				A.[is_read_committed_snapshot_on] <> B.[is_read_committed_snapshot_on]
					OR				A.[recovery_model] <> B.[recovery_model]
					OR				A.[recovery_model_desc] <> B.[recovery_model_desc] COLLATE database_default
					OR				A.[page_verify_option] <> B.[page_verify_option]
					OR				A.[page_verify_option_desc] <> B.[page_verify_option_desc] COLLATE database_default
					OR				A.[is_auto_create_stats_on] <> B.[is_auto_create_stats_on]
					OR				A.[is_auto_create_stats_incremental_on] <> B.[is_auto_create_stats_incremental_on]
					OR				A.[is_auto_update_stats_on] <> B.[is_auto_update_stats_on]
					OR				A.[is_auto_update_stats_async_on] <> B.[is_auto_update_stats_async_on]
					OR				A.[is_ansi_null_default_on] <> B.[is_ansi_null_default_on]
					OR				A.[is_ansi_nulls_on] <> B.[is_ansi_nulls_on]
					OR				A.[is_ansi_padding_on] <> B.[is_ansi_padding_on]
					OR				A.[is_ansi_warnings_on] <> B.[is_ansi_warnings_on]
					OR				A.[is_arithabort_on] <> B.[is_arithabort_on]
					OR				A.[is_concat_null_yields_null_on] <> B.[is_concat_null_yields_null_on]
					OR				A.[is_numeric_roundabort_on] <> B.[is_numeric_roundabort_on]
					OR				A.[is_quoted_identifier_on] <> B.[is_quoted_identifier_on]
					OR				A.[is_recursive_triggers_on] <> B.[is_recursive_triggers_on]
					OR				A.[is_cursor_close_on_commit_on] <> B.[is_cursor_close_on_commit_on]
					OR				A.[is_local_cursor_default] <> B.[is_local_cursor_default]
					OR				A.[is_fulltext_enabled] <> B.[is_fulltext_enabled]
					OR				A.[is_trustworthy_on] <> B.[is_trustworthy_on]
					OR				A.[is_db_chaining_on] <> B.[is_db_chaining_on]
					OR				A.[is_parameterization_forced] <> B.[is_parameterization_forced]
					OR				A.[is_master_key_encrypted_by_server] <> B.[is_master_key_encrypted_by_server]
					OR				A.[is_query_store_on] <> B.[is_query_store_on]
					OR				A.[is_published] <> B.[is_published]
					OR				A.[is_subscribed] <> B.[is_subscribed]
					OR				A.[is_merge_published] <> B.[is_merge_published]
					OR				A.[is_distributor] <> B.[is_distributor]
					OR				A.[is_sync_with_backup] <> B.[is_sync_with_backup]
					OR				A.[service_broker_guid] <> B.[service_broker_guid]
					OR				A.[is_broker_enabled] <> B.[is_broker_enabled]
					OR				A.[log_reuse_wait] <> B.[log_reuse_wait]
					OR				A.[log_reuse_wait_desc] <> B.[log_reuse_wait_desc] COLLATE database_default
					OR				A.[is_date_correlation_on] <> B.[is_date_correlation_on]
					OR				A.[is_cdc_enabled] <> B.[is_cdc_enabled]
					OR				A.[is_encrypted] <> B.[is_encrypted]
					OR				A.[is_honor_broker_priority_on] <> B.[is_honor_broker_priority_on]
					OR				A.[replica_id] <> B.[replica_id]
					OR				A.[group_database_id] <> B.[group_database_id]
					OR				A.[resource_pool_id] <> B.[resource_pool_id]
					OR				A.[default_language_lcid] <> B.[default_language_lcid]
					OR				A.[default_language_name] <> B.[default_language_name] COLLATE database_default
					OR				A.[default_fulltext_language_lcid] <> B.[default_fulltext_language_lcid]
					OR				A.[default_fulltext_language_name] <> B.[default_fulltext_language_name] COLLATE database_default
					OR				A.[is_nested_triggers_on] <> B.[is_nested_triggers_on]
					OR				A.[is_transform_noise_words_on] <> B.[is_transform_noise_words_on]
					OR				A.[two_digit_year_cutoff] <> B.[two_digit_year_cutoff]
					OR				A.[containment] <> B.[containment]
					OR				A.[containment_desc] <> B.[containment_desc] COLLATE database_default
					OR				A.[target_recovery_time_in_seconds] <> B.[target_recovery_time_in_seconds]
					OR				A.[delayed_durability] <> B.[delayed_durability]
					OR				A.[delayed_durability_desc] <> B.[delayed_durability_desc] COLLATE database_default
					OR				A.[is_memory_optimized_elevate_to_snapshot_on] <> B.[is_memory_optimized_elevate_to_snapshot_on]
					OR				A.[is_federation_member] <> B.[is_federation_member]
					OR				A.[is_remote_data_archive_enabled] <> B.[is_remote_data_archive_enabled]
					OR				A.[is_mixed_page_allocation_on] <> B.[is_mixed_page_allocation_on]
					OR				A.[is_temporal_history_retention_enabled] <> B.[is_temporal_history_retention_enabled])

					SELECT		@varDatabase_Name = MIN([name]) 
					FROM		sys.databases 
					WHERE		[name] > @varDatabase_Name
				END

			SELECT @varSQL_Text = 
			''INSERT INTO [dbo].[tblDBMon_Sys_Databases]
			SELECT	GETDATE(),
				[name],
				[database_id],
				[source_database_id],
				[owner_sid],
				[create_date],
				[compatibility_level],
				[collation_name],
				[user_access],
				[user_access_desc],
				[is_read_only],
				[is_auto_close_on],
				[is_auto_shrink_on],
				[state],
				[state_desc],
				[is_in_standby],
				[is_cleanly_shutdown],
				[is_supplemental_logging_enabled],
				[snapshot_isolation_state],
				[snapshot_isolation_state_desc],
				[is_read_committed_snapshot_on],
				[recovery_model],
				[recovery_model_desc],
				[page_verify_option],
				[page_verify_option_desc],
				[is_auto_create_stats_on],
				[is_auto_create_stats_incremental_on],
				[is_auto_update_stats_on],
				[is_auto_update_stats_async_on],
				[is_ansi_null_default_on],
				[is_ansi_nulls_on],
				[is_ansi_padding_on],
				[is_ansi_warnings_on],
				[is_arithabort_on],
				[is_concat_null_yields_null_on],
				[is_numeric_roundabort_on],
				[is_quoted_identifier_on],
				[is_recursive_triggers_on],
				[is_cursor_close_on_commit_on],
				[is_local_cursor_default],
				[is_fulltext_enabled],
				[is_trustworthy_on],
				[is_db_chaining_on],
				[is_parameterization_forced],
				[is_master_key_encrypted_by_server],
				[is_query_store_on],
				[is_published],
				[is_subscribed],
				[is_merge_published],
				[is_distributor],
				[is_sync_with_backup],
				[service_broker_guid],
				[is_broker_enabled],
				[log_reuse_wait],
				[log_reuse_wait_desc],
				[is_date_correlation_on],
				[is_cdc_enabled],
				[is_encrypted],
				[is_honor_broker_priority_on],
				[replica_id],
				[group_database_id],
				[resource_pool_id],
				[default_language_lcid],
				[default_language_name],
				[default_fulltext_language_lcid],
				[default_fulltext_language_name],
				[is_nested_triggers_on],
				[is_transform_noise_words_on],
				[two_digit_year_cutoff],
				[containment],
				[containment_desc],
				[target_recovery_time_in_seconds],
				[delayed_durability],
				[delayed_durability_desc],
				[is_memory_optimized_elevate_to_snapshot_on],
				[is_federation_member],
				[is_remote_data_archive_enabled],
				[is_mixed_page_allocation_on],
				[is_temporal_history_retention_enabled],
				SUSER_SNAME()
		FROM	[sys].[databases]
		WHERE	[name] NOT IN (SELECT [name] FROM [dbo].[tblDBMon_Sys_Databases])''
		EXEC (@varSQL_Text)'
		EXEC (@varSQL_Text)

		SELECT	@varSQL_Text = 
				'EXEC sys.sp_addextendedproperty 
					@name=N''Version'', 
					@value=N''1.0 2017'' , 
					@level0type=N''SCHEMA'',
					@level0name=N''dbo'', 
					@level1type=N''PROCEDURE'',
					@level1name=N''uspDBMon_Get_SYS_Databases'''
		EXEC (@varSQL_Text)
	END
GO
--IF SQL 2016

IF ((SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(50)),0, CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))))) = 13)
    BEGIN
		DECLARE @varSQL_Text VARCHAR(MAX)

		SELECT @varSQL_Text = 
		'CREATE TABLE [dbo].[tblDBMon_Sys_Databases](
			[Date_Captured] [datetime] NOT NULL CONSTRAINT [DF_tblDBMon_Sys_Databases_Date_Captured] DEFAULT GETDATE(),
			[name] [sysname] NOT NULL,
			[database_id] [int] NOT NULL,
			[source_database_id] [int] NULL,
			[owner_sid] [varbinary](85) NULL,
			[create_date] [datetime] NOT NULL,
			[compatibility_level] [tinyint] NOT NULL,
			[collation_name] [sysname] NULL,
			[user_access] [tinyint] NULL,
			[user_access_desc] [nvarchar](60) NULL,
			[is_read_only] [bit] NULL,
			[is_auto_close_on] [bit] NOT NULL,
			[is_auto_shrink_on] [bit] NULL,
			[state] [tinyint] NULL,
			[state_desc] [nvarchar](60) NULL,
			[is_in_standby] [bit] NULL,
			[is_cleanly_shutdown] [bit] NULL,
			[is_supplemental_logging_enabled] [bit] NULL,
			[snapshot_isolation_state] [tinyint] NULL,
			[snapshot_isolation_state_desc] [nvarchar](60) NULL,
			[is_read_committed_snapshot_on] [bit] NULL,
			[recovery_model] [tinyint] NULL,
			[recovery_model_desc] [nvarchar](60) NULL,
			[page_verify_option] [tinyint] NULL,
			[page_verify_option_desc] [nvarchar](60) NULL,
			[is_auto_create_stats_on] [bit] NULL,
			[is_auto_create_stats_incremental_on] [bit] NULL,
			[is_auto_update_stats_on] [bit] NULL,
			[is_auto_update_stats_async_on] [bit] NULL,
			[is_ansi_null_default_on] [bit] NULL,
			[is_ansi_nulls_on] [bit] NULL,
			[is_ansi_padding_on] [bit] NULL,
			[is_ansi_warnings_on] [bit] NULL,
			[is_arithabort_on] [bit] NULL,
			[is_concat_null_yields_null_on] [bit] NULL,
			[is_numeric_roundabort_on] [bit] NULL,
			[is_quoted_identifier_on] [bit] NULL,
			[is_recursive_triggers_on] [bit] NULL,
			[is_cursor_close_on_commit_on] [bit] NULL,
			[is_local_cursor_default] [bit] NULL,
			[is_fulltext_enabled] [bit] NULL,
			[is_trustworthy_on] [bit] NULL,
			[is_db_chaining_on] [bit] NULL,
			[is_parameterization_forced] [bit] NULL,
			[is_master_key_encrypted_by_server] [bit] NOT NULL,
			[is_query_store_on] [bit] NULL,
			[is_published] [bit] NOT NULL,
			[is_subscribed] [bit] NOT NULL,
			[is_merge_published] [bit] NOT NULL,
			[is_distributor] [bit] NOT NULL,
			[is_sync_with_backup] [bit] NOT NULL,
			[service_broker_guid] [uniqueidentifier] NOT NULL,
			[is_broker_enabled] [bit] NOT NULL,
			[log_reuse_wait] [tinyint] NULL,
			[log_reuse_wait_desc] [nvarchar](60) NULL,
			[is_date_correlation_on] [bit] NOT NULL,
			[is_cdc_enabled] [bit] NOT NULL,
			[is_encrypted] [bit] NULL,
			[is_honor_broker_priority_on] [bit] NULL,
			[replica_id] [uniqueidentifier] NULL,
			[group_database_id] [uniqueidentifier] NULL,
			[resource_pool_id] [int] NULL,
			[default_language_lcid] [smallint] NULL,
			[default_language_name] [nvarchar](128) NULL,
			[default_fulltext_language_lcid] [int] NULL,
			[default_fulltext_language_name] [nvarchar](128) NULL,
			[is_nested_triggers_on] [bit] NULL,
			[is_transform_noise_words_on] [bit] NULL,
			[two_digit_year_cutoff] [smallint] NULL,
			[containment] [tinyint] NULL,
			[containment_desc] [nvarchar](60) NULL,
			[target_recovery_time_in_seconds] [int] NULL,
			[delayed_durability] [int] NULL,
			[delayed_durability_desc] [nvarchar](60) NULL,
			[is_memory_optimized_elevate_to_snapshot_on] [bit] NULL,
			[is_federation_member] [bit] NULL,
			[is_remote_data_archive_enabled] [bit] NULL,
			[is_mixed_page_allocation_on] [bit] NULL,
			[Updated_By] [nvarchar](128) NOT NULL CONSTRAINT [DF_tblDBMon_Sys_Databases_Updated_By] DEFAULT SUSER_SNAME()
		)
		CREATE CLUSTERED INDEX IDX_tblDBMon_Sys_Databases_Date_Captured ON [dbo].[tblDBMon_Sys_Databases](Date_Captured)'
		EXEC (@varSQL_Text)

		SELECT @varSQL_Text = 
		'INSERT INTO [dbo].[tblDBMon_Sys_Databases]
		SELECT	GETDATE(),
				[name],
				[database_id],
				[source_database_id],
				[owner_sid],
				[create_date],
				[compatibility_level],
				[collation_name],
				[user_access],
				[user_access_desc],
				[is_read_only],
				[is_auto_close_on],
				[is_auto_shrink_on],
				[state],
				[state_desc],
				[is_in_standby],
				[is_cleanly_shutdown],
				[is_supplemental_logging_enabled],
				[snapshot_isolation_state],
				[snapshot_isolation_state_desc],
				[is_read_committed_snapshot_on],
				[recovery_model],
				[recovery_model_desc],
				[page_verify_option],
				[page_verify_option_desc],
				[is_auto_create_stats_on],
				[is_auto_create_stats_incremental_on],
				[is_auto_update_stats_on],
				[is_auto_update_stats_async_on],
				[is_ansi_null_default_on],
				[is_ansi_nulls_on],
				[is_ansi_padding_on],
				[is_ansi_warnings_on],
				[is_arithabort_on],
				[is_concat_null_yields_null_on],
				[is_numeric_roundabort_on],
				[is_quoted_identifier_on],
				[is_recursive_triggers_on],
				[is_cursor_close_on_commit_on],
				[is_local_cursor_default],
				[is_fulltext_enabled],
				[is_trustworthy_on],
				[is_db_chaining_on],
				[is_parameterization_forced],
				[is_master_key_encrypted_by_server],
				[is_query_store_on],
				[is_published],
				[is_subscribed],
				[is_merge_published],
				[is_distributor],
				[is_sync_with_backup],
				[service_broker_guid],
				[is_broker_enabled],
				[log_reuse_wait],
				[log_reuse_wait_desc],
				[is_date_correlation_on],
				[is_cdc_enabled],
				[is_encrypted],
				[is_honor_broker_priority_on],
				[replica_id],
				[group_database_id],
				[resource_pool_id],
				[default_language_lcid],
				[default_language_name],
				[default_fulltext_language_lcid],
				[default_fulltext_language_name],
				[is_nested_triggers_on],
				[is_transform_noise_words_on],
				[two_digit_year_cutoff],
				[containment],
				[containment_desc],
				[target_recovery_time_in_seconds],
				[delayed_durability],
				[delayed_durability_desc],
				[is_memory_optimized_elevate_to_snapshot_on],
				[is_federation_member],
				[is_remote_data_archive_enabled],
				[is_mixed_page_allocation_on],
				SUSER_SNAME()
		FROM	[sys].[databases]'
		PRINT 'SQL Server Version identified as SQL Server 2016'
		EXEC (@varSQL_Text) 


		--Stored Procedure code starts
		SELECT	@varSQL_Text = 
		'IF EXISTS (SELECT 1 FROM [sys].[procedures] WHERE [name] = ''uspDBMon_Get_SYS_Databases'' AND schema_id = SCHEMA_ID(''dbo''))
			BEGIN
				PRINT ''The procedure: [dbo].[uspDBMon_Get_SYS_Databases] already exists. Dropping it first.''
				DROP PROC [dbo].[uspDBMon_Get_SYS_Databases]
			END'
		EXEC (@varSQL_Text)

		--Create the procedure
		SELECT	@varSQL_Text = 
		'CREATE PROCEDURE [dbo].[uspDBMon_Get_SYS_Databases]
		AS
		/*
			Author	:	Raghu Gopalakrishnan
			Date	:	28th January 2018
			Purpose	:	This Stored Procedure is used by the DBMon tool to capture database configuration changes
						so that we have historical data to review changes over a period of time.
			Version	:	1.0 2016
			License:
			This script is provided "AS IS" with no warranties, and confers no rights.
						EXEC [dbo].[uspDBMon_Get_SYS_Databases]
						SELECT * FROM [dbo].[tblDBMon_Sys_Databases]
			Modification History
			----------------------
			Jan  28th, 2018	:	v1.0 2016	:	Raghu Gopalakrishnan	:	Inception
		*/
			SET NOCOUNT ON
			DECLARE @varDatabase_Name SYSNAME
			DECLARE @varSQL_Text VARCHAR(MAX)

			SELECT	@varDatabase_Name = MIN([name]) FROM [sys].[databases] 

			WHILE (@varDatabase_Name IS NOT NULL)
				BEGIN
					WITH cte_tblDBMon_Sys_Databases AS(
						SELECT TOP 1 * 
						FROM	[dbo].[tblDBMon_Sys_Databases]
						WHERE	[name] = @varDatabase_Name
						ORDER BY Date_Captured DESC
					)

					INSERT INTO		[dbo].[tblDBMon_Sys_Databases]
					SELECT			GETDATE(), A.*, SUSER_SNAME() 
					FROM			[sys].[databases] A
					LEFT OUTER JOIN cte_tblDBMon_Sys_Databases B
					ON				A.[name] = B.[name] 
					WHERE			(A.database_id <> B.database_id
					OR				A.[source_database_id] <> B.[source_database_id]
					OR				A.[owner_sid] <> B.[owner_sid]
					OR				A.[create_date] <> B.[create_date]
					OR				A.[compatibility_level] <> B.[compatibility_level]
					OR				A.[collation_name] <> B.[collation_name] COLLATE database_default
					OR				A.[user_access] <> B.[user_access]
					OR				A.[user_access_desc] <> B.[user_access_desc] COLLATE database_default
					OR				A.[is_read_only] <> B.[is_read_only]
					OR				A.[is_auto_close_on] <> B.[is_auto_close_on]
					OR				A.[is_auto_shrink_on] <> B.[is_auto_shrink_on]
					OR				A.[state] <> B.[state]
					OR				A.[state_desc] <> B.[state_desc] COLLATE database_default
					OR				A.[is_in_standby] <> B.[is_in_standby]
					OR				A.[is_cleanly_shutdown] <> B.[is_cleanly_shutdown]
					OR				A.[is_supplemental_logging_enabled] <> B.[is_supplemental_logging_enabled]
					OR				A.[snapshot_isolation_state] <> B.[snapshot_isolation_state]
					OR				A.[snapshot_isolation_state_desc] <> B.[snapshot_isolation_state_desc] COLLATE database_default
					OR				A.[is_read_committed_snapshot_on] <> B.[is_read_committed_snapshot_on]
					OR				A.[recovery_model] <> B.[recovery_model]
					OR				A.[recovery_model_desc] <> B.[recovery_model_desc] COLLATE database_default
					OR				A.[page_verify_option] <> B.[page_verify_option]
					OR				A.[page_verify_option_desc] <> B.[page_verify_option_desc] COLLATE database_default
					OR				A.[is_auto_create_stats_on] <> B.[is_auto_create_stats_on]
					OR				A.[is_auto_create_stats_incremental_on] <> B.[is_auto_create_stats_incremental_on]
					OR				A.[is_auto_update_stats_on] <> B.[is_auto_update_stats_on]
					OR				A.[is_auto_update_stats_async_on] <> B.[is_auto_update_stats_async_on]
					OR				A.[is_ansi_null_default_on] <> B.[is_ansi_null_default_on]
					OR				A.[is_ansi_nulls_on] <> B.[is_ansi_nulls_on]
					OR				A.[is_ansi_padding_on] <> B.[is_ansi_padding_on]
					OR				A.[is_ansi_warnings_on] <> B.[is_ansi_warnings_on]
					OR				A.[is_arithabort_on] <> B.[is_arithabort_on]
					OR				A.[is_concat_null_yields_null_on] <> B.[is_concat_null_yields_null_on]
					OR				A.[is_numeric_roundabort_on] <> B.[is_numeric_roundabort_on]
					OR				A.[is_quoted_identifier_on] <> B.[is_quoted_identifier_on]
					OR				A.[is_recursive_triggers_on] <> B.[is_recursive_triggers_on]
					OR				A.[is_cursor_close_on_commit_on] <> B.[is_cursor_close_on_commit_on]
					OR				A.[is_local_cursor_default] <> B.[is_local_cursor_default]
					OR				A.[is_fulltext_enabled] <> B.[is_fulltext_enabled]
					OR				A.[is_trustworthy_on] <> B.[is_trustworthy_on]
					OR				A.[is_db_chaining_on] <> B.[is_db_chaining_on]
					OR				A.[is_parameterization_forced] <> B.[is_parameterization_forced]
					OR				A.[is_master_key_encrypted_by_server] <> B.[is_master_key_encrypted_by_server]
					OR				A.[is_query_store_on] <> B.[is_query_store_on]
					OR				A.[is_published] <> B.[is_published]
					OR				A.[is_subscribed] <> B.[is_subscribed]
					OR				A.[is_merge_published] <> B.[is_merge_published]
					OR				A.[is_distributor] <> B.[is_distributor]
					OR				A.[is_sync_with_backup] <> B.[is_sync_with_backup]
					OR				A.[service_broker_guid] <> B.[service_broker_guid]
					OR				A.[is_broker_enabled] <> B.[is_broker_enabled]
					OR				A.[log_reuse_wait] <> B.[log_reuse_wait]
					OR				A.[log_reuse_wait_desc] <> B.[log_reuse_wait_desc] COLLATE database_default
					OR				A.[is_date_correlation_on] <> B.[is_date_correlation_on]
					OR				A.[is_cdc_enabled] <> B.[is_cdc_enabled]
					OR				A.[is_encrypted] <> B.[is_encrypted]
					OR				A.[is_honor_broker_priority_on] <> B.[is_honor_broker_priority_on]
					OR				A.[replica_id] <> B.[replica_id]
					OR				A.[group_database_id] <> B.[group_database_id]
					OR				A.[resource_pool_id] <> B.[resource_pool_id]
					OR				A.[default_language_lcid] <> B.[default_language_lcid]
					OR				A.[default_language_name] <> B.[default_language_name] COLLATE database_default
					OR				A.[default_fulltext_language_lcid] <> B.[default_fulltext_language_lcid]
					OR				A.[default_fulltext_language_name] <> B.[default_fulltext_language_name] COLLATE database_default
					OR				A.[is_nested_triggers_on] <> B.[is_nested_triggers_on]
					OR				A.[is_transform_noise_words_on] <> B.[is_transform_noise_words_on]
					OR				A.[two_digit_year_cutoff] <> B.[two_digit_year_cutoff]
					OR				A.[containment] <> B.[containment]
					OR				A.[containment_desc] <> B.[containment_desc] COLLATE database_default
					OR				A.[target_recovery_time_in_seconds] <> B.[target_recovery_time_in_seconds]
					OR				A.[delayed_durability] <> B.[delayed_durability]
					OR				A.[delayed_durability_desc] <> B.[delayed_durability_desc] COLLATE database_default
					OR				A.[is_memory_optimized_elevate_to_snapshot_on] <> B.[is_memory_optimized_elevate_to_snapshot_on]
					OR				A.[is_federation_member] <> B.[is_federation_member]
					OR				A.[is_remote_data_archive_enabled] <> B.[is_remote_data_archive_enabled]
					OR				A.[is_mixed_page_allocation_on] <> B.[is_mixed_page_allocation_on]
					)

					SELECT		@varDatabase_Name = MIN([name]) 
					FROM		sys.databases 
					WHERE		[name] > @varDatabase_Name
				END
				
			SELECT @varSQL_Text = 
			''INSERT INTO [dbo].[tblDBMon_Sys_Databases]
			SELECT	GETDATE(),
				[name],
				[database_id],
				[source_database_id],
				[owner_sid],
				[create_date],
				[compatibility_level],
				[collation_name],
				[user_access],
				[user_access_desc],
				[is_read_only],
				[is_auto_close_on],
				[is_auto_shrink_on],
				[state],
				[state_desc],
				[is_in_standby],
				[is_cleanly_shutdown],
				[is_supplemental_logging_enabled],
				[snapshot_isolation_state],
				[snapshot_isolation_state_desc],
				[is_read_committed_snapshot_on],
				[recovery_model],
				[recovery_model_desc],
				[page_verify_option],
				[page_verify_option_desc],
				[is_auto_create_stats_on],
				[is_auto_create_stats_incremental_on],
				[is_auto_update_stats_on],
				[is_auto_update_stats_async_on],
				[is_ansi_null_default_on],
				[is_ansi_nulls_on],
				[is_ansi_padding_on],
				[is_ansi_warnings_on],
				[is_arithabort_on],
				[is_concat_null_yields_null_on],
				[is_numeric_roundabort_on],
				[is_quoted_identifier_on],
				[is_recursive_triggers_on],
				[is_cursor_close_on_commit_on],
				[is_local_cursor_default],
				[is_fulltext_enabled],
				[is_trustworthy_on],
				[is_db_chaining_on],
				[is_parameterization_forced],
				[is_master_key_encrypted_by_server],
				[is_query_store_on],
				[is_published],
				[is_subscribed],
				[is_merge_published],
				[is_distributor],
				[is_sync_with_backup],
				[service_broker_guid],
				[is_broker_enabled],
				[log_reuse_wait],
				[log_reuse_wait_desc],
				[is_date_correlation_on],
				[is_cdc_enabled],
				[is_encrypted],
				[is_honor_broker_priority_on],
				[replica_id],
				[group_database_id],
				[resource_pool_id],
				[default_language_lcid],
				[default_language_name],
				[default_fulltext_language_lcid],
				[default_fulltext_language_name],
				[is_nested_triggers_on],
				[is_transform_noise_words_on],
				[two_digit_year_cutoff],
				[containment],
				[containment_desc],
				[target_recovery_time_in_seconds],
				[delayed_durability],
				[delayed_durability_desc],
				[is_memory_optimized_elevate_to_snapshot_on],
				[is_federation_member],
				[is_remote_data_archive_enabled],
				[is_mixed_page_allocation_on],
				SUSER_SNAME()
		FROM	[sys].[databases]
		WHERE	[name] NOT IN (SELECT [name] FROM [dbo].[tblDBMon_Sys_Databases])''
		EXEC (@varSQL_Text)'
		EXEC (@varSQL_Text)

		SELECT	@varSQL_Text = 
				'EXEC sys.sp_addextendedproperty 
					@name=N''Version'', 
					@value=N''1.0 2016'' , 
					@level0type=N''SCHEMA'',
					@level0name=N''dbo'', 
					@level1type=N''PROCEDURE'',
					@level1name=N''uspDBMon_Get_SYS_Databases'''
		EXEC (@varSQL_Text)

	END
GO 

--IF SQL 2014

IF ((SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(50)),0, CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))))) = 12)
    BEGIN
		DECLARE @varSQL_Text VARCHAR(MAX)

		SELECT @varSQL_Text = 
		'CREATE TABLE [dbo].[tblDBMon_Sys_Databases](
			[Date_Captured] [datetime] NOT NULL CONSTRAINT [DF_tblDBMon_Sys_Databases_Date_Captured] DEFAULT GETDATE(),
			[name] [sysname] NOT NULL,
			[database_id] [int] NOT NULL,
			[source_database_id] [int] NULL,
			[owner_sid] [varbinary](85) NULL,
			[create_date] [datetime] NOT NULL,
			[compatibility_level] [tinyint] NOT NULL,
			[collation_name] [sysname] NULL,
			[user_access] [tinyint] NULL,
			[user_access_desc] [nvarchar](60) NULL,
			[is_read_only] [bit] NULL,
			[is_auto_close_on] [bit] NOT NULL,
			[is_auto_shrink_on] [bit] NULL,
			[state] [tinyint] NULL,
			[state_desc] [nvarchar](60) NULL,
			[is_in_standby] [bit] NULL,
			[is_cleanly_shutdown] [bit] NULL,
			[is_supplemental_logging_enabled] [bit] NULL,
			[snapshot_isolation_state] [tinyint] NULL,
			[snapshot_isolation_state_desc] [nvarchar](60) NULL,
			[is_read_committed_snapshot_on] [bit] NULL,
			[recovery_model] [tinyint] NULL,
			[recovery_model_desc] [nvarchar](60) NULL,
			[page_verify_option] [tinyint] NULL,
			[page_verify_option_desc] [nvarchar](60) NULL,
			[is_auto_create_stats_on] [bit] NULL,
			[is_auto_create_stats_incremental_on] [bit] NULL,
			[is_auto_update_stats_on] [bit] NULL,
			[is_auto_update_stats_async_on] [bit] NULL,
			[is_ansi_null_default_on] [bit] NULL,
			[is_ansi_nulls_on] [bit] NULL,
			[is_ansi_padding_on] [bit] NULL,
			[is_ansi_warnings_on] [bit] NULL,
			[is_arithabort_on] [bit] NULL,
			[is_concat_null_yields_null_on] [bit] NULL,
			[is_numeric_roundabort_on] [bit] NULL,
			[is_quoted_identifier_on] [bit] NULL,
			[is_recursive_triggers_on] [bit] NULL,
			[is_cursor_close_on_commit_on] [bit] NULL,
			[is_local_cursor_default] [bit] NULL,
			[is_fulltext_enabled] [bit] NULL,
			[is_trustworthy_on] [bit] NULL,
			[is_db_chaining_on] [bit] NULL,
			[is_parameterization_forced] [bit] NULL,
			[is_master_key_encrypted_by_server] [bit] NOT NULL,
			[is_query_store_on] [bit] NULL,
			[is_published] [bit] NOT NULL,
			[is_subscribed] [bit] NOT NULL,
			[is_merge_published] [bit] NOT NULL,
			[is_distributor] [bit] NOT NULL,
			[is_sync_with_backup] [bit] NOT NULL,
			[service_broker_guid] [uniqueidentifier] NOT NULL,
			[is_broker_enabled] [bit] NOT NULL,
			[log_reuse_wait] [tinyint] NULL,
			[log_reuse_wait_desc] [nvarchar](60) NULL,
			[is_date_correlation_on] [bit] NOT NULL,
			[is_cdc_enabled] [bit] NOT NULL,
			[is_encrypted] [bit] NULL,
			[is_honor_broker_priority_on] [bit] NULL,
			[replica_id] [uniqueidentifier] NULL,
			[group_database_id] [uniqueidentifier] NULL,
			[resource_pool_id] [int] NULL,
			[default_language_lcid] [smallint] NULL,
			[default_language_name] [nvarchar](128) NULL,
			[default_fulltext_language_lcid] [int] NULL,
			[default_fulltext_language_name] [nvarchar](128) NULL,
			[is_nested_triggers_on] [bit] NULL,
			[is_transform_noise_words_on] [bit] NULL,
			[two_digit_year_cutoff] [smallint] NULL,
			[containment] [tinyint] NULL,
			[containment_desc] [nvarchar](60) NULL,
			[target_recovery_time_in_seconds] [int] NULL,
			[delayed_durability] [int] NULL,
			[delayed_durability_desc] [nvarchar](60) NULL,
			[is_memory_optimized_elevate_to_snapshot_on] [bit] NULL,
			[Updated_By] [nvarchar](128) NOT NULL CONSTRAINT [DF_tblDBMon_Sys_Databases_Updated_By] DEFAULT SUSER_SNAME()
		)
		CREATE CLUSTERED INDEX IDX_tblDBMon_Sys_Databases_Date_Captured ON [dbo].[tblDBMon_Sys_Databases](Date_Captured)'
		EXEC (@varSQL_Text)

		SELECT @varSQL_Text = 
		'INSERT INTO [dbo].[tblDBMon_Sys_Databases]
		SELECT	GETDATE(),
				[name],
				[database_id],
				[source_database_id],
				[owner_sid],
				[create_date],
				[compatibility_level],
				[collation_name],
				[user_access],
				[user_access_desc],
				[is_read_only],
				[is_auto_close_on],
				[is_auto_shrink_on],
				[state],
				[state_desc],
				[is_in_standby],
				[is_cleanly_shutdown],
				[is_supplemental_logging_enabled],
				[snapshot_isolation_state],
				[snapshot_isolation_state_desc],
				[is_read_committed_snapshot_on],
				[recovery_model],
				[recovery_model_desc],
				[page_verify_option],
				[page_verify_option_desc],
				[is_auto_create_stats_on],
				[is_auto_create_stats_incremental_on],
				[is_auto_update_stats_on],
				[is_auto_update_stats_async_on],
				[is_ansi_null_default_on],
				[is_ansi_nulls_on],
				[is_ansi_padding_on],
				[is_ansi_warnings_on],
				[is_arithabort_on],
				[is_concat_null_yields_null_on],
				[is_numeric_roundabort_on],
				[is_quoted_identifier_on],
				[is_recursive_triggers_on],
				[is_cursor_close_on_commit_on],
				[is_local_cursor_default],
				[is_fulltext_enabled],
				[is_trustworthy_on],
				[is_db_chaining_on],
				[is_parameterization_forced],
				[is_master_key_encrypted_by_server],
				[is_query_store_on],
				[is_published],
				[is_subscribed],
				[is_merge_published],
				[is_distributor],
				[is_sync_with_backup],
				[service_broker_guid],
				[is_broker_enabled],
				[log_reuse_wait],
				[log_reuse_wait_desc],
				[is_date_correlation_on],
				[is_cdc_enabled],
				[is_encrypted],
				[is_honor_broker_priority_on],
				[replica_id],
				[group_database_id],
				[resource_pool_id],
				[default_language_lcid],
				[default_language_name],
				[default_fulltext_language_lcid],
				[default_fulltext_language_name],
				[is_nested_triggers_on],
				[is_transform_noise_words_on],
				[two_digit_year_cutoff],
				[containment],
				[containment_desc],
				[target_recovery_time_in_seconds],
				[delayed_durability],
				[delayed_durability_desc],
				[is_memory_optimized_elevate_to_snapshot_on],
				SUSER_SNAME()
		FROM	[sys].[databases]'
		PRINT 'SQL Server Version identified as SQL Server 2014'
		EXEC (@varSQL_Text) 
		

		--Stored Procedure code starts
		SELECT	@varSQL_Text = 
		'IF EXISTS (SELECT 1 FROM [sys].[procedures] WHERE [name] = ''uspDBMon_Get_SYS_Databases'' AND schema_id = SCHEMA_ID(''dbo''))
			BEGIN
				PRINT ''The procedure: [dbo].[uspDBMon_Get_SYS_Databases] already exists. Dropping it first.''
				DROP PROC [dbo].[uspDBMon_Get_SYS_Databases]
			END'
		EXEC (@varSQL_Text)

		--Create the procedure
		SELECT	@varSQL_Text = 
		'CREATE PROCEDURE [dbo].[uspDBMon_Get_SYS_Databases]
		AS
		/*
			Author	:	Raghu Gopalakrishnan
			Date	:	28th January 2018
			Purpose	:	This Stored Procedure is used by the DBMon tool to capture database configuration changes
						so that we have historical data to review changes over a period of time.
			Version	:	1.0 2014
			License:
			This script is provided "AS IS" with no warranties, and confers no rights.
						EXEC [dbo].[uspDBMon_Get_SYS_Databases]
						SELECT * FROM [dbo].[tblDBMon_Sys_Databases]
			Modification History
			----------------------
			Jan  28th, 2018	:	v1.0 2014	:	Raghu Gopalakrishnan	:	Inception
		*/
			SET NOCOUNT ON
			DECLARE @varDatabase_Name SYSNAME
			DECLARE @varSQL_Text VARCHAR(MAX)

			SELECT	@varDatabase_Name = MIN([name]) FROM [sys].[databases] 

			WHILE (@varDatabase_Name IS NOT NULL)
				BEGIN
					WITH cte_tblDBMon_Sys_Databases AS(
						SELECT TOP 1 * 
						FROM	[dbo].[tblDBMon_Sys_Databases]
						WHERE	[name] = @varDatabase_Name
						ORDER BY Date_Captured DESC
					)

					INSERT INTO		[dbo].[tblDBMon_Sys_Databases]
					SELECT			GETDATE(), A.*, SUSER_SNAME() 
					FROM			[sys].[databases] A
					LEFT OUTER JOIN cte_tblDBMon_Sys_Databases B
					ON				A.[name] = B.[name] 
					WHERE			(A.database_id <> B.database_id
					OR				A.[source_database_id] <> B.[source_database_id]
					OR				A.[owner_sid] <> B.[owner_sid]
					OR				A.[create_date] <> B.[create_date]
					OR				A.[compatibility_level] <> B.[compatibility_level]
					OR				A.[collation_name] <> B.[collation_name] COLLATE database_default
					OR				A.[user_access] <> B.[user_access]
					OR				A.[user_access_desc] <> B.[user_access_desc] COLLATE database_default
					OR				A.[is_read_only] <> B.[is_read_only]
					OR				A.[is_auto_close_on] <> B.[is_auto_close_on]
					OR				A.[is_auto_shrink_on] <> B.[is_auto_shrink_on]
					OR				A.[state] <> B.[state]
					OR				A.[state_desc] <> B.[state_desc] COLLATE database_default
					OR				A.[is_in_standby] <> B.[is_in_standby]
					OR				A.[is_cleanly_shutdown] <> B.[is_cleanly_shutdown]
					OR				A.[is_supplemental_logging_enabled] <> B.[is_supplemental_logging_enabled]
					OR				A.[snapshot_isolation_state] <> B.[snapshot_isolation_state]
					OR				A.[snapshot_isolation_state_desc] <> B.[snapshot_isolation_state_desc] COLLATE database_default
					OR				A.[is_read_committed_snapshot_on] <> B.[is_read_committed_snapshot_on]
					OR				A.[recovery_model] <> B.[recovery_model]
					OR				A.[recovery_model_desc] <> B.[recovery_model_desc] COLLATE database_default
					OR				A.[page_verify_option] <> B.[page_verify_option]
					OR				A.[page_verify_option_desc] <> B.[page_verify_option_desc] COLLATE database_default
					OR				A.[is_auto_create_stats_on] <> B.[is_auto_create_stats_on]
					OR				A.[is_auto_create_stats_incremental_on] <> B.[is_auto_create_stats_incremental_on]
					OR				A.[is_auto_update_stats_on] <> B.[is_auto_update_stats_on]
					OR				A.[is_auto_update_stats_async_on] <> B.[is_auto_update_stats_async_on]
					OR				A.[is_ansi_null_default_on] <> B.[is_ansi_null_default_on]
					OR				A.[is_ansi_nulls_on] <> B.[is_ansi_nulls_on]
					OR				A.[is_ansi_padding_on] <> B.[is_ansi_padding_on]
					OR				A.[is_ansi_warnings_on] <> B.[is_ansi_warnings_on]
					OR				A.[is_arithabort_on] <> B.[is_arithabort_on]
					OR				A.[is_concat_null_yields_null_on] <> B.[is_concat_null_yields_null_on]
					OR				A.[is_numeric_roundabort_on] <> B.[is_numeric_roundabort_on]
					OR				A.[is_quoted_identifier_on] <> B.[is_quoted_identifier_on]
					OR				A.[is_recursive_triggers_on] <> B.[is_recursive_triggers_on]
					OR				A.[is_cursor_close_on_commit_on] <> B.[is_cursor_close_on_commit_on]
					OR				A.[is_local_cursor_default] <> B.[is_local_cursor_default]
					OR				A.[is_fulltext_enabled] <> B.[is_fulltext_enabled]
					OR				A.[is_trustworthy_on] <> B.[is_trustworthy_on]
					OR				A.[is_db_chaining_on] <> B.[is_db_chaining_on]
					OR				A.[is_parameterization_forced] <> B.[is_parameterization_forced]
					OR				A.[is_master_key_encrypted_by_server] <> B.[is_master_key_encrypted_by_server]
					OR				A.[is_query_store_on] <> B.[is_query_store_on]
					OR				A.[is_published] <> B.[is_published]
					OR				A.[is_subscribed] <> B.[is_subscribed]
					OR				A.[is_merge_published] <> B.[is_merge_published]
					OR				A.[is_distributor] <> B.[is_distributor]
					OR				A.[is_sync_with_backup] <> B.[is_sync_with_backup]
					OR				A.[service_broker_guid] <> B.[service_broker_guid]
					OR				A.[is_broker_enabled] <> B.[is_broker_enabled]
					OR				A.[log_reuse_wait] <> B.[log_reuse_wait]
					OR				A.[log_reuse_wait_desc] <> B.[log_reuse_wait_desc] COLLATE database_default
					OR				A.[is_date_correlation_on] <> B.[is_date_correlation_on]
					OR				A.[is_cdc_enabled] <> B.[is_cdc_enabled]
					OR				A.[is_encrypted] <> B.[is_encrypted]
					OR				A.[is_honor_broker_priority_on] <> B.[is_honor_broker_priority_on]
					OR				A.[replica_id] <> B.[replica_id]
					OR				A.[group_database_id] <> B.[group_database_id]
					OR				A.[resource_pool_id] <> B.[resource_pool_id]
					OR				A.[default_language_lcid] <> B.[default_language_lcid]
					OR				A.[default_language_name] <> B.[default_language_name] COLLATE database_default
					OR				A.[default_fulltext_language_lcid] <> B.[default_fulltext_language_lcid]
					OR				A.[default_fulltext_language_name] <> B.[default_fulltext_language_name] COLLATE database_default
					OR				A.[is_nested_triggers_on] <> B.[is_nested_triggers_on]
					OR				A.[is_transform_noise_words_on] <> B.[is_transform_noise_words_on]
					OR				A.[two_digit_year_cutoff] <> B.[two_digit_year_cutoff]
					OR				A.[containment] <> B.[containment]
					OR				A.[containment_desc] <> B.[containment_desc] COLLATE database_default
					OR				A.[target_recovery_time_in_seconds] <> B.[target_recovery_time_in_seconds]
					OR				A.[delayed_durability] <> B.[delayed_durability]
					OR				A.[delayed_durability_desc] <> B.[delayed_durability_desc] COLLATE database_default
					OR				A.[is_memory_optimized_elevate_to_snapshot_on] <> B.[is_memory_optimized_elevate_to_snapshot_on]
					)

					SELECT		@varDatabase_Name = MIN([name]) 
					FROM		sys.databases 
					WHERE		[name] > @varDatabase_Name
				END
			
			SELECT @varSQL_Text = 
			''INSERT INTO [dbo].[tblDBMon_Sys_Databases]
			SELECT	GETDATE(),
				[name],
				[database_id],
				[source_database_id],
				[owner_sid],
				[create_date],
				[compatibility_level],
				[collation_name],
				[user_access],
				[user_access_desc],
				[is_read_only],
				[is_auto_close_on],
				[is_auto_shrink_on],
				[state],
				[state_desc],
				[is_in_standby],
				[is_cleanly_shutdown],
				[is_supplemental_logging_enabled],
				[snapshot_isolation_state],
				[snapshot_isolation_state_desc],
				[is_read_committed_snapshot_on],
				[recovery_model],
				[recovery_model_desc],
				[page_verify_option],
				[page_verify_option_desc],
				[is_auto_create_stats_on],
				[is_auto_create_stats_incremental_on],
				[is_auto_update_stats_on],
				[is_auto_update_stats_async_on],
				[is_ansi_null_default_on],
				[is_ansi_nulls_on],
				[is_ansi_padding_on],
				[is_ansi_warnings_on],
				[is_arithabort_on],
				[is_concat_null_yields_null_on],
				[is_numeric_roundabort_on],
				[is_quoted_identifier_on],
				[is_recursive_triggers_on],
				[is_cursor_close_on_commit_on],
				[is_local_cursor_default],
				[is_fulltext_enabled],
				[is_trustworthy_on],
				[is_db_chaining_on],
				[is_parameterization_forced],
				[is_master_key_encrypted_by_server],
				[is_query_store_on],
				[is_published],
				[is_subscribed],
				[is_merge_published],
				[is_distributor],
				[is_sync_with_backup],
				[service_broker_guid],
				[is_broker_enabled],
				[log_reuse_wait],
				[log_reuse_wait_desc],
				[is_date_correlation_on],
				[is_cdc_enabled],
				[is_encrypted],
				[is_honor_broker_priority_on],
				[replica_id],
				[group_database_id],
				[resource_pool_id],
				[default_language_lcid],
				[default_language_name],
				[default_fulltext_language_lcid],
				[default_fulltext_language_name],
				[is_nested_triggers_on],
				[is_transform_noise_words_on],
				[two_digit_year_cutoff],
				[containment],
				[containment_desc],
				[target_recovery_time_in_seconds],
				[delayed_durability],
				[delayed_durability_desc],
				[is_memory_optimized_elevate_to_snapshot_on],
				SUSER_SNAME()
		FROM	[sys].[databases]
		WHERE	[name] NOT IN (SELECT [name] FROM [dbo].[tblDBMon_Sys_Databases])''
		EXEC (@varSQL_Text)'
		EXEC (@varSQL_Text)

		SELECT	@varSQL_Text = 
				'EXEC sys.sp_addextendedproperty 
					@name=N''Version'', 
					@value=N''1.0 2014'' , 
					@level0type=N''SCHEMA'',
					@level0name=N''dbo'', 
					@level1type=N''PROCEDURE'',
					@level1name=N''uspDBMon_Get_SYS_Databases'''
		EXEC (@varSQL_Text)
		 
	END
GO

--IF SQL 2012

IF ((SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(50)),0, CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))))) = 11)
    BEGIN
		DECLARE @varSQL_Text VARCHAR(MAX)

		SELECT @varSQL_Text = 
		'CREATE TABLE [dbo].[tblDBMon_Sys_Databases](
			[Date_Captured] [datetime] NOT NULL CONSTRAINT [DF_tblDBMon_Sys_Databases_Date_Captured] DEFAULT GETDATE(),
			[name] [sysname] NOT NULL,
			[database_id] [int] NOT NULL,
			[source_database_id] [int] NULL,
			[owner_sid] [varbinary](85) NULL,
			[create_date] [datetime] NOT NULL,
			[compatibility_level] [tinyint] NOT NULL,
			[collation_name] [sysname] NULL,
			[user_access] [tinyint] NULL,
			[user_access_desc] [nvarchar](60) NULL,
			[is_read_only] [bit] NULL,
			[is_auto_close_on] [bit] NOT NULL,
			[is_auto_shrink_on] [bit] NULL,
			[state] [tinyint] NULL,
			[state_desc] [nvarchar](60) NULL,
			[is_in_standby] [bit] NULL,
			[is_cleanly_shutdown] [bit] NULL,
			[is_supplemental_logging_enabled] [bit] NULL,
			[snapshot_isolation_state] [tinyint] NULL,
			[snapshot_isolation_state_desc] [nvarchar](60) NULL,
			[is_read_committed_snapshot_on] [bit] NULL,
			[recovery_model] [tinyint] NULL,
			[recovery_model_desc] [nvarchar](60) NULL,
			[page_verify_option] [tinyint] NULL,
			[page_verify_option_desc] [nvarchar](60) NULL,
			[is_auto_create_stats_on] [bit] NULL,
			[is_auto_update_stats_on] [bit] NULL,
			[is_auto_update_stats_async_on] [bit] NULL,
			[is_ansi_null_default_on] [bit] NULL,
			[is_ansi_nulls_on] [bit] NULL,
			[is_ansi_padding_on] [bit] NULL,
			[is_ansi_warnings_on] [bit] NULL,
			[is_arithabort_on] [bit] NULL,
			[is_concat_null_yields_null_on] [bit] NULL,
			[is_numeric_roundabort_on] [bit] NULL,
			[is_quoted_identifier_on] [bit] NULL,
			[is_recursive_triggers_on] [bit] NULL,
			[is_cursor_close_on_commit_on] [bit] NULL,
			[is_local_cursor_default] [bit] NULL,
			[is_fulltext_enabled] [bit] NULL,
			[is_trustworthy_on] [bit] NULL,
			[is_db_chaining_on] [bit] NULL,
			[is_parameterization_forced] [bit] NULL,
			[is_master_key_encrypted_by_server] [bit] NOT NULL,
			[is_published] [bit] NOT NULL,
			[is_subscribed] [bit] NOT NULL,
			[is_merge_published] [bit] NOT NULL,
			[is_distributor] [bit] NOT NULL,
			[is_sync_with_backup] [bit] NOT NULL,
			[service_broker_guid] [uniqueidentifier] NOT NULL,
			[is_broker_enabled] [bit] NOT NULL,
			[log_reuse_wait] [tinyint] NULL,
			[log_reuse_wait_desc] [nvarchar](60) NULL,
			[is_date_correlation_on] [bit] NOT NULL,
			[is_cdc_enabled] [bit] NOT NULL,
			[is_encrypted] [bit] NULL,
			[is_honor_broker_priority_on] [bit] NULL,
			[replica_id] [uniqueidentifier] NULL,
			[group_database_id] [uniqueidentifier] NULL,
			[default_language_lcid] [smallint] NULL,
			[default_language_name] [nvarchar](128) NULL,
			[default_fulltext_language_lcid] [int] NULL,
			[default_fulltext_language_name] [nvarchar](128) NULL,
			[is_nested_triggers_on] [bit] NULL,
			[is_transform_noise_words_on] [bit] NULL,
			[two_digit_year_cutoff] [smallint] NULL,
			[containment] [tinyint] NULL,
			[containment_desc] [nvarchar](60) NULL,
			[target_recovery_time_in_seconds] [int] NULL,
			[Updated_By] [nvarchar](128) NOT NULL CONSTRAINT [DF_tblDBMon_Sys_Databases_Updated_By] DEFAULT SUSER_SNAME()
		)
		CREATE CLUSTERED INDEX IDX_tblDBMon_Sys_Databases_Date_Captured ON [dbo].[tblDBMon_Sys_Databases](Date_Captured)'
		
		EXEC (@varSQL_Text)

		SELECT @varSQL_Text = 
		'INSERT INTO [dbo].[tblDBMon_Sys_Databases]
		SELECT	GETDATE(),
				[name],
				[database_id],
				[source_database_id],
				[owner_sid],
				[create_date],
				[compatibility_level],
				[collation_name],
				[user_access],
				[user_access_desc],
				[is_read_only],
				[is_auto_close_on],
				[is_auto_shrink_on],
				[state],
				[state_desc],
				[is_in_standby],
				[is_cleanly_shutdown],
				[is_supplemental_logging_enabled],
				[snapshot_isolation_state],
				[snapshot_isolation_state_desc],
				[is_read_committed_snapshot_on],
				[recovery_model],
				[recovery_model_desc],
				[page_verify_option],
				[page_verify_option_desc],
				[is_auto_create_stats_on],
				[is_auto_update_stats_on],
				[is_auto_update_stats_async_on],
				[is_ansi_null_default_on],
				[is_ansi_nulls_on],
				[is_ansi_padding_on],
				[is_ansi_warnings_on],
				[is_arithabort_on],
				[is_concat_null_yields_null_on],
				[is_numeric_roundabort_on],
				[is_quoted_identifier_on],
				[is_recursive_triggers_on],
				[is_cursor_close_on_commit_on],
				[is_local_cursor_default],
				[is_fulltext_enabled],
				[is_trustworthy_on],
				[is_db_chaining_on],
				[is_parameterization_forced],
				[is_master_key_encrypted_by_server],
				[is_published],
				[is_subscribed],
				[is_merge_published],
				[is_distributor],
				[is_sync_with_backup],
				[service_broker_guid],
				[is_broker_enabled],
				[log_reuse_wait],
				[log_reuse_wait_desc],
				[is_date_correlation_on],
				[is_cdc_enabled],
				[is_encrypted],
				[is_honor_broker_priority_on],
				[replica_id],
				[group_database_id],
				[default_language_lcid],
				[default_language_name],
				[default_fulltext_language_lcid],
				[default_fulltext_language_name],
				[is_nested_triggers_on],
				[is_transform_noise_words_on],
				[two_digit_year_cutoff],
				[containment],
				[containment_desc],
				[target_recovery_time_in_seconds],
				SUSER_SNAME()
		FROM	[sys].[databases]'
		PRINT 'SQL Server Version identified as SQL Server 2012'
		EXEC (@varSQL_Text)
		

		--Stored Procedure code starts
		SELECT	@varSQL_Text = 
		'IF EXISTS (SELECT 1 FROM [sys].[procedures] WHERE [name] = ''uspDBMon_Get_SYS_Databases'' AND schema_id = SCHEMA_ID(''dbo''))
			BEGIN
				PRINT ''The procedure: [dbo].[uspDBMon_Get_SYS_Databases] already exists. Dropping it first.''
				DROP PROC [dbo].[uspDBMon_Get_SYS_Databases]
			END'
		EXEC (@varSQL_Text)

		--Create the procedure
		SELECT	@varSQL_Text = 
		'CREATE PROCEDURE [dbo].[uspDBMon_Get_SYS_Databases]
		AS
		/*
			Author	:	Raghu Gopalakrishnan
			Date	:	28th January 2018
			Purpose	:	This Stored Procedure is used by the DBMon tool to capture database configuration changes
						so that we have historical data to review changes over a period of time.
			Version	:	1.0 2012
			License:
			This script is provided "AS IS" with no warranties, and confers no rights.
						EXEC [dbo].[uspDBMon_Get_SYS_Databases]
						SELECT * FROM [dbo].[tblDBMon_Sys_Databases]
			Modification History
			----------------------
			Jan  28th, 2018	:	v1.0 2012	:	Raghu Gopalakrishnan	:	Inception
		*/
			SET NOCOUNT ON
			DECLARE @varDatabase_Name SYSNAME
			DECLARE @varSQL_Text VARCHAR(MAX)

			SELECT	@varDatabase_Name = MIN([name]) FROM [sys].[databases] 

			WHILE (@varDatabase_Name IS NOT NULL)
				BEGIN
					WITH cte_tblDBMon_Sys_Databases AS(
						SELECT TOP 1 * 
						FROM	[dbo].[tblDBMon_Sys_Databases]
						WHERE	[name] = @varDatabase_Name
						ORDER BY Date_Captured DESC
					)

					INSERT INTO		[dbo].[tblDBMon_Sys_Databases]
					SELECT			GETDATE(), A.*, SUSER_SNAME() 
					FROM			[sys].[databases] A
					LEFT OUTER JOIN cte_tblDBMon_Sys_Databases B
					ON				A.[name] = B.[name] 
					WHERE			(A.database_id <> B.database_id
					OR				A.[source_database_id] <> B.[source_database_id]
					OR				A.[owner_sid] <> B.[owner_sid]
					OR				A.[create_date] <> B.[create_date]
					OR				A.[compatibility_level] <> B.[compatibility_level]
					OR				A.[collation_name] <> B.[collation_name] COLLATE database_default
					OR				A.[user_access] <> B.[user_access]
					OR				A.[user_access_desc] <> B.[user_access_desc] COLLATE database_default
					OR				A.[is_read_only] <> B.[is_read_only]
					OR				A.[is_auto_close_on] <> B.[is_auto_close_on]
					OR				A.[is_auto_shrink_on] <> B.[is_auto_shrink_on]
					OR				A.[state] <> B.[state]
					OR				A.[state_desc] <> B.[state_desc] COLLATE database_default
					OR				A.[is_in_standby] <> B.[is_in_standby]
					OR				A.[is_cleanly_shutdown] <> B.[is_cleanly_shutdown]
					OR				A.[is_supplemental_logging_enabled] <> B.[is_supplemental_logging_enabled]
					OR				A.[snapshot_isolation_state] <> B.[snapshot_isolation_state]
					OR				A.[snapshot_isolation_state_desc] <> B.[snapshot_isolation_state_desc] COLLATE database_default
					OR				A.[is_read_committed_snapshot_on] <> B.[is_read_committed_snapshot_on]
					OR				A.[recovery_model] <> B.[recovery_model]
					OR				A.[recovery_model_desc] <> B.[recovery_model_desc] COLLATE database_default
					OR				A.[page_verify_option] <> B.[page_verify_option]
					OR				A.[page_verify_option_desc] <> B.[page_verify_option_desc] COLLATE database_default
					OR				A.[is_auto_create_stats_on] <> B.[is_auto_create_stats_on]
					OR				A.[is_auto_update_stats_on] <> B.[is_auto_update_stats_on]
					OR				A.[is_auto_update_stats_async_on] <> B.[is_auto_update_stats_async_on]
					OR				A.[is_ansi_null_default_on] <> B.[is_ansi_null_default_on]
					OR				A.[is_ansi_nulls_on] <> B.[is_ansi_nulls_on]
					OR				A.[is_ansi_padding_on] <> B.[is_ansi_padding_on]
					OR				A.[is_ansi_warnings_on] <> B.[is_ansi_warnings_on]
					OR				A.[is_arithabort_on] <> B.[is_arithabort_on]
					OR				A.[is_concat_null_yields_null_on] <> B.[is_concat_null_yields_null_on]
					OR				A.[is_numeric_roundabort_on] <> B.[is_numeric_roundabort_on]
					OR				A.[is_quoted_identifier_on] <> B.[is_quoted_identifier_on]
					OR				A.[is_recursive_triggers_on] <> B.[is_recursive_triggers_on]
					OR				A.[is_cursor_close_on_commit_on] <> B.[is_cursor_close_on_commit_on]
					OR				A.[is_local_cursor_default] <> B.[is_local_cursor_default]
					OR				A.[is_fulltext_enabled] <> B.[is_fulltext_enabled]
					OR				A.[is_trustworthy_on] <> B.[is_trustworthy_on]
					OR				A.[is_db_chaining_on] <> B.[is_db_chaining_on]
					OR				A.[is_parameterization_forced] <> B.[is_parameterization_forced]
					OR				A.[is_master_key_encrypted_by_server] <> B.[is_master_key_encrypted_by_server]
					OR				A.[is_published] <> B.[is_published]
					OR				A.[is_subscribed] <> B.[is_subscribed]
					OR				A.[is_merge_published] <> B.[is_merge_published]
					OR				A.[is_distributor] <> B.[is_distributor]
					OR				A.[is_sync_with_backup] <> B.[is_sync_with_backup]
					OR				A.[service_broker_guid] <> B.[service_broker_guid]
					OR				A.[is_broker_enabled] <> B.[is_broker_enabled]
					OR				A.[log_reuse_wait] <> B.[log_reuse_wait]
					OR				A.[log_reuse_wait_desc] <> B.[log_reuse_wait_desc] COLLATE database_default
					OR				A.[is_date_correlation_on] <> B.[is_date_correlation_on]
					OR				A.[is_cdc_enabled] <> B.[is_cdc_enabled]
					OR				A.[is_encrypted] <> B.[is_encrypted]
					OR				A.[is_honor_broker_priority_on] <> B.[is_honor_broker_priority_on]
					OR				A.[replica_id] <> B.[replica_id]
					OR				A.[group_database_id] <> B.[group_database_id]
					OR				A.[default_language_lcid] <> B.[default_language_lcid]
					OR				A.[default_language_name] <> B.[default_language_name] COLLATE database_default
					OR				A.[default_fulltext_language_lcid] <> B.[default_fulltext_language_lcid]
					OR				A.[default_fulltext_language_name] <> B.[default_fulltext_language_name] COLLATE database_default
					OR				A.[is_nested_triggers_on] <> B.[is_nested_triggers_on]
					OR				A.[is_transform_noise_words_on] <> B.[is_transform_noise_words_on]
					OR				A.[two_digit_year_cutoff] <> B.[two_digit_year_cutoff]
					OR				A.[containment] <> B.[containment]
					OR				A.[containment_desc] <> B.[containment_desc] COLLATE database_default
					OR				A.[target_recovery_time_in_seconds] <> B.[target_recovery_time_in_seconds]
					)

					SELECT		@varDatabase_Name = MIN([name]) 
					FROM		sys.databases 
					WHERE		[name] > @varDatabase_Name
				END
			
			SELECT @varSQL_Text = 
			''INSERT INTO [dbo].[tblDBMon_Sys_Databases]
			SELECT	GETDATE(),
				[name],
				[database_id],
				[source_database_id],
				[owner_sid],
				[create_date],
				[compatibility_level],
				[collation_name],
				[user_access],
				[user_access_desc],
				[is_read_only],
				[is_auto_close_on],
				[is_auto_shrink_on],
				[state],
				[state_desc],
				[is_in_standby],
				[is_cleanly_shutdown],
				[is_supplemental_logging_enabled],
				[snapshot_isolation_state],
				[snapshot_isolation_state_desc],
				[is_read_committed_snapshot_on],
				[recovery_model],
				[recovery_model_desc],
				[page_verify_option],
				[page_verify_option_desc],
				[is_auto_create_stats_on],
				[is_auto_update_stats_on],
				[is_auto_update_stats_async_on],
				[is_ansi_null_default_on],
				[is_ansi_nulls_on],
				[is_ansi_padding_on],
				[is_ansi_warnings_on],
				[is_arithabort_on],
				[is_concat_null_yields_null_on],
				[is_numeric_roundabort_on],
				[is_quoted_identifier_on],
				[is_recursive_triggers_on],
				[is_cursor_close_on_commit_on],
				[is_local_cursor_default],
				[is_fulltext_enabled],
				[is_trustworthy_on],
				[is_db_chaining_on],
				[is_parameterization_forced],
				[is_master_key_encrypted_by_server],
				[is_published],
				[is_subscribed],
				[is_merge_published],
				[is_distributor],
				[is_sync_with_backup],
				[service_broker_guid],
				[is_broker_enabled],
				[log_reuse_wait],
				[log_reuse_wait_desc],
				[is_date_correlation_on],
				[is_cdc_enabled],
				[is_encrypted],
				[is_honor_broker_priority_on],
				[replica_id],
				[group_database_id],
				[default_language_lcid],
				[default_language_name],
				[default_fulltext_language_lcid],
				[default_fulltext_language_name],
				[is_nested_triggers_on],
				[is_transform_noise_words_on],
				[two_digit_year_cutoff],
				[containment],
				[containment_desc],
				[target_recovery_time_in_seconds],
				SUSER_SNAME()
		FROM	[sys].[databases]
		WHERE	[name] NOT IN (SELECT [name] FROM [dbo].[tblDBMon_Sys_Databases])''
		EXEC (@varSQL_Text)'
		EXEC (@varSQL_Text)

		SELECT	@varSQL_Text = 
				'EXEC sys.sp_addextendedproperty 
					@name=N''Version'', 
					@value=N''1.0 2012'' , 
					@level0type=N''SCHEMA'',
					@level0name=N''dbo'', 
					@level1type=N''PROCEDURE'',
					@level1name=N''uspDBMon_Get_SYS_Databases'''
		EXEC (@varSQL_Text)
		 
	END
GO
--IF SQL 2008 R2

IF ((SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(50)),0, CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))))) = 10)
    BEGIN
		DECLARE @varSQL_Text VARCHAR(MAX)

		SELECT @varSQL_Text = 
		'CREATE TABLE [dbo].[tblDBMon_Sys_Databases](
			[Date_Captured] [datetime] NOT NULL CONSTRAINT [DF_tblDBMon_Sys_Databases_Date_Captured] DEFAULT GETDATE(),
			[name] [sysname] NOT NULL,
			[database_id] [int] NOT NULL,
			[source_database_id] [int] NULL,
			[owner_sid] [varbinary](85) NULL,
			[create_date] [datetime] NOT NULL,
			[compatibility_level] [tinyint] NOT NULL,
			[collation_name] [sysname] NULL,
			[user_access] [tinyint] NULL,
			[user_access_desc] [nvarchar](60) NULL,
			[is_read_only] [bit] NULL,
			[is_auto_close_on] [bit] NOT NULL,
			[is_auto_shrink_on] [bit] NULL,
			[state] [tinyint] NULL,
			[state_desc] [nvarchar](60) NULL,
			[is_in_standby] [bit] NULL,
			[is_cleanly_shutdown] [bit] NULL,
			[is_supplemental_logging_enabled] [bit] NULL,
			[snapshot_isolation_state] [tinyint] NULL,
			[snapshot_isolation_state_desc] [nvarchar](60) NULL,
			[is_read_committed_snapshot_on] [bit] NULL,
			[recovery_model] [tinyint] NULL,
			[recovery_model_desc] [nvarchar](60) NULL,
			[page_verify_option] [tinyint] NULL,
			[page_verify_option_desc] [nvarchar](60) NULL,
			[is_auto_create_stats_on] [bit] NULL,
			[is_auto_update_stats_on] [bit] NULL,
			[is_auto_update_stats_async_on] [bit] NULL,
			[is_ansi_null_default_on] [bit] NULL,
			[is_ansi_nulls_on] [bit] NULL,
			[is_ansi_padding_on] [bit] NULL,
			[is_ansi_warnings_on] [bit] NULL,
			[is_arithabort_on] [bit] NULL,
			[is_concat_null_yields_null_on] [bit] NULL,
			[is_numeric_roundabort_on] [bit] NULL,
			[is_quoted_identifier_on] [bit] NULL,
			[is_recursive_triggers_on] [bit] NULL,
			[is_cursor_close_on_commit_on] [bit] NULL,
			[is_local_cursor_default] [bit] NULL,
			[is_fulltext_enabled] [bit] NULL,
			[is_trustworthy_on] [bit] NULL,
			[is_db_chaining_on] [bit] NULL,
			[is_parameterization_forced] [bit] NULL,
			[is_master_key_encrypted_by_server] [bit] NOT NULL,
			[is_published] [bit] NOT NULL,
			[is_subscribed] [bit] NOT NULL,
			[is_merge_published] [bit] NOT NULL,
			[is_distributor] [bit] NOT NULL,
			[is_sync_with_backup] [bit] NOT NULL,
			[service_broker_guid] [uniqueidentifier] NOT NULL,
			[is_broker_enabled] [bit] NOT NULL,
			[log_reuse_wait] [tinyint] NULL,
			[log_reuse_wait_desc] [nvarchar](60) NULL,
			[is_date_correlation_on] [bit] NOT NULL,
			[is_cdc_enabled] [bit] NOT NULL,
			[is_encrypted] [bit] NULL,
			[is_honor_broker_priority_on] [bit] NULL,
			[Updated_By] [nvarchar](128) NOT NULL CONSTRAINT [DF_tblDBMon_Sys_Databases_Updated_By] DEFAULT SUSER_SNAME()
		)
		CREATE CLUSTERED INDEX IDX_tblDBMon_Sys_Databases_Date_Captured ON [dbo].[tblDBMon_Sys_Databases](Date_Captured)'
		
		EXEC (@varSQL_Text)

		SELECT @varSQL_Text = 
		'INSERT INTO [dbo].[tblDBMon_Sys_Databases]
		SELECT	GETDATE(),
				[name],
				[database_id],
				[source_database_id],
				[owner_sid],
				[create_date],
				[compatibility_level],
				[collation_name],
				[user_access],
				[user_access_desc],
				[is_read_only],
				[is_auto_close_on],
				[is_auto_shrink_on],
				[state],
				[state_desc],
				[is_in_standby],
				[is_cleanly_shutdown],
				[is_supplemental_logging_enabled],
				[snapshot_isolation_state],
				[snapshot_isolation_state_desc],
				[is_read_committed_snapshot_on],
				[recovery_model],
				[recovery_model_desc],
				[page_verify_option],
				[page_verify_option_desc],
				[is_auto_create_stats_on],
				[is_auto_update_stats_on],
				[is_auto_update_stats_async_on],
				[is_ansi_null_default_on],
				[is_ansi_nulls_on],
				[is_ansi_padding_on],
				[is_ansi_warnings_on],
				[is_arithabort_on],
				[is_concat_null_yields_null_on],
				[is_numeric_roundabort_on],
				[is_quoted_identifier_on],
				[is_recursive_triggers_on],
				[is_cursor_close_on_commit_on],
				[is_local_cursor_default],
				[is_fulltext_enabled],
				[is_trustworthy_on],
				[is_db_chaining_on],
				[is_parameterization_forced],
				[is_master_key_encrypted_by_server],
				[is_published],
				[is_subscribed],
				[is_merge_published],
				[is_distributor],
				[is_sync_with_backup],
				[service_broker_guid],
				[is_broker_enabled],
				[log_reuse_wait],
				[log_reuse_wait_desc],
				[is_date_correlation_on],
				[is_cdc_enabled],
				[is_encrypted],
				[is_honor_broker_priority_on],
				SUSER_SNAME()
		FROM	[sys].[databases]'
		PRINT 'SQL Server Version identified as SQL Server 2008 (R2)'
		EXEC (@varSQL_Text) 

		--Stored Procedure code starts
		SELECT	@varSQL_Text = 
		'IF EXISTS (SELECT 1 FROM [sys].[procedures] WHERE [name] = ''uspDBMon_Get_SYS_Databases'' AND schema_id = SCHEMA_ID(''dbo''))
			BEGIN
				PRINT ''The procedure: [dbo].[uspDBMon_Get_SYS_Databases] already exists. Dropping it first.''
				DROP PROC [dbo].[uspDBMon_Get_SYS_Databases]
			END'
		EXEC (@varSQL_Text)

		--Create the procedure
		SELECT	@varSQL_Text = 
		'CREATE PROCEDURE [dbo].[uspDBMon_Get_SYS_Databases]
		AS
		/*
			Author	:	Raghu Gopalakrishnan
			Date	:	28th January 2018
			Purpose	:	This Stored Procedure is used by the DBMon tool to capture database configuration changes
						so that we have historical data to review changes over a period of time.
			Version	:	1.0 2008 (R2)
			License:
			This script is provided "AS IS" with no warranties, and confers no rights.
						EXEC [dbo].[uspDBMon_Get_SYS_Databases]
						SELECT * FROM [dbo].[tblDBMon_Sys_Databases]
			Modification History
			----------------------
			Jan  28th, 2018	:	v1.0 2008 (R2)	:	Raghu Gopalakrishnan	:	Inception
		*/
			SET NOCOUNT ON
			DECLARE @varDatabase_Name SYSNAME
			DECLARE @varSQL_Text VARCHAR(MAX)

			SELECT	@varDatabase_Name = MIN([name]) FROM [sys].[databases] 

			WHILE (@varDatabase_Name IS NOT NULL)
				BEGIN
					WITH cte_tblDBMon_Sys_Databases AS(
						SELECT TOP 1 * 
						FROM	[dbo].[tblDBMon_Sys_Databases]
						WHERE	[name] = @varDatabase_Name
						ORDER BY Date_Captured DESC
					)

					INSERT INTO		[dbo].[tblDBMon_Sys_Databases]
					SELECT			GETDATE(), A.*, SUSER_SNAME() 
					FROM			[sys].[databases] A
					LEFT OUTER JOIN cte_tblDBMon_Sys_Databases B
					ON				A.[name] = B.[name] 
					WHERE			(A.database_id <> B.database_id
					OR				A.[source_database_id] <> B.[source_database_id]
					OR				A.[owner_sid] <> B.[owner_sid]
					OR				A.[create_date] <> B.[create_date]
					OR				A.[compatibility_level] <> B.[compatibility_level]
					OR				A.[collation_name] <> B.[collation_name] COLLATE database_default
					OR				A.[user_access] <> B.[user_access]
					OR				A.[user_access_desc] <> B.[user_access_desc] COLLATE database_default
					OR				A.[is_read_only] <> B.[is_read_only]
					OR				A.[is_auto_close_on] <> B.[is_auto_close_on]
					OR				A.[is_auto_shrink_on] <> B.[is_auto_shrink_on]
					OR				A.[state] <> B.[state]
					OR				A.[state_desc] <> B.[state_desc] COLLATE database_default
					OR				A.[is_in_standby] <> B.[is_in_standby]
					OR				A.[is_cleanly_shutdown] <> B.[is_cleanly_shutdown]
					OR				A.[is_supplemental_logging_enabled] <> B.[is_supplemental_logging_enabled]
					OR				A.[snapshot_isolation_state] <> B.[snapshot_isolation_state]
					OR				A.[snapshot_isolation_state_desc] <> B.[snapshot_isolation_state_desc] COLLATE database_default
					OR				A.[is_read_committed_snapshot_on] <> B.[is_read_committed_snapshot_on]
					OR				A.[recovery_model] <> B.[recovery_model]
					OR				A.[recovery_model_desc] <> B.[recovery_model_desc] COLLATE database_default
					OR				A.[page_verify_option] <> B.[page_verify_option]
					OR				A.[page_verify_option_desc] <> B.[page_verify_option_desc] COLLATE database_default
					OR				A.[is_auto_create_stats_on] <> B.[is_auto_create_stats_on]
					OR				A.[is_auto_update_stats_on] <> B.[is_auto_update_stats_on]
					OR				A.[is_auto_update_stats_async_on] <> B.[is_auto_update_stats_async_on]
					OR				A.[is_ansi_null_default_on] <> B.[is_ansi_null_default_on]
					OR				A.[is_ansi_nulls_on] <> B.[is_ansi_nulls_on]
					OR				A.[is_ansi_padding_on] <> B.[is_ansi_padding_on]
					OR				A.[is_ansi_warnings_on] <> B.[is_ansi_warnings_on]
					OR				A.[is_arithabort_on] <> B.[is_arithabort_on]
					OR				A.[is_concat_null_yields_null_on] <> B.[is_concat_null_yields_null_on]
					OR				A.[is_numeric_roundabort_on] <> B.[is_numeric_roundabort_on]
					OR				A.[is_quoted_identifier_on] <> B.[is_quoted_identifier_on]
					OR				A.[is_recursive_triggers_on] <> B.[is_recursive_triggers_on]
					OR				A.[is_cursor_close_on_commit_on] <> B.[is_cursor_close_on_commit_on]
					OR				A.[is_local_cursor_default] <> B.[is_local_cursor_default]
					OR				A.[is_fulltext_enabled] <> B.[is_fulltext_enabled]
					OR				A.[is_trustworthy_on] <> B.[is_trustworthy_on]
					OR				A.[is_db_chaining_on] <> B.[is_db_chaining_on]
					OR				A.[is_parameterization_forced] <> B.[is_parameterization_forced]
					OR				A.[is_master_key_encrypted_by_server] <> B.[is_master_key_encrypted_by_server]
					OR				A.[is_published] <> B.[is_published]
					OR				A.[is_subscribed] <> B.[is_subscribed]
					OR				A.[is_merge_published] <> B.[is_merge_published]
					OR				A.[is_distributor] <> B.[is_distributor]
					OR				A.[is_sync_with_backup] <> B.[is_sync_with_backup]
					OR				A.[service_broker_guid] <> B.[service_broker_guid]
					OR				A.[is_broker_enabled] <> B.[is_broker_enabled]
					OR				A.[log_reuse_wait] <> B.[log_reuse_wait]
					OR				A.[log_reuse_wait_desc] <> B.[log_reuse_wait_desc] COLLATE database_default
					OR				A.[is_date_correlation_on] <> B.[is_date_correlation_on]
					OR				A.[is_cdc_enabled] <> B.[is_cdc_enabled]
					OR				A.[is_encrypted] <> B.[is_encrypted]
					OR				A.[is_honor_broker_priority_on] <> B.[is_honor_broker_priority_on]
					)

					SELECT		@varDatabase_Name = MIN([name]) 
					FROM		sys.databases 
					WHERE		[name] > @varDatabase_Name
				END
			
			SELECT @varSQL_Text = 
			''INSERT INTO [dbo].[tblDBMon_Sys_Databases]
			SELECT	GETDATE(),
				[name],
				[database_id],
				[source_database_id],
				[owner_sid],
				[create_date],
				[compatibility_level],
				[collation_name],
				[user_access],
				[user_access_desc],
				[is_read_only],
				[is_auto_close_on],
				[is_auto_shrink_on],
				[state],
				[state_desc],
				[is_in_standby],
				[is_cleanly_shutdown],
				[is_supplemental_logging_enabled],
				[snapshot_isolation_state],
				[snapshot_isolation_state_desc],
				[is_read_committed_snapshot_on],
				[recovery_model],
				[recovery_model_desc],
				[page_verify_option],
				[page_verify_option_desc],
				[is_auto_create_stats_on],
				[is_auto_update_stats_on],
				[is_auto_update_stats_async_on],
				[is_ansi_null_default_on],
				[is_ansi_nulls_on],
				[is_ansi_padding_on],
				[is_ansi_warnings_on],
				[is_arithabort_on],
				[is_concat_null_yields_null_on],
				[is_numeric_roundabort_on],
				[is_quoted_identifier_on],
				[is_recursive_triggers_on],
				[is_cursor_close_on_commit_on],
				[is_local_cursor_default],
				[is_fulltext_enabled],
				[is_trustworthy_on],
				[is_db_chaining_on],
				[is_parameterization_forced],
				[is_master_key_encrypted_by_server],
				[is_published],
				[is_subscribed],
				[is_merge_published],
				[is_distributor],
				[is_sync_with_backup],
				[service_broker_guid],
				[is_broker_enabled],
				[log_reuse_wait],
				[log_reuse_wait_desc],
				[is_date_correlation_on],
				[is_cdc_enabled],
				[is_encrypted],
				[is_honor_broker_priority_on],
				SUSER_SNAME()
		FROM	[sys].[databases]
		WHERE	[name] NOT IN (SELECT [name] FROM [dbo].[tblDBMon_Sys_Databases])''
		EXEC (@varSQL_Text)'

		EXEC (@varSQL_Text)

		SELECT	@varSQL_Text = 
				'EXEC sys.sp_addextendedproperty 
					@name=N''Version'', 
					@value=N''1.0 2008 (R2)'' , 
					@level0type=N''SCHEMA'',
					@level0name=N''dbo'', 
					@level1type=N''PROCEDURE'',
					@level1name=N''uspDBMon_Get_SYS_Databases'''
		EXEC (@varSQL_Text)

	END
GO

--IF SQL 2005

IF ((SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(50)),0, CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))))) = 9)
    BEGIN
		DECLARE @varSQL_Text VARCHAR(MAX)

		SELECT @varSQL_Text = 
		'CREATE TABLE [dbo].[tblDBMon_Sys_Databases](
			[Date_Captured] [datetime] NOT NULL CONSTRAINT [DF_tblDBMon_Sys_Databases_Date_Captured] DEFAULT GETDATE(),
			[name] [sysname] NOT NULL,
			[database_id] [int] NOT NULL,
			[source_database_id] [int] NULL,
			[owner_sid] [varbinary](85) NULL,
			[create_date] [datetime] NOT NULL,
			[compatibility_level] [tinyint] NOT NULL,
			[collation_name] [sysname] NULL,
			[user_access] [tinyint] NULL,
			[user_access_desc] [nvarchar](60) NULL,
			[is_read_only] [bit] NULL,
			[is_auto_close_on] [bit] NOT NULL,
			[is_auto_shrink_on] [bit] NULL,
			[state] [tinyint] NULL,
			[state_desc] [nvarchar](60) NULL,
			[is_in_standby] [bit] NULL,
			[is_cleanly_shutdown] [bit] NULL,
			[is_supplemental_logging_enabled] [bit] NULL,
			[snapshot_isolation_state] [tinyint] NULL,
			[snapshot_isolation_state_desc] [nvarchar](60) NULL,
			[is_read_committed_snapshot_on] [bit] NULL,
			[recovery_model] [tinyint] NULL,
			[recovery_model_desc] [nvarchar](60) NULL,
			[page_verify_option] [tinyint] NULL,
			[page_verify_option_desc] [nvarchar](60) NULL,
			[is_auto_create_stats_on] [bit] NULL,
			[is_auto_update_stats_on] [bit] NULL,
			[is_auto_update_stats_async_on] [bit] NULL,
			[is_ansi_null_default_on] [bit] NULL,
			[is_ansi_nulls_on] [bit] NULL,
			[is_ansi_padding_on] [bit] NULL,
			[is_ansi_warnings_on] [bit] NULL,
			[is_arithabort_on] [bit] NULL,
			[is_concat_null_yields_null_on] [bit] NULL,
			[is_numeric_roundabort_on] [bit] NULL,
			[is_quoted_identifier_on] [bit] NULL,
			[is_recursive_triggers_on] [bit] NULL,
			[is_cursor_close_on_commit_on] [bit] NULL,
			[is_local_cursor_default] [bit] NULL,
			[is_fulltext_enabled] [bit] NULL,
			[is_trustworthy_on] [bit] NULL,
			[is_db_chaining_on] [bit] NULL,
			[is_parameterization_forced] [bit] NULL,
			[is_master_key_encrypted_by_server] [bit] NOT NULL,
			[is_published] [bit] NOT NULL,
			[is_subscribed] [bit] NOT NULL,
			[is_merge_published] [bit] NOT NULL,
			[is_distributor] [bit] NOT NULL,
			[is_sync_with_backup] [bit] NOT NULL,
			[service_broker_guid] [uniqueidentifier] NOT NULL,
			[is_broker_enabled] [bit] NOT NULL,
			[log_reuse_wait] [tinyint] NULL,
			[log_reuse_wait_desc] [nvarchar](60) NULL,
			[is_date_correlation_on] [bit] NOT NULL,
			[Updated_By] [nvarchar](128) NOT NULL CONSTRAINT [DF_tblDBMon_Sys_Databases_Updated_By] DEFAULT SUSER_SNAME()
		)
		CREATE CLUSTERED INDEX IDX_tblDBMon_Sys_Databases_Date_Captured ON [dbo].[tblDBMon_Sys_Databases](Date_Captured)'
		
		EXEC (@varSQL_Text)

		SELECT @varSQL_Text = 
		'INSERT INTO [dbo].[tblDBMon_Sys_Databases]
		SELECT	GETDATE(),
				[name],
				[database_id],
				[source_database_id],
				[owner_sid],
				[create_date],
				[compatibility_level],
				[collation_name],
				[user_access],
				[user_access_desc],
				[is_read_only],
				[is_auto_close_on],
				[is_auto_shrink_on],
				[state],
				[state_desc],
				[is_in_standby],
				[is_cleanly_shutdown],
				[is_supplemental_logging_enabled],
				[snapshot_isolation_state],
				[snapshot_isolation_state_desc],
				[is_read_committed_snapshot_on],
				[recovery_model],
				[recovery_model_desc],
				[page_verify_option],
				[page_verify_option_desc],
				[is_auto_create_stats_on],
				[is_auto_update_stats_on],
				[is_auto_update_stats_async_on],
				[is_ansi_null_default_on],
				[is_ansi_nulls_on],
				[is_ansi_padding_on],
				[is_ansi_warnings_on],
				[is_arithabort_on],
				[is_concat_null_yields_null_on],
				[is_numeric_roundabort_on],
				[is_quoted_identifier_on],
				[is_recursive_triggers_on],
				[is_cursor_close_on_commit_on],
				[is_local_cursor_default],
				[is_fulltext_enabled],
				[is_trustworthy_on],
				[is_db_chaining_on],
				[is_parameterization_forced],
				[is_master_key_encrypted_by_server],
				[is_published],
				[is_subscribed],
				[is_merge_published],
				[is_distributor],
				[is_sync_with_backup],
				[service_broker_guid],
				[is_broker_enabled],
				[log_reuse_wait],
				[log_reuse_wait_desc],
				[is_date_correlation_on],
				SUSER_SNAME()
		FROM	[sys].[databases]'
		PRINT 'SQL Server Version identified as SQL Server 2005'
		EXEC (@varSQL_Text) 

		--Stored Procedure code starts
		SELECT	@varSQL_Text = 
		'IF EXISTS (SELECT 1 FROM [sys].[procedures] WHERE [name] = ''uspDBMon_Get_SYS_Databases'' AND schema_id = SCHEMA_ID(''dbo''))
			BEGIN
				PRINT ''The procedure: [dbo].[uspDBMon_Get_SYS_Databases] already exists. Dropping it first.''
				DROP PROC [dbo].[uspDBMon_Get_SYS_Databases]
			END'
		EXEC (@varSQL_Text)

		--Create the procedure
		SELECT	@varSQL_Text = 
		'CREATE PROCEDURE [dbo].[uspDBMon_Get_SYS_Databases]
		AS
		/*
			Author	:	Raghu Gopalakrishnan
			Date	:	28th January 2018
			Purpose	:	This Stored Procedure is used by the DBMon tool to capture database configuration changes
						so that we have historical data to review changes over a period of time.
			Version	:	1.0 2005
			License:
			This script is provided "AS IS" with no warranties, and confers no rights.
						EXEC [dbo].[uspDBMon_Get_SYS_Databases]
						SELECT * FROM [dbo].[tblDBMon_Sys_Databases]
			Modification History
			----------------------
			Jan  28th, 2018	:	v1.0 2005	:	Raghu Gopalakrishnan	:	Inception
		*/
			SET NOCOUNT ON
			DECLARE @varDatabase_Name SYSNAME
			DECLARE @varSQL_Text VARCHAR(MAX)

			SELECT	@varDatabase_Name = MIN([name]) FROM [sys].[databases] 

			WHILE (@varDatabase_Name IS NOT NULL)
				BEGIN
					WITH cte_tblDBMon_Sys_Databases AS(
						SELECT TOP 1 * 
						FROM	[dbo].[tblDBMon_Sys_Databases]
						WHERE	[name] = @varDatabase_Name
						ORDER BY Date_Captured DESC
					)

					INSERT INTO		[dbo].[tblDBMon_Sys_Databases]
					SELECT			GETDATE(), A.*, SUSER_SNAME() 
					FROM			[sys].[databases] A
					LEFT OUTER JOIN cte_tblDBMon_Sys_Databases B
					ON				A.[name] = B.[name] 
					WHERE			(A.database_id <> B.database_id
					OR				A.[source_database_id] <> B.[source_database_id]
					OR				A.[owner_sid] <> B.[owner_sid]
					OR				A.[create_date] <> B.[create_date]
					OR				A.[compatibility_level] <> B.[compatibility_level]
					OR				A.[collation_name] <> B.[collation_name] COLLATE database_default
					OR				A.[user_access] <> B.[user_access]
					OR				A.[user_access_desc] <> B.[user_access_desc] COLLATE database_default
					OR				A.[is_read_only] <> B.[is_read_only]
					OR				A.[is_auto_close_on] <> B.[is_auto_close_on]
					OR				A.[is_auto_shrink_on] <> B.[is_auto_shrink_on]
					OR				A.[state] <> B.[state]
					OR				A.[state_desc] <> B.[state_desc] COLLATE database_default
					OR				A.[is_in_standby] <> B.[is_in_standby]
					OR				A.[is_cleanly_shutdown] <> B.[is_cleanly_shutdown]
					OR				A.[is_supplemental_logging_enabled] <> B.[is_supplemental_logging_enabled]
					OR				A.[snapshot_isolation_state] <> B.[snapshot_isolation_state]
					OR				A.[snapshot_isolation_state_desc] <> B.[snapshot_isolation_state_desc] COLLATE database_default
					OR				A.[is_read_committed_snapshot_on] <> B.[is_read_committed_snapshot_on]
					OR				A.[recovery_model] <> B.[recovery_model]
					OR				A.[recovery_model_desc] <> B.[recovery_model_desc] COLLATE database_default
					OR				A.[page_verify_option] <> B.[page_verify_option]
					OR				A.[page_verify_option_desc] <> B.[page_verify_option_desc] COLLATE database_default
					OR				A.[is_auto_create_stats_on] <> B.[is_auto_create_stats_on]
					OR				A.[is_auto_update_stats_on] <> B.[is_auto_update_stats_on]
					OR				A.[is_auto_update_stats_async_on] <> B.[is_auto_update_stats_async_on]
					OR				A.[is_ansi_null_default_on] <> B.[is_ansi_null_default_on]
					OR				A.[is_ansi_nulls_on] <> B.[is_ansi_nulls_on]
					OR				A.[is_ansi_padding_on] <> B.[is_ansi_padding_on]
					OR				A.[is_ansi_warnings_on] <> B.[is_ansi_warnings_on]
					OR				A.[is_arithabort_on] <> B.[is_arithabort_on]
					OR				A.[is_concat_null_yields_null_on] <> B.[is_concat_null_yields_null_on]
					OR				A.[is_numeric_roundabort_on] <> B.[is_numeric_roundabort_on]
					OR				A.[is_quoted_identifier_on] <> B.[is_quoted_identifier_on]
					OR				A.[is_recursive_triggers_on] <> B.[is_recursive_triggers_on]
					OR				A.[is_cursor_close_on_commit_on] <> B.[is_cursor_close_on_commit_on]
					OR				A.[is_local_cursor_default] <> B.[is_local_cursor_default]
					OR				A.[is_fulltext_enabled] <> B.[is_fulltext_enabled]
					OR				A.[is_trustworthy_on] <> B.[is_trustworthy_on]
					OR				A.[is_db_chaining_on] <> B.[is_db_chaining_on]
					OR				A.[is_parameterization_forced] <> B.[is_parameterization_forced]
					OR				A.[is_master_key_encrypted_by_server] <> B.[is_master_key_encrypted_by_server]
					OR				A.[is_published] <> B.[is_published]
					OR				A.[is_subscribed] <> B.[is_subscribed]
					OR				A.[is_merge_published] <> B.[is_merge_published]
					OR				A.[is_distributor] <> B.[is_distributor]
					OR				A.[is_sync_with_backup] <> B.[is_sync_with_backup]
					OR				A.[service_broker_guid] <> B.[service_broker_guid]
					OR				A.[is_broker_enabled] <> B.[is_broker_enabled]
					OR				A.[log_reuse_wait] <> B.[log_reuse_wait]
					OR				A.[log_reuse_wait_desc] <> B.[log_reuse_wait_desc] COLLATE database_default
					OR				A.[is_date_correlation_on] <> B.[is_date_correlation_on]
					)

					SELECT		@varDatabase_Name = MIN([name]) 
					FROM		sys.databases 
					WHERE		[name] > @varDatabase_Name
				END
			
			SELECT @varSQL_Text = 
			''INSERT INTO [dbo].[tblDBMon_Sys_Databases]
			SELECT	GETDATE(),
				[name],
				[database_id],
				[source_database_id],
				[owner_sid],
				[create_date],
				[compatibility_level],
				[collation_name],
				[user_access],
				[user_access_desc],
				[is_read_only],
				[is_auto_close_on],
				[is_auto_shrink_on],
				[state],
				[state_desc],
				[is_in_standby],
				[is_cleanly_shutdown],
				[is_supplemental_logging_enabled],
				[snapshot_isolation_state],
				[snapshot_isolation_state_desc],
				[is_read_committed_snapshot_on],
				[recovery_model],
				[recovery_model_desc],
				[page_verify_option],
				[page_verify_option_desc],
				[is_auto_create_stats_on],
				[is_auto_update_stats_on],
				[is_auto_update_stats_async_on],
				[is_ansi_null_default_on],
				[is_ansi_nulls_on],
				[is_ansi_padding_on],
				[is_ansi_warnings_on],
				[is_arithabort_on],
				[is_concat_null_yields_null_on],
				[is_numeric_roundabort_on],
				[is_quoted_identifier_on],
				[is_recursive_triggers_on],
				[is_cursor_close_on_commit_on],
				[is_local_cursor_default],
				[is_fulltext_enabled],
				[is_trustworthy_on],
				[is_db_chaining_on],
				[is_parameterization_forced],
				[is_master_key_encrypted_by_server],
				[is_published],
				[is_subscribed],
				[is_merge_published],
				[is_distributor],
				[is_sync_with_backup],
				[service_broker_guid],
				[is_broker_enabled],
				[log_reuse_wait],
				[log_reuse_wait_desc],
				[is_date_correlation_on],
				SUSER_SNAME()
		FROM	[sys].[databases]
		WHERE	[name] NOT IN (SELECT [name] FROM [dbo].[tblDBMon_Sys_Databases])''
		EXEC (@varSQL_Text)'

		EXEC (@varSQL_Text)

		SELECT	@varSQL_Text = 
				'EXEC sys.sp_addextendedproperty 
					@name=N''Version'', 
					@value=N''1.0 2005'' , 
					@level0type=N''SCHEMA'',
					@level0name=N''dbo'', 
					@level1type=N''PROCEDURE'',
					@level1name=N''uspDBMon_Get_SYS_Databases'''
		EXEC (@varSQL_Text)

	END
GO


/*
SELECT [name], Date_Captured, recovery_model_desc, is_auto_create_stats_on, * from [dbo].[tblDBMon_Sys_Databases]
GO
*/

ALTER DATABASE [model] SET RECOVERY SIMPLE
ALTER DATABASE [model] SET AUTO_CREATE_STATISTICS ON
ALTER DATABASE [dba_local] SET RECOVERY SIMPLE
ALTER DATABASE [dba_local] SET AUTO_CREATE_STATISTICS ON
GO


EXEC  [dbo].[uspDBMon_Get_SYS_Databases]
GO

SELECT [name], Date_Captured, recovery_model_desc, is_auto_create_stats_on, * from [dbo].[tblDBMon_Sys_Databases]
GO
