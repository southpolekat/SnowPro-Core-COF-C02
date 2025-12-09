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

## Architecture & Core Concepts (Cheat Sheet)

| Concept | Simple Cheat Sheet Note |
| :--- | :--- |
| **Snowflake Architecture** | **Hybrid** of Shared-Disk (Storage) and Shared-Nothing (Compute) architectures. |
| **Multi-Cluster Architecture** | Compute and Storage are **separated** and **scale independently**. |
| **Virtual Warehouses** | The **Compute Cluster** (engine) that runs queries. Scales up/out. |
| **Cloud Services Layer** | The **Brain** that handles all management (metadata, security, optimization, transactions). |
| **Database Storage Layer** | **Centralized**, persistent home for your data, optimized for analytics. |
| **Shared-Disk Concept** | All compute nodes (Warehouses) access the **same copy** of data without copying it. |

## Data Storage Concepts
## 💾 Data Storage & Continuous Data Protection (Cheat Sheet)

| Concept | Simple Cheat Sheet Note |
| :--- | :--- |
| **Micro-partitions** | The base unit of storage. Contain **50 MB - 500 MB of UNCOMPRESSED** columnar data. |
| **Columnar Storage** | Data is organized by column inside micro-partitions for faster scanning and better compression. |
| **Immutability** | Micro-partitions cannot be changed once written (DML/updates create new ones). |
| **Metadata** | Statistics (Min/Max values, distinct counts) stored in the Cloud Services Layer. **Crucial for Pruning.** |
| **Data Pruning** | The process of using **Metadata** to skip reading irrelevant micro-partitions during a query. |
| **Clustering Keys** | User-defined column(s) used to physically **co-locate** related data to maximize pruning effectiveness. |
| **Data Compression** | All data is **automatically compressed** upon loading, lowering storage costs and improving I/O performance. |
| **Zero-Copy Cloning** | Instantly creates a writable copy of a Database, Schema, or Table by duplicating only the **metadata** (no added storage cost until the clone is modified). |

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


## Snowflake Editions

| Edition | Description |
|---------|-------------|
| Standard | Basic Snowflake features with standard support, Max Time Travel retention 1 day | 
| Enterprise | + Multi-cluster warehouses, + materialized views, Max Time Travel retention 90 days |
| Business Critical | Enhanced Security features, HIPAA compliance, database failover |
| Virtual Private Snowflake | Dedicated virtual infrastructure with complete isolation |

[Reference](https://docs.snowflake.com/en/user-guide/intro-editions#overview-of-editions)
