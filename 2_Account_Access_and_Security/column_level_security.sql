/* Column-Level Security (CLS) Test Script
    * Demonstrates segregation of duties (SYSADMIN creates, SECURITYADMIN grants, 
    * governance_role manages policy, ROLE_1/ROLE_2 consume masked data).
    * ROLE_1 sees CUST_NAME clearly; ROLE_2 sees CUST_NAME masked.
    * The script will create all necessary roles, databases, policies, and clean up at the end.
*/

-- Define the variables for all objects
!define database_name=SNOWPRO_COF_C02;
!define schema_name=SCHEMA_1;
!define table_name=TABLE_1;
!define warehouse_name=WAREHOUSE_1;

!define security_schema_name=ACCESS_CONTROL;
!define security_policy_name=CLS_MASKING_POLICY;

!define governance_role=governance_role;
!define role_1=ROLE_1;
!define role_2=ROLE_2;

set current_user = current_user();

/* -----------------------------------------------------------------------------    
  SECTION 1: RESOURCE CREATION (Executed by SYSADMIN)
------------------------------------------------------------------------------- */
USE ROLE SYSADMIN;

CREATE OR REPLACE DATABASE &{database_name};
CREATE SCHEMA IF NOT EXISTS &{database_name}.&{schema_name};
-- Create the test table with the sensitive column
CREATE OR REPLACE TABLE &{database_name}.&{schema_name}.&{table_name} (
    CUST_ID INT,
    CUST_NAME VARCHAR, -- This is the column that will be masked
    REGION VARCHAR
);

-- Insert data for testing
INSERT INTO &{database_name}.&{schema_name}.&{table_name} (CUST_ID, CUST_NAME, REGION) VALUES
(1, 'Alice Smith', 'REGION_1'),
(2, 'Bob Johnson', 'REGION_2'),
(3, 'Charlie Brown', 'REGION_1'),
(4, 'David Wilson', 'REGION_3')
;

CREATE SCHEMA IF NOT EXISTS &{database_name}.&{security_schema_name};

-- Create the warehouse (compute layer)
CREATE WAREHOUSE IF NOT EXISTS &{warehouse_name}
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
;

/* -----------------------------------------------------------------------------    
  SECTION 2: ROLE and GRANT SETUP (Executed by SECURITYADMIN)
------------------------------------------------------------------------------- */
USE ROLE SECURITYADMIN;

-- Create the GOVERNANCE Role
CREATE ROLE IF NOT EXISTS &{governance_role};
GRANT USAGE ON DATABASE &{database_name} TO ROLE &{governance_role};
GRANT USAGE ON SCHEMA &{security_schema_name} TO ROLE &{governance_role};
-- REQUIRED: Grant CREATE policy on the schema where the policy definition lives (Schema-Level)
GRANT CREATE MASKING POLICY ON SCHEMA &{database_name}.&{security_schema_name} TO ROLE &{governance_role};
-- REQUIRED: Grant APPLY policy (a global privilege) on the Account (Account-Level)
GRANT APPLY MASKING POLICY ON ACCOUNT TO ROLE &{governance_role};

-- Create the two consumer roles
CREATE OR REPLACE ROLE &{role_1};
CREATE OR REPLACE ROLE &{role_2};

-- Grant necessary privileges to the roles
GRANT USAGE ON WAREHOUSE &{warehouse_name} TO ROLE &{role_1};
GRANT USAGE ON WAREHOUSE &{warehouse_name} TO ROLE &{role_2};
GRANT USAGE ON DATABASE &{database_name} TO ROLE &{role_1};
GRANT USAGE ON DATABASE &{database_name} TO ROLE &{role_2};
GRANT USAGE ON SCHEMA &{database_name}.&{schema_name} TO ROLE &{role_1};
GRANT USAGE ON SCHEMA &{database_name}.&{schema_name} TO ROLE &{role_2};
GRANT SELECT ON TABLE &{database_name}.&{schema_name}.&{table_name} TO ROLE &{role_1};
GRANT SELECT ON TABLE &{database_name}.&{schema_name}.&{table_name} TO ROLE &{role_2};

-- Grant the roles to the current user for testing
GRANT ROLE &{governance_role} TO USER identifier($current_user);
GRANT ROLE &{role_1} TO USER identifier($current_user);
GRANT ROLE &{role_2} TO USER identifier($current_user);

/* -----------------------------------------------------------------------------    
  SECTION 3: CLS POLICY DEFINITION AND APPLICATION (Executed by ROLE_1)
------------------------------------------------------------------------------- */
-- ROLE_1 is now acting as the policy creator/applier (Governance)
USE ROLE &{governance_role};
USE WAREHOUSE &{warehouse_name};

-- 1. Create the MASKING POLICY (CLS)
-- Policy logic: If CURRENT_ROLE() is ROLE_1, show the actual value. Otherwise, mask.
USE SCHEMA &{database_name}.&{security_schema_name};
CREATE OR REPLACE MASKING POLICY &{security_policy_name} AS (CUST_NAME_COL VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN CURRENT_ROLE() = '&{role_1}' THEN CUST_NAME_COL -- Unrestricted View
    ELSE '***'
  END;

-- Apply the MASKING POLICY to the target column
ALTER TABLE &{database_name}.&{schema_name}.&{table_name} MODIFY COLUMN CUST_NAME SET MASKING POLICY &{security_policy_name};

-- Optional: Verify policy creation
SHOW MASKING POLICIES;

/* -----------------------------------------------------------------------------    
  SECTION 4: TEST THE MASKING POLICY
------------------------------------------------------------------------------- */
-- 1. Test A: Unrestricted Role (ROLE_1)
USE ROLE &{role_1};
USE SECONDARY ROLE NONE;

SELECT * FROM &{database_name}.&{schema_name}.&{table_name};

-- 2. Test B: Restricted Role (ROLE_2)
USE ROLE &{role_2};
USE SECONDARY ROLE NONE;

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

ALTER TABLE &{database_name}.&{schema_name}.&{table_name} DROP COLUMN CUST_NAME SET MASKING POLICY &{security_policy_name};
USE SCHEMA &{database_name}.&{security_schema_name};
DROP MASKING POLICY IF EXISTS &{security_policy_name};

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