!source variables.sql
--!source setup_db_objects.sql

/* -----------------------------------------------------------------------------
   MONITOR and AUDIT
   Section: Query History and Performance
------------------------------------------------------------------------------- */

-- Setup Context
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE &{warehouse_name};
USE DATABASE &{database_name}; 

/* -----------------------------------------------------------------------------
   METHOD 1: REAL-TIME MONITORING (Information Schema)
   Use this to debug "Why is it slow RIGHT NOW?" or recent failures.
   * Retention: 7 Days
   * No Latency
------------------------------------------------------------------------------- */

-- 1. Check for CURRENTLY RUNNING or QUEUED queries
--    Exam Tip: If you see many 'QUEUED' queries, you need to Scale Out (Multi-cluster).
SELECT 
    QUERY_ID, 
    USER_NAME, 
    WAREHOUSE_NAME, 
    EXECUTION_STATUS,
    START_TIME,
    DATEDIFF('second', START_TIME, CURRENT_TIMESTAMP()) as RUN_SECONDS
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(
    RESULT_LIMIT => 100,
    END_TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP()),
    END_TIME_RANGE_END => CURRENT_TIMESTAMP()
))
WHERE EXECUTION_STATUS IN ('RUNNING', 'QUEUED', 'BLOCKED')
ORDER BY START_TIME ASC;

-- 2. Find queries that FAILED in the last hour
SELECT 
    QUERY_ID, 
    QUERY_TEXT, 
    ERROR_MESSAGE, 
    EXECUTION_STATUS,
    START_TIME
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(
    RESULT_LIMIT => 100,
    END_TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP()),
    END_TIME_RANGE_END => CURRENT_TIMESTAMP()
))
WHERE EXECUTION_STATUS IN ('FAILED_WITH_ERROR', 'FAILED_WITH_INCIDENT')
ORDER BY START_TIME DESC;

-- Others query history table functions:
-- QUERY_HISTORY_BY_SESSION
-- QUERY_HISTORY_BY_USER
-- QUERY_HISTORY_BY_WAREHOUSE

/* -----------------------------------------------------------------------------
   METHOD 2: HISTORICAL ANALYSIS (Account Usage)
   Use this for Cost Optimization and Deep Dives.
   * Retention: 365 Days
   * Latency: ~45 mins
------------------------------------------------------------------------------- */

-- 1. Identify "Heavy Hitters" (Longest Duration) in the last 7 days
--    These are the best candidates for optimization.
SELECT 
    QUERY_ID,
    USER_NAME,
    WAREHOUSE_NAME,
    TOTAL_ELAPSED_TIME / 1000 AS SECONDS, -- Convert millis to seconds
    BYTES_SCANNED,
    QUERY_TEXT
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE 
    START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    AND WAREHOUSE_SIZE IS NOT NULL
ORDER BY TOTAL_ELAPSED_TIME DESC
LIMIT 20;

-- 2. "Spilling to Disk" Check (CRITICAL EXAM TOPIC)
--    Exam Tip: If BYTES_SPILLED > 0, the Warehouse is too small (Memory pressure).
--    Solution: Scale Up (increase T-Shirt size).
SELECT 
    QUERY_ID,
    USER_NAME,
    WAREHOUSE_NAME,
    WAREHOUSE_SIZE,
    BYTES_SPILLED_TO_LOCAL_STORAGE,  -- Spilled to SSD (Slow)
    BYTES_SPILLED_TO_REMOTE_STORAGE, -- Spilled to S3/Blob (Very Slow)
    TOTAL_ELAPSED_TIME / 1000 AS SECONDS
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE 
    START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    AND (BYTES_SPILLED_TO_LOCAL_STORAGE > 0 OR BYTES_SPILLED_TO_REMOTE_STORAGE > 0)
ORDER BY BYTES_SPILLED_TO_REMOTE_STORAGE DESC;

--!source cleanup_db_objects.sql