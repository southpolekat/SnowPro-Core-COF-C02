!source ../variables.sql
--!source ../setup_db_objects.sql

/* -----------------------------------------------------------------------------
   RESOURCE MONITORS (Cost Control)
   Requires ACCOUNTADMIN role.
   
   Scope Rules:
   1. A Monitor can be assigned to the ACCOUNT (Global).
   2. A Monitor can be assigned to one or more WAREHOUSES.
   3. A Warehouse can only have ONE Monitor attached.
------------------------------------------------------------------------------- */

USE ROLE ACCOUNTADMIN;

/* -----------------------------------------------------------------------------
   EXAMPLE 1: WAREHOUSE LEVEL MONITOR
   Scenario: Limit this specific warehouse to 100 Credits per DAY.
   Resets: Every 24 hours (UTC).
------------------------------------------------------------------------------- */

CREATE OR REPLACE RESOURCE MONITOR RM_WAREHOUSE_DAILY
    WITH 
    CREDIT_QUOTA = 100           -- Daily Limit: 100 Credits
    FREQUENCY = DAILY            -- Resets daily
    START_TIMESTAMP = IMMEDIATELY
    NOTIFY_USERS = ($current_user)
    TRIGGERS 
        ON 50 PERCENT DO NOTIFY          -- Alert at 50 Credits
        ON 100 PERCENT DO SUSPEND;       -- Stop NEW queries at 100 Credits

-- Assign to the specific Warehouse
ALTER WAREHOUSE &{warehouse_name} SET RESOURCE_MONITOR = RM_WAREHOUSE_DAILY;


/* -----------------------------------------------------------------------------
   EXAMPLE 2: ACCOUNT LEVEL MONITOR
   Scenario: Limit the ENTIRE ACCOUNT to 1000 Credits per MONTH.
   Resets: 1st of every month.
------------------------------------------------------------------------------- */

CREATE OR REPLACE RESOURCE MONITOR RM_ACCOUNT_MONTHLY
    WITH 
    CREDIT_QUOTA = 1000          -- Monthly Limit: 1000 Credits
    FREQUENCY = MONTHLY          -- Resets monthly
    START_TIMESTAMP = IMMEDIATELY
    NOTIFY_USERS = ($current_user)
    TRIGGERS 
        ON 50 PERCENT DO NOTIFY          -- Alert at 500 Credits
        ON 100 PERCENT DO SUSPEND;       -- Stop NEW queries globally at 1000 Credits

-- Assign to the Account (Global Cap)
ALTER ACCOUNT SET RESOURCE_MONITOR = RM_ACCOUNT_MONTHLY;


/* -----------------------------------------------------------------------------
   VERIFICATION
------------------------------------------------------------------------------- */

SHOW RESOURCE MONITORS;

-- Check assignment
SHOW WAREHOUSES LIKE '&{warehouse_name}'; -- Look for 'resource_monitor' column
SHOW PARAMETERS LIKE 'RESOURCE_MONITOR' IN ACCOUNT;


/* -----------------------------------------------------------------------------
   CLEANUP
   (Critical: Unset monitors before dropping to avoid "phantom" limits)
------------------------------------------------------------------------------- */

-- 1. Unset Warehouse Monitor
ALTER WAREHOUSE &{warehouse_name} SET RESOURCE_MONITOR = NULL;
DROP RESOURCE MONITOR IF EXISTS RM_WAREHOUSE_DAILY;

-- 2. Unset Account Monitor
ALTER ACCOUNT SET RESOURCE_MONITOR = NULL;
DROP RESOURCE MONITOR IF EXISTS RM_ACCOUNT_MONTHLY;

--!source cleanup_db_objects.sql