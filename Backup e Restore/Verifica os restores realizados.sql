--Query para verificar os Restores que j� foram realizados


select *  
from msdb.dbo.restorehistory 
order by restore_date desc
