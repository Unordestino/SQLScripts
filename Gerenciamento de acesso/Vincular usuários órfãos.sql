-- Vincular usuários órfãos 

EXEC sp_change_users_login 'Update_One', 'login', 'user';