-- 1. SWITCH TO THE DESIGNATED ROLE
-- This activates all the privileges granted to ROLE_1 (USAGE on WH, OWNERSHIP on DB).
USE ROLE ROLE_1;

-- 2. SET SESSION CONTEXT (Warehouse and Database)
USE WAREHOUSE WAREHOUSE_1;
USE DATABASE SNOWPRO_COF_C02;

------------------------------------------------------
-- A. TEST: CREATE SCHEMA
------------------------------------------------------

-- Create a new schema (ROLE_1 is the owner of the database).
CREATE SCHEMA IF NOT EXISTS SCHEMA_1;

-- Set the default schema for the session.
USE SCHEMA SCHEMA_1;

------------------------------------------------------
-- B. TEST: CREATE TABLE
------------------------------------------------------

-- Create a table within the new schema (ROLE_1 owns the schema).
CREATE TABLE IF NOT EXISTS TABLE_1 (
    CUST_ID INT,
    CUST_NAME VARCHAR,
    ORDER_DATE DATE
);

------------------------------------------------------
-- C. TEST: INSERT DATA
------------------------------------------------------

-- Insert a few records into the new table.
INSERT INTO TABLE_1 (CUST_ID, CUST_NAME, ORDER_DATE) VALUES
(1, 'Alice', '2025-10-01'),
(2, 'Bob', '2025-10-05'),
(3, 'Charlie', '2025-10-10');

------------------------------------------------------
-- D. TEST: SIMPLE QUERY
------------------------------------------------------

-- Query the data (SELECT privilege on the table is implicit via ownership).
SELECT CUST_ID, CUST_NAME, ORDER_DATE FROM TABLE_1 WHERE ORDER_DATE >= '2025-10-05';

-- Output should be:
-- CUST_ID | CUST_NAME | ORDER_DATE
-- 2       | Bob       | 2025-10-05
-- 3       | Charlie   | 2025-10-10

------------------------------------------------------
-- E. TEST: CLEANUP
------------------------------------------------------

-- Optional: Drop the table (ROLE_1 is the owner).
DROP TABLE TABLE_1;

-- Optional: Drop the schema (ROLE_1 is the owner).
DROP SCHEMA SCHEMA_1;
