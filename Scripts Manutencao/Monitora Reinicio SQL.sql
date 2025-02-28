Declare @TableHead varchar(max),@TableTail varchar(max), @Subject varchar(2000), @Body varchar(max)
Declare @Email_TO varchar(2000), @Servidor varchar(2000), @SQLNo varchar(2000)

SELECT @Servidor = @@SERVERNAME
Set @TableTail = '</body></html>';
Set @TableHead = '<html><head>' +
			'<style>' +
			'td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:9pt;} ' +
			'</style>' +
			'</head>' +
			'<body>' + 
			'<P style=font-size:18pt;" ><B>Servidor ' + @Servidor +  ' reiniciou</B></P>'


/**************** Monta HTML Final e envia email ********************/
set @Body = @TableHead
set @Body = @Body + @TableTail
--Select @Body

select @Email_TO = email_address from msdb.dbo.sysoperators where name = 'DBA_Alerta'
set @Subject = 'SYNNEX: SQL REINICIOU !!! ' + @@SERVERNAME + ' do dia ' + CONVERT(varchar(30),getdate(),103)

EXEC msdb.dbo.sp_send_dbmail
@recipients=@Email_TO,
@subject = @Subject,
@body = @Body,
@body_format = 'HTML' ,
@profile_name='SQLProfile'
