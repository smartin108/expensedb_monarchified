select * From landing.MonarchLoad
order by TransactionDate asc


select * From stage.MonarchLoad
order by TransactionDate asc


select * From landing.MonarchDuplicate 
order by TransactionDate asc


select * from prod.ExpenseFact_Locking;


select * From prod.ExpenseFact 
order by TransactionDate asc


select * from prod.MonarchLoadMessages


--exec stage.LoadMonarch;