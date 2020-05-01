/************************************************************
 * Code formatted by SoftTree SQL Assistant © v6.1.35
 * Time: 05.07.2012 14:58:54
 ************************************************************/

IF OBJECT_ID(N'[dbo].[Find_Fields_By_Value]') IS NOT NULL
    DROP PROCEDURE [dbo].[Find_Fields_By_Value]
GO

CREATE PROCEDURE [dbo].[Find_Fields_By_Value]
	@TableNameP VARCHAR(50),
	@Value VARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE FieldsCursor CURSOR FAST_FORWARD 
	FOR
	    SELECT t.[name],
	           ac.[name]
	    FROM   sys.[tables] t
	           INNER JOIN sys.[all_columns] ac
	                ON  ac.[object_id] = t.[object_id]
	                AND ac.[system_type_id] NOT IN (34, 35, 165) -- image,text,varbinary
	    WHERE  t.[name] LIKE @TableNameP
	
	OPEN FieldsCursor
	
	DECLARE @TableName VARCHAR(MAX),
	        @FieldName VARCHAR(MAX)
	
	FETCH NEXT FROM FieldsCursor
	INTO @TableName, @FieldName
	
	CREATE TABLE #MatchFields
	(
		[TableName]      VARCHAR(MAX),
		[FieldName]      VARCHAR(MAX),
		[FieldValue]     VARCHAR(MAX)
	)
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
	    DECLARE @Command     NVARCHAR(MAX),
	            @Params      NVARCHAR(MAX)
	    
	    SET @Command = N'INSERT INTO #MatchFields
					 	 SELECT TOP 1 ''' + @TableName + ''', ''' + @FieldName + 
	        ''', [' + @FieldName + '] FROM [dbo].[' + @TableName + 
	        ']
					 	 WHERE CAST([' + @FieldName + 
	        '] AS VARCHAR(MAX)) LIKE @Value'
	    
	    SET @Params = N'@Value VARCHAR(MAX)'
	    
	    EXEC dbo.sp_executesql
	         @Command,
	         @Params,
	         @Value
	    
	    FETCH NEXT FROM FieldsCursor
	    INTO @TableName, @FieldName
	END
	
	CLOSE FieldsCursor
	DEALLOCATE FieldsCursor
	
	SELECT *
	FROM   #MatchFields
	
	SET NOCOUNT OFF
END
GO

EXEC [Find_Fields_By_Value]
     @TableNameP = '%Setup%',
     @Value = '%100%200%'