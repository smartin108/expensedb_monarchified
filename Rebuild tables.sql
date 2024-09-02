USE Expenses
GO


-- disable constraints
EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"
GO


drop table if exists cfg.Monarch_SourceRowRetention;
drop table if exists prod.ExpenseFact_Locking;
drop table if exists prod.ExpenseFact;
drop table if exists stage.MonarchLoad;
drop table if exists landing.MonarchDuplicate;
drop table if exists landing.MonarchLoad;
drop table if exists xref.MessageSeverity;
drop table if exists prod.MonarchLoadMessages;
GO


--		Reference data structures						─────┐
--															 │
--															 ▼

create table xref.MessageSeverity(
	ID int identity not null primary key
	, MessageSeverityID int not null
	, MessageSeverityText varchar(32) not null
);


create unique index ix_MessageSeverityID 
on xref.MessageSeverity (MessageSeverityID)
;


insert into xref.MessageSeverity(MessageSeverityID, MessageSeverityText)
values
		(0,		'DEBUG')
	,	(1,		'MESSAGE')
	,	(2,		'INFORMATION')
	,	(3,		'WARNING')
	,	(104,	'CRITICAL')
	,	(105,	'FATAL')
;


create table prod.MonarchLoadMessages (
	ID int identity NOT NULL primary key
	, MessageSeverity int NOT NULL foreign key (MessageSeverity) references xref.MessageSeverity(MessageSeverityID)
	, MessageTimestamp datetime2 NOT NULL
	, BatchID int NULL
	, ObjectRef varchar(256) NULL
	, ErrorNumber int null
	, ErrorMessage nvarchar(4000) NULL
	, ErrorSeverity int null
	, ErrorState int null
	, AdditionalMessage varchar(512) NULL
);


create table cfg.Monarch_SourceRowRetention (
	ID int identity not null primary key
	, RowActive bit not null 
	, MinimumAge int
	, MinimumRows int
);
insert into cfg.Monarch_SourceRowRetention (RowActive, MinimumAge, MinimumRows)
values (1, 18, 1500)
;

--															 ▲
--															 │
--		Reference data structures						─────┘


--		Mart tables										─────┐
--															 │
--															 ▼

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
	, RecordSource varchar(255)
	, DataHash varbinary(32)
	, FileTimeStamp varchar(255)
	, RowLocked bit not null default 0

	, BatchID int null
	, CreatedTimestamp datetime2 not null
	, UpdatedTimestamp datetime2 not null
);


create table prod.ExpenseFact_Locking (
	ID int identity not null primary key
	, ExpenseFact_ID int not null

	, BatchID int null
	, CreatedTimestamp datetime2 not null
	, UpdatedTimestamp datetime2 not null

	, foreign key (ExpenseFact_ID) references prod.ExpenseFact(ID)
);


CREATE TABLE stage.MonarchLoad(
	ID int IDENTITY(1,1) NOT NULL primary key
	, TransactionDate date NULL
	, Merchant varchar(255) NULL
	, Category varchar(255) NULL
	, Account varchar(255) NULL
	, OriginalStatement varchar(255) NULL
	, Notes varchar(255) NULL
	, Amount decimal(9, 2) NULL
	, Tags varchar(255) NULL
	, DataHash varbinary(32) NULL
	, FileTimeStamp varchar(255) NULL

	, BatchID int null
	, CreatedTimestamp datetime2 not null
	, UpdatedTimestamp datetime2 not null
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

	, BatchID int null
	, CreatedTimestamp datetime2 not null
	, UpdatedTimestamp datetime2 not null
);


CREATE TABLE landing.MonarchLoad(
	ID int IDENTITY(1,1) NOT NULL primary key
	, TransactionDate varchar(255) NULL
	, Merchant varchar(255) NULL
	, Category varchar(255) NULL
	, Account varchar(255) NULL
	, OriginalStatement varchar(255) NULL
	, Notes varchar(255) NULL
	, Amount varchar(255) NULL
	, Tags varchar(255) NULL
	, DataHash varbinary(32) NULL
	, FileTimeStamp varchar(255) NULL

	, BatchID int null
	, CreatedTimestamp datetime2 not null default getdate()
	, UpdatedTimestamp datetime2 not null default getdate()
);

--															 ▲
--															 │
--		Mart tables										─────┘


-- reenable constraints
exec sp_MSforeachtable @command1="print '?'", @command2="ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"
