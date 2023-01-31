ALTER PROCEDURE sp_CloneLogin
    @Login VARCHAR(255),
    @NewLogin VARCHAR(255) = null,
    @SpecificDatabase VARCHAR(255) = null
AS
BEGIN
 
    IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = @Login)
    BEGIN
        RAISERROR (50000, 20, 20, 'Insert a existing login name.');
    END;
 
    IF (@NewLogin IS NULL)
    BEGIN
        SET @NewLogin = @Login
    END
 
    DECLARE @ReturnTable AS TABLE
    (
        Num_Order INT,
        DatabaseName NVARCHAR(255),
        Command NVARCHAR(3000)
    );
 
    DECLARE @databaseName NVARCHAR(255);
 
    DECLARE cur_Database CURSOR FAST_FORWARD LOCAL FOR
        SELECT name FROM sys.databases WHERE state_desc = 'ONLINE';
 
    OPEN cur_Database;
 
    FETCH NEXT FROM cur_Database INTO @databaseName;
 
    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @cmd VARCHAR(2000) = 'SELECT 2,  ''' + @DatabaseName + ''',
            ''USE ' + QUOTENAME(@DatabaseName) + '
 
            CREATE USER ' + QUOTENAME(@NewLogin) + ' FOR LOGIN ' + QUOTENAME(@NewLogin) +
            ';''
             FROM sys.server_principals server_login
                INNER JOIN ' + QUOTENAME(@DatabaseName) + '.sys.database_principals database_user
                    ON (server_login.sid = database_user.sid)
                    WHERE server_login.name = ''' + @Login + '''';
 
        INSERT INTO @ReturnTable EXEC(@cmd);
 
        SET @cmd =
        'SELECT 3,  ''' + @DatabaseName + ''',
            ''USE ' + QUOTENAME(@DatabaseName) + '''  +        
 
            + '' '' +  state_desc + '' '' + permission_name +
CASE WHEN class = 1 THEN '' ON '' + QUOTENAME(obj.name) +
ISNULL(''('' + col.name + '')'','''') END + '' TO ' +
QUOTENAME(@NewLogin) + ''' + '';'' COLLATE Latin1_General_CI_AI
            FROM sys.server_principals server_login
                INNER JOIN ' + QUOTENAME(@DatabaseName) + '.sys.database_principals database_user
                    ON (server_login.sid = database_user.sid)
                INNER JOIN ' + QUOTENAME(@DatabaseName) + '.sys.database_permissions db_perms
                    ON (database_user.principal_id = db_perms.grantee_principal_id)
                INNER JOIN ' + QUOTENAME(@DatabaseName) + '.sys.objects obj
                    ON (obj.object_id = db_perms.major_id)
                LEFT OUTER JOIN ' + QUOTENAME(@DatabaseName) + '.sys.columns col
                    ON (col.object_id = db_perms.major_id AND col.column_id = db_perms.minor_id)
        WHERE server_login.name = ''' + @Login + '''';
 
        INSERT INTO @ReturnTable EXEC(@cmd);
 
        SET @cmd =
        'SELECT 4,  ''' + @DatabaseName + ''',
        ''USE ' + QUOTENAME(@DatabaseName) + ' ' +
        'ALTER ROLE '' + QUOTENAME(roles.name) + '' ADD MEMBER ' + QUOTENAME(@NewLogin) + ';''
          FROM
        sys.server_principals srv_login
        INNER JOIN ' + QUOTENAME(@DatabaseName) + '.sys.database_principals db_user ON (srv_login.sid = db_user.sid)
        INNER JOIN ' + QUOTENAME(@DatabaseName) + '.sys.database_role_members rm ON (db_user.principal_id = rm.member_principal_id)
        INNER JOIN ' + QUOTENAME(@DatabaseName) + '.sys.database_principals roles ON (roles.principal_id = rm.role_principal_id)
        WHERE srv_login.name = ''' + @Login + '''';
 
        INSERT INTO @ReturnTable EXEC(@cmd);
 
        FETCH NEXT FROM cur_Database INTO @databaseName;
    END;
 
    CLOSE cur_Database;
 
    DEALLOCATE cur_Database;
 
    INSERT INTO @ReturnTable (Num_Order, DatabaseName, Command)
    SELECT
        1, null, 'USE [master] ' +  state_desc + ' ' + permission_name + ' TO ' + QUOTENAME(@NewLogin) + ';'
    FROM sys.server_principals logins
    INNER JOIN sys.server_permissions perms ON (perms.grantee_principal_id = logins.principal_id) WHERE logins.name = @Login;
 
    SELECT Command FROM @ReturnTable
    WHERE DatabaseName = @SpecificDatabase OR @SpecificDatabase IS NULL
     ORDER BY Num_Order, DatabaseName
END
 
/*
    exec sp_CloneLogin 'Teste'
    exec sp_CloneLogin 'Teste', 'Teste2'
    exec sp_CloneLogin 'Teste', 'Teste2', 'msdb'
*/