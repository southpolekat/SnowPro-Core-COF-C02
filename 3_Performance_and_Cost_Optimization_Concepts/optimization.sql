!source ../variables.sql
--!source ../setup_db_objects.sql

/* -----------------------------------------------------------------------------
   QUERY OPTIMIZATION
   Requires SYSADMIN role.
   
   Features covered:
   1. Materialized Views (Pre-computed Aggregates)
   2. Clustering Keys (Data Organization)
   3. Search Optimization Service (Point Lookups)
   4. Persisted Query Results (Result Cache)
   5. Query Acceleration Service (QAS)
------------------------------------------------------------------------------- */

USE ROLE SYSADMIN;
USE WAREHOUSE &{warehouse_name};
USE DATABASE &{database_name};
USE SCHEMA &{schema_name};

/* -----------------------------------------------------------------------------
   FEATURE 1: MATERIALIZED VIEWS
   Scenario: You frequently check a table with a large number of rows.
------------------------------------------------------------------------------- */
CREATE OR REPLACE MATERIALIZED VIEW &{database_name}.&{schema_name}.&{secure_view_name}
    AS
    SELECT * FROM &{database_name}.&{schema_name}.&{table_name};

-- Test: Query the MV directly
SELECT * FROM &{database_name}.&{schema_name}.&{secure_view_name} ORDER BY CUST_ID;

-- Verification: Check if it is refreshed
SHOW MATERIALIZED VIEWS LIKE '&{secure_view_name}';

/* -----------------------------------------------------------------------------
   FEATURE 2: CLUSTERING
   Scenario: You always filter by CUST_ID.
   Clustering sorts the underlying micro-partitions by this column to skip unnecessary data.
------------------------------------------------------------------------------- */

-- Set the Clustering Key
ALTER TABLE &{database_name}.&{schema_name}.&{table_name} CLUSTER BY (CUST_ID);

-- Check Clustering Information (Depth, Overlap)
-- Note: On this tiny table, it won't show much effective clustering yet.
SELECT SYSTEM$CLUSTERING_INFORMATION('&{database_name}.&{schema_name}.&{table_name}');

/* -----------------------------------------------------------------------------
   FEATURE 3: SEARCH OPTIMIZATION SERVICE (SOS)
   Scenario: You need to find "Needle in a Haystack" (e.g., WHERE CUST_ID = 1).
   SOS creates a search access path (like a secondary index) for point lookups.
------------------------------------------------------------------------------- */

-- Enable Search Optimization on the table
ALTER TABLE &{database_name}.&{schema_name}.&{table_name} ADD SEARCH OPTIMIZATION;
ALTER TABLE &{database_name}.&{schema_name}.&{table_name} ADD SEARCH OPTIMIZATION ON EQUALITY(CUST_ID);

-- Test: Run a point lookup query (Snowflake will use SOS if efficient)
SELECT * FROM &{database_name}.&{schema_name}.&{table_name} WHERE CUST_ID = 1;

-- Verify setup
SHOW TABLES LIKE '&{table_name}'; -- Look for 'search_optimization' = 'ON'

/* -----------------------------------------------------------------------------
   FEATURE 4: PERSISTED QUERY RESULTS (Result Cache)
   Scenario: Run the exact same query twice. The second run should take 0 milliseconds.
   * Requirement: Underlying data must not change.
   * Retention: 24 Hours.
------------------------------------------------------------------------------- */

-- Run 1: Normal Execution (Compute used)
SELECT REGION, COUNT(*) FROM &{database_name}.&{schema_name}.&{table_name} GROUP BY REGION ORDER BY 1;

-- Run 2: Result Cache Fetch (No Compute used)
-- Look at the Query Profile -> "Query Result Reuse"
SELECT REGION, COUNT(*) FROM &{database_name}.&{schema_name}.&{table_name} GROUP BY REGION ORDER BY 1;

/* -----------------------------------------------------------------------------
   FEATURE 5: QUERY ACCELERATION SERVICE (QAS)
   Scenario: A massive query needs more CPU than a single cluster can provide.
   QAS offloads parts of the query to a serverless pool of compute.
   * Enabled on the WAREHOUSE level.
------------------------------------------------------------------------------- */

-- Enable QAS on the warehouse
ALTER WAREHOUSE &{warehouse_name} 
    SET ENABLE_QUERY_ACCELERATION = TRUE
    QUERY_ACCELERATION_MAX_SCALE_FACTOR = 8; -- Can expand up to 8x the warehouse size

-- Verification
SHOW WAREHOUSES LIKE '&{warehouse_name}';


/* -----------------------------------------------------------------------------
   CLEANUP
------------------------------------------------------------------------------- */

-- Disable QAS (Optional, good practice to revert changes)
ALTER WAREHOUSE &{warehouse_name} SET ENABLE_QUERY_ACCELERATION = FALSE;

--!source ../cleanup_db_objects.sql