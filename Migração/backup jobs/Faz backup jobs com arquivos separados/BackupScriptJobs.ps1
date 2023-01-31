# Utilizando a fun��o do Dbatools para capturar a lista de todos os Jobs de um servidor espec�fico
$JobList = Get-DbaAgentJob -SqlInstance "DESKTOP-A7S2JPV\SQLSERVER2016" -EnableException
#Caminho onde ser� gerado os scripts
$Pathbase = "C:\temp\BackupJobs\"
$Path = ""
 ForEach ($Job in $JobList)
 {
  #Corrige nome do arquivo em jobs com caracter especial no nome
  $Path = $Pathbase + $Job.Name.Replace("/"," ").Replace("\"," ").Replace(":"," ") + ".sql"

  #Inclui algumas op��es no script, como cabe�alho do Job
  $options = New-DbaScriptingOption
  $options.ScriptSchema = $true
  $options.IncludeDatabaseContext  = $true
  $options.IncludeHeaders = $true
  $options.ScriptBatchTerminator = $true
  $options.AnsiFile = $true

  #Exportar Job por Job para o caminho especificado utilizando Dbatools.
  $Job | Export-DbaScript -Path $Path -ScriptingOptionsObject $options  -EnableException
 } 