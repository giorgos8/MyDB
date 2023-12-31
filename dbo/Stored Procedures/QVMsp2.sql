﻿

CREATE PROC [dbo].[QVMsp2] 
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

		EXEC [dbo].[QVMspBIsetLog] @RUN_ID, @PARENT_PROC_NAME, @PROC_NAME, @LOG_TYPE = 1

		WAITFOR DELAY '00:00:07';
		--RAISERROR('Error on CUSTOMERS procedure: ', 16, 0)

		
		SET @TRACE = 'Trace Customers #1'

		EXEC [dbo].[QVMspBIsetLog] @RUN_ID, @PARENT_PROC_NAME, @PROC_NAME, 4, @TRACE

		WAITFOR DELAY '00:00:03';

		--RAISERROR('Error AFTER Trace #2', 16, 0)
		
		EXEC [dbo].[QVMspBIsetLog] @RUN_ID, @PARENT_PROC_NAME, @PROC_NAME, 5, @TRACE


		WAITFOR DELAY '00:00:30';
		

		EXEC [dbo].[QVMspBIsetLog] @RUN_ID, @PARENT_PROC_NAME, @PROC_NAME, @LOG_TYPE = 2

	END TRY
	BEGIN CATCH

		EXEC [dbo].[QVMspBIsetLog] @RUN_ID, @PARENT_PROC_NAME, @PROC_NAME, 3
		RETURN -1

	END CATCH
END
