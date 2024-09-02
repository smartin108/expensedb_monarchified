USE [Expenses]
GO

create or alter    procedure [stage].[LoadMonarchStage]
as begin


declare @LoadTime datetime2 = getdate();

/*

	Move all data in LANDING to STAGE with necessary transformations and helpful metadata

*/


-- landing -> stage
; with UniqueSource as (
	select 
		ID
		, ROW_NUMBER() over (partition by DataHash order by CreatedTimestamp desc) as RN
	from landing.MonarchLoad
)
insert into stage.MonarchLoad (
	TransactionDate
	, Merchant
	, Category
	, Account
	, OriginalStatement
	, Notes
	, Amount
	, Tags
	, FileTimeStamp

	, BatchID
	, CreatedTimestamp
	, UpdatedTimestamp
)
select 
	cast(A.TransactionDate as date)
	, A.Merchant
	, A.Category
	, A.Account
	, A.OriginalStatement
	, nullif(trim(A.Notes), '')
	, cast(A.Amount as decimal(9,2))
	, nullif(trim(A.Tags), '')
	, cast(A.FileTimeStamp as datetime2)

	, BatchID
	, @LoadTime
	, @LoadTime
from landing.MonarchLoad as A
inner join UniqueSource as B
	on A.ID = B.ID
	and B.RN = 1
;


declare @RowCount int = @@ROWCOUNT;
declare @Message varchar(512) = REPLACE('% rows were inserted to stage.MonarchLoad', '%', cast(@RowCount as varchar(512)));
exec prod.MessageCapture null, 2, @Message


update A
set DataHash = 
		HASHBYTES(
			'SHA2_256'
			, CONCAT_WS(
				'~'
				, TransactionDate
				, Merchant 
				, Category 
				, Account 
				, OriginalStatement
				, Notes 
				, Amount
				, Tags
			)
		)
	, UpdatedTimestamp = @LoadTime
from stage.MonarchLoad as A
where A.DataHash is null
;


end
GO

