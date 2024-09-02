USE [Expenses]
GO

CREATE or ALTER procedure [stage].[LoadMonarch]
as BEGIN


exec stage.LoadMonarchUpdateHash;
BEGIN TRY
	BEGIN TRANSACTION
		exec stage.LoadMonarchStage;
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
	COMMIT TRANSACTION
;


END
GO

