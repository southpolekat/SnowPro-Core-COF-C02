# Domain 1: Snowflake AI Data Cloud Features & Architecture (24%)

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


## Editions

The 4 main snowflake editions are
1. Standard
2. Enterprise
3. Business Critical
4. Virtual Private Snowflake

### Standard Edition
This is the introductory offering.
- Provides full, unlimited access to all of Snowflake's standard features.
- Time Travel retention period defaults to 1 day.
### Enterprise Edition
This edition includes all Standard features plus additional capabilities designed for large organizations.
- Key Features Added
  - Time Travel: Maximum retention period is increased to 90 days.
  - Materialized Views
  - Mulit-cluster Warehouses
### Business Critical Edition
This edition (formerly known as Enterprise for Sensitive Data or ESD) includes all Enterprise features plus enhanced security and data protection.
- Key Focus: Designed for organizations with extremely sensitive data, such as PHI data that must comply with HIPAA and HITRUST CSF regulations.
- Key Features Added:
  - Enhanced Security: Includes features like Tri-Secret Secure (encryption of sensitive data).
  - Business Continuity: Includes support for database failover/failback for disaster recovery.
### Virtual Private Snowflake (VPS)
This offers the highest level of security.
- Key Feature: The entire Snowflake environment is completely separate and isolated from all other Snowflake accounts. VPS accounts do not share any resources with accounts outside the VPS.

[Reference](https://docs.snowflake.com/en/user-guide/intro-editions#overview-of-editions)
