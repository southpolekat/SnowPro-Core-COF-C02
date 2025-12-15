!source ../variables.sql

/* -----------------------------------------------------------------------------
   EVENT TABLE and LOGGING TEST
   Requires ACCOUNTADMIN role (to set the active event table).
   
   Features covered:
   1. Creating an Event Table
   2. Activating the Event Table for the Account
   3. Creating a Python Stored Procedure with Logging
   4. Triggering Logs
   5. Querying the captured events


Notes:
* Definition: A specialized table designed to capture log messages and trace events from Stored Procedures and User-Defined Functions (UDFs).
*Schema: Has a pre-defined, fixed schema (columns like TIMESTAMP, RECORD_ATTRIBUTES, VALUE). You cannot add, drop, or modify columns.
* Account Limit: You can create multiple Event Tables, but only one can be active for the entire account at a time.
* Activation: Requires ACCOUNTADMIN privilege to set the active table (ALTER ACCOUNT SET EVENT_TABLE = ...).
* Latency: Logging is asynchronous and buffered. Logs may take a few seconds/minutes to appear in the table (not real-time).
* Log Levels: Controlled by the LOG_LEVEL parameter (e.g., INFO, WARN, ERROR).
    * Can be set at multiple levels: Account, Database, Schema, or specific Object(Function/Procedure).
    * The most specific level overrides the higher levels.
* Storage: Consumes storage costs like a standard table.
* Use Case: Debugging application code (Python/Java/Scala) running inside Snowflake.
------------------------------------------------------------------------------- */

USE WAREHOUSE &{warehouse_name};
USE DATABASE &{database_name};
USE SCHEMA &{schema_name};

/* -----------------------------------------------------------------------------
   STEP 1: CREATE THE EVENT TABLE
   * Note: This table has a fixed schema (TIMESTAMP, RESOURCE_ATTRIBUTES, etc.)
     You cannot add/remove columns from it.
------------------------------------------------------------------------------- */
USE ROLE SYSADMIN;

CREATE EVENT TABLE IF NOT EXISTS &{database_name}.&{schema_name}.MY_LOG_TABLE;

-- Verification
SHOW EVENT TABLES LIKE 'MY_LOG_TABLE';

/* -----------------------------------------------------------------------------
   STEP 2: ACTIVATE THE EVENT TABLE
   * Only one table can be active for the account.
   * Requires ACCOUNTADMIN.
------------------------------------------------------------------------------- */
USE ROLE ACCOUNTADMIN;

ALTER ACCOUNT SET EVENT_TABLE = &{database_name}.&{schema_name}.MY_LOG_TABLE;

-- Verify it is set
SHOW PARAMETERS LIKE 'EVENT_TABLE' IN ACCOUNT;

/* -----------------------------------------------------------------------------
   STEP 3: CREATE A PYTHON STORED PROCEDURE (THE LOG GENERATOR)
   We write a simple Python script that uses the standard 'logging' library.
   Snowflake automatically redirects these logs to your Event Table.
------------------------------------------------------------------------------- */
USE ROLE SYSADMIN;

CREATE OR REPLACE PROCEDURE &{database_name}.&{schema_name}.GENERATE_LOGS()
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'run_logs'
AS
$$
import logging
import sys

# Get the logger
logger = logging.getLogger("my_test_logger")

def run_logs(session):
    # Log different levels
    logger.info("INFO: This is a standard information message.")
    logger.warning("WARNING: This is a warning message!")
    logger.error("ERROR: Something went wrong (Simulation).")
    
    return "Logs generated successfully!"
$$;


/* -----------------------------------------------------------------------------
   STEP 4: SET LOG LEVEL and EXECUTE
   By default, only WARN/ERROR might be captured. We set level to INFO.
------------------------------------------------------------------------------- */

-- Set the logging level for this specific object (Procedure)
ALTER PROCEDURE &{database_name}.&{schema_name}.GENERATE_LOGS() 
    SET LOG_LEVEL = 'INFO';

-- Run the procedure to generate logs
CALL &{database_name}.&{schema_name}.GENERATE_LOGS();


/* -----------------------------------------------------------------------------
   STEP 5: VIEW THE LOGS
   * CRITICAL: Logs are buffered. It may take 30-60 seconds for them to appear.
------------------------------------------------------------------------------- */

-- Wait ~30 seconds before running this...
SELECT 
    TIMESTAMP,
    OBSERVED_TIMESTAMP,
    RESOURCE_ATTRIBUTES, -- Contains details about the warehouse/db/schema
    RECORD_ATTRIBUTES,   -- Contains the actual log message inside JSON
    VALUE                -- The raw log message
FROM &{database_name}.&{schema_name}.MY_LOG_TABLE
ORDER BY TIMESTAMP DESC
LIMIT 10;


/* -----------------------------------------------------------------------------
   CLEANUP
------------------------------------------------------------------------------- */
USE ROLE ACCOUNTADMIN;
ALTER ACCOUNT UNSET EVENT_TABLE;
USE ROLE SYSADMIN;
DROP EVENT TABLE IF EXISTS &{database_name}.&{schema_name}.MY_LOG_TABLE;