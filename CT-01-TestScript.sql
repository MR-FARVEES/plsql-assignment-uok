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

-- Test Case 001
-- Check functionaly of create_staff function
DECLARE 
  full_name VARCHAR2(100);
  contact VARCHAR2(15);
  address VARCHAR2(300);
  nic VARCHAR2(20);
  role VARCHAR2(10);
  staff_id NUMBER;
BEGIN
  full_name := 'Saroath Farvees';
  contact := '0756720854';
  address := '337/A, Central Road, Maligaikadu - West';
  nic := '200112803638';
  role := 'Manager';

  staff_id := create_staff(
    p_full_name => full_name,
    p_contact => contact,
    p_address => address,
    p_nic => nic,
    p_role => role
  );

  DBMS_OUTPUT.PUT_LINE('Test Case 001 [Create Staff] Executed!');
  DBMS_OUTPUT.PUT_LINE('New Staff ID : ' || staff_id);

EXCEPTION
WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Error : ' || SQLERRM);
END;
/

-- Test Case 002
-- Check functionality of create_branch function
DECLARE
  address VARCHAR2(300);
  manager_id NUMBER;
  branch_id NUMBER;
BEGIN
  manager_id := get_staff_id_by_nic(p_nic => '200112803638');
  address := 'Farvees working branch address';

  branch_id := create_branch(
    p_address => address,
    p_manager_id => manager_id
  );

  DBMS_OUTPUT.PUT_LINE('Test Case 002 [Create Branch] Executed!');
  DBMS_OUTPUT.PUT_LINE('Newly Created Branch ID : ' || branch_id);
  
EXCEPTION
WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Error : ' || SQLERRM);
END;
/

-- Test Case 003
-- Check functionality of create_customer function
DECLARE
  customer_id NUMBER;
  full_name VARCHAR2(100);
  phone VARCHAR2(15);
  email VARCHAR2(100);
  nic VARCHAR2(20);
BEGIN
  full_name := 'Promodya Happugolle';
  phone := '0757645343';
  email := 'promodya@gmail.com';
  nic := '200124243321';

  customer_id := create_customer(
    p_full_name => full_name,
    p_phone => phone,
    p_email => email,
    p_nic => nic
  );

  DBMS_OUTPUT.PUT_LINE('Test Case 003 [Create Customer] Executed!');
  DBMS_OUTPUT.PUT_LINE('New Customer ID : ' || customer_id);
EXCEPTION
WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Error : ' || SQLERRM);
END;
/

-- Test Case 004
-- Check functionality of create_account function
DECLARE
  account_id NUMBER;
  customer_id NUMBER;
  account_type VARCHAR2(20);
  branch_code NUMBER;
  balance NUMBER;
BEGIN
  customer_id := get_customer_id_by_nic(p_nic => '200124243321');
  account_type := 'Savings';
  branch_code := 1001;
  balance := 1500;
  account_id := create_account(
    p_customer_id => customer_id,
    p_account_type => account_type,
    p_branch_code => branch_code,
    p_balance => balance
  );
  DBMS_OUTPUT.PUT_LINE('Test Case 004 [Create Account] Executed!');
  DBMS_OUTPUT.PUT_LINE('Account ID : ' || account_id);
EXCEPTION
WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Error : ' || SQLERRM);
END;
/

-- Test Case 005
-- Check functionality of create_card function
DECLARE
  card_id NUMBER;
  account_id NUMBER;
  branch_code NUMBER;
BEGIN
  account_id := 10000007;
  branch_code := 1001;
  card_id := create_card(
    p_account_id => account_id,
    p_branch_code => branch_code
  );
  DBMS_OUTPUT.PUT_LINE('Test 005 [Create Card] Executed!');
  DBMS_OUTPUT.PUT_LINE('Card ID : ' || card_id);
EXCEPTION
WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Error : ' || SQLERRM);
END;
/

-- Test Case 006
-- Check functionality of create_transaction function
-- Transaction Method in ATM/CDM
DECLARE
  v_transaction_id NUMBER;
  v_transaction_log_id NUMBER;
  v_card_number VARCHAR2(30);
  v_pin VARCHAR2(5);
  v_transaction_type VARCHAR2(20);
  v_amount NUMBER;
  v_channel VARCHAR2(10);
  v_reson VARCHAR2(30);
  v_role VARCHAR2(10);
  v_result validation_result := validation_result(0, NULL);
BEGIN
  v_card_number := '2025-0510-1008-1001';
  v_pin := 9376;
  v_transaction_type := 'DEPOSIT';
  v_amount := 15000;
  v_channel := 'CDM';
  v_reson := 'N/A';
  v_role := 'Customer';
  -- Attempt to verify account with credentials
  v_result := validate_card(
    p_card_number => v_card_number,
    p_pin => v_pin
  );
  DBMS_OUTPUT.PUT_LINE('Test Case 006 [Create Transaction for ATM/Online] Executed!');
  IF v_result.status = 1 THEN
    v_transaction_id := create_transaction(
      p_account_id => v_result.account_id,
      p_transaction_type => v_transaction_type,
      p_amount => v_amount,
      p_channel => v_channel,
      p_reason => v_reson
    );
    DBMS_OUTPUT.PUT_LINE('Transaction ID : ' || v_transaction_id);
    v_transaction_log_id := create_transaction_log(
      p_transaction_id => v_transaction_id,
      p_authorized_by => NULL,
      p_role => v_role
    );
    DBMS_OUTPUT.PUT_LINE('Transaction Log ID : ' || v_transaction_log_id);
  ELSE
    DBMS_OUTPUT.PUT_LINE('Invalid Credientials');
  END IF;
EXCEPTION
WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Error : ' || SQLERRM);
END;
/

-- Test Case 007
-- Check functionality of create_transaction function
-- Transaction Method in ATM/CDM
DECLARE
  v_transaction_id NUMBER;
  v_transaction_log_id NUMBER;
  v_transaction_type VARCHAR2(20);
  v_account_id NUMBER;
  v_amount NUMBER;
  v_channel VARCHAR2(10);
  v_reson VARCHAR2(30);
  v_role VARCHAR2(10);
  v_authorized_by NUMBER;
  v_staff_nic VARCHAR2(20);
BEGIN
  v_transaction_type := 'DEPOSIT';
  v_account_id := 10000007;
  v_amount := 150000;
  v_channel := 'Counter';
  v_reson := 'N/A';
  v_role := 'Teller';
  v_staff_nic := '123343234432';
  v_authorized_by := get_staff_id_by_nic(p_nic => v_staff_nic);
  DBMS_OUTPUT.PUT_LINE('Test Case 006 [Create Transaction for Teller] Executed!');
  v_transaction_id := create_transaction(
    p_account_id => v_account_id,
    p_transaction_type => v_transaction_type,
    p_amount => v_amount,
    p_channel => v_channel,
    p_reason => v_reson
  );
  DBMS_OUTPUT.PUT_LINE('Transaction ID : ' || v_transaction_id);
  v_transaction_log_id := create_transaction_log(
    p_transaction_id => v_transaction_id,
    p_authorized_by => v_authorized_by,
    p_role => v_role
  );
  DBMS_OUTPUT.PUT_LINE('Transaction Log ID : ' || v_transaction_log_id);
EXCEPTION
WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Error : ' || SQLERRM);
END;
/