--Script para conferir se o um login especifico tem alguma conex�o aberta

select loginame, 'kill ' + cast(spid as char(2)),* 
from sysprocesses 
where loginame = 'Davi'