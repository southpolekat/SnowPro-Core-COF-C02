-- Script to setup the database, schemas, tables, views, roles, functions, and warehouse
!source variables.sql

/* -----------------------------------------------------------------------------
  SETUP THE DATABASE, SCHEMAS, TABLES, VIEWS, WAREHOUE
------------------------------------------------------------------------------- */
use role sysadmin;
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

CREATE SCHEMA IF NOT EXISTS &{database_name}.&{governance_schema_name};

CREATE WAREHOUSE IF NOT EXISTS &{warehouse_name}
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
;

/* -----------------------------------------------------------------------------
   SETUP USER AND ROLES
------------------------------------------------------------------------------- */
use role securityadmin;
CREATE ROLE IF NOT EXISTS &{role_name};
GRANT USAGE ON DATABASE &{database_name} TO ROLE &{role_name};
GRANT USAGE ON SCHEMA &{database_name}.&{schema_name} TO ROLE &{role_name};
GRANT SELECT ON FUTURE TABLES IN SCHEMA &{database_name}.&{schema_name} TO ROLE &{role_name};
GRANT SELECT ON FUTURE VIEWS IN SCHEMA &{database_name}.&{schema_name} TO ROLE &{role_name};
GRANT USAGE ON FUTURE FUNCTIONS IN SCHEMA &{database_name}.&{schema_name} TO ROLE &{role_name};
GRANT USAGE ON WAREHOUSE &{warehouse_name} TO ROLE &{role_name};

GRANT ROLE &{role_name} TO USER identifier($current_user);

/* -----------------------------------------------------------------------------
   SETUP Data Governance Role, Schema
------------------------------------------------------------------------------- */
use role securityadmin;

CREATE ROLE IF NOT EXISTS &{governance_role};
GRANT USAGE ON DATABASE &{database_name} TO ROLE &{governance_role};
GRANT USAGE ON SCHEMA &{database_name}.&{governance_schema_name} TO ROLE &{governance_role};
GRANT USAGE ON WAREHOUSE &{warehouse_name} TO ROLE &{governance_role};

GRANT ROLE &{governance_role} TO USER identifier($current_user);