

CREATE PROC [dbo].[QVMsp1]
	@RUN_ID INT = NULL,
	@PARENT_PROC_NAME VARCHAR(250) = NULL
AS
BEGIN

	DECLARE @PROC_NAME VARCHAR(250) = OBJECT_NAME(@@PROCID)
	DECLARE @TRACE NVARCHAR(250) = ''

	-- If Proc Run Alone
	IF @RUN_ID IS NULL
	BEGIN
		SET @RUN_ID = (SELECT [dbo].[QVMfnBIgetNextRunID]())
		SET @PARENT_PROC_NAME = @PROC_NAME
	END


	BEGIN TRY

		--=======================
		--=== START PROCEDURE ===
		--=======================

		WAITFOR DELAY '00:00:05';
		EXEC [dbo].[QVMspBIsetLog] @RUN_ID, @PARENT_PROC_NAME, @PROC_NAME, @LOG_TYPE = 1


		WAITFOR DELAY '00:00:05';
		--========================
		--======== TRACE 1 =======
		--========================
		
		SET @TRACE = 'Trace #1'
		EXEC [dbo].[QVMspBIsetLog] @RUN_ID, @PARENT_PROC_NAME, @PROC_NAME, @LOG_TYPE = 4, @TRACE = @TRACE
		WAITFOR DELAY '00:00:05';
		EXEC [dbo].[QVMspBIsetLog] @RUN_ID, @PARENT_PROC_NAME, @PROC_NAME, 5, @TRACE, 'Hello!!!'

		
		--RAISERROR('Error on code row 444: ', 16, 0)
		--select 1/0

		WAITFOR DELAY '00:00:05';
		--========================
		--======== TRACE 2 =======
		--========================

		SET @TRACE = 'Trace #2'		
		EXEC [dbo].[QVMspBIsetLog] @RUN_ID, @PARENT_PROC_NAME, @PROC_NAME, 4, @TRACE
		WAITFOR DELAY '00:00:05';
		EXEC [dbo].[QVMspBIsetLog] @RUN_ID, @PARENT_PROC_NAME, @PROC_NAME, 5, @TRACE

		

		WAITFOR DELAY '00:00:05';
		--=====================
		--=== END PROCEDURE ===
		--=====================		
		EXEC [dbo].[QVMspBIsetLog] @RUN_ID, @PARENT_PROC_NAME, @PROC_NAME, @LOG_TYPE = 2

	END TRY
	BEGIN CATCH

		EXEC [dbo].[QVMspBIsetLog] @RUN_ID, @PARENT_PROC_NAME, @PROC_NAME, @LOG_TYPE = 3
		--RAISERROR('Error on Catch: ', 16, 0)
		RETURN -1

	END CATCH
END
