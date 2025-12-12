!source ../variables.sql
--!source ../setup_db_objects.sql

USE ROLE SYSADMIN;
USE WAREHOUSE &{warehouse_name};
USE DATABASE &{database_name};
USE SCHEMA &{schema_name};

/* -----------------------------------------------------------------------------
   1. SETUP: Create Source and Target Tables
   ========================================================= */
CREATE OR REPLACE TABLE raw_orders (
    order_id INT,
    product_name VARCHAR,
    amount DECIMAL(10, 2)
);

CREATE OR REPLACE TABLE final_orders (
    order_id INT,
    product_name VARCHAR,
    amount DECIMAL(10, 2),
    processed_at TIMESTAMP,
    operation_type VARCHAR
);

/* =========================================================
   2. CREATE THE STREAM
   Concept: The stream acts as a bookmark on the 'raw_orders' table.
   It tracks changes (DML) but holds no data itself.
   ========================================================= */
CREATE OR REPLACE STREAM order_stream ON TABLE raw_orders;

-- Verify stream is created (it will be empty initially)
SHOW STREAMS;

/* =========================================================
   3. INSERT DATA (Simulate new records arriving)
   ========================================================= */
INSERT INTO raw_orders (order_id, product_name, amount) VALUES
    (101, 'Snowflake T-Shirt', 25.00),
    (102, 'Data Superhero Cape', 150.00);

/* =========================================================
   4. CHECK THE STREAM
   Concept: The stream now sees the "Delta" (change).
   Notice the METADATA$ columns.
   ========================================================= */
-- This confirms the stream has detected changes
SELECT SYSTEM$STREAM_HAS_DATA('order_stream'); 

-- View the actual changes waiting to be processed
SELECT 
    order_id, 
    product_name, 
    METADATA$ACTION,    -- INSERT or DELETE
    METADATA$ISUPDATE,  -- TRUE if it was an update
    METADATA$ROW_ID
FROM order_stream;

/* =========================================================
   5. CREATE THE TASK
   Concept: Automated worker that runs SQL when triggered.
   Condition: Only runs if the stream has data (saves money).
   ========================================================= */
CREATE OR REPLACE TASK process_orders_task
    WAREHOUSE = COMPUTE_WH  -- Replace with your warehouse name if different
    SCHEDULE = '1 MINUTE'   -- Runs every minute
    WHEN SYSTEM$STREAM_HAS_DATA('order_stream') 
AS
    INSERT INTO final_orders (order_id, product_name, amount, processed_at, operation_type)
    SELECT 
        order_id, 
        product_name, 
        amount, 
        CURRENT_TIMESTAMP(),
        METADATA$ACTION
    FROM order_stream
    WHERE METADATA$ACTION = 'INSERT'; -- Simple logic: Only process Inserts

/* =========================================================
   6. ACTIVATE AND TEST THE TASK
   ========================================================= */
-- Tasks are created in 'SUSPENDED' state by default
ALTER TASK process_orders_task RESUME;

-- OPTION A: Wait 60 seconds for the schedule...
-- OPTION B: Manually trigger it immediately (requires EXECUTE TASK privilege)
EXECUTE TASK process_orders_task;

/* =========================================================
   7. VERIFY RESULTS
   ========================================================= */
-- Check if data moved to the target table
SELECT * FROM final_orders;

-- Check if the Stream is now empty (the bookmark moved forward!)
SELECT * FROM order_stream; 

/* =========================================================
   8. CLEANUP
   ========================================================= */
ALTER TASK IF EXISTS process_orders_task SUSPEND;
DROP TASK IF EXISTS process_orders_task;
DROP STREAM IF EXISTS order_stream;
DROP TABLE IF EXISTS raw_orders;
DROP TABLE IF EXISTS final_orders;

--!source ../cleanup_db_objects.sql