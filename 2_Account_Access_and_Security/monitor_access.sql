!source variables.sql
--!source setup_db_objects.sql

/* -----------------------------------------------------------------------------
   MONITOR and AUDIT
   Section: Access History and Data Lineage
------------------------------------------------------------------------------- */

-- Setup Context
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE &{warehouse_name};
USE DATABASE &{database_name}; 

/* -----------------------------------------------------------------------------
   ACCESS HISTORY (Account Usage)
   This view records exactly WHICH data was accessed.
   * Retention: 365 Days. 
   * Latency for the view may be up to 180 minutes (3 hours).
   * Key Column: DIRECT_OBJECTS_ACCESSED (JSON)
------------------------------------------------------------------------------- */

-- 1. Find who accessed a SPECIFIC TABLE in the last 7 days
--    Useful for: "Who is looking at the SALARY table?"
SELECT 
    QUERY_ID,
    USER_NAME,
    QUERY_START_TIME,
    DIRECT_OBJECTS_ACCESSED
FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY
WHERE 
    QUERY_START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    -- Filter the JSON column for the specific object name
    AND DIRECT_OBJECTS_ACCESSED::STRING ILIKE '%&{table_name}%'
ORDER BY QUERY_START_TIME DESC;

-- 2. Audit: List all tables modified (INSERT/UPDATE/DELETE) 
--    Useful for: Data Lineage (Tracing where data came from)
SELECT 
    QUERY_ID,
    USER_NAME,
    QUERY_START_TIME,
    -- Objects that were modified (Target tables)
    OBJECTS_MODIFIED
FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY
WHERE 
    QUERY_START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    AND ARRAY_SIZE(OBJECTS_MODIFIED) > 0 -- Only show queries that changed data
ORDER BY QUERY_START_TIME DESC;

-- 3. Advanced: Parse the JSON to see SPECIFIC COLUMNS accessed
--    This flattens the JSON array to show one row per column accessed.
SELECT 
    ah.QUERY_ID,
    ah.USER_NAME,
    ah.QUERY_START_TIME,
    f1.value:"objectName"::STRING as TABLE_NAME,
    f2.value:"columnName"::STRING as COLUMN_NAME
FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY ah,
     LATERAL FLATTEN(input => ah.DIRECT_OBJECTS_ACCESSED) f1,
     LATERAL FLATTEN(input => f1.value:"columns") f2
WHERE 
    ah.QUERY_START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    AND f1.value:"objectName"::STRING ILIKE '%&{table_name}%'
LIMIT 50;

--!source cleanup_db_objects.sql