!source ../variables.sql

/* -----------------------------------------------------------------------------
   ALL TABLE TYPES TEST SCRIPT
   Requires SYSADMIN role.
   
   Types Covered:
   1. Permanent (Standard) - The default.
   2. Transient - No Fail-Safe, lower cost.
   3. Temporary - Session only.
   4. External - Points to S3/Azure/GCS.
   5. Directory - File catalog attached to a stage.
   6. Dynamic - Auto-refreshing transformation (Declarative ETL).
   7. Hybrid (Unistore) - *Note: Requires Unistore enabled account.
------------------------------------------------------------------------------- */

USE ROLE SYSADMIN;
USE WAREHOUSE &{warehouse_name};
USE DATABASE &{database_name};
USE SCHEMA &{schema_name};

/* -----------------------------------------------------------------------------
   TYPE 1: PERMANENT TABLE (Standard)
   * Fail-Safe: 7 Days
   * Time Travel: 0-90 Days (Enterprise)
------------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS &{database_name}.&{schema_name}.MY_PERM_TABLE (
    ID INT,
    DATA STRING
);

INSERT INTO &{database_name}.&{schema_name}.MY_PERM_TABLE VALUES (1, 'Permanent Data');
SELECT * FROM &{database_name}.&{schema_name}.MY_PERM_TABLE;

/* -----------------------------------------------------------------------------
   TYPE 2: TRANSIENT TABLE
   * Fail-Safe: 0 Days (Cost Saving)
   * Time Travel: 0-1 Day
------------------------------------------------------------------------------- */
CREATE TRANSIENT TABLE IF NOT EXISTS &{database_name}.&{schema_name}.MY_TRANS_TABLE (
    ID INT,
    DATA STRING
);

INSERT INTO &{database_name}.&{schema_name}.MY_TRANS_TABLE VALUES (1, 'Transient Data');
SELECT * FROM &{database_name}.&{schema_name}.MY_TRANS_TABLE;

/* -----------------------------------------------------------------------------
   TYPE 3: TEMPORARY TABLE
   * Duration: Only exists for this session. Drops when you log out.
   * Fail-Safe: 0 Days
   * Time Travel: 0-1 Day
------------------------------------------------------------------------------- */
CREATE TEMPORARY TABLE IF NOT EXISTS &{database_name}.&{schema_name}.MY_TEMP_TABLE (
    ID INT,
    DATA STRING
);

INSERT INTO &{database_name}.&{schema_name}.MY_TEMP_TABLE VALUES (1, 'Session Data');
SELECT * FROM &{database_name}.&{schema_name}.MY_TEMP_TABLE;

/* -----------------------------------------------------------------------------
   TYPE 4: DIRECTORY TABLE (Implicit)
   * Concept: Adds a file catalog to a Stage. (Internal Stage)
   * Queryable: Query 'DIRECTORY(@stage_name)'
------------------------------------------------------------------------------- */
-- 1. Create a stage with Directory enabled
CREATE STAGE IF NOT EXISTS &{database_name}.&{schema_name}.MY_DIR_STAGE
    DIRECTORY = (ENABLE = TRUE);

-- 2. Upload a dummy file (Simulated for script)
-- snowsql -c <connection_name> -d &{database_name} -s &{schema_name} -q 'PUT file:///tmp/test.csv @MY_DIR_STAGE'
LIST @&{database_name}.&{schema_name}.MY_DIR_STAGE;

-- 3. Query the Directory Table
-- Note: The Directory Table metadata is likely out of sync with the actual storage.
-- You need to manually refresh the metadata using the REFRESH command.
ALTER STAGE &{database_name}.&{schema_name}.MY_DIR_STAGE REFRESH;
SELECT * FROM DIRECTORY(@&{database_name}.&{schema_name}.MY_DIR_STAGE);

