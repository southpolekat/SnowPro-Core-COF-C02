!source ../variables.sql
--!source ../setup_db_objects.sql

USE ROLE SYSADMIN;
USE WAREHOUSE &{warehouse_name};
USE DATABASE &{database_name};
USE SCHEMA &{schema_name};

/* -----------------------------------------------------------------------------
   SETUP: Create a temporary dataset with 1 Million Rows
   We generate random category_ids to test distinct counting.
   ========================================================= */
CREATE OR REPLACE TEMPORARY TABLE test_dataset AS
SELECT
    seq4() AS row_id,
    uniform(1, 50000, random()) AS category_id -- Random values between 1 and 50,000
FROM TABLE(GENERATOR(rowcount => 1000000));

/* =========================================================
   TEST 1: ESTIMATION FUNCTIONS
   Compare Exact Count vs. Approximate Count
   Concept: APPROX_COUNT_DISTINCT is faster for massive datasets.
   ========================================================= */
SELECT
    'Exact vs Approx' as test_name,
    COUNT(DISTINCT category_id) AS exact_distinct_count,
    APPROX_COUNT_DISTINCT(category_id) AS approx_distinct_count,
    -- Calculate error rate
    ABS(exact_distinct_count - approx_distinct_count) AS difference
FROM test_dataset;

/* =========================================================
   TEST 2: HLL (HyperLogLog)
   Concept: Create a "Sketch" (binary blob) and estimate from it.
   Useful for rolling up distinct counts without storing raw data.
   ========================================================= */
-- Step A: Create the HLL Sketch (This returns binary data)
SELECT HLL_ACCUMULATE(category_id) AS hll_sketch
FROM test_dataset;

-- Step B: Estimate count from the Sketch
SELECT HLL_ESTIMATE(HLL_ACCUMULATE(category_id)) AS hll_estimate
FROM test_dataset;

/* =========================================================
   TEST 3: SAMPLING METHODS (SAMPLE / TABLESAMPLE)
   ========================================================= */

-- A. Fraction-Based Sampling (Percentage)
-- Get approximately 0.01% of the table
SELECT COUNT(*) AS sample_row_count
FROM test_dataset SAMPLE (0.01); -- 0.01 means 0.01%, not 1%

-- B. Fixed-Size Sampling (Row Count)
-- Get exactly 10 rows (Note: Fixed-size sampling may not be exact on very small tables due to block limitations, but works on large ones)
SELECT *
FROM test_dataset SAMPLE (10 ROWS);

/* =========================================================
   CLEANUP
   ========================================================= */
DROP TABLE IF EXISTS test_dataset;

--!source ../cleanup_db_objects.sql