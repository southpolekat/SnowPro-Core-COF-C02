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

## Tools & Interfaces

| Tool / Interface | Key Function | Best For |
| :--- | :--- | :--- |
| **Snowsight** | The **modern, web-based UI**. Explore, query, manage data, build Streamlit apps, and control cost. | Analysts, Admins, Interactive use. |
| **SnowSQL CLI** | Official **Command-Line Interface (CLI)**. Run SQL, DDL/DML, scripts, and execute **PUT/GET** local file transfers. | Automation, Scripts, Local data staging. |
| **Snowflake CLI** | **Modern, extensible CLI** (SnowCLI). | Managing and **deploying** modern developer objects (Native Apps, Snowpark functions). |
| **Snowflake Drivers** | **Low-level connection libraries** (JDBC, ODBC, Python, Node.js). Connect applications securely. | Developers integrating apps. |
| **Snowflake Connectors** | **Pre-built interfaces** for external systems (Kafka, Spark, BI tools). Stream data, run distributed transforms. | Data Integration, ETL workflows. |
| **Snowpark** | Developer framework for building in-database apps using **Python, Java, and Scala**. Use DataFrames/UDFs. | Data Scientists, Developers building scalable apps. |
| **Streamlit in Snowflake** | Develop and deploy **interactive data applications** directly **inside** Snowflake (no external servers needed). | Analysts, Data Scientists, Rapid Prototyping. |
| **Snowflake SQL API** | **Secure REST API** endpoint. Execute SQL statements programmatically and retrieve results via REST. | Serverless functions, Microservices, Automation scripts. |
| **Cortex AI/ML Services**| Snowflake's **integrated AI/ML layer**. Provides ready-to-use intelligence (Analyst, Search, Document AI) on your data. | Teams building AI-native applications. |
| **SnowCD** | **Command-Line Diagnostic Tool**. Checks network connectivity, DNS, proxy, and firewall configurations. | Network Admins, DevOps teams troubleshooting connectivity. |
| **VS Code Extension** | Enables running SQL queries and managing objects directly from the **Visual Studio Code** environment. | Developers who prefer a dedicated IDE experience. |