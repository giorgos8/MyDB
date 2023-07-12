

-- =============================================
-- Author:
-- Create date: LOGS for QVM => G.K. April 2023
-- Alter date:
-- Description:
-- =============================================

CREATE PROC [dbo].[QVMspBIsetLog]
	@RUN_ID INT,
	@PARENT_PROC_NAME VARCHAR(250),
	@PROC_NAME VARCHAR(250),
	@LOG_TYPE SMALLINT,
	@TRACE VARCHAR(1000) = NULL,
	@INFO VARCHAR(500) = NULL
AS
BEGIN

	/*
		@LOG_TYPE:
			1: INSERT - RUNNING
			2: UPDATE - SUCCESS
			3: UPDATE - ERROR (... and TRACE error)

			4: INSERT TRACE - RUNNING
			5: UPDATE TRACE - SUCCESS
	*/

	IF @LOG_TYPE NOT IN (1, 2, 3, 4, 5)
		RETURN;


	-- INSERT LOG
	IF @LOG_TYPE = 1
	BEGIN
		INSERT INTO [dbo].[QVM_SP_LOGS]
			(
				[SP_RUN_ID],
				[SP_PARENT_NAME],
				[SP_NAME],
				[SP_RESULT],
				[SP_START],
				[SP_END]
			)
			VALUES
			(
				@RUN_ID,
				@PARENT_PROC_NAME,
				@PROC_NAME,
				'RUNNING',
				GETDATE(),
				NULL
			)
	END

	-- SUCCESS LOG
	IF @LOG_TYPE = 2
	BEGIN
		UPDATE [dbo].[QVM_SP_LOGS]
		SET 
			[SP_END] = GETDATE(), 
			[SP_RESULT] = 'SUCCESS'
		WHERE 
			[SP_RUN_ID] = @RUN_ID
			AND [SP_NAME] = @PROC_NAME
			AND [SP_TRACE] IS NULL
			AND SP_END IS NULL
	END

	-- ERROR LOG
	IF @LOG_TYPE = 3
	BEGIN

		DECLARE @ERROR_MSG VARCHAR(2000) = SUBSTRING('Number: ' + ISNULL(CAST(ERROR_NUMBER() AS VARCHAR(10)), '') + ', Line: ' + ISNULL(CAST(ERROR_LINE() AS VARCHAR(10)), '') + ', Msg:' + ERROR_MESSAGE(), 0, 1999)

		UPDATE [dbo].[QVM_SP_LOGS]
		SET 
			[SP_END] = GETDATE(), 
			[SP_RESULT] = 'ERROR',
			[SP_MSG] = @ERROR_MSG
		WHERE [SP_RUN_ID] = @RUN_ID
			AND [SP_NAME] = @PROC_NAME
			AND [SP_TRACE] IS NULL
			AND SP_END IS NULL

		-- Trace Error Update
		UPDATE [dbo].[QVM_SP_LOGS]
		SET
			[SP_END] = GETDATE(),
			[SP_RESULT] = 'ERROR',
			[SP_MSG] = @ERROR_MSG
		WHERE [SP_RUN_ID] = @RUN_ID
			AND [SP_NAME] = @PROC_NAME
			AND [SP_RESULT] = 'RUNNING'
			AND SP_END IS NULL

		/*
			SELECT  
				ERROR_NUMBER() AS ErrorNumber
				,ERROR_SEVERITY() AS ErrorSeverity  
				,ERROR_STATE() AS ErrorState  
				,ERROR_PROCEDURE() AS ErrorProcedure  
				,ERROR_LINE() AS ErrorLine  
				,ERROR_MESSAGE() AS ErrorMessage;
		*/
		
	END

	-- TRACE INSERT
	IF @LOG_TYPE = 4
	BEGIN
		
		INSERT INTO [dbo].[QVM_SP_LOGS]
			(
				[SP_RUN_ID],
				[SP_PARENT_NAME],
				[SP_NAME],
				[SP_TRACE],
				[SP_RESULT],
				[SP_START],
				[SP_END]
			)
			VALUES
			(
				@RUN_ID,
				@PARENT_PROC_NAME,
				@PROC_NAME,
				@TRACE,
				'RUNNING',
				GETDATE(),
				NULL
			)

	END

	-- TRACE SUCCESS
	IF @LOG_TYPE = 5
	BEGIN
		UPDATE [dbo].[QVM_SP_LOGS]
		SET 
			[SP_END] = GETDATE(), 
			[SP_TRACE] = @TRACE, 
			[SP_RESULT] = 'SUCCESS',
			[SP_INFO] = @INFO
		WHERE 
			[SP_RUN_ID] = @RUN_ID
			AND [SP_NAME] = @PROC_NAME
			AND SP_TRACE = @TRACE
			AND SP_END IS NULL
	END
END
