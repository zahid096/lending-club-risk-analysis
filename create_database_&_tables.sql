-- Active: 1766597285355@@localhost@3306@lending_club
-- =========================================================
-- Lending Club — Database & Table Creation Script (MySQL)
-- =========================================================

CREATE DATABASE IF NOT EXISTS lending_club CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE lending_club;

-- Table 1: borrowers
CREATE TABLE borrowers (
    borrower_id BIGINT PRIMARY KEY,
    annual_income FLOAT,
    emp_length VARCHAR(20),
    home_ownership VARCHAR(20),
    state VARCHAR(5),
    dti FLOAT,
    verification_status VARCHAR(30),
    application_type VARCHAR(20)
);

-- Table 2: loans
CREATE TABLE loans (
    loan_id BIGINT PRIMARY KEY,
    borrower_id BIGINT,
    loan_amnt FLOAT,
    term VARCHAR(20),
    int_rate FLOAT,
    installment FLOAT,
    grade VARCHAR(2),
    sub_grade VARCHAR(3),
    purpose VARCHAR(50),
    issue_d VARCHAR(10), -- আগে text হিসেবে রাখছি ('Dec-2018' ফরম্যাট)
    CONSTRAINT fk_loans_borrower FOREIGN KEY (borrower_id) REFERENCES borrowers (borrower_id)
);

-- Table 3: credit_history
CREATE TABLE credit_history (
    borrower_id BIGINT,
    fico_range_low FLOAT,
    fico_range_high FLOAT,
    delinq_2yrs FLOAT,
    open_acc FLOAT,
    pub_rec FLOAT,
    revol_util FLOAT,
    revol_bal FLOAT,
    total_acc FLOAT,
    mort_acc FLOAT,
    pub_rec_bankruptcies FLOAT,
    inq_last_6mths FLOAT,
    CONSTRAINT fk_credit_borrower FOREIGN KEY (borrower_id) REFERENCES borrowers (borrower_id)
);

-- Table 4: payment_status
CREATE TABLE payment_status (
    loan_id BIGINT PRIMARY KEY,
    loan_status VARCHAR(30),
    last_pymnt_d VARCHAR(10),
    total_pymnt FLOAT,
    CONSTRAINT fk_payment_loan FOREIGN KEY (loan_id) REFERENCES loans (loan_id)
);

-- -----------------------------------------------------------
-- (ঐচ্ছিক কিন্তু সুপারিশকৃত) কমন query দ্রুত করার জন্য index
-- -----------------------------------------------------------
CREATE INDEX idx_loans_grade ON loans (grade);

CREATE INDEX idx_borrowers_state ON borrowers (state);

CREATE INDEX idx_payment_status ON payment_status (loan_status);