# Domain 6: Data Protection and Data Sharing (12%)

## Time Travel
* **Retention Period:**
    * Standard Edition: 1 day (default).
    * Enterprise Edition: Configurable up to 90 days.
* **Querying Historical Data:**
    * Uses `AT` or `BEFORE` clauses in SELECT statements.
    * Can query based on `TIMESTAMP`, `OFFSET` (time difference), or `STATEMENT` (Query ID).
* **Restoration:**
    * `UNDROP` command restores dropped tables, schemas, and databases.
* **Storage Costs:**
    * Requires additional storage which is reflected in monthly storage charges.
    * Storage is calculated based on modified data; if no data changes, cost is minimal.

## Fail-Safe
* **Definition:** A data recovery service provided by Snowflake for use only when Time Travel has expired.
* **Retention Period:** 7 days (Non-configurable).
* **Access:**
    * Strictly for Snowflake internal use.
    * Users cannot execute SQL queries against Fail-Safe data.
    * Users cannot restore Fail-Safe data themselves; must contact Snowflake support.
* **Cost:** Requires additional storage reflected in monthly charges.

## Zero-Copy Cloning
* **Concept:** Create a snapshot of any table, schema, or Database.
* **Mechanism:** Duplicates the metadata of the micro-partitions, not the physical data.
* **Speed:** Near-instantaneous.
* **Cost:**
    * Free at the time of creation (does not consume storage).
    * Storage costs are incurred only when cloned data is modified and new micro-partitions are created.
* **Privileges:** Access control privileges are not cloned to the new object.
* **Data History:** Load history and Time Travel history are not cloned.

## Data Sharing
* **Architecture:**
    * **No Data Movement:** Shared data is not copied or transferred between accounts; it is accessed live.
    * **Live Access:** Shared data is always up-to-date.
    * **Storage Cost:** Consumers do not pay for storage; the Provider pays.
* **Roles:**
    * **Provider (Producer):** Snowflake account that creates shares and makes them available.
    * **Consumer:** Accounts that receive the share/data.
    * **Reader Account:** Used to share data with a 3rd party who does not have a Snowflake account (Provider pays for compute and storage).
* **DDL Commands:**
    * `CREATE SHARE`
    * `GRANT USAGE ON DATABASE`
* **Share Types:**
    * Outbound & Inbound.

## Access Control & Views
* **Secure Views:**
    * Specifically designed for data sharing and privacy.
    * Hides the view definition and underlying table details.
* **Materialized Views:**
    * Pre-computed results stored for fast access.
* **Column-Level Security:**
    * Dynamic Data Masking & External Tokenization.