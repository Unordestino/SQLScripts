-- Procedure que apaga os registros da tabela com mais de 60 dias

create procedure stpExclui_Registros_Antigos 
AS 
BEGIN 
	declare  @Registro_Contador int 
	select  
	@Registro_Contador = 60 
	select * from Registro_Contador 
	where Dt_Log <  DATEADD(dd,@Registro_Contador*-1,getdate()) 
END