-- Category 5: Profitability Analysis

-- Not just default rate — the actual net return at the grade and sub-grade level.

-- Query 15: Profitability / Net Return by Grade
WITH
    grade_return as (
        SELECT l.grade, l.loan_amnt, l.int_rate, ps.total_pymnt, ps.loan_status, (ps.total_pymnt - l.loan_amnt) AS net_dollar_return
        FROM loans l
            JOIN payment_status ps ON ps.loan_id = l.loan_id
        WHERE
            ps.loan_status in (
                'Fully Paid',
                'Charged Off',
                'Default',
                'Does not meet the credit policy. Status:Fully Paid',
                'Does not meet the credit policy. Status:Charged Off'
            )
    )
SELECT
    grade,
    COUNT(*) as total_loans,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN loan_status IN (
                    "Charged Off",
                    "Default",
                    "Does not meet the credit policy. Status:Charged Off"
                ) THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS default_rate_pct,
    ROUND(AVG(int_rate), 2) as avg_interest_rate,
    ROUND(SUM(net_dollar_return), 0) as total_net_return,
    ROUND(
        100.0 * SUM(net_dollar_return) / SUM(loan_amnt),
        2
    ) as net_return_pct_of_principal
FROM grade_return
GROUP BY
    grade
ORDER BY net_return_pct_of_principal DESC;

-- Insight: Contrary to the assumption that higher interest rates compensate for higher risk, net return
-- actually declines monotonically with grade — Grade A delivers the best return (5.32% of principal) despite
-- the lowest interest rate, while grades E, F, and G are outright unprofitable (down to -8.67% for G), meaning
-- their elevated default rates overwhelm the extra interest charged. This directly answers the key
-- differentiator question: a lower default rate does correlate with being the better investment here —high-risk
-- grades are not compensated adequately by their higher rates.

-- Query 16: Subgrade Level Profitability
WITH
    grade_return as (
        SELECT l.sub_grade, l.loan_amnt, l.int_rate, ps.total_pymnt, ps.loan_status, (ps.total_pymnt - l.loan_amnt) AS net_dollar_return
        FROM loans l
            JOIN payment_status ps ON ps.loan_id = l.loan_id
        WHERE
            ps.loan_status in (
                'Fully Paid',
                'Charged Off',
                'Default',
                'Does not meet the credit policy. Status:Fully Paid',
                'Does not meet the credit policy. Status:Charged Off'
            )
    )
SELECT
    sub_grade,
    COUNT(*) as total_loans,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN loan_status IN (
                    "Charged Off",
                    "Default",
                    "Does not meet the credit policy. Status:Charged Off"
                ) THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS default_rate_pct,
    ROUND(AVG(int_rate), 2) as avg_interest_rate,
    ROUND(SUM(net_dollar_return), 0) as total_net_return,
    ROUND(
        100.0 * SUM(net_dollar_return) / SUM(loan_amnt),
        2
    ) as net_return_pct_of_principal
FROM grade_return
GROUP BY
    sub_grade
ORDER BY net_return_pct_of_principal DESC;

-- Insight: Zooming into sub-grades reveals that profitability doesn't drop off cleanly at grade
-- boundaries — B5 (3.99%) still outperforms C1 (3.55%), and within grade D, D1 stays marginally
-- profitable (1.54%) while D3 and D5 dip slightly negative — suggesting that a sub-grade-level
-- cutoff would let Lending Club capture more profitable loans than a blunt grade-level policy,
-- without sacrificing much volume.