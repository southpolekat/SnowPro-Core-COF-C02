!source ../variables.sql
--!source ../setup_db_objects.sql

/* -----------------------------------------------------------------------------
   INTERNAL STAGES and DATA LOADING
   Requires SYSADMIN role.
   
   Features covered:
   1. User Stages (Personal Storage)
   2. Table Stages (Table-bound Storage)
   3. Named Internal Stages (Shared Storage)
   4. Querying Staged Data (Metadata and Columns)
   5. Loading Data with Error Handling (COPY INTO)
------------------------------------------------------------------------------- */

USE ROLE SYSADMIN;
USE WAREHOUSE &{warehouse_name};
USE DATABASE &{database_name};
USE SCHEMA &{schema_name};

/* -----------------------------------------------------------------------------
   PREPARE a test csv file /tmp/test.csv
1,Alice,REGION_1
2,Bob,REGION_2
3,Charlie,REGION_1
4,David,REGION_3
------------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   FEATURE 1: USER STAGES (@~)
   Scenario: You need a personal scratchpad to upload files quickly for your own use.
   * Automatically available for every user.
   * No setup required.
   * References using tilde (~).
------------------------------------------------------------------------------- */

-- COPY the test.csv to your personal user stage
-- snowsql -c <connection_name> -q 'PUT file:///tmp/test.csv @~'

-- List files in your personal user stage
LIST @~;

/* -----------------------------------------------------------------------------
   FEATURE 2: TABLE STAGES (@%)
   Scenario: You want to store data files specifically allocated to one table.
   * Created automatically when a table is created.
   * Only accessible by users with privileges on this specific table.
------------------------------------------------------------------------------- */

-- COPY the test.csv to the table's stage, two ways
-- snowsql -c <connection_name> -q 'PUT file:///tmp/test.csv @&{database_name}.&{schema_name}.%&{table_name}'
-- snowsql -c <connection_name> -d &{database_name} -s &{schema_name} -q 'PUT file:///tmp/test.csv @%&{table_name}'

-- List files in the table's stage
LIST @%&{table_name};

/* -----------------------------------------------------------------------------
   FEATURE 3: NAMED INTERNAL STAGES
   Scenario: You need a centralized storage location accessible by multiple users/tables.
   * Requires explicit creation.
   * Can have specific file formats and copy options attached.
------------------------------------------------------------------------------- */

-- Create a specific file format first
CREATE OR REPLACE FILE FORMAT &{database_name}.&{schema_name}.MY_CSV_FORMAT
    TYPE = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 0;

-- Create the Named Stage using the file format
CREATE STAGE IF NOT EXISTS &{database_name}.&{schema_name}.&{stage_name}
    FILE_FORMAT = &{database_name}.&{schema_name}.MY_CSV_FORMAT
    COMMENT = 'Internal stage for testing data loads';

-- COPY the test.csv to the named stage
-- snowsql -c <connection_name> -d &{database_name} -s &{schema_name} -q 'PUT file:///tmp/test.csv @&{stage_name}'

-- Verification
SHOW STAGES LIKE '&{stage_name}';

-- List files in the named stage
LIST @&{database_name}.&{schema_name}.&{stage_name};

/* -----------------------------------------------------------------------------
   FEATURE 4: QUERYING STAGED DATA
   Scenario: You want to inspect file contents WITHOUT loading them into a table yet.
   * Useful for validation.
   * Access metadata columns (Filename, Row Number).
------------------------------------------------------------------------------- */

-- Query columns $1, $2 and Metadata from the stage
-- Note: This requires a file to be present in the stage.
SELECT 
    t.$1 AS ID, 
    t.$2 AS NAME,
    t.$3 AS REGION,
    METADATA$FILENAME,
    METADATA$FILE_ROW_NUMBER
FROM @&{database_name}.&{schema_name}.&{stage_name} (file_format => '&{database_name}.&{schema_name}.MY_CSV_FORMAT') t;

/* -----------------------------------------------------------------------------
   FEATURE 5: LOADING DATA (COPY INTO)
   Scenario: Bulk load data from the stage into the table with error handling.
   * FORCE = TRUE: Reloads files even if loaded < 64 days ago.
   * ON_ERROR: Manages how the load reacts to bad data.
------------------------------------------------------------------------------- */

-- clear existing data from the table
TRUNCATE TABLE &{database_name}.&{schema_name}.&{table_name};

-- Run the Bulk Load
COPY INTO &{database_name}.&{schema_name}.&{table_name}
    FROM @&{database_name}.&{schema_name}.&{stage_name}
    FILE_FORMAT = (FORMAT_NAME = '&{database_name}.&{schema_name}.MY_CSV_FORMAT')
    ON_ERROR = 'SKIP_FILE_1' -- Skip the file if 1 or more errors are found
    FORCE = TRUE;            -- Ignore load history

-- Verify Data
SELECT * FROM &{database_name}.&{schema_name}.&{table_name};

/* -----------------------------------------------------------------------------
   CLEANUP
------------------------------------------------------------------------------- */
--!source ../cleanup_db_objects.sql