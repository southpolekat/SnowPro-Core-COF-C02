!source ../variables.sql

USE ROLE ACCOUNTADMIN;
GRANT USAGE ON INTEGRATION s3_int TO ROLE SYSADMIN;

USE ROLE SYSADMIN;
USE WAREHOUSE &{warehouse_name};
USE DATABASE &{database_name};
USE SCHEMA &{schema_name};

/* -----------------------------------------------------------------------------
   STEP 1: CREATE TARGET TABLE
   We need a fresh table to prove the data is coming from the Pipe, 
------------------------------------------------------------------------------- */
CREATE OR REPLACE TABLE &{database_name}.&{schema_name}.PIPE_TEST_TABLE (
    COL1 STRING,
    COL2 STRING,
    COL3 STRING,
    LOAD_TIME TIMESTAMP_LTZ
);

/* -----------------------------------------------------------------------------
   STEP 2: CREATE THE PIPE
   Note: We reuse the integration 's3_int' you created earlier.
------------------------------------------------------------------------------- */
CREATE OR REPLACE PIPE &{database_name}.&{schema_name}.MY_CSV_PIPE
    AUTO_INGEST = TRUE
    AS
    COPY INTO &{database_name}.&{schema_name}.PIPE_TEST_TABLE
    FROM (
        SELECT $1, $2, $3, CURRENT_TIMESTAMP()
        FROM @&{database_name}.&{schema_name}.my_s3_stage
    )
    FILE_FORMAT = (TYPE = 'CSV');

/* -----------------------------------------------------------------------------
   STEP 3: THE "MAGIC" COMMAND (REFRESH)
   Since 'test.csv' is already there, we manually tell the pipe:
   "Go look at the stage and process anything you haven't seen before."
------------------------------------------------------------------------------- */

ALTER PIPE &{database_name}.&{schema_name}.MY_CSV_PIPE REFRESH;

-- Check the pipe status
SELECT SYSTEM$PIPE_STATUS('&{database_name}.&{schema_name}.MY_CSV_PIPE');

/* -----------------------------------------------------------------------------
   STEP 4: VERIFY
   Wait 10-20 seconds, then run this.
------------------------------------------------------------------------------- */

SELECT * FROM &{database_name}.&{schema_name}.PIPE_TEST_TABLE;