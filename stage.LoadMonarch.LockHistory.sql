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


drop table if exists #RetentionHelper;


declare @LoadTimeStamp datetime2 = getdate();
declare @MinimumRetentionAge int = (select MinimumAge from cfg.Monarch_SourceRowRetention where RowActive = 1);
declare @MinimumRetentionRows int = (select MinimumRows from cfg.Monarch_SourceRowRetention where RowActive = 1);
declare @MinimumLockDate datetime2 = eomonth(@LoadTimeStamp, -1 * @MinimumRetentionAge );
declare @LockDate datetime2
declare @IndicatedAge int;
declare @FeasibleAge int;


;with CountsAges as (
	select 
		eomonth(TransactionDate,0) as EOM
		, sum(count(1)) over (order by eomonth(TransactionDate,0)) CumulRowCount  -- cumulative transaction count in stage file
		, ROW_NUMBER() over (order by eomonth(TransactionDate,0) desc) - 1 as Age -- age of transaction
	from stage.MonarchLoad
	group by eomonth(TransactionDate,0)
)
, MaxAgeOfData as (
	select max(Age) as MaxAge
	from CountsAges
	where CumulRowCount >= @MinimumRetentionRows
)
select 
	max(Age) as IndicatedAge
	, min(Age) as FeasibleAge
into #RetentionHelper
from (
	values
		((select MaxAge from MaxAgeOfData))
		, (@MinimumRetentionAge)
	) as x (Age)
;

set @IndicatedAge = (select IndicatedAge from #RetentionHelper) 
set @FeasibleAge = (select FeasibleAge from #RetentionHelper)

IF @FeasibleAge < @IndicatedAge 
BEGIN
	BEGIN TRY
		THROW 979797, 'STAGED DATA IS INSUFFICIENT TO PRESERVE HISTORY WITH CURRENT CONFIGURATION', 20;
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
ELSE
BEGIN
	BEGIN TRANSACTION


		set @LockDate = eomonth(@LoadTimeStamp, -1 * @IndicatedAge);


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
			, CreatedTimestamp
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



	ROLLBACK
	--COMMIT

END


END
GO