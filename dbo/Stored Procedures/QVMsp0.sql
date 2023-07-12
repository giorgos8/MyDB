


CREATE PROC [dbo].[QVMsp0] AS
BEGIN

		-- vasilis
	DECLARE @PROC_NAME VARCHAR(250) = OBJECT_NAME(@@PROCID)
	DECLARE @PARENT_PROC_NAME VARCHAR(250) = @PROC_NAME

	DECLARE @RET_CHILD_PROC_CODE INT

	DECLARE @RUN_ID INT = (SELECT [dbo].[QVMfnBIgetNextRunID]())
	
	BEGIN TRY	

		--=======================
		--=== START PROCEDURE ===
		--=======================
		EXEC [dbo].[QVMspBIsetLog] @RUN_ID, @PARENT_PROC_NAME, @PROC_NAME, @LOG_TYPE = 1
		
		WAITFOR DELAY '00:00:30';


		--SELECT 1/0;
		
		--***********
		--**** 1 ****
		--***********
		EXEC @RET_CHILD_PROC_CODE = [dbo].[QVMsp1] @RUN_ID, @PROC_NAME;
		IF @RET_CHILD_PROC_CODE <> 0
			RAISERROR('Error on Procedure QVMsp1 .. hello .. from db .. delete from file .. 2', 16, 0)

		
		WAITFOR DELAY '00:00:05';

		--***********
		--**** 2 ****
		--***********
		EXEC @RET_CHILD_PROC_CODE = [dbo].[QVMsp2] @RUN_ID, @PROC_NAME;
		IF @RET_CHILD_PROC_CODE <> 0
			RAISERROR('Error on Procedure QVMsp2', 16, 0)


		WAITFOR DELAY '00:00:05';

		SELECT 1/0;
		--RAISERROR('Error on parent procedure!!!', 16, 0)

		--=====================
		--=== END PROCEDURE ===
		--=====================
		EXEC [dbo].[QVMspBIsetLog] @RUN_ID, @PARENT_PROC_NAME, @PROC_NAME, @LOG_TYPE = 2

	END TRY
	BEGIN CATCH

		EXEC [dbo].[QVMspBIsetLog] @RUN_ID, @PARENT_PROC_NAME, @PROC_NAME, @LOG_TYPE = 3	
		RAISERROR('Error on parent procedure!!!', 16, 0)
		RETURN -1

	END CATCH

END