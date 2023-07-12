﻿

CREATE VIEW [dbo].[QVMvwBILogs]
AS

	WITH CTE AS
	(
	SELECT
		*,
		CASE
			WHEN SP_PARENT_NAME = SP_NAME AND SP_TRACE IS NULL THEN 'PARENT'
			WHEN SP_PARENT_NAME <> SP_NAME AND SP_TRACE IS NULL THEN 'CHILD'
			ELSE 'TRACE'
		END AS V_TYPE
		,ROW_NUMBER() OVER (PARTITION BY SP_RUN_ID ORDER BY SP_START) AS V_STEP_NUM
		,DATEDIFF(SS, SP_START, ISNULL(SP_END, GETDATE())) AS V_DURATION_SEC
	FROM [dbo].[QVM_SP_LOGS]
	)
	SELECT
		*,
		V_DURATION_SEC/60.0 AS V_DURATION_MIN_2
	FROM CTE
	WHERE 
	1 = 1
	--AND SP_RUN_ID = 63
	--AND SP_TRACE IS NULL
	--ORDER BY
	--	SP_RUN_ID DESC, 
	--	V_STEP_NUM ASC