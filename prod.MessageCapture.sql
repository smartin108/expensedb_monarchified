create or alter procedure prod.MessageCapture 
	  @MessageSeverity		int				= null
	, @MessageTimestamp		datetime2		= null
	, @BatchID				int				= null
	, @ObjectRef			varchar(256)	= null
	, @ErrorNumber			int				= null
	, @ErrorMessage			nvarchar(4000)	= null
	, @ErrorSeverity		int				= null
	, @ErrorState			int				= null
	, @AdditionalMessage	varchar(512)	= null


as
BEGIN

		BEGIN TRANSACTION;


			set @MessageTimestamp = isnull(@MessageTimestamp, getdate());


			insert into prod.MonarchLoadMessages(
				  MessageSeverity
				, MessageTimestamp
				, BatchID
				, ObjectRef
				, ErrorNumber
				, ErrorMessage
				, ErrorSeverity
				, ErrorState
				, AdditionalMessage
				)
			values (
				  @MessageSeverity		
				, @MessageTimestamp		
				, @BatchID				
				, @ObjectRef			
				, @ErrorNumber			
				, @ErrorMessage			
				, @ErrorSeverity		
				, @ErrorState			
				, @AdditionalMessage	
				)
			;


		COMMIT;
	

END;


