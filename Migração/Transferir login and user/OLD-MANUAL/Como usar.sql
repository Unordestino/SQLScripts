Primeiro execute o arquivo "transferir logins"

Ao executar o script execute o comando abaixo para gerar os logins

EXEC dbo.stpExporta_Logins
    @Ds_Diretorio_Saida = 'C:\Teste\', -- varchar(500)
    @Fl_Permissoes_Database = 1, -- bit
    @Fl_Arquivo_Unico = 0 -- bit

-------------------------------------------------------------------------------------

Agora execute o script "Copiando permissões de um LoginUser no SQL Server"


em seguida execute o comando abaixo

    exec sp_CloneLogin 'Teste'
