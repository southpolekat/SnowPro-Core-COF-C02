-- Script to setup the object tags
!source setup_db_objects.sql

/* -----------------------------------------------------------------------------
  GRANT PRIVILEGES TO DATA GOVERNANCE ROLE TO MANAGE OBJECT TAGS
------------------------------------------------------------------------------- */
use role securityadmin;

GRANT CREATE TAG ON SCHEMA &{database_name}.&{governance_schema_name} TO ROLE &{governance_role};
GRANT APPLY TAG ON ACCOUNT TO ROLE &{governance_role};

/* -----------------------------------------------------------------------------
  SETUP THE OBJECT TAGS
------------------------------------------------------------------------------- */
use role &{governance_role};
use secondary role none;

use schema &{database_name}.&{governance_schema_name};

CREATE OR REPLACE TAG DATA_SENSITIVITY 
    ALLOWED_VALUES 'RESTRICTED', 'INTERNAL', 'CONFIDENTIAL', 'PUBLIC';

CREATE OR REPLACE TAG COST_CENTER;

SHOW TAGS;

/* -----------------------------------------------------------------------------
  APPLY THE OBJECT TAGS
------------------------------------------------------------------------------- */
use role &{governance_role};

-- 1. Apply to a Table
ALTER TABLE &{database_name}.&{schema_name}.&{table_name} 
    SET TAG DATA_SENSITIVITY = 'CONFIDENTIAL', COST_CENTER = 'FINANCE';

-- 2. Apply to a Column
ALTER TABLE &{database_name}.&{schema_name}.&{table_name} 
    MODIFY COLUMN CUST_NAME SET TAG DATA_SENSITIVITY = 'RESTRICTED';

-- 3. Apply to a Warehouse (for cost attribution)
ALTER WAREHOUSE &{warehouse_name} 
    SET TAG COST_CENTER = 'ENGINEERING';

-- 4. Apply to a Role
ALTER ROLE &{role_name} 
    SET TAG COST_CENTER = 'ANALYTICS';

/* -----------------------------------------------------------------------------
  GET THE OBJECT TAGS
------------------------------------------------------------------------------- */
use role &{governance_role};
use warehouse &{warehouse_name};

SELECT SYSTEM$GET_TAG('DATA_SENSITIVITY', '&{database_name}.&{schema_name}.&{table_name}', 'TABLE');
SELECT SYSTEM$GET_TAG('COST_CENTER', '&{database_name}.&{schema_name}.&{table_name}', 'TABLE');
SELECT SYSTEM$GET_TAG('DATA_SENSITIVITY', '&{database_name}.&{schema_name}.&{table_name}.CUST_NAME', 'COLUMN');
SELECT SYSTEM$GET_TAG('COST_CENTER', '&{warehouse_name}', 'WAREHOUSE');
SELECT SYSTEM$GET_TAG('COST_CENTER', '&{role_name}', 'ROLE');

-- Get from information schema
SELECT * FROM table(&{database_name}.information_schema.tag_references('&{database_name}.&{schema_name}.&{table_name}', 'table'));
SELECT * FROM table(&{database_name}.information_schema.tag_references('&{database_name}.&{schema_name}.&{table_name}.CUST_NAME', 'column'));

-- Use ACCOUNTADMIN or a role with access to SNOWFLAKE.ACCOUNT_USAGE
-- Note: This view is updated with a delay (up to ? hour)
USE ROLE ACCOUNTADMIN; 
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.TAGS;
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES;

/* -----------------------------------------------------------------------------
  Sample code to get warehouse cost using cost center tag
------------------------------------------------------------------------------- */
SELECT SUM(CREDITS_USED) FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY W
INNER JOIN SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES T
    ON W.WAREHOUSE_NAME = T.OBJECT_NAME
    AND T.TAG_NAME = 'COST_CENTER'
    AND T.DOMAIN = 'WAREHOUSE'
    AND T.TAG_VALUE = 'ENGINEERING'
;

/* -----------------------------------------------------------------------------
   Notes: Query Tag vs Object Tag
   Query Tag:
   - Goal: Track Activity, Usage, and Cost associated with compute time.
   - Scope: Applies to a single query or a user's current session.
   - Mechanism: Set using the QUERY_TAG session parameter.
   - Data Location: Found in the QUERY_TAG column within the Query History (Account Usage).
   - Persistence: Temporary; is not attached to the underlying data.

Object Tag:
   - Goal: Enforce Data Governance, Classification, and Compliance.
   - Scope: Applies to a securable object (Table, Column, Database, Warehouse, Role, etc.).
   - Mechanism: Set using DDL (ALTER [OBJECT] SET TAG...).
   - Data Location: Found in the TAG_REFERENCES view (Account Usage).
   - Persistence: Permanent; remains attached to the object until explicitly unset.
------------------------------------------------------------------------------- */

-- cleanup
--!quit -- UNCOMMENT THIS LINE TO STOP THE SCRIPT HERE BEFORE CLEANUP
!source cleanup_db_objects.sql