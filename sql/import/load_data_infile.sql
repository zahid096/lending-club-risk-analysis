-- Lending Club — Fast Bulk Import with LOAD DATA INFILE
-- First create the table by running create_schema.sql, then run this script.

-- Enable local_infile
SET GLOBAL local_infile = 1;

SHOW VARIABLES LIKE 'local_infile';

USE lending_club;

--
-- borrowers table
--
LOAD DATA LOCAL INFILE 'E:/Daily use/Job preparetion/projects/project-2/Lending Club — Loan Default Risk & Profitability Analysis/borrowers.csv' INTO
TABLE borrowers FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES (
    borrower_id,
    @annual_income,
    emp_length,
    home_ownership,
    state,
    @dti,
    verification_status,
    application_type
)
SET
    annual_income = NULLIF(@annual_income, ''),
    dti = NULLIF(@dti, '');

-- loans table
LOAD DATA LOCAL INFILE 'E:/Daily use/Job preparetion/projects/project-2/Lending Club — Loan Default Risk & Profitability Analysis/loans.csv' INTO
TABLE loans FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES (
    loan_id,
    borrower_id,
    @loan_amnt,
    term,
    @int_rate,
    @installment,
    grade,
    sub_grade,
    purpose,
    issue_d
)
SET
    loan_amnt = NULLIF(@loan_amnt, ''),
    int_rate = NULLIF(@int_rate, ''),
    installment = NULLIF(@installment, '');

-- credit_history table
LOAD DATA LOCAL INFILE 'E:/Daily use/Job preparetion/projects/project-2/Lending Club — Loan Default Risk & Profitability Analysis/credit_history.csv' INTO
TABLE credit_history FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES (
    borrower_id,
    @fico_low,
    @fico_high,
    @delinq_2yrs,
    @open_acc,
    @pub_rec,
    @revol_util,
    @revol_bal,
    @total_acc,
    @mort_acc,
    @pub_rec_bankruptcies,
    @inq_last_6mths
)
SET
    fico_range_low = NULLIF(@fico_low, ''),
    fico_range_high = NULLIF(@fico_high, ''),
    delinq_2yrs = NULLIF(@delinq_2yrs, ''),
    open_acc = NULLIF(@open_acc, ''),
    pub_rec = NULLIF(@pub_rec, ''),
    revol_util = NULLIF(@revol_util, ''),
    revol_bal = NULLIF(@revol_bal, ''),
    total_acc = NULLIF(@total_acc, ''),
    mort_acc = NULLIF(@mort_acc, ''),
    pub_rec_bankruptcies = NULLIF(@pub_rec_bankruptcies, ''),
    inq_last_6mths = NULLIF(@inq_last_6mths, '');

-- payment_status table
LOAD DATA LOCAL INFILE 'E:/Daily use/Job preparetion/projects/project-2/Lending Club — Loan Default Risk & Profitability Analysis/payment_status.csv' INTO
TABLE payment_status FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES (
    loan_id,
    loan_status,
    last_pymnt_d,
    @total_pymnt
)
SET
    total_pymnt = NULLIF(@total_pymnt, '');

-- Verify — Row number matches CSV
SELECT 'borrowers' AS table_name, COUNT(*) AS row_count
FROM borrowers
UNION ALL
SELECT 'loans', COUNT(*)
FROM loans
UNION ALL
SELECT 'credit_history', COUNT(*)
FROM credit_history
UNION ALL
SELECT 'payment_status', COUNT(*)
FROM payment_status;

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE payment_status;

TRUNCATE TABLE credit_history;

TRUNCATE TABLE loans;

TRUNCATE TABLE borrowers;

SET FOREIGN_KEY_CHECKS = 1;