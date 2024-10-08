USE [Expenses]
GO

/****** Object:  StoredProcedure [stage].[LoadMonarchCaptureDups]    Script Date: 8/31/2024 7:24:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER   procedure [stage].[LoadMonarchCaptureDups]
as begin


truncate table landing.MonarchDuplicate;


-- detected as duplicate in source file
; with UniqueSource as (
	select 
		ID
		, ROW_NUMBER() over (partition by DataHash order by CreatedTimestamp desc) as RN
	from landing.MonarchLoad
)
insert into landing.MonarchDuplicate (
	TransactionDate
	, Merchant
	, Category
	, Account
	, OriginalStatement
	, Notes
	, Amount
	, Tags
	, DataHash
	, FileTimeStamp
	, CreatedTimestamp
	, UpdatedTimestamp
)
select 
	A.TransactionDate 
	, A.Merchant
	, A.Category
	, A.Account
	, A.OriginalStatement
	, A.Notes
	, A.Amount
	, A.Tags
	, A.DataHash
	, A.FileTimeStamp 
	, A.CreatedTimestamp
	, A.UpdatedTimestamp
from landing.MonarchLoad A
left join UniqueSource B
	on A.ID = B.ID
where RN > 1


declare @PotentialDups int = @@ROWCOUNT;


if @PotentialDups > 0
BEGIN
	declare @Message varchar(512) = REPLACE('% potential duplicate transactions were found', '%', cast(@PotentialDups as varchar(16)))
	exec prod.MessageCapture 
		  @MessageSeverity		= 2
		, @ObjectRef			= 'stage.LoadMonarchCaptureDups'
		, @AdditionalMessage	= @Message;
END


end
GO

