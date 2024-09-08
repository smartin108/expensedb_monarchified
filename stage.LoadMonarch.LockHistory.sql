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
--select * from CountsAges order by 1 asc
, MaxAgeOfData as (
	select max(Age) as MaxAge
	from CountsAges
	where CumulRowCount >= @MinimumRetentionRows
)
--select * from MaxAgeOfData
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

--select * from #RetentionHelper


/*

LOL got a bit bogged down in my own logic here

Requirements:

	*	in the cfg table, we specify a /required/ minimum number of months of data we expect to see in the staging data (e.g., 18)
		*	This is a hard requirement; if staging does not contain this, we should fail the job and roll back
	*	in the cfg we also specify some number of transactions we expect to be /at least/ as old as the minimum age (e.g., 500)
		*	This is a flexible requirement, and can be adjusted downward in order to meet the minimum age requirement
		*	IFF the transaction-based parameter yields an Age sufficiently old, we use it
			*	Otherwise, we should fail the load


*/

set @IndicatedAge = (select IndicatedAge from #RetentionHelper) 
set @FeasibleAge = (select FeasibleAge from #RetentionHelper)

IF @FeasibleAge < @MinimumRetentionAge 
BEGIN


	/* Stored retention parameters are potentially insufficient; abort */


	declare @Message1 varchar(512) = 'STAGED DATA IS INSUFFICIENT TO PRESERVE HISTORY WITH CURRENT CONFIGURATION';
	declare @Message2 varchar(512) = REPLACE(REPLACE(@Message1 + '; IndicatedAge = %; FeasibleAge = ^;', '%', @IndicatedAge), '^', @FeasibleAge);

	BEGIN TRY
		THROW 979797, @Message2, 20;
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
ELSE
BEGIN
	BEGIN TRANSACTION


		/*	It's safe to proceed with stored retention parameters 
			Go ahead and lock older rows in prod before proceeding to the load step
		*/


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
			, UpdatedTimestamp
			)
		values (
			L.ID
			, @LoadTimeStamp
			, @LoadTimeStamp
			)

		when matched 
		then update
			set UpdatedTimestamp = @LoadTimeStamp
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


	--ROLLBACK
	COMMIT

END


END
GO