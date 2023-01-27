--Cancelar após um tempo o insert

DECLARE @Max_R_E_C_N_O_ INT, @Min_R_E_C_N_O_ INT, @Loop INT

SELECT @Min_R_E_C_N_O_ = MIN(R_E_C_N_O_), @Max_R_E_C_N_O_ = MAX(R_E_C_N_O_)
FROM SA1010

SET @Loop = @Min_R_E_C_N_O_

SELECT @Min_R_E_C_N_O_,@Max_R_E_C_N_O_

SET NOCOUNT ON

WHILE @Loop <= @Max_R_E_C_N_O_
BEGIN

	INSERT INTO SA1010([A1_FILIAL], [A1_COD], [A1_LOJA], [A1_NOME], [A1_PESSOA], [A1_END], [A1_NREDUZ], [A1_BAIRRO], [A1_TIPO], [A1_EST], [A1_ESTADO], [A1_CEP], [A1_CGC], [D_E_L_E_T_], [R_E_C_N_O_], [R_E_C_D_E_L_])
	SELECT [A1_FILIAL], @Max_R_E_C_N_O_+R_E_C_N_O_, [A1_LOJA], [A1_NOME], [A1_PESSOA], [A1_END], [A1_NREDUZ], [A1_BAIRRO], [A1_TIPO], [A1_EST], [A1_ESTADO], [A1_CEP], [A1_CGC], [D_E_L_E_T_], @Max_R_E_C_N_O_+R_E_C_N_O_, [R_E_C_D_E_L_]
	FROM SA1010
	WHERE [R_E_C_N_O_] >= @Loop AND [R_E_C_N_O_] < @Loop + 20000 

	set @Loop = @Loop + 20000 --intervalo
	
	--PRINT @Loop
	
	-- WAITFOR delay '00:00:00:200' -- esse tempo voce define de acordo com a criticidade do seu ambiente e horário que está executando
END