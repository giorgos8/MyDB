﻿CREATE TABLE [dbo].[tbl_AUDIT_OBJECTS] (
    [AA]           BIGINT        IDENTITY (1, 1) NOT NULL,
    [WHEN]         DATETIME      CONSTRAINT [DF_AUDIT_OBJECTS__WHEN] DEFAULT (getdate()) NOT NULL,
    [USER]         VARCHAR (100) CONSTRAINT [DF_AUDIT_OBJECTS__USER] DEFAULT (suser_sname()) NOT NULL,
    [HOST]         VARCHAR (100) CONSTRAINT [DF_AUDIT_OBJECTS__HOST] DEFAULT (host_name()) NOT NULL,
    [DATABASE]     VARCHAR (100) NULL,
    [SCHEMA]       VARCHAR (30)  NULL,
    [OBJECT_NAME]  VARCHAR (100) NULL,
    [EVENT_TYPE]   VARCHAR (100) NULL,
    [XML_DDL_CODE] XML           NULL
);

