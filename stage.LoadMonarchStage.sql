USE [Expenses]
GO

/****** Object:  StoredProcedure [stage].[LoadMonarchStage]    Script Date: 8/31/2024 7:25:52 PM ******/
DROP PROCEDURE [stage].[LoadMonarchStage]
GO

/****** Object:  StoredProcedure [stage].[LoadMonarchStage]    Script Date: 8/31/2024 7:25:52 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create     procedure [stage].[LoadMonarchStage]
as begin

/*

	Move all data in LANDING to STAGE with necessary transformations and helpful metadata

*/


-- landing -> stage
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


update MonarchLoad_A
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
from stage.MonarchLoad as MonarchLoad_A
where MonarchLoad_A.DataHash is null
;


end
GO

