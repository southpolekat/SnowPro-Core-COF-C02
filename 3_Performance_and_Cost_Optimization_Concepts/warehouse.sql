!source ../variables.sql
--!source ../setup_db_objects.sql

/* -----------------------------------------------------------------------------
   MANAGE WAREHOUSES
   Requires SYSADMIN or ACCOUNTADMIN role.
   
   Key Exam Concepts:
   1. Scaling UP (Resizing): Improves Performance for complex queries.
   2. Scaling OUT (Multi-cluster): Improves Concurrency for many users.
   3. Auto-Suspend/Resume: Critical for cost management.
------------------------------------------------------------------------------- */

USE ROLE SYSADMIN;

/* -----------------------------------------------------------------------------
   EXAMPLE 1: CREATE STANDARD WAREHOUSE
   Basic configuration for cost efficiency.
------------------------------------------------------------------------------- */

CREATE OR REPLACE WAREHOUSE &{warehouse_name}
    WITH 
    WAREHOUSE_SIZE = 'XSMALL'      -- Start small
    AUTO_SUSPEND = 300             -- Suspend after 5 mins (300 sec) of inactivity
    AUTO_RESUME = TRUE             -- Automatically wake up when a query is run
    INITIALLY_SUSPENDED = TRUE     -- Do not start billing immediately upon creation
    COMMENT = 'Standard warehouse for daily operations';

-- Verification
SHOW WAREHOUSES LIKE '&{warehouse_name}';


/* -----------------------------------------------------------------------------
   EXAMPLE 2: SCALING UP (Vertical Scaling)
   Scenario: A complex query is running too slow. We need more raw power (RAM/CPU).
   * Does NOT require stopping the warehouse.
   * New queries get the new size immediately.
------------------------------------------------------------------------------- */

ALTER WAREHOUSE &{warehouse_name} 
    SET WAREHOUSE_SIZE = 'MEDIUM'; -- 4x the credits of X-Small

-- Verification
-- Note the 'size' column change
SHOW WAREHOUSES LIKE '&{warehouse_name}';


/* -----------------------------------------------------------------------------
   EXAMPLE 3: SCALING OUT (Horizontal Scaling / Multi-Cluster)
   Scenario: It's Monday morning. 50 users are logging in. Queries are QUEUED.
   * Requires Enterprise Edition or higher.
   * Mode: AUTO_SCALE (Snowflake adds clusters as needed).
------------------------------------------------------------------------------- */

ALTER WAREHOUSE &{warehouse_name} 
    SET 
    MAX_CLUSTER_COUNT = 3         -- Can spin up to 3 parallel clusters
    MIN_CLUSTER_COUNT = 1         -- Minimum 1 cluster always active (when running)
    SCALING_POLICY = 'STANDARD';  -- Spins up new clusters quickly to minimize queuing

-- Verification
-- Note 'min_cluster_count' and 'max_cluster_count' columns
SHOW WAREHOUSES LIKE '&{warehouse_name}';


/* -----------------------------------------------------------------------------
   EXAMPLE 4: OPTIMIZE FOR COST (Downgrade)
   Scenario: The heavy workload is over. Revert to save credits.
------------------------------------------------------------------------------- */

ALTER WAREHOUSE &{warehouse_name} 
    SET 
    WAREHOUSE_SIZE = 'XSMALL'
    MAX_CLUSTER_COUNT = 1;        -- Disable multi-clustering

/* -----------------------------------------------------------------------------
   CLEANUP
------------------------------------------------------------------------------- */
--!source ../cleanup_db_objects.sql
