# Domain 2: Account Access and Security (18%)

This section covers the fundamental objects and approaches Snowflake uses to manage access to data and resources.

## Access control framework

- Snowflake’s approach to access control combines aspects from the following models:
  - **Discretionary Acess Control (DAC)**: Each object has an owner, who can in turn grant access to that object.
  - **Role-based Access Control (RBAC)**: Access privileges are assigned to roles, which are in turn assigned to users.
  - **User-based Access Control (UBAC)**: Access privileges are assigned directly to users. Access control considers privileges assigned directly to users only when USE SECONDARY ROLE is set to ALL. 
- Snowflake primarily employs Role-Based Access Control (**RBAC**)
- Core Entities
  - Securable Object: An entity to which access can be granted. Unless allowed by a grant, access is denied.
  - User: Person or Service. 
  - Role: Entity to which we grant privileges.
  - Privilege: Defined level of access to an object.


[Reference](https://docs.snowflake.com/en/user-guide/security-access-control-overview#access-control-framework)

## Roles

### System-Defined Roles
- **GLOBALORGADMIN**: Role that performs organization-level tasks such as managing the lifecycle of accounts and viewing organization-level usage information.
- **ORGADMIN**: Role that uses a regular account to manage operations at the organization level. The ORGADMIN role will be phased out in a future release.
- **ACCOUNTADMIN**: The top-level role in the system. It encapsulates the SYSADMIN and SECURITYADMIN roles.
- **SYSADMIN**: Has privileges to create warehouses and databases (and other objects). Used for system administration.
- **SECURITYADMIN**: Can manage any object grant globally, and create, monitor, and manage users and roles. Inherits the privileges of the USERADMIN role.
- **USERADMIN**: Dedicated to user and role management only. Granted the CREATE USER and CREATE ROLE privileges.
- **PUBLIC**: A pseudo-role automatically granted to every user and every role in your account. Objects owned by PUBLIC are available to all users.

### Types of Roles
Scope-Based Role Type
- **Account Roles**: Permit SQL actions on any object in your account. The system-defined roles (e.g., SYSADMIN) and standard custom roles are account roles.
- **Database Roles**: Limit SQL actions to objects within a single database. Cannot be activated directly in a session; they must be granted to an Account Role to be used.
- **Instance Roles**: Permit access to an instance of a class, and are granted to account roles.
- **Application Roles**: Enable consumer access to objects in a Snowflake Native App.
- **Service Roles**: Allow a role access to service endpoints (e.g., budgets or data quality features).

[Reference](https://docs.snowflake.com/en/user-guide/security-access-control-overview#roles)

## Authentication Methods

| Method | Simple Cheat Sheet Note | Use Case |
| :--- | :--- | :--- |
| **Username/Password** | Standard basic login. Enforced by strong **password policies**. | Default login for users (e.g., Snowsight). |
| **Multi-Factor Auth (MFA)** | **Additional security layer** (TOTP, push). Must be enabled by the user or required by policy. | Required for high-privilege roles (**ACCOUNTADMIN**, **SECURITYADMIN**). |
| **SSO Integration** | Uses external enterprise identity providers (IdPs) via **SAML 2.0**. | Centralized user management (e.g., Okta, Azure AD). |
| **Key Pair Authentication** | Uses **RSA public-private keys** instead of passwords. | Recommended for **scripting, automation**, and secure CLI connections (**SnowSQL**). |
| **External OAuth** | Grants access via **tokens** issued by external OAuth providers. | Used by modern web and mobile applications to access Snowflake. |

## Data Governance
| Feature | Category | Function (What it does) |
| :--- | :--- | :--- |
| **Row Access Policy** | RLS | Filters **WHICH ROWS** a user can see (Row-Level Security). |
| **Masking Policy** | CLS | Transforms or redacts data in **SPECIFIC COLUMNS** (Column-Level Security). |
| **Access History** | Auditing | Tracks **all read/write operations** on tables/columns for compliance. (Found in **Account Usage** views). |
| **Object Tags** | Classification | Applies **classification metadata** (key-value) for tracking cost/sensitivity/lineage. |
| **Role Hierarchy** | RBAC | Defines the flow of **Privilege Inheritance** through nested roles. |
| **Secure Views** | Privacy | Hides the underlying **View Definition (SQL logic)** from users. |
| **Secure Functions** | Privacy | Hides the underlying **UDF Logic** (proprietary code) from users. |
| **Information Schema** | Discovery | Provides metadata about objects within a **SINGLE DATABASE**. |
| **Accounts & Organizations** | Administration | Enables **Centralized Management** for multiple Snowflake accounts. |

## Network & Connectivity Security
| Feature | Category | Function (What it does) |
| :--- | :--- | :--- |
| **Network Policies** | Access Control | Manages **IP allowlists and blocklists** to restrict which public IP addresses can connect to your Snowflake account. |
| **Private Connectivity** | Network Isolation | Establishes a **private, secure, and dedicated connection** between your VPC and Snowflake using services like **GCP Private Service Connect**, **AWS PrivateLink** and **Azure Private Link**. |
| **Tri-Secret Secure** | Data Encryption | Requires Business Critical Edition or higher. Snowflake's advanced encryption layer using **three unique keys** (including the Customer-Managed Key, if configured) to secure data at rest. |
| **Client Redirect** | Seamless Connectivity | Requires Business Critical edition or higher. Allows administrators to redirect users to a **specific or secondary Snowflake URL** (e.g., for failover/DR) without users changing connection strings. |
| **Federated Authentication** | Identity | Enables **Single Sign-On (SSO)** for human users via an external Identity Provider (IdP) using SAML, replacing password authentication. |
