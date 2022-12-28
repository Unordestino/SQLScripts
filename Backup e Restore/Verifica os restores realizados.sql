--Query para verificar os Restores que já foram realizados


select *  
from msdb.dbo.restorehistory 
order by restore_date desc
