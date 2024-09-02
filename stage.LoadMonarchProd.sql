USE [Expenses]
GO

CREATE OR ALTER  procedure [stage].[LoadMonarchProd]
as BEGIN

/*

*/


drop table if exists #integrity_check;


select 
	isnull(A.RowLocked, 0) as RowLocked
	, count(1) as StageRowCount
into #integrity_check
from stage.MonarchLoad B
inner join prod.ExpenseFact A
	on A.DataHash = B.DataHash
group by isnull(A.RowLocked, 0)
;


declare @UnlockedRowCount int = isnull((select StageRowCount from #integrity_check where RowLocked = 0),0);
declare @LockedRowCount int = isnull((select StageRowCount from #integrity_check where RowLocked = 1),0);
declare @ProdIsInitialized int = isnull((select count(1) from prod.ExpenseFact),0);

select * from #integrity_check
print '@UnlockedRowCount  ' + cast(@UnlockedRowCount as varchar(50))
print '@LockedRowCount    ' + cast(@LockedRowCount as varchar(50))
print '@ProdIsInitialized ' + cast(@ProdIsInitialized as varchar(50))

if (@UnlockedRowCount < 100 or @LockedRowCount < 100) and (@ProdIsInitialized > 0)
BEGIN
	begin try
		throw 979797, 'staged data does not appear to be congruent with production',0;
	end try
	begin catch
		throw
	end catch
END
ELSE
BEGIN


	delete prod.ExpenseFact where RowLocked = 0;


	; with UniqueSource as (
		select 
			A.ID
			, ROW_NUMBER() over (partition by A.DataHash order by A.CreatedTimestamp desc) as RN
		from stage.MonarchLoad as A
	),
	ProdLoad as (
		select A.*
		from stage.MonarchLoad as A
		inner join UniqueSource as B
			on A.ID = B.ID
		where B.RN = 1
	)
	merge into prod.ExpenseFact as A
	using ProdLoad as L
	on A.DataHash = L.DataHash
	when not matched by target
	then insert (
		TransactionDate
		, Merchant
		, Category
		, Account
		, OriginalStatement
		, Notes
		, Amount
		, Tags
		, RecordSource
		, DataHash
		, FileTimeStamp
		, CreatedTimestamp
	)
	values ( 
		L.TransactionDate
		, L.Merchant
		, L.Category
		, L.Account
		, L.OriginalStatement
		, L.Notes
		, L.Amount
		, L.Tags
		, 'Monarch'
		, L.DataHash
		, L.FileTimeStamp
		, L.CreatedTimestamp
	);


END


END
GO

