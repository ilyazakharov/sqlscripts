-- Обычные таблицы
SELECT
  t.Name                                       AS TableName,
  s.Name                                       AS SchemaName,
  p.Rows                                       AS RowCounts,
  SUM(a.total_pages) * 8                       AS TotalSpaceKB,
  SUM(a.used_pages) * 8                        AS UsedSpaceKB,
  (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
FROM
  sys.tables t
  INNER JOIN sys.indexes i ON t.object_id = i.object_id
  INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
  INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
  LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE
  t.Name NOT LIKE 'dt%'
  AND t.is_ms_shipped = 0
  AND i.object_id > 255
GROUP BY
  t.Name, s.Name, p.Rows
ORDER BY
  4 DESC 
GO

; WITH cte AS (
-- in-memory таблицы
SELECT  object_id ,
        OBJECT_SCHEMA_NAME(object_id) + '.' + OBJECT_NAME(object_id) [Table_Name] ,
        memory_allocated_for_table_kb ,
        memory_used_by_table_kb ,
        memory_allocated_for_indexes_kb ,
        memory_used_by_indexes_kb
FROM    sys.dm_db_xtp_table_memory_stats
--ORDER BY 4 DESC 
)
SELECT SUM(memory_allocated_for_table_kb) / 1024 / 1024 FROM cte
WHERE [Table_Name] NOT LIKE 'updatable.factTimeLoss_HPSM%'
AND [Table_Name] NOT LIKE 'updatable.factPlanDataLine_FC%'