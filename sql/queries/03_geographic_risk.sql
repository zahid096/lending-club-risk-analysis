-- Category 3: Geographic Risk

-- State-wise concentration of risk.

-- Query 9: State - wise Risk Concentration
SELECT
    b.state,
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
    (
        SELECT ROUND(
                100.0 * SUM(
                    CASE
                        WHEN loan_status in (
                            "Charged Off", "Default", "Does not meet the credit policy. Status:Charged Off"
                        ) THEN 1
                        ELSE 0
                    END
                ) / COUNT(*), 2
            )
        FROM payment_status
    ) as national_avg_default_rate
FROM
    borrowers b
    JOIN loans l ON l.borrower_id = b.borrower_id
    JOIN payment_status ps ON ps.loan_id = l.loan_id
GROUP BY
    b.state
HAVING
    COUNT(*) >= 100
ORDER BY default_rate_pct DESC
LIMIT 15;

-- Insight: Alabama has the highest default rate among high-volume states at 14.42%, over 2.5 percentage points
-- above the national average (11.92%), with Arkansas, Louisiana, Oklahoma, and Nevada close behind — all in the
-- 13.6-14.2% range. Interestingly, high-volume states like New York (186,389 loans) and Florida (161,991 loans)
-- also sit meaningfully above the national average, showing that elevated risk isn't confined to small,
-- thin-volume states — it's present at scale in major lending markets too.

-- national_avg
SELECT ROUND(
        100.0 * SUM(
            CASE
                WHEN loan_status IN (
                    'Charged Off', 'Default', 'Does not meet the credit policy. Status:Charged Off'
                ) THEN 1
                ELSE 0
            END
        ) / COUNT(*), 2
    ) AS national_avg
FROM payment_status;

SELECT
    b.state,
    COUNT(*) AS total_loans,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN ps.loan_status IN (
                    'Charged Off',
                    'Default',
                    'Does not meet the credit policy. Status:Charged Off'
                ) THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS default_rate_pct,
    11.92 AS national_avg_default_rate
FROM
    borrowers b
    JOIN loans l ON b.borrower_id = l.borrower_id
    JOIN payment_status ps ON l.loan_id = ps.loan_id
GROUP BY
    b.state
HAVING
    COUNT(*) >= 100
ORDER BY default_rate_pct DESC
LIMIT 15;

CREATE TABLE state_default_summary AS
SELECT
    b.state,
    COUNT(*) AS total_loans,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN ps.loan_status IN (
                    'Charged Off',
                    'Default',
                    'Does not meet the credit policy. Status:Charged Off'
                ) THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS default_rate_pct
FROM
    borrowers b
    JOIN loans l ON b.borrower_id = l.borrower_id
    JOIN payment_status ps ON l.loan_id = ps.loan_id
GROUP BY
    b.state
HAVING
    COUNT(*) >= 100;

SELECT *, 11.92 AS national_avg_default_rate
FROM state_default_summary
ORDER BY default_rate_pct DESC
LIMIT 15;