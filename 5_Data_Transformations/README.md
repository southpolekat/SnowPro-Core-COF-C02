# Domain 5: Data Transformations (18%)

## Structured Data Processing
* **Estimation Functions:** `APPROX_COUNT_DISTINCT`, `HLL` (HyperLogLog) for fast, approximate analytics on massive datasets.
* **Sampling Methods:** `SAMPLE` / `TABLESAMPLE` supports fraction-based (percentage) and fixed-size (row count) sampling.
* **User-Defined Functions (UDFs):**
    * Perform operations not available in system functions.
    * **Languages:** SQL, JavaScript, Java, and Python.
    * **Returns:** A single row (Scalar) or a tabular result (UDTF).
* **Stored Procedures:**
    * Extend Snowflake SQL to perform complex operations.
    * **Languages:** JavaScript and Snowflake Scripting (SQL). Also supports Python, Java, and Scala.
* **Streams (CDC):**
    * **Definition:** Objects that record DML changes (INSERT, UPDATE, DELETE) and metadata.
    * **Types:** Standard, Append Only, and Insert Only.
    * **Metadata Columns:** `METADATA$ACTION`, `METADATA$ISUPDATE`, `METADATA$ROW_ID`.
    * **System Check:** `SYSTEM$STREAM_HAS_DATA` indicates if CDC records exist.
* **Tasks:**
    * **Definition:** Schedulable scripts executing a single SQL statement or Stored Procedure.
    * **Constraints:** Maximum duration of **60 minutes** by default.
    * **Tree:** A root task can have up to 1000 child tasks total (max 100 immediate children per task).
    * **Serverless:** Compute resources automatically scale up/down by Snowflake.

## Semi-Structured Data
* **Supported Formats:** JSON, Parquet, XML, Avro, ORC.
    * *Note: CSV is categorized explicitly as "Structured Data".*
* **Loading:**
    * **VARIANT:** The primary data type for storing semi-structured data.
    * **Size Limit:** Up to 16MB per value.
* **FLATTEN Command:** Converts semi-structured data (nested arrays/objects) into a relational representation (rows and columns).
* **Extraction Notation:** Use colon (`:`) for object keys and brackets (`[]`) for array indices.
    * *Example:* `src:customer.name::string`

## Unstructured Data Features
* **Directory Tables:** Auto-generated metadata (file size, last modified, URL) for files stored in external stages.
* **File Access Functions:**
    * `GET_PRESIGNED_URL`: Generates a temporary URL for secure access.
    * `BUILD_SCOPED_FILE_URL`: URL valid only within the current session/query scope.
    * `BUILD_STAGE_FILE_URL`: Permanent URL referencing the stage location.

## Advanced SQL Features
* **Sequences:**
    * **Use Case:** Generate unique numbers across sessions and statements.
    * **Syntax:** Use `nextval` to generate the next set of distinct values.
* **Transactions:**
    * **Properties:** ACID compliant.
    * **Commands:** `COMMIT`, `ROLLBACK`.
    * **Abort:** Running transactions auto-abort after **4 hours** if not manually handled.
    * **Scope:** Snowflake does NOT support Nested Transactions; each transaction has an independent scope.
* **Common Table Expressions (CTEs):** `WITH` clauses for query organization and readability.
* **Pivot/Unpivot:** Rotate row data into columns (Pivot) or columns into rows (Unpivot).

## Snowflake Data Types
* **Structured:**
    * `NUMBER`: Precision and scale for exact numerics.
    * `VARCHAR`: Variable-length strings (Max 16MB).
    * `TIMESTAMP`: Date/time with timezone support (LTZ, NTZ, TZ).
* **Semi-Structured:**
    * `VARIANT`: Generic container for JSON, XML, etc.
    * `ARRAY`: Ordered list of values.
    * `OBJECT`: Key-value pairs.