-- Verifica quais bases de dados tem um CHECKSUM ATIVO

select name, page_verify_option_desc 
from sys.databases