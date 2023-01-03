/* 
Deleta todos os dados da tabela [dbo].[Traces] que tenha mais de 10 dias
*/

create procedure stpExclui_Registros_Antigos 
AS 
BEGIN 
	declare  @Traces int 
	select  
	@Traces = 10 

	delete from Traces.[dbo].Traces 
	where StartTime <  DATEADD(dd,@Traces*-1,getdate())
END

