!source ../variables.sql
--!source ../setup_db_objects.sql

/* -----------------------------------------------------------------------------
   PERFORMANCE MONITORING
   Requires ACCOUNTADMIN or a role with usage on SNOWFLAKE database.
   
   Focus Areas:
   1. Query Breakdown (Compile vs Execute vs Queue)
   2. Warehouse Load (Concurrency Pressure)
   3. Credit Consumption (Billable usage)
   4. Concurrency (User activity)
   5. Data Transfer (Egress costs)
------------------------------------------------------------------------------- */

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE &{warehouse_name};
USE DATABASE SNOWFLAKE; 
USE SCHEMA ACCOUNT_USAGE;

/* -----------------------------------------------------------------------------
   1. QUERY PERFORMANCE: Breakdown of Time
   Why: If a query takes 10s, is it "Working" (Execute) or "Waiting" (Queue)?
------------------------------------------------------------------------------- */

SELECT 
    QUERY_ID, 
    --START_TIME,
    --QUERY_TEXT,
    WAREHOUSE_NAME, 
    -- Total time the user waited
    (TOTAL_ELAPSED_TIME / 1000) AS TOTAL_SEC,
    -- Time spent waiting for a warehouse slot (Concurrency issue)
    (QUEUED_OVERLOAD_TIME / 1000) AS QUEUE_SEC,
    -- Time spent translating SQL to machine code (Metadata/Complex SQL issue)
    (COMPILATION_TIME / 1000) AS COMPILE_SEC,
    -- Time spent actually processing data
    (EXECUTION_TIME / 1000) AS EXEC_SEC,
    BYTES_SCANNED
FROM QUERY_HISTORY
WHERE 
    START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    AND TOTAL_ELAPSED_TIME > 5000 -- Only look at queries > 5 seconds
ORDER BY TOTAL_ELAPSED_TIME DESC
LIMIT 5;

/* -----------------------------------------------------------------------------
   2. WAREHOUSE UTILIZATION: Load History
   Why: "Avg Running" > "Clusters" means the warehouse is 100% busy.
        "Avg Queued" > 0 means queries are stuck waiting.
------------------------------------------------------------------------------- */

SELECT 
    START_TIME,
    WAREHOUSE_NAME,
    AVG_RUNNING,       -- Average number of queries executing
    AVG_QUEUED_LOAD,   -- Average number of queries waiting (Should be near 0)
    AVG_QUEUED_PROVISIONING -- Waiting for the warehouse to wake up
FROM WAREHOUSE_LOAD_HISTORY
WHERE 
    START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    AND WAREHOUSE_NAME = '&{warehouse_name}'
ORDER BY START_TIME DESC
LIMIT 5;

/* -----------------------------------------------------------------------------
   3. CREDIT CONSUMPTION: Compute vs. Cloud Services
   Why: Cloud Services (Optimizer, Metadata) are free up to 10% of Compute.
        If Cloud Services > 10%, you pay for the overage.
------------------------------------------------------------------------------- */

SELECT 
    START_TIME::DATE AS USAGE_DATE,
    WAREHOUSE_NAME,
    SUM(CREDITS_USED_COMPUTE) AS COMPUTE_CREDITS,
    SUM(CREDITS_USED_CLOUD_SERVICES) AS CLOUD_SERVICES_CREDITS,
    -- Calculate the ratio
    (SUM(CREDITS_USED_CLOUD_SERVICES) / NULLIF(SUM(CREDITS_USED_COMPUTE),0)) * 100 AS CLOUD_RATIO_PERCENT
FROM WAREHOUSE_METERING_HISTORY
WHERE 
    START_TIME >= DATEADD('day', -30, CURRENT_TIMESTAMP())
    AND WAREHOUSE_NAME = '&{warehouse_name}'
GROUP BY 1, 2
ORDER BY 1 DESC
LIMIT 5;


/* -----------------------------------------------------------------------------
   4. CONCURRENCY: Activity Trends
   Why: Determine the best time for maintenance or resizing.
------------------------------------------------------------------------------- */

SELECT 
    DATE_TRUNC('HOUR', START_TIME) AS HOUR_BUCKET,
    COUNT(*) AS TOTAL_QUERIES,
    COUNT(DISTINCT USER_NAME) AS UNIQUE_USERS,
    AVG(TOTAL_ELAPSED_TIME)/1000 AS AVG_DURATION_SEC
FROM QUERY_HISTORY
WHERE 
    START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY 1
ORDER BY 1 DESC
LIMIT 5;


/* -----------------------------------------------------------------------------
   5. DATA TRANSFER: Egress Costs
   Why: You pay when moving data OUT of Snowflake (to another region or cloud).
   Ingress (loading data in) is usually free.
------------------------------------------------------------------------------- */

SELECT 
    START_TIME::DATE AS TRANSFER_DATE,
    TARGET_CLOUD,   -- AWS, AZURE, GCP
    TARGET_REGION,  -- e.g., us-east-1
    TRANSFER_TYPE,  -- COPY, REPLICATION, EXTERNAL_FUNCTION
    SUM(BYTES_TRANSFERRED) / 1024 / 1024 / 1024 AS GB_TRANSFERRED
FROM DATA_TRANSFER_HISTORY
WHERE 
    START_TIME >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY 1, 2, 3, 4
ORDER BY GB_TRANSFERRED DESC
LIMIT 5;

--!source cleanup_db_objects.sql