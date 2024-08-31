USE [Expenses]
GO

/****** Object:  StoredProcedure [stage].[LoadMonarchProd]    Script Date: 8/31/2024 7:25:37 PM ******/
DROP PROCEDURE [stage].[LoadMonarchProd]
GO

/****** Object:  StoredProcedure [stage].[LoadMonarchProd]    Script Date: 8/31/2024 7:25:37 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE   procedure [stage].[LoadMonarchProd]
as begin

/*

idea: 

	*	delete records that are not locked (!)
	*	merge staged data into prod


conditions
	*	stage should have at least one (and really, many more than 1) row that matches a locked record in prod 
		If this isn't the case, then stage should be considered incomplete

	*	stage should have at least one row that matches an unlocked record in prod as well
		If this isn't the case then we should question the integrity of stage and prod

*/


drop table if exists #integrity_check;


select 
	A.RowLocked
	, count(1) as StageRowCount
into #integrity_check
from prod.ExpenseFact A
inner join stage.MonarchLoad B
	on A.DataHash = B.DataHash
group by A.RowLocked
;


declare @UnlockedRowCount int = (select StageRowCount from #integrity_check where RowLocked = 0);
declare @LockedRowCount int = (select isnull(StageRowCount,0) from #integrity_check where RowLocked = 1);
select * from #integrity_check
print @UnlockedRowCount 
print @LockedRowCount 

if @UnlockedRowCount < 100 or @LockedRowCount < 100
begin
	begin try
		throw 979797, 'staged data does not appear to be congruent with production',0;
	end try
	begin catch
		throw
	end catch
end
ELSE
BEGIN


	delete prod.ExpenseFact where RowLocked = 0;


	; with UniqueSource as (
		select 
			A.ID
			, ROW_NUMBER() over (partition by A.DataHash order by A.LoadCreateDate desc) as RN
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
		, LoadCreateDate
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
		, L.LoadCreateDate
	);


END


end
GO

