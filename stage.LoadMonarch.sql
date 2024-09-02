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
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
	THROW;
END CATCH


IF @@TRANCOUNT > 0 
	COMMIT TRANSACTION;

END
GO

