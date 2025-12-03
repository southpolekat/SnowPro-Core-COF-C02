/* 
    Simple test of row level security (RLS):
    * A governance role that configures the row level security policies.
    * ROLE_1 can view region 1 data
    * ROLE_2 can view region 2 data
    * For simplicity, all roles are granted to the current user.
*/

/* 
    Define the variables for the database, schema, table, warehouse, etc.
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
  SECTION 1: SETUP THE DATABASE AND SCHEMAS AND TABLES USING THE SYSADMIN ROLE
------------------------------------------------------------------------------- */
USE ROLE SYSADMIN;
CREATE OR REPLACE DATABASE &{database_name};
CREATE SCHEMA IF NOT EXISTS &{schema_name};
CREATE TABLE IF NOT EXISTS &{database_name}.&{schema_name}.&{table_name} (
    CUST_ID INT,
    CUST_NAME VARCHAR,
    REGION VARCHAR
);
INSERT INTO &{database_name}.&{schema_name}.&{table_name} (CUST_ID, CUST_NAME, REGION) VALUES
(1, 'Alice', 'REGION_1'),
(2, 'Bob', 'REGION_2'),
(3, 'Charlie', 'REGION_1'),
(4, 'David', 'REGION_3')
;

CREATE SCHEMA IF NOT EXISTS &{security_schema_name};

CREATE WAREHOUSE IF NOT EXISTS &{warehouse_name}
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
;

/* -----------------------------------------------------------------------------    
  SECTION 2: SETUP THE ROLES AND GRANTS USING THE SECURITYADMIN ROLE
------------------------------------------------------------------------------- */
USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS &{governance_role};
GRANT USAGE ON DATABASE &{database_name} TO ROLE &{governance_role};
GRANT USAGE ON SCHEMA &{security_schema_name} TO ROLE &{governance_role};
GRANT CREATE TABLE ON SCHEMA &{security_schema_name} TO ROLE &{governance_role};
GRANT CREATE FUNCTION ON SCHEMA &{security_schema_name} TO ROLE &{governance_role};
GRANT CREATE ROW ACCESS POLICY ON SCHEMA &{security_schema_name} TO ROLE &{governance_role};
GRANT APPLY ROW ACCESS POLICY ON ACCOUNT TO ROLE &{governance_role};

CREATE ROLE IF NOT EXISTS &{role_1};
CREATE ROLE IF NOT EXISTS &{role_2};
GRANT USAGE ON DATABASE &{database_name} TO ROLE &{role_1};
GRANT USAGE ON DATABASE &{database_name} TO ROLE &{role_2};
GRANT USAGE ON SCHEMA &{schema_name} TO ROLE &{role_1};
GRANT USAGE ON SCHEMA &{schema_name} TO ROLE &{role_2};
GRANT SELECT ON TABLE &{database_name}.&{schema_name}.&{table_name} TO ROLE &{role_1};
GRANT SELECT ON TABLE &{database_name}.&{schema_name}.&{table_name} TO ROLE &{role_2}; 

GRANT USAGE ON WAREHOUSE &{warehouse_name} TO ROLE &{governance_role};
GRANT USAGE ON WAREHOUSE &{warehouse_name} TO ROLE &{role_1};
GRANT USAGE ON WAREHOUSE &{warehouse_name} TO ROLE &{role_2};

-- Grant the roles to the current user
GRANT ROLE &{governance_role} TO USER identifier($current_user);
GRANT ROLE &{role_1} TO USER identifier($current_user);
GRANT ROLE &{role_2} TO USER identifier($current_user);

/* -----------------------------------------------------------------------------    
  SECTION 3: SETUP THE ROW LEVEL SECURITY POLICIES USING THE GOVERNANCE ROLE
------------------------------------------------------------------------------- */
USE ROLE &{governance_role};
USE SECONDARY ROLE NONE;

USE DATABASE &{database_name};
USE SCHEMA &{security_schema_name};
USE WAREHOUSE &{warehouse_name};

CREATE OR REPLACE TABLE &{security_mapping_table_name} (
    ROLE_NAME VARCHAR,
    REGION VARCHAR
);
INSERT INTO &{security_mapping_table_name} (ROLE_NAME, REGION) VALUES
('&{role_1}', 'REGION_1'),
('&{role_2}', 'REGION_2');

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

-- Create the ROW ACCESS POLICY (RLS)
CREATE OR REPLACE ROW ACCESS POLICY &{security_policy_name} AS (REGION_COL VARCHAR) RETURNS BOOLEAN ->
  &{security_function_name}(REGION_COL);

SHOW ROW ACCESS POLICIES;

-- APPLY the RLS policy to the table
ALTER TABLE &{database_name}.&{schema_name}.&{table_name} ADD ROW ACCESS POLICY &{security_policy_name} ON (REGION);

/* -----------------------------------------------------------------------------    
  SECTION 4: TEST THE RLS POLICY USING THE ROLE_1 and ROLE_2
------------------------------------------------------------------------------- */
USE ROLE &{role_1};
USE SECONDARY ROLE NONE;

SELECT count(*) FROM &{database_name}.&{schema_name}.&{table_name};
SELECT * FROM &{database_name}.&{schema_name}.&{table_name};

-- Test the RLS policy using role_2
USE ROLE &{role_2};
USE SECONDARY ROLE NONE;

SELECT count(*) FROM &{database_name}.&{schema_name}.&{table_name};
SELECT * FROM &{database_name}.&{schema_name}.&{table_name};

/* -----------------------------------------------------------------------------    
  SECTION 5: CLEANUP
------------------------------------------------------------------------------- */
!quit -- comment this line to clean up everything
USE ROLE &{governance_role};
USE SECONDARY ROLE NONE;

ALTER TABLE &{database_name}.&{schema_name}.&{table_name} DROP ROW ACCESS POLICY &{security_policy_name};
DROP ROW ACCESS POLICY IF EXISTS &{security_policy_name};
DROP FUNCTION IF EXISTS &{security_function_name}(VARCHAR);
DROP TABLE IF EXISTS &{security_mapping_table_name};

USE ROLE SECURITYADMIN;
DROP ROLE IF EXISTS &{governance_role};
DROP ROLE IF EXISTS &{role_1};
DROP ROLE IF EXISTS &{role_2};

USE ROLE SYSADMIN;
USE SECONDARY ROLE NONE;
DROP DATABASE IF EXISTS &{database_name};
DROP WAREHOUSE IF EXISTS &{warehouse_name};
