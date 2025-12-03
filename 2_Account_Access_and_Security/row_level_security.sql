/* Simple test of Row-Level Security (RLS) using a Row Access Policy:
    * Demonstrates segregation of duties (SYSADMIN creates, SECURITYADMIN grants, 
      governance_role manages policy, ROLE_1/ROLE_2 consume filtered data).
    * ROLE_1 is mapped to view REGION_1 data.
    * ROLE_2 is mapped to view REGION_2 data.
*/

/* Define the variables for the database, schema, table, warehouse, etc.
    Variables are expanded by the SnowSQL/Snowflake CLI client before execution.
*/
!define database_name=SNOWPRO_COF_C02;
!define schema_name=SCHEMA_1;
!define table_name=TABLE_1;
!define warehouse_name=WAREHOUSE_1;

!define security_schema_name=ACCESS_CONTROL;
!define security_mapping_table_name=RLS_REGION_MAPPING;
!define security_function_name=RLS_REGION_FUNCTION;
!define security_policy_name=RLS_REGION_POLICY;

!define governance_role=governance_role;
!define role_1=ROLE_1;
!define role_2=ROLE_2;

set current_user = current_user();

/* -----------------------------------------------------------------------------    
  SECTION 1: SETUP THE DATABASE, SCHEMAS, AND TABLES (Executed by SYSADMIN)
------------------------------------------------------------------------------- */
-- SYSADMIN is responsible for creating databases and warehouses.
USE ROLE SYSADMIN;
CREATE OR REPLACE DATABASE &{database_name};
CREATE SCHEMA IF NOT EXISTS &{schema_name};
CREATE TABLE IF NOT EXISTS &{database_name}.&{schema_name}.&{table_name} (
    CUST_ID INT,
    CUST_NAME VARCHAR,
    REGION VARCHAR -- This is the column the RLS policy will filter on
);
-- Insert four records, including one for REGION_3 (should be visible to NO ONE)
INSERT INTO &{database_name}.&{schema_name}.&{table_name} (CUST_ID, CUST_NAME, REGION) VALUES
(1, 'Alice', 'REGION_1'),
(2, 'Bob', 'REGION_2'),
(3, 'Charlie', 'REGION_1'),
(4, 'David', 'REGION_3')
;

CREATE SCHEMA IF NOT EXISTS &{security_schema_name};

-- Create the warehouse (compute layer)
CREATE WAREHOUSE IF NOT EXISTS &{warehouse_name}
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
;

/* -----------------------------------------------------------------------------    
  SECTION 2: SETUP THE ROLES AND GRANTS (Executed by SECURITYADMIN)
------------------------------------------------------------------------------- */
-- SECURITYADMIN manages all roles and grants.
USE ROLE SECURITYADMIN;

-- 1. Create the GOVERNANCE Role
CREATE ROLE IF NOT EXISTS &{governance_role};
GRANT USAGE ON DATABASE &{database_name} TO ROLE &{governance_role};
GRANT USAGE ON SCHEMA &{security_schema_name} TO ROLE &{governance_role};
GRANT CREATE TABLE ON SCHEMA &{security_schema_name} TO ROLE &{governance_role};
GRANT CREATE FUNCTION ON SCHEMA &{security_schema_name} TO ROLE &{governance_role};
-- REQUIRED: Grant CREATE policy on the schema where the policy definition lives (Schema-Level)
GRANT CREATE ROW ACCESS POLICY ON SCHEMA &{database_name}.&{security_schema_name} TO ROLE &{governance_role};
-- REQUIRED: Grant APPLY policy (a global privilege) on the Account (Account-Level)
GRANT APPLY ROW ACCESS POLICY ON ACCOUNT TO ROLE &{governance_role};

-- 2. Create the two restricted consumer roles
CREATE ROLE IF NOT EXISTS &{role_1};
CREATE ROLE IF NOT EXISTS &{role_2};

-- 3. Grant USAGE and SELECT privileges to the consumer roles
GRANT USAGE ON DATABASE &{database_name} TO ROLE &{role_1};
GRANT USAGE ON DATABASE &{database_name} TO ROLE &{role_2};
GRANT USAGE ON SCHEMA &{schema_name} TO ROLE &{role_1};
GRANT USAGE ON SCHEMA &{schema_name} TO ROLE &{role_2};
GRANT SELECT ON TABLE &{database_name}.&{schema_name}.&{table_name} TO ROLE &{role_1};
GRANT SELECT ON TABLE &{database_name}.&{schema_name}.&{table_name} TO ROLE &{role_2}; 

-- 4. Grant Warehouse USAGE (Compute)
GRANT USAGE ON WAREHOUSE &{warehouse_name} TO ROLE &{governance_role};
GRANT USAGE ON WAREHOUSE &{warehouse_name} TO ROLE &{role_1};
GRANT USAGE ON WAREHOUSE &{warehouse_name} TO ROLE &{role_2};

