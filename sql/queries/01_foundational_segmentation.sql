-- Active: 1766597285355@@localhost@3306@lending_club
-- Category 1: Foundational Segmentation

-- What the default rate looks like across different groups
-- (income, employment, verification, DTI) ___basic foundational analysis.

-- Query 1: Multi-table join __ Complete loan profile
SELECT l.loan_id, b.state, b.annual_income, b.emp_length, l.loan_amnt, l.int_rate, l.grade, ch.fico_range_low, ps.loan_status
FROM
    loans l
    JOIN borrowers b ON l.borrower_id = b.borrower_id
    JOIN credit_history ch ON ch.borrower_id = b.borrower_id
    JOIN payment_status ps ON ps.loan_id = l.loan_id;

-- Insight: This query merges borrower demographics, loan terms, credit score, and repayment outcome
-- into a single row per loan, creating the unified base dataset all later segmentation
-- and profitability analyses build on. Just from a quick scan, higher-grade (A/B) loans
-- with better FICO scores tend toward lower interest rates and "Fully Paid" status,
-- while lower grades (E/F) show more "Charged Off" or "Does not meet the credit policy" outcomes.

-- Query 2: CASE based income segmentation + default rate:
WITH
    income_segmentations AS (
        SELECT
            l.loan_id,
            ps.loan_status,
            CASE
                WHEN b.annual_income < 40000 THEN "Low Inncome"
                WHEN b.annual_income BETWEEN 40000 AND 80000  THEN "Mid Income"
                WHEN b.annual_income BETWEEN 80000 AND 150000  THEN "High Income"
                ELSE "Very High Income"
            END as income_bracket
        FROM
            loans l
            JOIN borrowers b ON b.borrower_id = l.borrower_id
            JOIN payment_status ps ON ps.loan_id = l.loan_id
    )
SELECT
    income_bracket,
    COUNT(*) as total_loans,
    SUM(
        CASE
            WHEN loan_status in (
                "Charged Off",
                "Default",
                "Does not meet the credit policy. Status:Charged Off"
            ) THEN 1
            ELSE 0
        END
    ) as defaults,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN loan_status in (
                    "Charged Off",
                    "Default",
                    "Does not meet the credit policy. Status:Charged Off"
                ) THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) as default_rate_pct
FROM income_segmentations
GROUP BY
    income_bracket
ORDER BY default_rate_pct DESC;

-- Insight: Default rate declines steadily as income rises — the Low Income group has the highest default rate
-- at 14.28%, nearly double that of the Very High Income group (7.78%), confirming income as a meaningful risk
-- signal. However, the Mid Income bracket carries the largest loan volume (over half of all loans),
-- so even at a moderate 12.72% default rate, it contributes the largest absolute number of defaults
-- (146,158) — making it the biggest concentration of risk in raw terms, not just the lowest income tier.

-- query-3:Employment lenght vs default
SELECT
    CASE
        WHEN b.emp_length is NULL
        or TRIM(b.emp_length) = " " THEN "Not Reported"
        ELSE b.emp_length
    END as emp_length,
    COUNT(*) as total_loans,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN ps.loan_status in (
                    "Charged Off",
                    "Default",
                    "Does not meet the credit policy. Status:Charged Off"
                ) THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) as default_rate_pct,
    ROUND(AVG(l.int_rate), 2) AS avg_int_rate,
    ROUND(AVG(l.loan_amnt), 0) AS avg_loan_amount
FROM
    borrowers b
    JOIN loans l ON l.borrower_id = b.borrower_id
    JOIN payment_status ps ON ps.loan_id = l.loan_id
GROUP BY
    CASE
        WHEN b.emp_length is NULL
        or TRIM(b.emp_length) = " " THEN "Not Reported"
        ELSE b.emp_length
    END
ORDER BY default_rate_pct desc;

-- Insight: Employment length shows a mild but consistent inverse relationship with risk — borrowers with 10+
-- years of employment have the lowest default rate (11.13%) and highest average loan amount, while those with
-- "Not Reported" employment length stand out as the riskiest segment (14.40% default rate) with the smallest
-- average loan (12,118), suggesting missing employment data itself is a useful risk signal, not just noise.

-- Query 4: Loan Term vs Default Rate
SELECT
    l.term as Loan_Term,
    COUNT(*) AS total_loans,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN ps.loan_status IN (
                    "Charged Off",
                    "Default",
                    "Does not meet the credit policy. Status:Charged Off"
                ) THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) as default_rate_pct,
    ROUND(AVG(l.int_rate), 2) as avg_int_rate,
    ROUND(AVG(l.loan_amnt), 2) as avg_loan_amount
FROM loans l
    JOIN payment_status ps ON ps.loan_id = l.loan_id
GROUP BY
    l.term
ORDER BY default_rate_pct DESC;

-- Insight: 60-month loans have a substantially higher default rate (16.20%) than 36-month loans
-- (10.18%) — roughly 1.6x higher — and they also come with higher interest rates and nearly double the average
-- loan amount, confirming that longer terms combine with larger, riskier loans to compound default risk.

-- Query 5: verification satatus vs default rate
SELECT
    b.verification_status,
    COUNT(*) AS total_loans,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN ps.loan_status in (
                    "Charged Off",
                    "Default",
                    "Does not meet the credit policy. Status:Charged Off"
                ) THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) as default_rate_pct,
    ROUND(AVG(b.annual_income), 0) as avg_annual_income
FROM
    borrowers b
    JOIN loans l ON l.borrower_id = b.borrower_id
    JOIN payment_status ps ON ps.loan_id = l.loan_id
GROUP BY
    b.verification_status
ORDER BY default_rate_pct desc;

-- Insight: Counter-intuitively, "Verified" borrowers have the highest default rate (15.88%), while "Not
-- Verified" borrowers have the lowest (8.06%) despite having the lowest average income — this suggests income
-- verification isn't reducing risk, and may instead correlate with borrowers who needed verification because
-- their profiles looked riskier to begin with (reverse causation, not a protective effect).

-- Query 6: DTI(Debt to Income) bucket  vs default rate:
WITH
    dti_segments AS (
        SELECT
            ps.loan_status,
            CASE
                WHEN b.dti < 10 THEN "Low DTI (<10)"
                WHEN b.dti BETWEEN 10 AND 20  THEN "Mid DTI (10-20)"
                WHEN b.dti BETWEEN 20 AND 30  THEN "High DTI (20-30)"
                ELSE "Very High DTI (30+)"
            END as DTI_bucket
        FROM
            borrowers b
            JOIN loans l ON l.borrower_id = b.borrower_id
            JOIN payment_status ps ON ps.loan_id = l.loan_id
        WHERE
            b.dti is NOT NULL
            AND b.dti >= 0
    )
SELECT
    DTI_bucket,
    COUNT(*) as total_loans,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN loan_status in (
                    "Charged Off",
                    "Default",
                    "Does not meet the credit policy. Status:Charged Off"
                ) THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) as default_rate_pct
FROM dti_segments
GROUP BY
    DTI_bucket
ORDER BY default_rate_pct DESC;

-- Insight: Default rate rises consistently with DTI — borrowers with Very High DTI (30+) default at 15.26%,
-- nearly 1.7x the rate of Low DTI borrowers (9.02%), confirming DTI as a strong, independent risk signal
-- beyond income alone. Notably, the largest volume of loans (923,452) sits in the Mid DTI bucket, so this
-- segment also contributes the highest absolute count of defaults.