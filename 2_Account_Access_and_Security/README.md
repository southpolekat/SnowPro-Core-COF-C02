# Domain 2: Account Access and Security

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
