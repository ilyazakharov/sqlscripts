SELECT OBJECT_NAME([object_id]),* 
FROM sys.sql_modules WHERE definition LIKE '%ActivityClient%'
ORDER BY 1 

-- находит все объекты, где используются имя ActivityClientClarityID