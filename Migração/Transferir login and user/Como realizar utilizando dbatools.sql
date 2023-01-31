1º *Instale os modulos do Dbatools no seu powershell*


Install-Module Dbatools -Scope CurrentUser
Update-Module Dbatools
Import-Module Dbatools
Get-Module Dbatools


Get-Command -Module Dbatools | Measure-Object
Get-Command -name *User* -ModuleName Dbatools

----------------------------------------------------------------------------------------

2º *Execute a função com os parametros para replicar os logins/users*

Example: 1
PS C:\> Export-DbaLogin -SqlInstance sql2005 -Path C:\temp\sql2005-logins.sql
