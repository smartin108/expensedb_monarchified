USE [Expenses]
GO

/****** Object:  StoredProcedure [stage].[LoadMonarchUpdateHash]    Script Date: 8/31/2024 7:26:10 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER   procedure [stage].[LoadMonarchUpdateHash]
as begin


declare @LoadTime datetime2 = getdate();


update landing.MonarchLoad
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

