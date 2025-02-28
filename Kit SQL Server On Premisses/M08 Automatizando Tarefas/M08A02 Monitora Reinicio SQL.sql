/************************************************************
 Autor: Landry Duailibe

 Hands On: Alerta Boot Servidor SQL Server
*************************************************************/
use master
go

DECLARE @Empresa varchar(200) = 'SQL Server Expert'
DECLARE @ProfileSMTP varchar(200) = 'Profile_SMTP'
DECLARE @Operador varchar(200) = 'DBA'

DECLARE @TableHead varchar(max),@TableTail varchar(max), @Subject varchar(2000), @Body varchar(max)
DECLARE @Email_TO varchar(2000), @Servidor varchar(2000), @SQLNo varchar(2000)

SELECT @Servidor = @@SERVERNAME
Set @TableTail = '</body></html>';
Set @TableHead = '<html><head>' +
			'<style>' +
			'td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:9pt;} ' +
			'</style>' +
			'</head>' +
			'<body>' + 
			'<P style=font-size:18pt;" ><B>Servidor ' + @Servidor +  ' Reiniciou</B></P>'


/**************** Monta HTML Final e envia email ********************/
set @Body = @TableHead
set @Body = @Body + @TableTail
--Select @Body

select @Email_TO = email_address from msdb.dbo.sysoperators where name = @Operador
set @Subject = @Empresa + ': ' + @@SERVERNAME + ' - SQL Server REINICIOU no dia ' + CONVERT(varchar(30),getdate(),103)

EXEC msdb.dbo.sp_send_dbmail
@recipients=@Email_TO,
@subject = @Subject,
@body = @Body,
@body_format = 'HTML' ,
@profile_name= @ProfileSMTP
go




