
--select * from stage.MonarchLoad

declare @LoadTimeStamp datetime2 = getdate();
declare @MinimumAge int = (select RetainSourceOlderThanMonths from cfg.Monarch_SourceRowRetention where RowActive = 1);
declare @MinimumLockDate datetime2 = eomonth(@LoadTimeStamp, -1 * @MinimumAge);
print @MinimumLockDate


--select 
--	sum(case when eomonth(TransactionDate,0) < @LockDate then 1 else 0 end) as LT
--	, sum(case when eomonth(TransactionDate,0) = @LockDate then 1 else 0 end) as EQ
--	, sum(case when eomonth(TransactionDate,0) > @LockDate then 1 else 0 end) as GT
--from stage.MonarchLoad
--;


;with CountsAges as (
	select 
		eomonth(TransactionDate,0) as EOM
		, sum(count(1)) over (order by eomonth(TransactionDate,0)) CumulRowCount  -- cumulative transaction count in stage file
		, ROW_NUMBER() over (order by eomonth(TransactionDate,0) desc) - 1 as Age -- age of transaction
	from stage.MonarchLoad
	group by eomonth(TransactionDate,0)
)
, MaxAge as (
	select max(Age) as Age
	from CountsAges
	where CumulRowCount >= 500
)

select max(Age) as IndicatedAge
from (
	values
		((select Age from MaxAge))
		, (@MinimumAge)
	) as x (Age)
;