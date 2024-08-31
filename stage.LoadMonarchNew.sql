USE [Expenses]
GO

/****** Object:  StoredProcedure [stage].[LoadMonarchNew]    Script Date: 8/31/2024 7:25:19 PM ******/
DROP PROCEDURE [stage].[LoadMonarchNew]
GO

/****** Object:  StoredProcedure [stage].[LoadMonarchNew]    Script Date: 8/31/2024 7:25:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   procedure [stage].[LoadMonarchNew]
as begin


-- Monarch transactions : landing -> stage
; with UniqueSource as (
	select 
		ID
		, ROW_NUMBER() over (partition by DataHash order by LoadCreateDate desc) as RN
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
	, LoadCreateDate
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
	, A.LoadCreateDate
from landing.MonarchLoad as A
inner join UniqueSource as B
	on A.ID = B.ID
	and B.RN = 1
;


update stage.MonarchLoad
set DataHash = HASHBYTES('SHA2_256', CONCAT_WS('~', 
		TransactionDate
		, Merchant 
		, Category 
		, Account 
		, OriginalStatement
		, Notes 
		, Amount
		, Tags
		)
	)
;


end
GO

