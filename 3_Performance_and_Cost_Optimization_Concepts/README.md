# Domain 3: Performance and Cost Optiimization Concepts (16%)

## 1. Virtual Warehouse Management
* **Definition:** A cluster of computing resources (CPU, memory, temporary storage) used to perform queries and DML operations.
* **Billing:** Per-second billing with a 60-second minimum each time the warehouse starts.
* **Auto-Suspend & Auto-Resume:** Enabled by default. Stops the warehouse after inactivity to save credits and restarts it when a query is submitted.
* **Warehouse Size:**
    * Impacts the speed of query execution (larger size = faster for complex queries).
    * **External Knowledge:** Sizes range from X-Small to 6X-Large (and beyond in newer editions), doubling credit usage with each size increase.

## 2. Scaling Strategies
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

## 6. Snowflake Optimization & Performance Features 
| Feature | Solves (The Problem) | Cases (Best Use Scenarios) |
| :--- | :--- | :--- |
| **Materialized Views** | **Repeated Computation.** Expensive aggregations are calculated every time the query runs. | **Dashboards/Reports:** Queries that frequently use `SUM`, `COUNT`, or `AVG` on huge tables (e.g., "Daily Sales by Region"). |
| **Clustering** | **Inefficient Pruning.** Snowflake scans too many micro-partitions because data is not sorted physically. | **Range Filters:** Queries using `BETWEEN` dates or timestamps. Also helpful for low-cardinality filters (e.g., `Region`). |
| **Search Optimization** | **"Needle in a Haystack".** Finding a specific row in billions of records is slow without an index. | **Point Lookups:** Finding a single Customer `ID`, `Email`, `UUID`, or checking a JSON field in a massive table. |
| **Query Acceleration** | **Outlier Queries (Complexity).** A single massive query overloads the warehouse, sucking up all resources. | **Ad-hoc Analytics:** A Data Scientist scans 10TB of data in one query, requiring a temporary "burst" of compute power without resizing the whole warehouse. |
| **Multi-cluster Warehouses** | **Concurrency (Traffic Jams).** Too many users are running queries at the same time, causing **Queuing**. | **Monday Morning Rush:** 50+ users logging in at 9 AM. The warehouse adds "lanes" (clusters) to handle the volume, then shuts them down. |