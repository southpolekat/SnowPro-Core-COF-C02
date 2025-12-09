
!define database_name=SNOWPRO_COF_C02;
!define warehouse_name=WAREHOUSE_1;
!define schema_name=SCHEMA_1;
!define table_name=TABLE_1;
!define view_name=VIEW_1;
!define role_name=ROLE_1;
!define secure_view_name=SECURE_VIEW_1;
!define secure_function_name=SECURE_FUNCTION_1;

set current_user = current_user();

/* -----------------------------------------------------------------------------
  SETUP THE WAREHOUSE, DATABASE, SCHEMAS, TABLES, AND VIEWS
------------------------------------------------------------------------------- */
USE ROLE SYSADMIN;
CREATE WAREHOUSE IF NOT EXISTS &{warehouse_name}
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
;
CREATE DATABASE IF NOT EXISTS &{database_name};
CREATE SCHEMA IF NOT EXISTS &{database_name}.&{schema_name};
CREATE TABLE IF NOT EXISTS &{database_name}.&{schema_name}.&{table_name} (
    CUST_ID INT,
    CUST_NAME VARCHAR,
    REGION VARCHAR
);
INSERT INTO &{database_name}.&{schema_name}.&{table_name} (CUST_ID, CUST_NAME, REGION) VALUES
(1, 'Alice', 'REGION_1'),
(2, 'Bob', 'REGION_2'),
(3, 'Charlie', 'REGION_1'),
(4, 'David', 'REGION_3');

/* -----------------------------------------------------------------------------
   SETUP ROLES AND GRANTS
------------------------------------------------------------------------------- */
USE ROLE SECURITYADMIN;
CREATE ROLE IF NOT EXISTS &{role_name};
GRANT USAGE ON DATABASE &{database_name} TO ROLE &{role_name};
GRANT USAGE ON SCHEMA &{database_name}.&{schema_name} TO ROLE &{role_name};
GRANT SELECT ON FUTURE TABLES IN SCHEMA &{database_name}.&{schema_name} TO ROLE &{role_name};
GRANT SELECT ON FUTURE VIEWS IN SCHEMA &{database_name}.&{schema_name} TO ROLE &{role_name};
GRANT USAGE ON WAREHOUSE &{warehouse_name} TO ROLE &{role_name};

GRANT ROLE &{role_name} TO USER identifier($current_user);

/* -----------------------------------------------------------------------------
   Test normal view and secure view
------------------------------------------------------------------------------- */
USE ROLE SYSADMIN;

CREATE VIEW IF NOT EXISTS &{database_name}.&{schema_name}.&{view_name} AS
SELECT * FROM &{database_name}.&{schema_name}.&{table_name};

CREATE OR REPLACE SECURE VIEW &{database_name}.&{schema_name}.&{secure_view_name} AS
SELECT * FROM &{database_name}.&{schema_name}.&{table_name};

USE ROLE &{role_name};
USE SECONDARY ROLE NONE;
USE WAREHOUSE &{warehouse_name};

SELECT * FROM &{database_name}.&{schema_name}.&{view_name};
SELECT * FROM &{database_name}.&{schema_name}.&{secure_view_name};

SELECT GET_DDL('VIEW', '&{database_name}.&{schema_name}.&{view_name}');
-- SELECT GET_DDL('VIEW', '&{database_name}.&{schema_name}.&{secure_view_name}');
-- Error: Object does not exist, or operation cannot be performed.

/* -----------------------------------------------------------------------------
   CLEANUP
------------------------------------------------------------------------------- */
--!quit -- UNCOMMENT THIS LINE TO STOP THE SCRIPT HERE BEFORE CLEANUP

USE ROLE SECURITYADMIN;
DROP ROLE IF EXISTS &{role_name};

USE ROLE SYSADMIN;
DROP DATABASE IF EXISTS &{database_name};
DROP WAREHOUSE IF EXISTS &{warehouse_name};