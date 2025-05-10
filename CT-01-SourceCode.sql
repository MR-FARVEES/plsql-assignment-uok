-- Banking System
-- Contributers
-- * CT/2020/076 FARVEES J.M.S. farvees-ct20076@stu.kln.ac.lk
-- * CT/2017/001 ABDULLAH M.N.  abdullah_ct17001@stu.kln.ac.lk
-- Date Created 
-- * 4th May 2025

-- connect with banking_system user
CONNECT banking_system/banking123@localhost:1521/xepdb1 

-- enable show output 
SET SERVEROUTPUT ON;

-- ======================================================
-- |  ALL STANDALONE FUNCTION FOR BANKING_SYSTEM SCHEMA |
-- ======================================================
-- Create new staff
CREATE OR REPLACE FUNCTION create_staff(
  p_full_name IN VARCHAR2,
  p_contact IN VARCHAR2,
  p_address IN VARCHAR2,
  p_nic IN VARCHAR2,
  p_role IN VARCHAR2
) RETURN NUMBER IS v_staff_id NUMBER;
BEGIN
  IF p_role NOT IN ('Manager', 'Teller') THEN
    RAISE_APPLICATION_ERROR(-20001, 'Invalid role specified.');
  END IF;
  v_staff_id := staff_seq.NEXTVAL;
  INSERT INTO staffs (staff_id, full_name, contact, address, nic, role)
  VALUES (v_staff_id, p_full_name, p_contact, p_address, p_nic, p_role);
  RETURN v_staff_id;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN 
    DBMS_OUTPUT.PUT_LINE('Error: record already exists.');
    RETURN -1;
  WHEN OTHERS THEN 
    DBMS_OUTPUT.PUT_LINE('Error : ' || SQLERRM);
END;
/

-- Create new branch
CREATE OR REPLACE FUNCTION create_branch (
  p_address VARCHAR2, 
  p_manager_id NUMBER
) RETURN NUMBER IS v_branch_id NUMBER;
BEGIN 
  -- IF p_role NOT IN ('Manager') THEN
  --   RAISE_APPLICATION_ERROR(-20001, 'Invalid role specified.');
  -- END IF;
  v_branch_id := branche_seq.NEXTVAL;
  INSERT INTO branches (branch_id, address, manager_id)
  VALUES (v_branch_id, p_address, p_manager_id);
  RETURN v_branch_id;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN 
    DBMS_OUTPUT.PUT_LINE('Error: record already exists.');
    RETURN -1;
  WHEN OTHERS THEN 
    DBMS_OUTPUT.PUT_LINE('Error : ' || SQLERRM);
END;
/

-- Create new customer
CREATE OR REPLACE FUNCTION create_customer(
  p_full_name IN VARCHAR2,
  p_phone IN VARCHAR2,
  p_email IN VARCHAR2,
  p_nic IN VARCHAR2
) RETURN NUMBER IS v_customer_id NUMBER;
BEGIN v_customer_id := customer_seq.NEXTVAL;
  INSERT INTO customers (customer_id, full_name, phone, email, nic)
  VALUES (v_customer_id, p_full_name, p_phone, p_email, p_nic);
  RETURN v_customer_id;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN 
    DBMS_OUTPUT.PUT_LINE('Error: record already exists.');
    RETURN -1;
  WHEN OTHERS THEN 
    DBMS_OUTPUT.PUT_LINE('Error : ' || SQLERRM);
  RETURN NULL;
END;
/

-- Create new account for a customer
CREATE OR REPLACE FUNCTION create_account(
  p_customer_id IN NUMBER,
  p_account_type IN VARCHAR2,
  p_branch_code IN NUMBER,
  p_balance IN NUMBER
) RETURN NUMBER IS v_account_id NUMBER;
BEGIN v_account_id := account_seq.NEXTVAL;
  INSERT INTO accounts (account_id, customer_id, account_type, branch_code, balance)
  VALUES (v_account_id, p_customer_id, p_account_type, p_branch_code, p_balance);
  RETURN v_account_id;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN 
    DBMS_OUTPUT.PUT_LINE('Error: record already exists.');
    RETURN -1;
  WHEN OTHERS THEN 
    DBMS_OUTPUT.PUT_LINE('Error : ' || SQLERRM);
  RETURN NULL;
END;
/

