# Domain 4: Data Loading and Unloading (12%)

## 1. Snowflake Stages
Stages are locations where data files are stored for loading into or unloading out of Snowflake .

### Internal Stages
Stored within Snowflake-managed storage.
* **User Internal Stage (`@~`)**: A personal storage area for each user .
* **Table Internal Stage (`@%`)**: A storage area automatically allocated to a specific table .
* **Named Internal Stage**: Explicitly created stage objects for storing data files internally .

### External Stages
References to external cloud storage locations (Amazon S3, Azure, GCS) .
* **Security**: Use **Storage Integrations** to avoid supplying credentials directly when creating stages or loading data .
* **Definition**: A Storage Integration is an object that stores a generated identity and access management (IAM) entity for your external cloud storage .

### Staging Commands
* **PUT**: Uploads files from a **local** directory to an **internal** stage .
* **GET**: Downloads files from an **internal** stage to a **local** directory .
* **Web UI Limitation**: You **cannot** use `PUT` or `GET` through the Snowflake Web Interface; they require a client like SnowSQL .
* **Web UI Loading**: Using the Snowflake UI, you can only load files up to 50MB .

## 2. File Formats
Describes the structure of the data files to be loaded .

* **Structured**:
    * **CSV**: The fastest way to load data .
* **Semi-Structured**:
    * **Types**: JSON, Parquet, XML, Avro, ORC .
    * **FLATTEN Function**: Used to convert semi-structured data into a relational representation .

## 3. Data Loading Methods

### A. Bulk Load (`COPY INTO`)
The primary method for loading batches of data from existing files in a stage .

* **Source**: Loads data from any stage to an existing table .
* **Metadata Retention**: Stores load history for **64 days** to prevent duplicate file loading .
* **Performance Tip**: Organizing input data by granular path can improve load performance .
* **Important Options**:
    * `FORCE = TRUE`: Loads files again, ignoring the 64-day metadata history .
    * `PURGE = TRUE`: Removes the data files from the stage after a successful load .
* **Error Handling (`ON_ERROR`)** :
    * `ABORT_STATEMENT` (Default)
    * `CONTINUE`
    * `SKIP_FILE`
    * `SKIP_FILE_<num>`
    * `SKIP_FILE_<num>%`

### B. Continuous Load (Snowpipe)
Designed for loading small volumes of frequent data (micro-batches) near real-time .

* **Compute**: **Serverless**. It does *not* use your Virtual Warehouse; it uses Snowflake-managed compute resources .
* **Metadata Retention**: Stores load history for **14 days** .
* **Trigger Methods**:
    1.  **Cloud Messaging (Auto-Ingest)**: Detects new files via automated cloud messaging .
    2.  **REST API**: Call Snowpipe REST endpoints programmatically .


## 4. Comparison Summary

| Feature | Bulk Load (`COPY INTO`) | Snowpipe |
| :--- | :--- | :--- |
| **Use Case** | Large batches | Micro-batches |
| **Compute** | User-managed Virtual Warehouse | Serverless (Snowflake-managed) |
| **Load History** | 64 Days | 14 Days |


## 5. Stage Metadata Querying
You can query metadata columns when loading data or inspecting a stage .

* `METADATA$FILENAME`: Name of the staged data file the current row belongs to .
* `METADATA$FILE_ROW_NUMBER`: Row number for each record in the container staged data file .

## Table Types

| Table Type | Storage | Time Travel | Use Case |
| :--- | :--- | :--- | :--- |
| **Permanent** | Snowflake | 0-90 Days | Standard production data. |
| **Transient** | Snowflake | 0-1 Day | Dev/Test data. No Fail-Safe costs. |
| **Temporary** | Snowflake | 0-1 Day | Session-only data. Dropped when session ends. |
| **External** | Customer (S3/Azure) | N/A | Querying data in Data Lake without loading. |
| **Hybrid** (Unistore)* | Snowflake | Yes | **OLTP**, high-concurrency transactional workloads. |
| **Directory*** | Stage Attachment | N/A | File catalog (size, mod_time) for unstructured data. |
| **Dynamic*** | Snowflake | Yes | Declarative data engineering pipelines (Auto-refreshing). |
