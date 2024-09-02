create or alter procedure prod.MessageCapture 
	@BatchID int
	, @MessageSeverity int
	, @MessageText varchar(512)


as
BEGIN

BEGIN TRANSACTION
	insert into prod.MonarchLoadMessages(MessageTimestamp, BatchID, MessageSeverity, LoadMessage)
	values (
		getdate()
		, @BatchID
		, @MessageSeverity
		, @MessageText
		)
	;
COMMIT;
	

END;