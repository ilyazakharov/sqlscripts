SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/*кто кого*/
SELECT DB_NAME(pr1.dbid) AS 'DB'
      ,pr1.spid AS 'ID жертвы'
      ,RTRIM(pr1.loginame) AS 'Login жертвы'
      ,pr2.spid AS 'ID виновника'
      ,RTRIM(pr2.loginame) AS 'Login виновника'
      ,pr1.program_name AS 'программа жертвы'
      ,pr2.program_name AS 'программа виновника'
      ,txt.[text] AS 'Запрос виновника'
FROM   MASTER.dbo.sysprocesses pr1(NOLOCK)
       JOIN MASTER.dbo.sysprocesses pr2(NOLOCK)
            ON  (pr2.spid = pr1.blocked)
       OUTER APPLY sys.[dm_exec_sql_text](pr2.[sql_handle]) AS txt
WHERE  pr1.blocked <> 0

/* Кто что блокирует */
SELECT s.[nt_username]
      ,request_session_id
      ,tran_locks.[request_status]
      ,rd.[Description] + ' (' + tran_locks.resource_type + ' ' + tran_locks.request_mode + ')' [Object]
      ,txt_blocked.[text]
      ,COUNT(*) [COUNT]
FROM   sys.dm_tran_locks AS tran_locks WITH (NOLOCK)
       JOIN sys.sysprocesses AS s WITH (NOLOCK)
            ON  tran_locks.request_session_id = s.[spid]
       JOIN (
                SELECT 'KEY' AS sResource_type
                      ,p.[hobt_id] AS [id]
                      ,QUOTENAME(o.name) + '.' + QUOTENAME(i.name) AS [Description]
                FROM   sys.partitions p
                       JOIN sys.objects o
                            ON  p.object_id = o.object_id
                       JOIN sys.indexes i
                            ON  p.object_id = i.object_id
                            AND p.index_id = i.index_id
                UNION ALL
                SELECT 'RID' AS sResource_type
                      ,p.[hobt_id] AS [id]
                      ,QUOTENAME(o.name) + '.' + QUOTENAME(i.name) AS [Description]
                FROM   sys.partitions p
                       JOIN sys.objects o
                            ON  p.object_id = o.object_id
                       JOIN sys.indexes i
                            ON  p.object_id = i.object_id
                            AND p.index_id = i.index_id
                UNION ALL
                SELECT 'PAGE'
                      ,p.[hobt_id]
                      ,QUOTENAME(o.name) + '.' + QUOTENAME(i.name)
                FROM   sys.partitions p
                       JOIN sys.objects o
                            ON  p.object_id = o.object_id
                       JOIN sys.indexes i
                            ON  p.object_id = i.object_id
                            AND p.index_id = i.index_id
                
                UNION ALL
                SELECT 'OBJECT'
                      ,o.[object_id]
                      ,QUOTENAME(o.name)
                FROM   sys.objects o
            ) AS RD
            ON  RD.[sResource_type] = tran_locks.resource_type
            AND RD.[id] = tran_locks.resource_associated_entity_id
       OUTER APPLY sys.[dm_exec_sql_text](s.[sql_handle]) AS txt_Blocked
WHERE  (
           tran_locks.request_mode = 'X'
           AND tran_locks.resource_type = 'OBJECT'
       )
       OR  tran_locks.[request_status] = 'WAIT'
GROUP BY
       s.[nt_username]
      ,request_session_id
      ,tran_locks.[request_status]
      ,rd.[Description] + ' (' + tran_locks.resource_type + ' ' + tran_locks.request_mode + ')'
      ,txt_blocked.[text]
ORDER BY
       6 DESC
       
GO       

/* Чем занят сервер*/
SELECT s.[spid]
      ,s.[loginame]
      ,s.[open_tran]
      ,s.[blocked]
      ,s.[waittime]
      ,s.[cpu]
      ,s.[physical_io]
      ,s.[memusage]
       INTO #sysprocesses
FROM   sys.[sysprocesses] s

WAITFOR DELAY '00:00:05' 

SELECT txt.[text]
      ,s.[spid]
      ,s.[loginame]
      ,s.[hostname]
      ,DB_NAME(s.[dbid]) [db_name]
      ,SUM(s.[waittime] -ts.[waittime]) [waittime]
      ,SUM(s.[cpu] -ts.[cpu]) [cpu]
      ,SUM(s.[physical_io] -ts.[physical_io]) [physical_io]
      ,s.[program_name]
FROM   sys.[sysprocesses] s
       JOIN #sysprocesses ts
            ON  s.[spid] = ts.[spid]
            AND s.[loginame] = ts.[loginame]
       OUTER APPLY sys.[dm_exec_sql_text](s.[sql_handle]) AS txt
WHERE  s.[cpu] -ts.[cpu] 
       + s.[physical_io] -ts.[physical_io] 
       > 500
       OR  (s.[waittime] -ts.[waittime]) > 3000
GROUP BY
       txt.[text]
      ,s.[spid]
      ,s.[loginame]
      ,s.[hostname]
      ,DB_NAME(s.[dbid])
      ,s.[program_name]
ORDER BY
       [physical_io] DESC
       
DROP TABLE #sysprocesses