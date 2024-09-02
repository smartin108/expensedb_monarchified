
drop table if exists #RetentionHelper;

declare @LoadTimeStamp datetime2 = getdate();
declare @MinimumRetentionAge int = (select MinimumAge from cfg.Monarch_SourceRowRetention where RowActive = 1);
declare @MinimumRetentionRows int = (select MinimumRows from cfg.Monarch_SourceRowRetention where RowActive = 1);
declare @MinimumLockDate datetime2 = eomonth(@LoadTimeStamp, -1 * @MinimumRetentionAge );
declare @IndicatedAge int;
declare @FeasibleAge int;
print @MinimumLockDate


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
		THROW 979797, 'STAGED DATA IS INSUFFICIENT TO PRESERVE HISTORY WITH CURRENT CONFIGURATION',0;
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
ELSE
BEGIN
	-- It's Safe to use indicated age

END;