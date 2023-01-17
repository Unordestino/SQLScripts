-- Fortamar querys: http://poorsql.com/

-- TOP AS MELHORES

--	01)	CTRL + N � Cria uma nova janela de query

--	02)	CTRL + O � Exibe a caixa de di�logo�Abrir Arquivo�para abrir um arquivo existente

--	03)	CTRL + F4 � Fecha a janela da query atual

--	04)	CTRL + TAB � Alterna entre as janelas das consultas e pain�is

--	05)	CTRL + H � Exibe a janela de Substitui��o

--	09)	F1 � Abre o Menu de Ajuda. Utilizar em cima de alguma fun��o ou c�digo sql.

--	07)	F7 � Exibe a janela Object Explorer Details com os detalhes dos objetos do Banco de Dados 

--	08) Selecionar Colunas:	Clicar na posi��o inicial + pressionar as teclas SHIFT e ALT + clicar na posi��o final

-- 09) Incrementa uma identa��o no c�digo selecionado: Selecionar C�digo + TAB

-- 10) Decrementa uma identa��o no c�digo selecionado: Selecionar C�digo + SHIFT + TAB

--	11)	CTRL + SHIFT + L � Transforma todas as letras do texto selecionado em Min�sculo (LOWER)

--	12)	CTRL + SHIFT + U � Transforma todas as letras do texto selecionado em Mai�sculo (UPPER) 

-------------------------------------------------------
-- Dicas
-------------------------------------------------------

--	13)	Exibir a numera��o das linhas
--	Basta habilitar / desabilitar a op��o no menu �Tools -> Options -> Text Editor -> All Languages -> Line numbers�.

--	14)	CTRL + G � Vai para a linha informada

--	15)	CTRL + K, CTRL + C � Comenta as linhas selecionadas

--  16) Selecione o nome da tabela e pressione as teclas ALT + F1. Ela retorna v�rias informa��es sobre a tabela de forma simples e r�pida, 

--	17)	Exibir informa��es de Consumo de uma Query 

--	18)	Atualizar o cache local	CTRL+SHIFT+R
----------------------------------------------------------------------------------------------------------------------------
-- OBS: Muito �til na realiza��o de Tuning!!!

SET STATISTICS IO ON		-- Leitura
SET STATISTICS IO OFF		-- Leitura

SET STATISTICS TIME ON		-- CPU
SET STATISTICS TIME OFF		-- CPU

SET STATISTICS IO, TIME ON	-- Leitura e CPU
SET STATISTICS IO, TIME OFF	-- Leitura e CPU

