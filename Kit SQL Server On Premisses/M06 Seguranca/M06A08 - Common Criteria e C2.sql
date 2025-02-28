/*******************************************************************
 Autor: Landry Duailibe
 
 HAnds On: Auditoria C2 e Common Criteria
********************************************************************/
use master
go

/******************************************************************
 C2 Audit Mode

 C2 foi publicado pela National Computer Security Center (NCSC), 
 em um documento  chamado Trusted Computer System Evaluation 
 Creteria (TCSEC), tamb�m chamado �Orange  Book� (faz parte da 
 s�rie arcoiris �Raimbow Series�).

 Salva arquivo de log na pasta da inst�ncia, quando o arquivo 
 chega a 200MB cria outro.
*******************************************************************/

exec sp_configure 'show advanced options', 1 
RECONFIGURE 
go

exec sp_configure 'c2 audit mode', 1 
RECONFIGURE 
go

/********************************************************************
 Common Criteria Audit Option

 C2 � um padr�o Americano, j� Common Criteria � Intenacional 
 (mais de 20 pa�ses 1999 � ISSO 15408).

 SQl Server foi definido como Level 4 (EAL4+).
 http://go.microsoft.com/fwlink/?LinkId=616319

 - Residual Information Protection (RIP) - na aloca��o de mem�ria 
   sobrescreve com padr�o de Bits, torna um pouco mais lento.
 - Ver estat�sticas de login.
 - GRANT na coluna n�o sobrep�e DENY na tabela.
*********************************************************************/
exec sp_configure 'show advanced options', 1
RECONFIGURE
go

exec sp_configure 'common criteria compliance enabled', 1
RECONFIGURE
go




