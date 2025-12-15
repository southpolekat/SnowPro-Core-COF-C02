!source ../variables.sql

/* -----------------------------------------------------------------------------
   EXTERNAL TABLES (Data Lake Querying)
   Requires SYSADMIN role.
   
   Features covered:
   1. Creating an External Stage (Reused)
   2. Creating an External Table (Schema-on-Read)
   3. Manual Refresh (Syncing Metadata)
   4. Querying and Performance
------------------------------------------------------------------------------- */

USE ROLE SYSADMIN;
USE WAREHOUSE &{warehouse_name};
USE DATABASE &{database_name};
USE SCHEMA &{schema_name};

/* -----------------------------------------------------------------------------
   STEP 1: PREPARE STAGE and FORMAT
   We reuse the S3 Integration and Stage from external_stages.sql.
------------------------------------------------------------------------------- */

-- 1. Create File Format (Standard CSV)
CREATE FILE FORMAT IF NOT EXISTS &{database_name}.&{schema_name}.MY_CSV_FORMAT
    TYPE = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 0; -- Your test.csv has no header

-- 2. Ensure Stage Exists (Pointing to your bucket)
-- Note: Requires the 's3_int' integration we created earlier.
CREATE STAGE IF NOT EXISTS &{database_name}.&{schema_name}.my_s3_stage
    STORAGE_INTEGRATION = s3_int
    URL = 's3://snowpro-core-test-bucket/'
    FILE_FORMAT = &{database_name}.&{schema_name}.MY_CSV_FORMAT;


/* -----------------------------------------------------------------------------
   STEP 2: CREATE THE EXTERNAL TABLE
   * Syntax: You must define the columns and map them to the file positions ($1, $2).
   * LOCATION: Points to the stage (@my_s3_stage).
   * AUTO_REFRESH = FALSE: Because we haven't configured SQS notifications.
------------------------------------------------------------------------------- */

CREATE OR REPLACE EXTERNAL TABLE &{database_name}.&{schema_name}.MY_EXT_TABLE (
    CUST_ID INT AS (value:c1::INT),
    CUST_NAME VARCHAR AS (value:c2::VARCHAR),
    REGION VARCHAR AS (value:c3::VARCHAR)
)
    LOCATION = @&{database_name}.&{schema_name}.my_s3_stage
    FILE_FORMAT = &{database_name}.&{schema_name}.MY_CSV_FORMAT
    AUTO_REFRESH = FALSE;

-- Verification
-- Note specific icon or type in the output
SHOW EXTERNAL TABLES LIKE 'MY_EXT_TABLE';


/* -----------------------------------------------------------------------------
   STEP 3: SYNC METADATA (REFRESH)
   Like Snowpipe, the External Table needs to know which files exist.
   Since we turned off Auto-Refresh, we must manually tell it to scan the bucket.
------------------------------------------------------------------------------- */

ALTER EXTERNAL TABLE &{database_name}.&{schema_name}.MY_EXT_TABLE REFRESH;


/* -----------------------------------------------------------------------------
   STEP 4: QUERY THE DATA
   Now we query it just like a regular table.
   * Note: The data is NOT in Snowflake. It is being read from S3 on-the-fly.
------------------------------------------------------------------------------- */

SELECT * FROM &{database_name}.&{schema_name}.MY_EXT_TABLE;

-- You can also see the hidden metadata column (Filename)
SELECT 
    metadata$filename, 
    metadata$file_row_number, 
    CUST_NAME 
FROM &{database_name}.&{schema_name}.MY_EXT_TABLE;


/* -----------------------------------------------------------------------------
   CLEANUP
------------------------------------------------------------------------------- */
-- DROP EXTERNAL TABLE IF EXISTS &{database_name}.&{schema_name}.MY_EXT_TABLE;