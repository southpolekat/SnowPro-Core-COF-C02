!source ../variables.sql
--!source ../setup_db_objects.sql

/* -----------------------------------------------------------------------------
   MONITOR and AUDIT
   Section: Login History
------------------------------------------------------------------------------- */
-- Setup context
USE ROLE ACCOUNTADMIN; -- Or a role with MONITOR usage on the account
USE WAREHOUSE &{warehouse_name};
USE DATABASE &{database_name}; -- Any DB

/* -----------------------------------------------------------------------------
   METHOD 1: REAL-TIME CHECKS (Information Schema)
   Use this when a user says "I can't log in right now!"
   * No Latency
   * Retention: Only past 7 days
   * Syntax: requires TABLE() wrapper
------------------------------------------------------------------------------- */

-- 1. Check the last 5 login attempts globally (in the last hour)
SELECT * FROM TABLE(INFORMATION_SCHEMA.LOGIN_HISTORY(
    RESULT_LIMIT => 5,
    TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP()),
    TIME_RANGE_END => CURRENT_TIMESTAMP()
))
ORDER BY EVENT_TIMESTAMP DESC;

-- 2. Check a SPECIFIC USER'S recent login failures
--    (Replace 'USER_3' with the actual username)
SELECT 
    EVENT_TIMESTAMP, 
    USER_NAME, 
    CLIENT_IP, 
    REPORTED_CLIENT_TYPE, 
    ERROR_MESSAGE
FROM TABLE(INFORMATION_SCHEMA.LOGIN_HISTORY_BY_USER(
    USER_NAME => '&{user_name}', 
    RESULT_LIMIT => 10
))
WHERE IS_SUCCESS = 'NO'
ORDER BY EVENT_TIMESTAMP DESC;

-- 3. Check for specific IP address activity in the last hour
SELECT * FROM TABLE(INFORMATION_SCHEMA.LOGIN_HISTORY(
    RESULT_LIMIT => 5
))
WHERE CLIENT_IP LIKE '180.%' -- Replace with IP to check
ORDER BY EVENT_TIMESTAMP DESC;

/* -----------------------------------------------------------------------------
   METHOD 2: HISTORICAL AUDIT (Account Usage)
   Use this for compliance reports or analyzing patterns.
   * Latency for the view may be up to 120 minutes (2 hours).
   * Retention: 365 days
------------------------------------------------------------------------------- */

-- 1. General Audit: Count of logins by User and Success Status (Last 30 Days)
SELECT 
    USER_NAME,
    IS_SUCCESS,
    COUNT(*) as LOGIN_COUNT,
    MAX(EVENT_TIMESTAMP) as LAST_ATTEMPT
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE EVENT_TIMESTAMP >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY 1, 2
ORDER BY USER_NAME;

-- 2. Security Audit: Identify brute force attacks? 
--    (High volume of failures from a single IP)
SELECT 
    CLIENT_IP,
    USER_NAME,
    COUNT(*) as FAILURE_COUNT,
    MIN(EVENT_TIMESTAMP) as FIRST_FAILURE,
    MAX(EVENT_TIMESTAMP) as LAST_FAILURE
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE 
    IS_SUCCESS = 'NO'
    AND EVENT_TIMESTAMP >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY 1, 2
HAVING FAILURE_COUNT > 5
ORDER BY FAILURE_COUNT DESC;

--!source cleanup_db_objects.sql