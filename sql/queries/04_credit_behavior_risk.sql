-- Category 4: Credit Behavior & Payment History Risk

-- Loan purpose, credit utilization, bankruptcy history, application type,
-- and recent credit inquiries — behavioral risk signals for the borrower.

-- Query 10: Purpose-wise Loan Risk Profile
WITH
    purpose_status as (
        SELECT
            l.purpose,
            COUNT(*) total_loans,
            SUM(l.loan_amnt) AS total_disbursed,
            SUM(
                CASE
                    WHEN ps.loan_status in (
                        "Charged Off",
                        "Default",
                        "Does not meet the credit policy. Status:Charged Off"
                    ) THEN 1
                    ELSE 0
                END
            ) as defaults
        FROM loans l
            JOIN payment_status ps ON l.loan_id = ps.loan_id
        GROUP BY
            l.purpose
    )
SELECT
    purpose,
    total_loans,
    total_disbursed,
    ROUND(
        100.0 * defaults / total_loans,
        2
    ) as default_rate_pct,
    RANK() OVER (
        ORDER BY 100.0 * defaults / total_loans DESC
    ) as risk_rank
FROM purpose_status
WHERE
    total_loans >= 50
ORDER BY risk_rank;

-- Insight: Educational (20.75%) and small business (18.84%) loans carry the highest default rates by far,
-- while car loans (8.98%) and credit cards (9.68%) are the safest — but debt consolidation dominates by
-- volume (1.28M loans, over $20B disbursed), so despite a moderate 12.94% default rate, it contributes the
-- largest absolute dollar risk in the portfolio.

-- Query 11: Credit Utilization Tier — using revol_bal and total_acc
WITH
    utilization as (
        SELECT ch.borrower_id, ch.revol_bal, ch.total_acc, ps.loan_status, NTILE(4) OVER (
                ORDER BY ch.revol_bal desc
            ) as revol_bal_quartile
        FROM
            credit_history ch
            JOIN loans l ON l.borrower_id = ch.borrower_id
            JOIN payment_status ps ON ps.loan_id = l.loan_id
    )
SELECT
    revol_bal_quartile,
    COUNT(*) as total_loans,
    ROUND(AVG(total_acc), 1) as avg_total_accounts,
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
FROM utilization
GROUP BY
    revol_bal_quartile
ORDER BY revol_bal_quartile;

-- Insight: Contrary to expectation, borrowers with the highest revolving balances (quartile 1) actually have
-- the lowest default rate (10.84%), while the highest default rate (12.52%) appears in quartile 3, not quartile
-- 1 — suggesting revol_bal alone isn't a strong linear risk predictor. Interestingly, avg_total_accounts
-- decreases as revol_bal drops (29.3 → 19.8), hinting that high revolving balances may simply reflect
-- borrowers with longer, more established credit histories rather than financial distress.

-- Query 12: Serious Credit Event History — mort_acc ও pub_rec_bankruptcies
SELECT
    CASE
        WHEN ch.pub_rec_bankruptcies > 0 THEN "Has bankrupcy_history"
        ELSE "No bankrupcy_history"
    END as bankruptcy_flag,
    COUNT(*) as total_loans,
    ROUND(AVG(ch.mort_acc), 2) as avg_mortage_account,
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
    ) as default_rate_pct
FROM
    credit_history ch
    JOIN loans l ON l.borrower_id = ch.borrower_id
    JOIN payment_status ps on ps.loan_id = l.loan_id
GROUP BY
    bankruptcy_flag
ORDER BY default_rate_pct DESC;

-- Insight: Borrowers with a prior bankruptcy history have a meaningfully higher default rate (13.99%) than
-- those without (11.63%) — a 2.36 percentage-point gap, confirming that past bankruptcy remains a relevant
-- risk signal even after being reported, though the difference is more modest than FICO or income effects.
-- Average mortgage accounts are nearly identical between the two groups, so this risk isn't driven by
-- differences in mortgage exposure.

-- Query 13: Application Type — Individual vs Joint
SELECT
    b.application_type,
    COUNT(*) as total_loans,
    ROUND(AVG(b.annual_income), 0) avg_annual_income,
    ROUND(AVG(l.loan_amnt), 0) as avg_loan_amount,
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
    ) as default_rate_pct
FROM
    borrowers b
    JOIN loans l ON l.borrower_id = b.borrower_id
    JOIN payment_status ps ON ps.loan_id = l.loan_id
GROUP BY
    b.application_type
ORDER BY default_rate_pct DESC;

-- Insight: Joint applications have a strikingly lower default rate (5.26%) than individual applications
-- (12.29%) — less than half — despite showing a lower average annual income (60,111 vs 79,001), which is somewh
-- at counterintuitive since joint income should typically combine two incomes. This gap likely also reflects
-- stricter underwriting: joint loans are a small, newer segment (only 5.3% of loans) and may be subject to
-- additional scrutiny beyond just combined income.

-- Query 14: Recent Credit Inquiry (inq_last_6mths) vs Default Rate
SELECT
    CASE
        WHEN ch.inq_last_6mths >= 10 THEN '10+'
        ELSE CAST(ch.inq_last_6mths AS CHAR)
    END AS inquiry_bucket,
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
    ) AS default_rate_pct
FROM
    credit_history ch
    JOIN loans l ON l.borrower_id = ch.borrower_id
    JOIN payment_status ps ON ps.loan_id = l.loan_id
WHERE
    ch.inq_last_6mths IS NOT NULL
GROUP BY
    CASE
        WHEN ch.inq_last_6mths >= 10 THEN '10+'
        ELSE CAST(ch.inq_last_6mths AS CHAR)
    END
ORDER BY
    CASE
        WHEN inquiry_bucket = '10+' THEN 1
        ELSE 0
    END,
    inquiry_bucket + 0;

-- Insight: Default rate climbs steadily and consistently as recent credit inquiries increase — from 10.00% with
-- zero inquiries to a peak of 37.70% at eight inquiries, nearly a 4x jump — making inq_last_6mths one of the
-- strongest and most reliable behavioral risk signals in the dataset.