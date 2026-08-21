-- Category 6: Time-Series / Vintage Analysis

-- Default trends by issue year and quarter, and the impact of the recession.

-- Query 17 — Vintage Analysis: Default Trend by Issue Year
WITH
    vintage as (
        SELECT CAST(
                RIGHT(
                    TRIM(
                        TRAILING "\r"
                        FROM l.issue_d
                    ), 4
                ) as UNSIGNED
            ) as issue_year, ps.loan_status
        FROM loans l
            JOIN payment_status ps ON ps.loan_id = l.loan_id
    )
SELECT
    issue_year,
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
    ) AS default_rate_pct
FROM vintage
GROUP BY
    issue_year
ORDER BY issue_year;

-- Insight: Default rate peaked at 26.20% for the 2007 recession-era cohort — nearly double the rates seen from
-- 2010-2014 — confirming that recessionary loans carried significantly elevated risk. However, the sharp drop
-- for 2017 (8.83%) and 2018 (1.79%) is misleading: this query includes all loans regardless of status, and
-- these are the most recently issued loans, so most are still "Current" and haven't had time to default
-- yet — they shouldn't be compared directly to older, fully-matured cohorts.

-- Query 18: Quarter-wise Default Trend
WITH
    quarterly_vintage AS (
        SELECT
            CAST(
                RIGHT(
                    TRIM(
                        TRAILING '\r'
                        FROM l.issue_d
                    ),
                    4
                ) AS UNSIGNED
            ) AS issue_year,
            CASE LEFT(l.issue_d, 3)
                WHEN 'Jan' THEN 1
                WHEN 'Feb' THEN 1
                WHEN 'Mar' THEN 1
                WHEN 'Apr' THEN 2
                WHEN 'May' THEN 2
                WHEN 'Jun' THEN 2
                WHEN 'Jul' THEN 3
                WHEN 'Aug' THEN 3
                WHEN 'Sep' THEN 3
                WHEN 'Oct' THEN 4
                WHEN 'Nov' THEN 4
                WHEN 'Dec' THEN 4
            END AS issue_quarter,
            ps.loan_status
        FROM loans l
            JOIN payment_status ps ON l.loan_id = ps.loan_id
    )
SELECT
    issue_year,
    issue_quarter,
    COUNT(*) AS total_loans,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN loan_status IN (
                    'Charged Off',
                    'Default',
                    'Does not meet the credit policy. Status:Charged Off'
                ) THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS default_rate_pct
FROM quarterly_vintage
GROUP BY
    issue_year,
    issue_quarter
ORDER BY issue_year, issue_quarter;

-- Insight: Default rate peaked sharply at 29.56% in Q4 2007, right as the financial crisis was unfolding, and
-- stayed elevated through 2008 (17-23%) before gradually declining to more stable levels by
-- 2009-2010 — confirming the recession's direct impact on loan performance at a quarterly level of precision.
-- As before, the steep decline from 2017 onward (down to 0.10% by Q4 2018) reflects loan immaturity rather than
-- genuine risk reduction, since these are the most recently issued loans and haven't had time to default yet.