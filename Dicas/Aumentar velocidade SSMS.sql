Apenas algumas dicas que podem resolver isso:

Primeiro:

Vá para Painel de Controle -> Opções da Internet
Uma vez lá, vá para a guia "Avançado" e próximo ao final desmarque a opção "Verificar revogação de certificado do servidor" (tem um * porque você precisa reiniciar o computador)
Inicie o SSMS após a reinicialização.

Segundo:

Edite o arquivo hosts (lembre-se de usar o editor de texto de sua escolha como administrador) localizado aqui %systemroot%\system32\drivers\etc\hosts
Adicione esta linha ao final: 127.0.0.1 crl.microsoft.com
Salve e inicie o SSMS.

Terceiro:


Abra o SSMS (depois de tanto tempo)
Vá em Ferramentas -> Opções e em "Ambiente" selecione "Abrir ambiente vazio" na inicialização.
Ok e reinicie o SSMS.
Durar:

--**********/* RECOMENDADO */--**********

Edite o atalho que você usa para abrir o SSMS
Adicione no final o parâmetro /nosplash (será mais ou menos assim: "C:\Program Files\Microsoft SQL Server\XXX\Tools\Binn\VSShell\Common7\IDE\Ssms.exe" /nosplash)
Inicie o SSMS.