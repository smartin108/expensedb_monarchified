USE Expenses
GO


drop table if exists cfg.Monarch_SourceRowRetention
drop table if exists prod.ExpenseFact_Locking
drop table if exists prod.ExpenseFact
drop table if exists [stage].[MonarchLoad]
drop table if exists landing.MonarchDuplicate
drop table if exists landing.[MonarchLoad]


EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"
GO


create table cfg.Monarch_SourceRowRetention (
	ID int identity not null primary key
	, RowActive bit not null 
	, RetainSourceOlderThanMonths int
);


create table prod.ExpenseFact (
	ID int identity not null primary key
	, TransactionDate date
	, Merchant varchar(255)
	, Category varchar(255)
	, Account varchar(255)
	, OriginalStatement varchar(255)
	, Notes varchar(255)
	, Amount decimal(9,2)
	, Tags varchar(255)
	, DataHash varbinary(32)
	, FileTimeStamp varchar(255)
	, LoadCreateDate datetime2 not null default getdate()
	, LoadUpdateDate datetime2 not null default getdate()
	, RowLocked bit not null default 0
);


create table prod.ExpenseFact_Locking (
	ID int identity not null primary key
	, ExpenseFact_ID int not null
	, LoadCreateDate datetime2 not null
	, LoadUpdateDate datetime2 not null

	, foreign key (ExpenseFact_ID) references prod.ExpenseFact(ID)
);


CREATE TABLE [stage].[MonarchLoad](
	[ID] [int] IDENTITY(1,1) NOT NULL primary key,
	[TransactionDate] [date] NULL,
	[Merchant] [varchar](255) NULL,
	[Category] [varchar](255) NULL,
	[Account] [varchar](255) NULL,
	[OriginalStatement] [varchar](255) NULL,
	[Notes] [varchar](255) NULL,
	[Amount] [decimal](9, 2) NULL,
	[Tags] [varchar](255) NULL,
	[DataHash] [varbinary](32) NULL,
	[FileTimeStamp] [varchar](255) NULL,
	[LoadCreateDate] [datetime2](7) NOT NULL,
);


create table landing.MonarchDuplicate (
	ID int identity not null primary key
	, TransactionDate varchar(255)
	, Merchant varchar(255)
	, Category varchar(255)
	, Account varchar(255)
	, OriginalStatement varchar(255)
	, Notes varchar(255)
	, Amount varchar(255)
	, Tags varchar(255)
	, DataHash varbinary(32)
	, FileTimeStamp varchar(255)
	, LoadCreateDate datetime2 not null default getdate()
);


CREATE TABLE landing.[MonarchLoad](
	[ID] [int] IDENTITY(1,1) NOT NULL primary key,
	[TransactionDate] [varchar](255) NULL,
	[Merchant] [varchar](255) NULL,
	[Category] [varchar](255) NULL,
	[Account] [varchar](255) NULL,
	[OriginalStatement] [varchar](255) NULL,
	[Notes] [varchar](255) NULL,
	[Amount] [varchar](255) NULL,
	[Tags] [varchar](255) NULL,
	[DataHash] [varbinary](32) NULL,
	[FileTimeStamp] [varchar](255) NULL,
	[LoadCreateDate] [datetime2](7) NOT NULL default getdate()
);

exec sp_MSforeachtable @command1="print '?'", @command2="ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"
