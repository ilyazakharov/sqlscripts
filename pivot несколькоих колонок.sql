--DROP TABLE Task_Details
--GO

CREATE TABLE Task_Details
(
	JobNo             NVARCHAR(100),
	TaskName          NVARCHAR(100),
	ACTUAL_DATE       DATE,
	FORECAST_DATE     DATE,
	TaskType          NVARCHAR(100)
)  
GO

INSERT INTO Task_Details
  (
    JobNo,
    TaskName,
    ACTUAL_DATE,
    FORECAST_DATE,
    TaskType
  )
VALUES
('A111','Name1','2020-01-01','2030-01-01','delayed'),
('A111', 'Name2', '2020-02-02', '2020-03-03', 'active'),
('A222', 'Name1', '2020-03-03', '2020-04-04', 'cancel'),
('A222', 'Name2', '2020-04-04', '2020-05-05', 'pending')
GO

SELECT JobNo,
       [Name1A_TaskDate] AS Name1F,
       [Name1F_TaskDate] AS Name1A,
       [Name1F_TaskType] AS Name1T,
       [Name2A_TaskDate] AS Name2F,
       [Name2F_TaskDate] AS Name2A,
       [Name2F_TaskType] AS Name2T
FROM   (
           SELECT JobNo,
                  task,
                  TaskCode + '_' + JOB  AS rr
           FROM   (
                      SELECT JobNo,
                             TaskName + 'F' AS TaskCode,
                             CAST(FORECAST_DATE AS NVARCHAR(100)) AS TaskDate,
                             TaskType
                      FROM   Task_Details AS FcstDateQuery
                      WHERE  FORECAST_DATE IS NOT NULL
                      UNION
                      SELECT JobNo,
                             TaskName + 'A' AS TaskCode,
                             CAST(ACTUAL_DATE AS NVARCHAR(100)) AS TaskDate,
                             TaskType
                      FROM   Task_Details AS ActDateQuery
                      WHERE  ACTUAL_DATE IS NOT NULL
                  )                     AS t
                  UNPIVOT(Task FOR JOB IN ([TaskDate], [TaskType])) AS h
       ) AS t 
       PIVOT(
           MAX(task) FOR rr IN ([Name1A_TaskDate], [Name1F_TaskDate], [Name1F_TaskType], [Name2A_TaskDate], 
                               [Name2F_TaskDate], [Name2F_TaskType])
       ) AS pvt                