-- Create new cards for a customer
CREATE OR REPLACE FUNCTION create_card(
  p_account_id IN NUMBER,
  p_branch_code IN NUMBER
) RETURN NUMBER IS
  v_card_id NUMBER;
  v_pin NUMBER;
  v_now TIMESTAMP := SYSTIMESTAMP;
  v_card_number VARCHAR2(30);
  v_expir_year VARCHAR2(4);
  v_expir_month VARCHAR2(2);
  v_cvc VARCHAR2(3);
  v_count NUMBER;
BEGIN
  -- Validate account_id
  SELECT COUNT(*)
  INTO v_count
  FROM accounts
  WHERE account_id = p_account_id;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Invalid account ID');
  END IF;
  -- Validate branch_code
  IF p_branch_code < 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Invalid branch code');
  END IF;
  -- Generate card ID
  v_card_id := card_seq.NEXTVAL;
  -- Construct card number (YYYYMMDD-CARDID-BRANCH)
  v_card_number := TO_CHAR(v_now, 'YYYY') || '-' || TO_CHAR(v_now, 'MMDD') || '-' || v_card_id || '-' || p_branch_code;
  -- Expiration date (+5 years)
  v_expir_year := TO_CHAR(ADD_MONTHS(SYSDATE, 60), 'YYYY');
  v_expir_month := TO_CHAR(ADD_MONTHS(SYSDATE, 60), 'MM');
  -- Random CVC (100 - 999)
  v_cvc := TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(100, 1000)));
  -- Random PIN (1000 - 9999)
  v_pin := TRUNC(DBMS_RANDOM.VALUE(1000, 10000));
  -- Insert card record
  INSERT INTO cards (card_id, account_id, card_number, expir_year, expir_month, cvc, pin)
  VALUES (v_card_id, p_account_id, v_card_number, v_expir_year, v_expir_month, v_cvc, v_pin);
  RETURN v_card_id;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error (replace with proper logging mechanism)
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    RAISE; -- Re-raise to inform caller
END;
/

-- Make new transaction for an account
CREATE OR REPLACE FUNCTION create_transaction(
  p_account_id NUMBER,
  p_transaction_type VARCHAR2,
  p_amount NUMBER,
  p_channel VARCHAR2,
  p_reason VARCHAR2
) RETURN NUMBER IS v_transaction_id NUMBER;
v_balance NUMBER;
BEGIN 
  -- Validate amount
  IF p_amount <= 0 THEN
    RAISE_APPLICATION_ERROR(-20003, 'Amount must be positive');
  END IF;
  -- Validate channel
  IF p_channel NOT IN ('ATM', 'CDM', 'Mobile', 'Counter') THEN
    RAISE_APPLICATION_ERROR(-20004, 'Invalid channel');
  END IF;
  -- Lock account record and fetch balance
  SELECT balance INTO v_balance FROM accounts WHERE account_id = p_account_id FOR UPDATE;
  -- Check for balance if transaction type is withdraw
  IF UPPER(p_transaction_type) = 'WITHDRAW' THEN
    IF v_balance < p_amount THEN 
      RAISE_APPLICATION_ERROR(-20001, 'Insufficient Balance');
    END IF;
    v_balance := v_balance - p_amount;
  ELSIF UPPER(p_transaction_type) = 'DEPOSIT' THEN
    v_balance := v_balance + p_amount;
  ELSE 
    RAISE_APPLICATION_ERROR(-20002, 'Invalid Transaction Type');
  END IF;
  -- Create trasaction record
  v_transaction_id := transactions_seq.NEXTVAL;
  INSERT INTO transactions(transaction_id, account_id, transaction_type, amount, channel, transaction_reason)
  VALUES (v_transaction_id, p_account_id, p_transaction_type, p_amount, p_channel, p_reason);
  -- Update changes into account balance
  UPDATE accounts SET balance = v_balance WHERE account_id = p_account_id;
  RETURN v_transaction_id;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN 
    DBMS_OUTPUT.PUT_LINE('Error: record already exists.');
    RETURN -1;
  WHEN OTHERS THEN 
    DBMS_OUTPUT.PUT_LINE('Error : ' || SQLERRM);
  RETURN NULL;
END;
/

