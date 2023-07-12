


-- =============================================
-- Author:
-- Create date: G.K. April 2023 => Get the Next Log Id for the Logs Table
-- Alter date:
-- Description:
-- =============================================

CREATE FUNCTION [dbo].[QVMfnBIgetNextRunID]
(
	
)
RETURNS INT AS  
BEGIN 
	DECLARE @RET_RUN_ID int

	SELECT @RET_RUN_ID = (SELECT ISNULL(MAX([SP_RUN_ID]), 0) + 1 FROM [dbo].[QVM_SP_LOGS])

	RETURN @RET_RUN_ID
END
