USE [Expenses]
GO

/****** Object:  StoredProcedure [stage].[LoadMonarchLockHistory]    Script Date: 8/31/2024 7:24:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER   procedure [stage].[LoadMonarchLockHistory]
as
begin


declare @LoadTimeStamp datetime2 = getdate();
declare @MonthsHistory int = (select RetainSourceOlderThanMonths from cfg.Monarch_SourceRowRetention where RowActive = 1);
declare @LockDate datetime2 = DATEADD("MONTH", -1 * @MonthsHistory, eomonth(@LoadTimeStamp, 0));


; with LockRow as (
	select ID
	from prod.ExpenseFact A
	where A.TransactionDate <= @LockDate
)
merge into prod.ExpenseFact_Locking T
using LockRow L
on T.ExpenseFact_ID = L.ID
when not matched by target
then insert (
	ExpenseFact_ID
	, LoadCreateDate
	, LoadUpdateDate
	)
values (
	L.ID
	, @LoadTimeStamp
	, @LoadTimeStamp
	)
;


; with LockRow as (
	select ID
	from prod.ExpenseFact A
	where A.TransactionDate <= @LockDate
		and A.RowLocked = 0
)
update A
set A.RowLocked = 1
from prod.ExpenseFact as A
inner join LockRow B
	on A.ID = B.ID
;


end
GO

