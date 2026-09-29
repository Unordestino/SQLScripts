--Script para conferir se o um login especifico tem alguma conexão aberta

select loginame, 'kill ' + cast(spid as char(2)),* 
from sysprocesses 
where loginame = 'Davi'