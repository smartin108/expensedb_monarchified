USE [Expenses]
GO

CREATE OR ALTER  procedure [stage].[LoadMonarchProd]
as BEGIN

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

	, BatchID
	, CreatedTimestamp
	, UpdatedTimestamp
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

	, BatchID
	, CreatedTimestamp
	, UpdatedTimestamp

);


declare @RowCount int = @@ROWCOUNT;
declare @Message varchar(512) = REPLACE('% rows were inserted to prod.ExpenseFact', '%', cast(@RowCount as varchar(512)));
exec prod.MessageCapture 
	  @MessageSeverity		= 2
	, @ObjectRef			= 'stage.LoadMonarchProd'
	, @AdditionalMessage	= @Message;

		
END
GO

