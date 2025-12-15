!source ../variables.sql

/* -----------------------------------------------------------------------------
   ICEBERG TABLES
   Requires ACCOUNTADMIN (for Volume) and SYSADMIN (for Table).
   
   Features covered:
   1. Creating an External Volume (The connector for Iceberg)
   2. Creating an Iceberg Table (Snowflake-managed Catalog)
   3. Performing DML (Insert/Update) - Yes, you can WRITE to these!
------------------------------------------------------------------------------- */

USE WAREHOUSE &{warehouse_name};
USE DATABASE &{database_name};
USE SCHEMA &{schema_name};

/* -----------------------------------------------------------------------------
   STEP 1: CREATE EXTERNAL VOLUME
   This defines WHERE Snowflake writes the Parquet files in your bucket.
------------------------------------------------------------------------------- */
USE ROLE ACCOUNTADMIN;

CREATE EXTERNAL VOLUME IF NOT EXISTS my_iceberg_vol
   STORAGE_LOCATIONS =
      (
         (
            NAME = 'my-s3-us-east-1',
            STORAGE_PROVIDER = 'S3',
            STORAGE_BASE_URL = 's3://snowpro-core-test-bucket/iceberg/',
            STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:role/Snowflake-Access-Role' -- Reuse your Role ARN
         )
      );

/* -----------------------------------------------------------------------------
   STEP 1.5: THE HANDSHAKE (RE-REQUIRED)
   The External Volume creates a NEW Identity. You must trust it in AWS.
   
   1. Run: DESC EXTERNAL VOLUME my_iceberg_vol;
   2. Get 'STORAGE_AWS_IAM_USER_ARN' and 'STORAGE_AWS_EXTERNAL_ID'.
   3. Update your AWS IAM Role Trust Policy (add this new user or replace the old one).
------------------------------------------------------------------------------- */
DESC EXTERNAL VOLUME my_iceberg_vol;

/* -----------------------------------------------------------------------------
   STEP 2: CREATE THE ICEBERG TABLE
   * CATALOG = 'SNOWFLAKE': Snowflake manages the metadata (easy mode).
   * BASE_LOCATION: The folder inside the volume where this table lives.
------------------------------------------------------------------------------- */
USE ROLE SYSADMIN;

CREATE OR REPLACE ICEBERG TABLE &{database_name}.&{schema_name}.MY_ICEBERG_TABLE (
    ID INT,
    NAME STRING,
    CITY STRING
)
    CATALOG = 'SNOWFLAKE'
    EXTERNAL_VOLUME = 'my_iceberg_vol'
    BASE_LOCATION = 'my_iceberg_table/';


/* -----------------------------------------------------------------------------
   STEP 3: TEST DML (INSERT and UPDATE)
   Unlike External Tables (Read-Only), Iceberg tables support full DML.
   Snowflake will generate Parquet files in your S3 bucket immediately.
------------------------------------------------------------------------------- */

INSERT INTO &{database_name}.&{schema_name}.MY_ICEBERG_TABLE VALUES 
    (1, 'Alice', 'New York'),
    (2, 'Bob', 'London');

UPDATE &{database_name}.&{schema_name}.MY_ICEBERG_TABLE 
SET CITY = 'Paris' WHERE ID = 2;

-- Verify
SELECT * FROM &{database_name}.&{schema_name}.MY_ICEBERG_TABLE;

/* -----------------------------------------------------------------------------
   CLEANUP
------------------------------------------------------------------------------- */
-- DROP ICEBERG TABLE IF EXISTS &{database_name}.&{schema_name}.MY_ICEBERG_TABLE;
-- USE ROLE ACCOUNTADMIN;
-- DROP EXTERNAL VOLUME IF EXISTS my_iceberg_vol;