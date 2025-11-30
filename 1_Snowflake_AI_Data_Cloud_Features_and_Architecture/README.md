# Domain 1: Snowflake AI Data Cloud Features & Architecture

This domain covers the fundamental design and core components of the Snowflake platform.

## Architecture 
Snowflake is a Data Solution provided as *Software-as-a-Service (SaaS)*. It is a hybrid architecture combining traditional shared-disk and shared-nothing database architectures.

| Layer | Function | Core Technology |
|-------|----------|-----------------|
| Database storage | Persists and manages the data. | Data is reorganized into Snowflake's internal optimized, compressed, columnar format. |
| Compute | Executes queries and DML operations. | Uses Virtual Warehouses. Query execution is performed in this layer. |
| Cloud Services | Coordinates activities across Snowflake. | Includes services for Security, Management, Metadata and Optimization. |

[Reference](https://docs.snowflake.com/en/user-guide/intro-key-concepts#snowflake-architecture)

## Data Storage Concepts
- All data in Snowflake tables is automatically divided into **micro-partitions**.
- Each micro-partitions contains between **50 MB and 500 MB** of uncompressed data.
- Snowflake stores **metadata** about all all rows stored in a micro-partitions
  - The range of values for eacho of the columns
  - The number of distinct values
  - Additional properties used for both optimization and efficient query processing.
- Data is organized in a **columnar** way.
- Micro-partitions are **immutable**, meaning they cannot be changed once created.

[Reference](https://docs.snowflake.com/en/user-guide/tables-clustering-micropartitions#what-are-micro-partitions)

## Securable Object Hierarchy 

- Organization
  - Account
    - User
    - Role
    - Other account objects
    - Warehouse
    - Database
      - Database Role
      - Schema
        - Table
        - View
        - Stage
        - Stored Procedure
        - User Defined Function (UDF)
        - Other schema objects

[Reference](https://docs.snowflake.com/en/user-guide/security-access-control-overview#securable-objects)
