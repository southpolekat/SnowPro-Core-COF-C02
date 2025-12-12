use role securityadmin;
drop role if exists &{governance_role};
drop role if exists &{role_name};
drop role if exists &{role_2_name};

USE ROLE SYSADMIN;
DROP DATABASE IF EXISTS &{database_name};
DROP WAREHOUSE IF EXISTS &{warehouse_name};
