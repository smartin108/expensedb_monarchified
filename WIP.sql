

select * From landing.MonarchLoad
order by TransactionDate asc


exec stage.LoadMonarchUpdateHash;
select * From landing.MonarchLoad
order by TransactionDate asc


exec stage.LoadMonarchNew;
select * From stage.MonarchLoad
order by TransactionDate asc


exec stage.LoadMonarchCaptureDups;
select * From landing.MonarchDuplicate 
order by TransactionDate asc


exec stage.LoadMonarchProd;
select * from stage.MonarchLoad;


select * From prod.ExpenseFact 
order by TransactionDate asc


select
	D.LastDayOfMonth
	, count(1)
from stage.MonarchLoad E
inner join ReferenceData.Ref.Dates D
	on E.TransactionDate = D.Date
group by D.LastDayOfMonth
order by 1
;
