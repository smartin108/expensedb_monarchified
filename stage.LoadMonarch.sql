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
    DECLARE @ErrorNumber INT = ERROR_NUMBER();
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;

	exec prod.MessageCapture 
				  @MessageSeverity		= 105
				, @ObjectRef			= 'stage.LoadMonarch'
				, @ErrorNumber			= @ErrorNumber
				, @ErrorMessage			= @ErrorMessage
				, @ErrorSeverity		= @ErrorSeverity
				, @ErrorState			= @ErrorState;
	THROW;
END CATCH


IF @@TRANCOUNT > 0 
	COMMIT TRANSACTION
;


END
GO

