CREATE TABLE [dbo].[T] (
    [i]        INT      IDENTITY (1, 1) NOT NULL,
    [dt]       DATETIME NOT NULL,
    [dt_year]  INT      NOT NULL,
    [dt_month] INT      NOT NULL,
    [dt_day]   INT      NOT NULL,
    PRIMARY KEY CLUSTERED ([i] ASC)
);

