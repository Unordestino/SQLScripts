--Query para acompanhar os e-mails que est�o sendo enviados

select top 5 sent_status,* from msdb.dbo.sysmail_unsentitems order by send_request_date desc