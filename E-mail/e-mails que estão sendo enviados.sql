--Query para acompanhar os e-mails que estão sendo enviados

select top 5 sent_status,* from msdb.dbo.sysmail_unsentitems order by send_request_date desc