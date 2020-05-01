if EXISTS
	(SELECT * FROM information_SCHEMA.COLUMNS WHERE (table_name = N'CROC$Agreement')AND (column_name = N'digitally_signed'))
	PRINT 'Колонка существует'