!source ../variables.sql
!source ../setup_db_objects.sql

/* -----------------------------------------------------------------------------
  Network Policy Test Script
  Tests allowing and blocking access based on IP address.
  Creates two network policies:
  - TEST_NETWORK_POLICY_1: Using ALLOWED_IP_LIST and BLOCKED_IP_LIST.
  - TEST_NETWORK_POLICY_2: Using ALLOWED_NETWORK_RULE_LIST and BLOCKED_NETWORK_RULE_LIST.
------------------------------------------------------------------------------- */
!define policy_1_name=TEST_NETWORK_POLICY_1;
!define policy_2_name=TEST_NETWORK_POLICY_2;

-- Replace this with your actual public IP address!
!define allowed_ip='<YOUR_IP_ADDRESS>'; 
-- A known dummy IP address that should be blocked
!define blocked_ip='192.168.1.1'; 

!define allowed_rule_name='ALLOWED_RULE_1';
!define blocked_rule_name='BLOCKED_RULE_1';

/* -----------------------------------------------------------------------------
  GRANT PRIVILEGES TO DATA GOVERNANCE ROLE TO MANAGE OBJECT TAGS
------------------------------------------------------------------------------- */
use role securityadmin;

GRANT CREATE NETWORK POLICY ON ACCOUNT TO ROLE &{governance_role};
GRANT CREATE NETWORK RULE ON SCHEMA &{database_name}.&{governance_schema_name} TO ROLE &{governance_role};

/* -----------------------------------------------------------------------------
  CREATE THE NETWORK POLICY_1
  The policy explicitly allows YOUR IP and explicitly blocks the DUMMY IP.
  By default, any IP NOT in the ALLOWED list is implicitly denied access.
------------------------------------------------------------------------------- */
USE ROLE &{governance_role};

CREATE NETWORK POLICY IF NOT EXISTS &{policy_1_name}
    -- List of IPs that ARE allowed access (MUST include your current IP)
    ALLOWED_IP_LIST = ('&{allowed_ip}')
    -- List of IPs that are explicitly denied access (optional, but good for testing)
    BLOCKED_IP_LIST = ('&{blocked_ip}')
;

CREATE NETWORK RULE IF NOT EXISTS &{database_name}.&{governance_schema_name}.&{allowed_rule_name}
    TYPE = IPV4
    MODE = INGRESS
    VALUE_LIST = ('&{allowed_ip}')
;

CREATE NETWORK RULE IF NOT EXISTS &{database_name}.&{governance_schema_name}.&{blocked_rule_name}
    TYPE = IPV4
    MODE = INGRESS
    VALUE_LIST = ('&{blocked_ip}')
;

CREATE NETWORK POLICY IF NOT EXISTS &{policy_2_name}
    ALLOWED_NETWORK_RULE_LIST = ('&{database_name}.&{governance_schema_name}.&{allowed_rule_name}')
    BLOCKED_NETWORK_RULE_LIST = ('&{database_name}.&{governance_schema_name}.&{blocked_rule_name}')
;

SHOW NETWORK POLICIES;

/* -----------------------------------------------------------------------------
   APPLY THE NETWORK POLICY TO THE USERS
------------------------------------------------------------------------------- */
use role &{governance_role};
ALTER USER &{user_name} SET NETWORK_POLICY = &{policy_1_name};
ALTER USER &{user_2_name} SET NETWORK_POLICY = &{policy_2_name};

/* -----------------------------------------------------------------------------
  APPLY THE NETWORK POLICY TO THE ACCOUNT
  *IMPORTANT*: Do not apply the policy globally with ALTER ACCOUNT SET NETWORK_POLICY until you are certain it works. 
------------------------------------------------------------------------------- */
-- Applying the policy immediately restricts access based on IP address.
-- ALTER ACCOUNT SET NETWORK_POLICY = &{policy_1_name};

/* -----------------------------------------------------------------------------
  VALIDATION AND TEST (External Step)
------------------------------------------------------------------------------- */

-- TEST A: Successful Connection
-- Action: Log in with SnowSQL or your UI browser from your current machine.
-- Expected Result: **SUCCESS**. Your IP is on the ALLOWED list.

-- TEST B: Failed Connection
-- Action: Attempt to log in from a different IP address (e.g., using a VPN set to a different country, or asking a colleague in a different location to try).
-- Expected Result: **FAILURE**. Connection will be denied with an error message like: 
-- "Public key failed to decrypt. The client IP address is not allowed to access Snowflake."

-- Note: The blocked_ip will fail immediately. Any other IP not on the allowed list will also fail.

/* -----------------------------------------------------------------------------
  CLEANUP
------------------------------------------------------------------------------- */
--!quit -- UNCOMMENT THIS LINE TO STOP THE SCRIPT HERE BEFORE CLEANUP

use role &{governance_role};
-- WARNING: Do not skip cleanup or you may lock out all users!
ALTER USER &{user_name} UNSET NETWORK_POLICY;
ALTER USER &{user_2_name} UNSET NETWORK_POLICY;
--ALTER ACCOUNT UNSET NETWORK_POLICY;

-- 2. Drop the policy object
DROP NETWORK POLICY IF EXISTS &{policy_1_name};
DROP NETWORK POLICY IF EXISTS &{policy_2_name};

!source ../cleanup_db_objects.sql