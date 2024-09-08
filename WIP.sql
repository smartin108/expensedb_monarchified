/*

		DEFECTS

		*	20204 08 25 sp stage.LoadMonarchProd is supposed to throw error 979797 and abort when loading a blank table for 
				the first time, but it isn't doing either of those things. 




*/


/*	
	
		Piece-wise execution of sp stage.LoadMonarch	─────┐
															 │
															 ▼
*/


-- 	[ First... ]
-- 	[ Run this script and import something : ]
-- 	[ "C:\Users\Z40\Documents\git\expenses\monarch_data_load.py" ]
select * From landing.MonarchLoad
order by TransactionDate asc


exec stage.LoadMonarchUpdateHash;
select * From landing.MonarchLoad
order by TransactionDate asc


exec stage.LoadMonarchStage;
select * From stage.MonarchLoad
order by TransactionDate asc


exec stage.LoadMonarchCaptureDups;
select * From landing.MonarchDuplicate 
order by TransactionDate asc


select * from cfg.Monarch_SourceRowRetention;


exec stage.LoadMonarchLockHistory;
select * from prod.ExpenseFact_Locking;



exec stage.LoadMonarchProd;
select * from stage.MonarchLoad; --???


select * From prod.ExpenseFact 
order by TransactionDate asc



truncate table landing.MonarchLoad;
truncate table stage.MonarchLoad;


/*	
															 ▲
															 │
		Piece-wise execution of sp stage.LoadMonarch	─────┘

*/

select
	D.LastDayOfMonth
	, count(1)
from stage.MonarchLoad E
inner join ReferenceData.Ref.Dates D
	on E.TransactionDate = D.Date
group by D.LastDayOfMonth
order by 1
;



exec stage.LoadMonarch


