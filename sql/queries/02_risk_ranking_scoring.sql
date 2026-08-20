-- Category 2: Risk Ranking & Scoring

-- Using window functions to rank risk by grade and FICO.

-- Query 7 — Window Function: Default Rate Ranking by Grade
with
    grade_states as (
        SELECT
            l.grade,
            COUNT(*) as total_loans,
            SUM(
                CASE
                    WHEN ps.loan_status in (
                        "Charged Off",
                        "Default",
                        "Does not meet the credit policy. Status:Charged Off"
                    ) THEN 1
                    ELSE 0
                END
            ) as defaults,
            ROUND(AVG(l.int_rate), 2) as avg_installment_rate,
            ROUND(AVG(l.loan_amnt), 0) as avg_loan_amount
        FROM loans l
            JOIN payment_status ps ON l.loan_id = ps.loan_id
        GROUP BY
            l.grade
    )
SELECT
    grade,
    total_loans,
    defaults,
    ROUND(
        100.0 * defaults / total_loans,
        2
    ) as default_rate_pct,
    avg_loan_amount,
    RANK() OVER (
        ORDER BY 100.0 * defaults / total_loans DESC
    ) as risk_rank
FROM grade_states
ORDER BY risk_rank;

-- Insight: Default rate rises sharply and consistently as grade worsens — from just 3.28% for A-grade loans
-- to 38.07% for G-grade loans, roughly a 12x difference — confirming that Lending Club's grading system is a
-- very strong, well-calibrated risk predictor. Interestingly, average loan amount doesn't follow a clean
-- pattern with grade (G has the highest at 20,384, but B and C are lower than D), suggesting risk-based
-- pricing (via interest rate) rather than loan size is the primary lever used to manage grade-level risk.

-- Query 8 — NTILE: Risk Scoring (splitting customers into 4 groups)
WITH
    borrower_risk AS (
        SELECT b.borrower_id, l.loan_id, b.annual_income, ch.fico_range_low, l.int_rate, ps.loan_status, NTILE(4) OVER (
                ORDER BY ch.fico_range_low ASC
            ) as fico_quartile
        FROM
            borrowers b
            JOIN credit_history ch ON ch.borrower_id = b.borrower_id
            JOIN loans l ON l.borrower_id = b.borrower_id
            JOIN payment_status ps ON ps.loan_id = l.loan_id
    )
SELECT
    fico_quartile,
    COUNT(*) as borrower_count,
    ROUND(AVG(annual_income), 0) as avg_annual_income,
    ROUND(AVG(int_rate), 2) as avg_interest_rate,
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
FROM borrower_risk
GROUP BY
    fico_quartile
ORDER BY fico_quartile;

-- Insight: FICO quartile shows the strongest and cleanest risk gradient seen so far — default rate drops
-- steadily from 16.79% in the lowest FICO quartile (quartile 1) to just 6.26% in the highest (quartile 4),
-- a nearly 2.7x difference, while average income and interest rate move in perfect lockstep with credit quality.
-- This confirms FICO as one of the single most reliable predictors of default in this dataset, even stronger
-- than income or DTI alone.