USE [Expenses]
GO

/****** Object:  StoredProcedure [stage].[LoadMonarch]    Script Date: 8/31/2024 7:23:42 PM ******/
DROP PROCEDURE [stage].[LoadMonarch]
GO

/****** Object:  StoredProcedure [stage].[LoadMonarch]    Script Date: 8/31/2024 7:23:42 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   procedure [stage].[LoadMonarch]
as begin

begin try
	begin transaction
		exec stage.LoadMonarchUpdateHash;
		exec stage.LoadMonarchNew;
		exec stage.LoadMonarchCaptureDups;
		exec stage.LoadMonarchLockHistory;
		--exec stage.LoadMonarchProd;
	commit

	begin transaction
		truncate table landing.MonarchLoad;
		truncate table stage.MonarchLoad;
	commit
end try
begin catch
	if @@TRANCOUNT > 0
		print 'rolling back because ?'
		rollback
end catch


end
GO

