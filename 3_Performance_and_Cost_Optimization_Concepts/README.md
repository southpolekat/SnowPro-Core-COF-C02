# Domain 3: Performance and Cost Optiimization Concepts (16%)

## 1. Virtual Warehouse Management
* **Definition:** A cluster of computing resources (CPU, memory, temporary storage) used to perform queries and DML operations.
* **Billing:** Per-second billing with a 60-second minimum each time the warehouse starts.
* **Auto-Suspend & Auto-Resume:** Enabled by default. Stops the warehouse after inactivity to save credits and restarts it when a query is submitted.
* **Warehouse Size:**
    * Impacts the speed of query execution (larger size = faster for complex queries).
    * **External Knowledge:** Sizes range from X-Small to 6X-Large (and beyond in newer editions), doubling credit usage with each size increase.

## 2. Scaling Strategies
Your uploaded notes distinguish between two specific types of scaling:

* **Scale Up (Vertical Scaling):**
    * **Goal:** Increase performance.
    * **Action:** Resize the warehouse to a larger size (e.g., Medium to Large).
* **Scale Out (Horizontal Scaling):**
    * **Goal:** Improve concurrency for users/queries.
    * **Action:** Add additional clusters to a Multi-Cluster Warehouse.

## 3. Multi-Cluster Warehouses
Used to automatically scale compute resources to manage high query concurrency.

* **Modes:**
    * **Maximized:** Runs all configured clusters constantly (External Knowledge: best for strict performance SLAs).
    * **Auto-scale:** Spins clusters up and down based on load.
* **Scaling Policies:**
    * **Standard:** Prioritizes starting clusters immediately to prevent queuing.
    * **Economy:** Prioritizes conserving credits by waiting to ensure load justifies a new cluster.

## 4. Caching Strategies
Snowflake uses three distinct layers of caching to optimize performance:

1.  **Metadata Cache:**
    * Stores object information and statistics (e.g., min/max values, row counts).
2.  **Local Disk Cache (Warehouse Cache):**
    * Attached SSD storage on the Virtual Warehouse.
    * **Warning:** Information is lost when the warehouse is suspended.
3.  **Query Result Cache:**
    * Stores the results of queries for **24 hours**.
    * **Condition:** Returns the result immediately without using warehouse credits *if* the data hasn't changed and the query is identical.

## 5. Cost Control & Resource Monitors
*Crucial for the exam, these control credit usage limits.*

* **Function:** Monitor credit usage for the entire Account or individual Warehouses.
* **Actions (When specific thresholds are reached):**
    1.  **Notify:** Send an alert.
    2.  **Notify & Suspend:** Suspend the warehouse after current queries finish.
    3.  **Notify & Suspend Immediately:** Kill running queries and suspend immediately.
* **Permissions:** Can only be created by AccountAdmins.

## 6. Query Optimization Features
* **Micro-partitions:** Data is automatically divided into contiguous units (50-500MB) compressed and columnar.
    * **Pruning:** The process of scanning only relevant micro-partitions to answer a query, saving time.
* **Materialized Views:** Pre-computed views useful for aggregation; mentioned as a view type in your notes.
* **Clustering:** (External Knowledge) Reorganizing data to improve pruning efficiency.
* **Search Optimization Service:** (External Knowledge) Accelerates point lookups.
