-- Banking System
-- Contributers
-- * CT/2020/076 FARVEES J.M.S. farvees-ct20076@stu.kln.ac.lk
-- * CT/2017/001 ABDULLAH M.N.  abdullah_ct17001@stu.kln.ac.lk
-- Date Created 
-- * 29th April 2025
-- ===========================================================================
-- |                            IMPORTANT NOTE                               |
-- ===========================================================================
-- | Please login in via system administrator to create new users for this   |
-- | seperate schema to ensure default users data safe(hr schema).           |
-- | Step 1: Enter user name: / as sysdba                                    |   
-- | Step 2: SQL> conn sys/<your password>@localhost:1521/xepdb1             |
-- | Then execute below all commands via copy and paste on SQL Plus          |
-- ===========================================================================

-- Drop users if already exists
DECLARE v_exists NUMBER := 0;
BEGIN -- Check if the user exists (username is stored in uppercase)
SELECT
    COUNT(*) INTO v_exists
FROM
    dba_users
WHERE
    username = 'BANKING_SYSTEM';
    IF v_exists > 0 THEN EXECUTE IMMEDIATE 'DROP USER banking_system CASCADE';
            DBMS_OUTPUT.PUT_LINE('User banking_system dropped.');
    ELSE    DBMS_OUTPUT.PUT_LINE('User banking_system does not exist.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN 
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/ 

-- Create new user banking_system
CREATE USER banking_system 
IDENTIFIED BY banking123 
DEFAULT TABLESPACE users 
QUOTA UNLIMITED ON users;

-- Give all permissions & create session
GRANT CONNECT,
RESOURCE,
CREATE SESSION TO banking_system;

-- Connect banking_system users
CONNECT banking_system/banking123@localhost:1521/xepdb1 

-- Staff TABLE
CREATE TABLE staffs (
    staff_id            NUMBER PRIMARY KEY,
    full_name           VARCHAR2(100),
    contact             VARCHAR2(15) CONSTRAINT uni_staff_contact UNIQUE,
    address             VARCHAR2(300),
    nic                 VARCHAR2(20) CONSTRAINT uni_staff_nic UNIQUE,
    role                VARCHAR2(10),
    CONSTRAINT chk_role CHECK (role in ('Manager', 'Teller'))
);

-- Branch TABLE
CREATE TABLE branches (
    branch_id           NUMBER PRIMARY KEY,
    address             VARCHAR2(300),
    manager_id          NUMBER,
    CONSTRAINT fk_staffs_branch FOREIGN KEY (manager_id) REFERENCES staffs(staff_id)
);

-- Customer TABLE
CREATE TABLE customers (
    customer_id         NUMBER PRIMARY KEY,
    full_name           VARCHAR2(100),
    phone               VARCHAR2(15) CONSTRAINT uni_customer_phone UNIQUE,
    email               VARCHAR2(100) CONSTRAINT uni_customer_email UNIQUE,
    nic                 VARCHAR2(20) CONSTRAINT uni_customer_nic UNIQUE,
    created_on          DATE DEFAULT SYSDATE
);

-- Account TABLE
CREATE TABLE accounts (
    account_id          NUMBER PRIMARY KEY,
    customer_id         NUMBER,
    account_type        VARCHAR2(20),
    branch_code         NUMBER(4),
    balance             NUMBER(12, 2) DEFAULT 0,
    opened_on           DATE DEFAULT SYSDATE,
    CONSTRAINT chk_account_type CHECK (account_type in ('Savings', 'Fixed Diposite', 'Joint', 'Student', 'Payroll')),
    CONSTRAINT fk_customer      FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_branch        FOREIGN KEY (branch_code) REFERENCES branches(branch_id)
);

-- Card Table
CREATE TABLE cards (
    card_id             NUMBER PRIMARY KEY,
    account_id          NUMBER,
    card_number         VARCHAR2(19) CONSTRAINT uni_card_number UNIQUE,
    pin                 VARCHAR2(5),
    expir_year          VARCHAR2(5),
    expir_month         VARCHAR2(5),
    cvc                 VARCHAR2(5),
    CONSTRAINT fk_account_to_card FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- Transaction TABLE
CREATE TABLE transactions (
    transaction_id      NUMBER PRIMARY KEY,
    account_id          NUMBER,
    transaction_type    VARCHAR2(10), -- 'DIPOSIT' or 'WITHDRAW'
    amount              NUMBER(10, 2),
    transaction_time    TIMESTAMP DEFAULT SYSTIMESTAMP,
    channel             VARCHAR2(20), -- ATM, CDM, Mobile, Counter
    transaction_reason  VARCHAR2(255),
    CONSTRAINT fk_account_to_transaction FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- Transaction Logs TABLE
CREATE TABLE transaction_logs (
    log_id              NUMBER PRIMARY KEY,
    transaction_id      NUMBER,
    authorized_by       NUMBER, -- Could be emplyee or NULL (for ATM/CDM/Mobile)
    role                VARCHAR2(20), -- 'Customer', 'Teller', 'System'
    log_time            TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT fk_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id),
    CONSTRAINT fk_staffs_log  FOREIGN KEY (authorized_by) REFERENCES staffs(staff_id)
);

-- ====================================================
--          CONFIGURE TABLE SEQUENCES
-- ====================================================

-- Create starting sequences for each table for more reality
CREATE SEQUENCE staff_seq               START WITH 106;
CREATE SEQUENCE branche_seq             START WITH 1006;
CREATE SEQUENCE customer_seq            START WITH 108;
CREATE SEQUENCE account_seq             START WITH 10000006;
CREATE SEQUENCE card_seq                START WITH 1006;
CREATE SEQUENCE transactions_seq        START WITH 1006;
CREATE SEQUENCE transaction_logs_seq    START WITH 2006;

-- ====================================================
--          CONFIGURE TABLE COLUMNS
-- ====================================================

SET LINESIZE 120;
SET PAGESIZE 50;
SET SERVEROUTPUT ON SIZE UNLIMITED;
-- SET FEEDBACK OFF;

-- Format columns for the staffs table
COLUMN staff_id             FORMAT 999999 HEADING 'Staff ID';
COLUMN full_name            FORMAT A20 HEADING 'Full Name';
COLUMN contact              FORMAT A15 HEADING 'Contact';
COLUMN address              FORMAT A30 HEADING 'Address';
COLUMN nic                  FORMAT A15 HEADING 'NIC';
COLUMN role                 FORMAT A10 HEADING 'Role';

-- Format columns for the branches table
COLUMN branch_id            FORMAT 9999 HEADING 'Branch ID';
COLUMN address              FORMAT A30 HEADING 'Address';
COLUMN manager_id           FORMAT 999999 HEADING 'Manager ID';

-- Format columns for the customers table
COLUMN customer_id          FORMAT 999 HEADING 'Customer ID';
COLUMN full_name            FORMAT A20 HEADING 'Full Name';
COLUMN phone                FORMAT A15 HEADING 'Phone';
COLUMN email                FORMAT A20 HEADING 'E-mail';
COLUMN nic                  FORMAT A15 HEADING 'NIC';
COLUMN created_on           FORMAT A9 HEADING 'Created On';

-- Format columns for the accounts
COLUMN account_id           FORMAT 99999999 HEADING 'Account ID';
COLUMN customer_id          FORMAT 999999 HEADING 'Customer ID';
COLUMN account_type         FORMAT A20 HEADING 'Account Type';
COLUMN branch_code          FORMAT 9999 HEADING 'Branch Code';
COLUMN balance              FORMAT 999999999999 HEADING 'Balance';
COLUMN opened_on            FORMAT A9 HEADING 'Opened On';

-- Format columns for the cards
COLUMN card_id              FORMAT 99999999 HEADING 'Card ID';
COLUMN account_id           FORMAT 99999999 HEADING 'Account ID';
COLUMN card_number          FORMAT A20 HEADING 'Card Number';
COLUMN pin                  FORMAT A5 HEADING 'Pin';
COLUMN expir_year           FORMAT A10 HEADING 'Expir Year';
COLUMN expir_month          FORMAT A11 HEADING 'Expir Month';
COLUMN cvc                  FORMAT A5 HEADING 'CVC';

-- Format columns for the transactions
COLUMN transaction_id       FORMAT 99999999 HEADING 'Transaction ID';
COLUMN account_id           FORMAT 99999999 HEADING 'Account ID';
COLUMN transaction_type     FORMAT A10 HEADING 'Transaction Type';
COLUMN amount               FORMAT 99999999 HEADING 'Amount';
COLUMN transaction_time     FORMAT A30 HEADING 'Transaction Time';
COLUMN channel              FORMAT A10 HEADING 'Channel';
COLUMN transaction_reason   FORMAT A20 HEADING 'Reason';

-- Format columns for the transaction_logs
COLUMN log_id               FORMAT 99999999 HEADING 'Log ID';
COLUMN transaction_id       FORMAT 99999999 HEADING 'Transaction ID';
COLUMN authorized_by        FORMAT 999999 HEADING 'Authroized By';
COLUMN role                 FORMAT A10 HEADING 'Role';
COLUMN log_time             FORMAT A30 HEADING 'Log Time';

-- ====================================================
--          INSERT TEST DATA INTO TABLES
-- ====================================================

-- Insert data into staffs
INSERT INTO staffs           VALUES (101, 'Shamha Asfer'   , '0755223362', 'Shamha home address'    , '143543343452', 'Manager');
INSERT INTO staffs           VALUES (102, 'Abdullah Naleem', '0765623362', 'Abdullah home address'  , '142341233432', 'Manager');
INSERT INTO staffs           VALUES (103, 'Madusha Johseph', '0765423932', 'Madusha home address'   , '322323333452', 'Manager');
INSERT INTO staffs           VALUES (104, 'Fathima Hazeera', '0755523532', 'Fathima home address'   , '123343543332', 'Manager');
INSERT INTO staffs           VALUES (105, 'Mohamed Rushdy' , '0765653352', 'Rushdy home address'    , '123454234432', 'Manager');
INSERT INTO staffs           VALUES (106, 'Sutharsini'     , '0766934452', 'Sutharsini home address', '123343234432', 'Teller' );
INSERT INTO staffs           VALUES (107, 'Vishnu Kajan'   , '0768934552', 'Vishnu home address'    , '123454545232', 'Teller' );

-- Insert data into branches
INSERT INTO branches         VALUES (1001, 'Branch 1 Address', 101);
INSERT INTO branches         VALUES (1002, 'Branch 2 Address', 102);
INSERT INTO branches         VALUES (1003, 'Branch 3 Address', 103);
INSERT INTO branches         VALUES (1004, 'Branch 4 Address', 104);
INSERT INTO branches         VALUES (1005, 'Branch 5 Address', 105);

-- Insert data into customers
INSERT INTO customers        VALUES (101, 'Sajees'   , '0763456234', 'sajees@gmail.com'   , '200232184354', SYSDATE);
INSERT INTO customers        VALUES (102, 'Sajeeth'  , '0763564434', 'sajeeth@gmail.com'  , '200112383254', SYSDATE);
INSERT INTO customers        VALUES (103, 'Denujan'  , '0768654454', 'denu@gmail.com'     , '200121154354', SYSDATE);
INSERT INTO customers        VALUES (104, 'Sanjeevan', '0756545434', 'sanjeevan@gmail.com', '200133285454', SYSDATE);
INSERT INTO customers        VALUES (105, 'Faslan'   , '0765543244', 'faslan@gmail.com'   , '200112382454', SYSDATE);

-- Insert data into accounts
INSERT INTO accounts         VALUES (10000001, 101, 'Savings', 1001, 5000.00  , SYSDATE);
INSERT INTO accounts         VALUES (10000002, 102, 'Savings', 1001, 15000.00 , SYSDATE);
INSERT INTO accounts         VALUES (10000003, 103, 'Savings', 1001, 50000.00 , SYSDATE);
INSERT INTO accounts         VALUES (10000004, 104, 'Savings', 1001, 51000.00 , SYSDATE);
INSERT INTO accounts         VALUES (10000005, 105, 'Savings', 1001, 150000.00, SYSDATE);

-- Insert data into cards
INSERT INTO cards            VALUES (1001, 10000001, '2025-0505-2431-1001', 4212,'2030', '05', '923');
INSERT INTO cards            VALUES (1002, 10000002, '2025-0505-5431-1001', 3235,'2030', '05', '324');
INSERT INTO cards            VALUES (1003, 10000003, '2025-0505-5435-1001', 6534,'2030', '05', '123');
INSERT INTO cards            VALUES (1004, 10000004, '2025-0505-6545-1001', 3454,'2030', '05', '431');
INSERT INTO cards            VALUES (1005, 10000005, '2025-0505-7456-1001', 8932,'2030', '05', '765');

-- Insert data into transactions
INSERT INTO transactions     VALUES (1001, 10000002, 'DIPOSITE', 5000.00 , SYSTIMESTAMP, 'CDM'    , 'N/A');
INSERT INTO transactions     VALUES (1002, 10000002, 'DIPOSITE', 5000.00 , SYSTIMESTAMP, 'ATM'    , 'N/A');
INSERT INTO transactions     VALUES (1003, 10000002, 'DIPOSITE', 5000.00 , SYSTIMESTAMP, 'Counter', 'N/A');
INSERT INTO transactions     VALUES (1004, 10000003, 'WITHDRAW', 15000.00, SYSTIMESTAMP, 'ATM'    , 'N/A');
INSERT INTO transactions     VALUES (1005, 10000004, 'WITHDRAW', 9000.00 , SYSTIMESTAMP, 'Counter', 'N/A');

-- Insert data into transaction_logs
INSERT INTO transaction_logs VALUES (2001, 1001, NULL, 'Customer', SYSTIMESTAMP);
INSERT INTO transaction_logs VALUES (2002, 1002, NULL, 'Customer', SYSTIMESTAMP);
INSERT INTO transaction_logs VALUES (2003, 1003, 106 , 'Teller'  , SYSTIMESTAMP);
INSERT INTO transaction_logs VALUES (2004, 1004, NULL, 'Customer', SYSTIMESTAMP);
INSERT INTO transaction_logs VALUES (2005, 1005, 107 , 'Teller'  , SYSTIMESTAMP);

-- Commit the changes
COMMIT;

-- Verify tables
SELECT table_name
FROM all_tables
WHERE owner = 'BANKING_SYSTEM';

-- Verify sequences
SELECT sequence_name
FROM all_sequences
WHERE sequence_owner = 'BANKING_SYSTEM';

-- Verify tables data
SELECT * FROM staffs;
SELECT * FROM branches;
SELECT * FROM customers;
SELECT * FROM cards;
SELECT * FROM transactions;
SELECT * FROM transaction_logs;
/
