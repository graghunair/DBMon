SET NOCOUNT ON
GO

USE [Password_Expiration]
GO
DROP TABLE IF EXISTS [dbo].[tblSQL_Login_With_Owners]
GO
CREATE TABLE [dbo].[tblSQL_Login_With_Owners](
	[SQL_Login] [sysname] NOT NULL,
	[Owner_Name] [varchar](50) NULL,
	[Owner_EMail] [varchar](200) NULL,
	[DBA_EMail] [varchar](200) NOT NULL,
	[Date_Captured] [datetime] NOT NULL) 
GO
ALTER TABLE [dbo].[tblSQL_Login_With_Owners] ADD CONSTRAINT PK_tblSQL_Login_With_Owners PRIMARY KEY CLUSTERED ([SQL_Login])
GO
ALTER TABLE [dbo].[tblSQL_Login_With_Owners] ADD CONSTRAINT DF_tblSQL_Login_With_Owners_DBA_EMail DEFAULT 'DBA@abc.com' FOR [DBA_EMail]
GO
ALTER TABLE [dbo].[tblSQL_Login_With_Owners] ADD CONSTRAINT DF_tblSQL_Login_With_Owners_Date_Captured DEFAULT GETDATE() FOR [Date_Captured]
GO
ALTER TABLE [dbo].[tblSQL_Login_With_Owners] ADD CONSTRAINT CK_tblSQL_Login_With_Owners_Owner_EMail CHECK ([Owner_EMail] LIKE '%@abc.com');
GO
ALTER TABLE [dbo].[tblSQL_Login_With_Owners] ADD CONSTRAINT CK_tblSQL_Login_With_Owners_DBA_EMail CHECK ([DBA_EMail] LIKE '%@abc.com');
GO

--INSERT INTO [dbo].[tblSQL_Login_With_Owners](SQL_Login, Owner_Name, Owner_EMail)

--SELECT * FROM [dbo].[tblSQL_Login_With_Owners]

DROP PROC IF EXISTS [dbo].[uspNotify_Password_Expiry]
GO
CREATE PROC [dbo].[uspNotify_Password_Expiry]
@DaysToExpire SMALLINT = 15
AS
/*
		Date Created	:	21st March 2024
		Purpose			:	Track SQL Logins nearing expiry and notify them by email.
		Version			:	1.0

		EXEC [dbo].[uspNotify_Password_Expiry] @DaysToExpire = 15

		Modification History
		--------------------
		21st Mar 2024	:	v1.0	:	Inception
*/
SET NOCOUNT ON

DECLARE @varSQL_Login SYSNAME = NULL
DECLARE @varDays_To_Expire SMALLINT = NULL
DECLARE @varProfile_Name VARCHAR(50) = 'DB MAIL PROFILE'
DECLARE @varServer_Name SYSNAME = CAST(SERVERPROPERTY('servername') AS SYSNAME)
DECLARE @varRecipients VARCHAR(2000) = NULL
DECLARE @varDBA_Recipients VARCHAR(2000) = NULL
DECLARE @varMail_Subject VARCHAR(MAX)
DECLARE @varMail_Body VARCHAR(MAX)

INSERT INTO		[dbo].[tblSQL_Login_With_Owners]([SQL_Login])
SELECT			sl.[name]
FROM			sys.sql_logins sl
LEFT OUTER JOIN [dbo].[tblSQL_Login_With_Owners] slqo
			ON	sl.[name]= slqo.[SQL_Login]
WHERE			sl.is_disabled = 0 
AND				sl.is_expiration_checked = 1
AND				slqo.SQL_Login IS NULL

SELECT		[name] AS [SQL Login]
			, LOGINPROPERTY(sl.[name], 'DaysUntilExpiration') AS [Days Until Expiration]
FROM		sys.sql_logins sl
INNER JOIN	[dbo].[tblSQL_Login_With_Owners] slqo
		ON	sl.[name] = slqo.SQL_Login
WHERE		sl.[is_disabled] = 0 
AND			sl.[is_expiration_checked] = 1
AND			LOGINPROPERTY(sl.[name], 'DaysUntilExpiration') > 0
AND			LOGINPROPERTY(sl.[name], 'DaysUntilExpiration') <= @DaysToExpire

SELECT		@varSQL_Login = MIN([name])
FROM		sys.sql_logins sl
INNER JOIN	[dbo].[tblSQL_Login_With_Owners] slqo
		ON	sl.[name] = slqo.SQL_Login
WHERE		sl.[is_disabled] = 0 
AND			sl.[is_expiration_checked] = 1
AND			LOGINPROPERTY(sl.[name], 'DaysUntilExpiration') > 0
AND			LOGINPROPERTY(sl.[name], 'DaysUntilExpiration') <= @DaysToExpire

WHILE (@varSQL_Login IS NOT NULL)
	BEGIN
			SELECT		@varDays_To_Expire = CAST(LOGINPROPERTY(sl.[name], 'DaysUntilExpiration') AS SMALLINT),
						@varRecipients = [Owner_EMail],
						@varDBA_Recipients = [DBA_EMail]
			FROM		sys.sql_logins sl
			INNER JOIN	[dbo].[tblSQL_Login_With_Owners] slqo
					ON	sl.[name] = slqo.SQL_Login
			WHERE		sl.[is_disabled] = 0 
			AND			sl.[is_expiration_checked] = 1
			AND			LOGINPROPERTY(sl.[name], 'DaysUntilExpiration') > 0
			AND			LOGINPROPERTY(sl.[name], 'DaysUntilExpiration') <= @DaysToExpire
			AND			[name] = @varSQL_Login


			SET @varMail_Subject = 'SQL Account Password Set to Expire for [' + @varSQL_Login + '] in ' + CAST(@varDays_To_Expire AS VARCHAR(5)) + ' days.'
			SET @varMail_Body = 'SQL Account Password Set to Expire for [' + @varSQL_Login + '] in ' + CAST(@varDays_To_Expire AS VARCHAR(5)) + ' days' + ' on Server: ' + @varServer_Name

			--EXEC msdb.dbo.sp_send_dbmail
			--	@profile_name	= @varProfile_Name,
			--	@recipients		= @varRecipients,
			--	@copy_recipients= @varDBA_Recipients,
			--	@body			= @varMail_Body,
			--	@body_format	= 'HTML',
			--	@subject		= @varMail_Subject

			PRINT @varMail_Body

			SELECT		@varSQL_Login = MIN([name])
			FROM		sys.sql_logins sl
			INNER JOIN	[dbo].[tblSQL_Login_With_Owners] slqo
					ON	sl.[name] = slqo.SQL_Login
			WHERE		sl.[is_disabled] = 0 
			AND			sl.[is_expiration_checked] = 1
			AND			LOGINPROPERTY(sl.[name], 'DaysUntilExpiration') > 0
			AND			LOGINPROPERTY(sl.[name], 'DaysUntilExpiration') <= @DaysToExpire
			AND			@varSQL_Login < [name]
	END

GO

EXEC [dbo].[uspNotify_Password_Expiry] @DaysToExpire = 45
GO