-- Create a transaction log for a transaction
CREATE OR REPLACE FUNCTION create_transaction_log(
  p_transaction_id IN NUMBER,
  p_authorized_by IN NUMBER,
  p_role IN VARCHAR2
) RETURN NUMBER IS v_log_id NUMBER;
BEGIN v_log_id := transaction_logs_seq.NEXTVAL;
  INSERT INTO transaction_logs(log_id, transaction_id, authorized_by, role)
  VALUES (v_log_id, p_transaction_id, p_authorized_by, p_role);
  RETURN v_log_id;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN 
    DBMS_OUTPUT.PUT_LINE('Error: record already exists.');
    RETURN -1;
  WHEN OTHERS THEN 
    DBMS_OUTPUT.PUT_LINE('Error : ' || SQLERRM);
  RETURN NULL;
END;
/

-- Get staff id by their nic number
CREATE OR REPLACE FUNCTION get_staff_id_by_nic(
  p_nic IN VARCHAR2
) RETURN NUMBER IS v_staff_id NUMBER;
CURSOR staff_cursor IS
SELECT staff_id FROM staffs WHERE nic = p_nic;
BEGIN
  -- Open and fetch from cursor
  OPEN staff_cursor;
  FETCH staff_cursor INTO v_staff_id;
  -- Check if data was found
  IF staff_cursor%NOTFOUND THEN
    CLOSE staff_cursor;
    RAISE_APPLICATION_ERROR(-20003, 'No staff found with NIC: ' || p_nic);
  END IF;
  -- Check for additional rows 
  FETCH staff_cursor INTO v_staff_id;
  IF staff_cursor%FOUND THEN
    CLOSE staff_cursor;
    RAISE_APPLICATION_ERROR(-20004, 'Multiple staff found with NIC: ' || p_nic);
  END IF;
  CLOSE staff_cursor;
  RETURN v_staff_id;
EXCEPTION
  WHEN OTHERS THEN
    IF staff_cursor%ISOPEN THEN
      CLOSE staff_cursor;
    END IF;
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    RETURN -1;
END;
/

-- Get staff id by their nic number
CREATE OR REPLACE FUNCTION get_customer_id_by_nic(
  p_nic IN VARCHAR2
) RETURN NUMBER IS v_customer_id NUMBER;
CURSOR customer_cursor IS
SELECT customer_id
FROM customers
WHERE nic = p_nic;
BEGIN
  -- Open and fetch from cursor
  OPEN customer_cursor;
  FETCH customer_cursor INTO v_customer_id;
  -- Check if data was found
  IF customer_cursor%NOTFOUND THEN
    CLOSE customer_cursor;
    RAISE_APPLICATION_ERROR(-20003, 'No staff found with NIC: ' || p_nic);
  END IF;
  -- Check for additional rows 
  FETCH customer_cursor INTO v_customer_id;
  IF customer_cursor%FOUND THEN
    CLOSE customer_cursor;
    RAISE_APPLICATION_ERROR(-20004, 'Multiple staff found with NIC: ' || p_nic);
  END IF;
  CLOSE customer_cursor;
  RETURN v_customer_id;
EXCEPTION
  WHEN OTHERS THEN
    IF customer_cursor%ISOPEN THEN
      CLOSE customer_cursor;
    END IF;
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    RETURN -1;
END;
/

-- Record type for contain multiple values within single object to return
CREATE OR REPLACE TYPE validation_result AS OBJECT (
  status NUMBER,
  account_id NUMBER
);
/

-- Pin Verification of ATM/CDM/Mobile
CREATE OR REPLACE FUNCTION validate_card(
  p_card_number IN VARCHAR2,
  p_pin IN NUMBER
) RETURN validation_result IS 
v_result validation_result := validation_result(0, NULL);
v_count NUMBER;
v_account_id NUMBER;
BEGIN
  IF p_card_number IS NULL OR LENGTH(TRIM(p_card_number)) = 0 THEN 
    v_result.status := 0;
    RETURN v_result;
  END IF;
  IF p_pin < 1000 OR p_pin > 9999 THEN
    v_result.status := 0;
    RETURN v_result;
  END IF;
  SELECT COUNT(*), MAX(account_id)
  INTO v_count, v_account_id
  FROM cards
  WHERE card_number = p_card_number AND pin = p_pin;
  IF v_count = 1 THEN 
    v_result.status := 1;
    v_result.account_id := v_account_id;
  END IF;
  RETURN v_result;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    v_result.status := 0;
    v_result.account_id := NULL;
    RETURN v_result;
END;
/
