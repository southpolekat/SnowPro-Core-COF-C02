
!define database_name=SNOWPRO_COF_C02;
!define security_schema_name=ACCESS_CONTROL;
!define security_role=SECURITY_ADMIN;
!define policy_1_name=all_users_ui_authentication_policy;
!define policy_2_name=service_users_authentication_policy;

set current_user = current_user();

use role sysadmin;

create database if not exists &{database_name};
USE DATABASE &{database_name};

create schema if not exists &{security_schema_name};
USE SCHEMA &{security_schema_name};

use role securityadmin;
/* -----------------------------------------------------------------------------
  CREATE THE SECURITY ROLE
------------------------------------------------------------------------------- */
CREATE ROLE IF NOT EXISTS &{security_role};
GRANT USAGE ON DATABASE &{database_name} TO ROLE &{security_role};
GRANT USAGE ON SCHEMA &{security_schema_name} TO ROLE &{security_role};
GRANT CREATE AUTHENTICATION POLICY ON SCHEMA &{security_schema_name} TO ROLE &{security_role};
GRANT APPLY AUTHENTICATION POLICY ON ACCOUNT TO ROLE &{security_role};

GRANT ROLE &{security_role} TO USER identifier($current_user);

/* -----------------------------------------------------------------------------
  Policy 1: Create an authentication policy that allows users to authenticate using Snowflake UI or snowsql with SAML or PASSWORD.
------------------------------------------------------------------------------- */
USE ROLE &{security_role};
CREATE AUTHENTICATION POLICY IF NOT EXISTS &{policy_1_name}
  CLIENT_TYPES = ('SNOWFLAKE_UI', 'SNOWSQL')
  AUTHENTICATION_METHODS = ('SAML', 'PASSWORD');

-- Apply the authentication policy to the account or user level
ALTER ACCOUNT SET AUTHENTICATION POLICY &{policy_1_name};
-- ALTER USER USER_1 SET AUTHENTICATION POLICY snowflake_ui_authentication_policy;

-- Add exception for specific users to bypass the authentication policy
ALTER USER identifier($current_user) UNSET AUTHENTICATION POLICY;

/* -----------------------------------------------------------------------------
  Policy 2: Create an authentication policy that all service users authenticate using snowsql with key pair authentication.
------------------------------------------------------------------------------- */
USE ROLE &{security_role};
CREATE AUTHENTICATION POLICY IF NOT EXISTS &{policy_2_name}
  CLIENT_TYPES = ('SNOWSQL')
  AUTHENTICATION_METHODS = ('KEYPAIR');

-- Apply the authentication policy on all users of type SERVICE
ALTER ACCOUNT SET AUTHENTICATION POLICY &{policy_2_name} FOR ALL SERVICE USERS;


SHOW AUTHENTICATION POLICIES;

/* -----------------------------------------------------------------------------
  CLEAN UP
------------------------------------------------------------------------------- */
--!quit -- UNCOMMENT THIS LINE TO STOP THE SCRIPT HERE BEFORE CLEANUP

ALTER ACCOUNT UNSET AUTHENTICATION POLICY;
ALTER ACCOUNT UNSET AUTHENTICATION POLICY FOR ALL SERVICE USERS;
--ALTER USER_1 UNSET AUTHENTICATION POLICY;
DROP AUTHENTICATION POLICY IF EXISTS &{policy_1_name};
DROP AUTHENTICATION POLICY IF EXISTS &{policy_2_name};

USE ROLE SECURITYADMIN;
DROP ROLE IF EXISTS &{security_role};

USE ROLE SYSADMIN;
DROP DATABASE IF EXISTS &{database_name};