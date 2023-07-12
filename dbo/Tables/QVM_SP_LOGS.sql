CREATE TABLE [dbo].[QVM_SP_LOGS] (
    [SP_RUN_ID]      INT            NOT NULL,
    [SP_PARENT_NAME] VARCHAR (250)  NULL,
    [SP_NAME]        VARCHAR (250)  NULL,
    [SP_TRACE]       VARCHAR (1000) NULL,
    [SP_RESULT]      VARCHAR (1000) NULL,
    [SP_START]       DATETIME       NULL,
    [SP_END]         DATETIME       NULL,
    [SP_MSG]         VARCHAR (2000) NULL,
    [SP_INFO]        VARCHAR (500)  NULL,
    [SP_USER]        VARCHAR (200)  CONSTRAINT [DF_QVM_SP_LOGS__USER] DEFAULT (suser_sname()) NULL,
    [SP_HOST]        VARCHAR (100)  CONSTRAINT [DF_QVM_SP_LOGS__HOST] DEFAULT (host_name()) NULL
);

