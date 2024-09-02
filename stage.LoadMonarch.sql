USE [Expenses]
GO

CREATE or ALTER procedure [stage].[LoadMonarch]
as BEGIN

exec stage.LoadMonarchUpdateHash;
exec stage.LoadMonarchNew;
BEGIN TRY
	BEGIN TRANSACTION
		exec stage.LoadMonarchCaptureDups;
		exec stage.LoadMonarchLockHistory;
		exec stage.LoadMonarchProd;
		truncate table landing.MonarchLoad;
		truncate table stage.MonarchLoad;
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH

END
GO

