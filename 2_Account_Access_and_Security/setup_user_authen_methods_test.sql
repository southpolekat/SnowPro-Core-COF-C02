-- Note: Replace the password with a secure, temporary password
!define password=TEMP_CHANGE_ME_NOW_123!;

/* -----------------------------------------------------------------------------
  USE THE USERADMIN ROLE TO CREATE USERS
  - USER_1: Standard username/password authentication
  - USER_2: Username/password + Multi-factor authentication (MFA)
  - USER_3: Key pair authentication
------------------------------------------------------------------------------- */
USE ROLE USERADMIN;

/* -----------------------------------------------------------------------------
  CREATE USER_1 WITH STANDARD USERNAME/PASSWORD AUTHENTICATION
------------------------------------------------------------------------------- */

CREATE OR REPLACE USER USER_1
    PASSWORD = '&{password}'
    LOGIN_NAME = 'USER_1'
    DEFAULT_ROLE = 'PUBLIC'
    MUST_CHANGE_PASSWORD = TRUE
    COMMENT = 'User for testing standard authentication.';

/*
 Test login:
 - Method 1: Using the Snowsight UI
 - Method 2: Using the snowsql command line tool
    - snowsql --accountname <account_name> --username USER_1
*/


/* -----------------------------------------------------------------------------
  CREATE USER_2 WITH USERNAME/PASSWORD + MULTI-FACTOR AUTHENTICATION (MFA)
  Note: MFA is ENABLED by the user in Snowsight, not via this DDL.
------------------------------------------------------------------------------- */

CREATE OR REPLACE USER USER_2
    PASSWORD = '&{password}'
    LOGIN_NAME = 'USER_2'
    DEFAULT_ROLE = 'PUBLIC'
    MUST_CHANGE_PASSWORD = TRUE
    COMMENT = 'User for testing username/password + multi-factor authentication (MFA).';

/* User_2 login via snowsight to enable MFA

**Steps:**
1. Login to Snowsight as USER_2
2. Click on the user icon in the bottom left corner
3. Click on "Settings"
4. Click on "Authentication"
5. Click on "Add new authentication method"
6. Follow the instructions to enable MFA


MFA options
    - Passkey
    - Authenticator
*/

/* -----------------------------------------------------------------------------
  CREATE USER_3 WITH KEY PAIR AUTHENTICATION
------------------------------------------------------------------------------- */

/* 
  Generate a key pair on linux terminal:
    1. Generate a private key:
      openssl genrsa 2048 | openssl pkcs8 -topk8 -v2 des3 -inform PEM -out rsa_key.p8
    2. Generate a public key:
      openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
*/

CREATE OR REPLACE USER USER_3
    RSA_PUBLIC_KEY = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1rNk3y+m9ulen+w27uGy
RkPRLE5C/fS7+cGxIDHlZH2ekDo5DXdOvCwlJYT4YafhiSdqO0y1D+3z35F1Pt5R
obQq6zh5KvFRATolW+IRWIrDmc295VejQsyqHv0eTE4TQnzs88KNHD3bbWyiinJc
XELrBXyx/QjSMwaLwMor+SZ+CHIcZpLokwSXIchht7R5zNcnxlTMH6VXOKf6ynh5
l3rM2Kpswsl0FDyDglcHAFzUO71SYguF9/K6NOSREBT+K5zAyonFYfieS2LAPEi6
s7cG+fkDSSqANmjg6KeUiwxw9bi8IzOHWHiC4FUWr7S2+aMRFU7UBsTbtH/GV2Fl
VwIDAQAB'
    LOGIN_NAME = 'USER_3'
    DEFAULT_ROLE = 'PUBLIC'
    COMMENT = 'User for testing key pair authentication.';
