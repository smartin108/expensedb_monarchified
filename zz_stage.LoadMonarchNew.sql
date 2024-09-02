USE [Expenses]
GO

CREATE or alter   procedure [stage].[LoadMonarchNew]
as begin


declare @LoadTime datetime2 = getdate();


-- Monarch transactions : landing -> stage
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


update stage.MonarchLoad
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
		),
	UpdatedTimestamp = @LoadTime
;


end
GO