-- 5. Grant the roles to the current user for testing
GRANT ROLE &{governance_role} TO USER identifier($current_user);
GRANT ROLE &{role_1} TO USER identifier($current_user);
GRANT ROLE &{role_2} TO USER identifier($current_user);

/* -----------------------------------------------------------------------------    
  SECTION 3: SETUP AND APPLY THE RLS POLICY (Executed by governance_role)
------------------------------------------------------------------------------- */
-- The GOVERNANCE role defines and applies the policy.
USE ROLE &{governance_role};
USE SECONDARY ROLE NONE;

USE DATABASE &{database_name};
USE SCHEMA &{security_schema_name}; -- Context for policy creation
USE WAREHOUSE &{warehouse_name};

-- 1. Create the MAPPING table
CREATE OR REPLACE TABLE &{security_mapping_table_name} (
    ROLE_NAME VARCHAR,
    REGION VARCHAR
);
-- Map roles to the regions they are allowed to see
INSERT INTO &{security_mapping_table_name} (ROLE_NAME, REGION) VALUES
('&{role_1}', 'REGION_1'),
('&{role_2}', 'REGION_2');

-- 2. Create the Policy Function
-- The function checks if the current role is present in the mapping table for the row's region.
CREATE OR REPLACE FUNCTION &{security_function_name} (REGION_COL VARCHAR)
  RETURNS BOOLEAN
AS
$$
  EXISTS (
    SELECT 1 FROM &{security_mapping_table_name} AS M
    WHERE M.REGION = REGION_COL 
      AND M.ROLE_NAME = CURRENT_ROLE()
  )
$$;

-- 3. Create the ROW ACCESS POLICY (RLS) object
CREATE OR REPLACE ROW ACCESS POLICY &{security_policy_name} AS (REGION_COL VARCHAR) RETURNS BOOLEAN ->
  &{security_function_name}(REGION_COL);

-- Optional: Verify policy creation
SHOW ROW ACCESS POLICIES;

-- 4. APPLY the RLS policy to the table (Requires APPLY ROW ACCESS POLICY privilege)
ALTER TABLE &{database_name}.&{schema_name}.&{table_name} ADD ROW ACCESS POLICY &{security_policy_name} ON (REGION);

/* -----------------------------------------------------------------------------    
  SECTION 4: TEST THE RLS POLICY (Executed by the current user switching roles)
------------------------------------------------------------------------------- */
-- Test the RLS policy using role_1 (Should see 2 rows: Alice, Charlie)
USE ROLE &{role_1};
USE SECONDARY ROLE NONE;

-- Expected: 2 (The RLS policy is applied)
SELECT count(*) FROM &{database_name}.&{schema_name}.&{table_name}; 
-- Expected: Alice (REGION_1), Charlie (REGION_1)
SELECT * FROM &{database_name}.&{schema_name}.&{table_name};

-- Test the RLS policy using role_2 (Should see 1 row: Bob)
USE ROLE &{role_2};
USE SECONDARY ROLE NONE;

-- Expected: 1 (The RLS policy is applied)
SELECT count(*) FROM &{database_name}.&{schema_name}.&{table_name};
-- Expected: Bob (REGION_2)
SELECT * FROM &{database_name}.&{schema_name}.&{table_name};

/* -----------------------------------------------------------------------------    
  SECTION 5: CLEANUP
------------------------------------------------------------------------------- */
!quit -- UNCOMMENT THIS LINE TO STOP THE SCRIPT HERE BEFORE CLEANUP

-- Cleanup requires switching roles with specific privileges (SECURITYADMIN or OWNER)

-- 1. Unset and Drop the Policy objects (requires GOVERNANCE_ROLE)
USE ROLE &{governance_role};
USE SECONDARY ROLE NONE;
USE SCHEMA &{database_name}.&{schema_name}; 

ALTER TABLE &{table_name} DROP ROW ACCESS POLICY &{security_policy_name};
USE SCHEMA &{database_name}.&{security_schema_name};
DROP ROW ACCESS POLICY IF EXISTS &{security_policy_name};
DROP FUNCTION IF EXISTS &{security_function_name}(VARCHAR);
DROP TABLE IF EXISTS &{security_mapping_table_name};

-- 2. Drop the Roles (requires SECURITYADMIN)
USE ROLE SECURITYADMIN;
DROP ROLE IF EXISTS &{governance_role};
DROP ROLE IF EXISTS &{role_1};
DROP ROLE IF EXISTS &{role_2};

-- 3. Drop Database and Warehouse (requires SYSADMIN)
USE ROLE SYSADMIN;
USE SECONDARY ROLE NONE;
DROP DATABASE IF EXISTS &{database_name};
DROP WAREHOUSE IF EXISTS &{warehouse_name};