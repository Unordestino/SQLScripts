-- Fortamar querys: http://poorsql.com/

-- TOP AS MELHORES

--	01)	CTRL + N – Cria uma nova janela de query

--	02)	CTRL + O – Exibe a caixa de diálogo Abrir Arquivo para abrir um arquivo existente

--	03)	CTRL + F4 – Fecha a janela da query atual

--	04)	CTRL + TAB – Alterna entre as janelas das consultas e painéis

--	05)	CTRL + H – Exibe a janela de Substituição

--	09)	F1 – Abre o Menu de Ajuda. Utilizar em cima de alguma função ou código sql.

--	07)	F7 – Exibe a janela Object Explorer Details com os detalhes dos objetos do Banco de Dados 

--	08) Selecionar Colunas:	Clicar na posição inicial + pressionar as teclas SHIFT e ALT + clicar na posição final

-- 09) Incrementa uma identação no código selecionado: Selecionar Código + TAB

-- 10) Decrementa uma identação no código selecionado: Selecionar Código + SHIFT + TAB

--	11)	CTRL + SHIFT + L – Transforma todas as letras do texto selecionado em Minúsculo (LOWER)

--	12)	CTRL + SHIFT + U – Transforma todas as letras do texto selecionado em Maiúsculo (UPPER) 

-------------------------------------------------------
-- Dicas
-------------------------------------------------------

--	13)	Exibir a numeração das linhas
--	Basta habilitar / desabilitar a opção no menu ”Tools -> Options -> Text Editor -> All Languages -> Line numbers”.

--	14)	CTRL + G – Vai para a linha informada

--	15)	CTRL + K, CTRL + C – Comenta as linhas selecionadas

--  16) Selecione o nome da tabela e pressione as teclas ALT + F1. Ela retorna várias informações sobre a tabela de forma simples e rápida, 

--	17)	Exibir informações de Consumo de uma Query 

--	18)	Atualizar o cache local	CTRL+SHIFT+R
----------------------------------------------------------------------------------------------------------------------------
-- OBS: Muito útil na realização de Tuning!!!

SET STATISTICS IO ON		-- Leitura
SET STATISTICS IO OFF		-- Leitura

SET STATISTICS TIME ON		-- CPU
SET STATISTICS TIME OFF		-- CPU

SET STATISTICS IO, TIME ON	-- Leitura e CPU
SET STATISTICS IO, TIME OFF	-- Leitura e CPU