/* -----------------------------------------------------------------------------
   TYPE 5: EXTERNAL TABLE
   * Concept: "Window" into S3/Azure. Data stays in cloud bucket.
   * Note: Reusing the S3 integration from external_stages.sql.
------------------------------------------------------------------------------- */
-- Create File Format
CREATE FILE FORMAT IF NOT EXISTS &{database_name}.&{schema_name}.MY_CSV_FORMAT TYPE='CSV';

-- Create External Table
CREATE EXTERNAL TABLE IF NOT EXISTS &{database_name}.&{schema_name}.MY_EXT_TABLE (
    CUST_ID INT AS (value:c1::INT),
    CUST_NAME VARCHAR AS (value:c2::VARCHAR),
    REGION VARCHAR AS (value:c3::VARCHAR)
)
    LOCATION = @&{database_name}.&{schema_name}.my_s3_stage
    FILE_FORMAT = &{database_name}.&{schema_name}.MY_CSV_FORMAT
    AUTO_REFRESH = FALSE;

SELECT CUST_ID, CUST_NAME, REGION FROM &{database_name}.&{schema_name}.MY_EXT_TABLE;

/* -----------------------------------------------------------------------------
   TYPE 6: DYNAMIC TABLE
   * Concept: "Set it and forget it" transformation pipeline.
   * Lag: 1 minute (Snowflake auto-schedules the refresh).   
------------------------------------------------------------------------------- */
CREATE DYNAMIC TABLE IF NOT EXISTS &{database_name}.&{schema_name}.MY_DYN_TABLE
    TARGET_LAG = '1 minute'
    WAREHOUSE = &{warehouse_name}
    AS
    SELECT ID, DATA FROM &{database_name}.&{schema_name}.MY_PERM_TABLE;
    
-- Check status
SELECT * FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLES(
    RESULT_LIMIT => 10
));

SELECT * FROM &{database_name}.&{schema_name}.MY_DYN_TABLE;

/* -----------------------------------------------------------------------------
   TYPE 7: HYBRID TABLE (Unistore)
   * Concept: OLTP (Row-based) storage for fast single-row lookups.
   * Note: This might fail if your trial account doesn't have Unistore enabled.
   * Note: Unistore is not available in the trial account

Hybrid Tables (Unistore)
   * Definition: A table type optimized for transactional (OLTP) workloads that supports high concurrency and low latency.
   * Storage Architecture: Uses a dual-engine approach:
     * Row Store: For fast single-row lookups and updates.
     * Column Store: Automatically synced for fast analytical queries.
     * Constraints: Primary Keys are **enforced** (unlike standard tables). Unique constraints are supported.
     * Indexes: Supports secondary indexes to speed up filtering on non-PK columns.
     * Locking: Row-level locking (instead of partition-level) for better concurrency.
------------------------------------------------------------------------------- */
-- Syntax Check Only
/*
CREATE OR REPLACE HYBRID TABLE test_hybrid_table (
    order_id INT,
    customer_name VARCHAR(50),
    amount DECIMAL(10, 2),
    PRIMARY KEY(order_id),
    INDEX idx_cust_name(customer_name)
);
*/

/* -----------------------------------------------------------------------------
   CLEANUP
------------------------------------------------------------------------------- */
-- DROP TABLE IF EXISTS &{database_name}.&{schema_name}.MY_PERM_TABLE;
-- DROP TABLE IF EXISTS &{database_name}.&{schema_name}.MY_TRANS_TABLE;
-- DROP TABLE IF EXISTS &{database_name}.&{schema_name}.MY_TEMP_TABLE;
-- DROP EXTERNAL TABLE IF EXISTS &{database_name}.&{schema_name}.MY_EXT_TABLE;
-- DROP DYNAMIC TABLE IF EXISTS &{database_name}.&{schema_name}.MY_DYN_TABLE;
-- DROP STAGE IF EXISTS &{database_name}.&{schema_name}.MY_DIR_STAGE;