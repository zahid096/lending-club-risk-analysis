-- Category 7: Policy Simulation

-- Simulating the trade-off of applying a FICO cutoff.

-- Query 19 — Policy Cutoff Simulation (Trade-off Query)
WITH
    cutoff_sim as (
        SELECT ch.fico_range_low, b.dti, ps.loan_status
        FROM
            borrowers b
            JOIN credit_history ch ON b.borrower_id = ch.borrower_id
            JOIN loans l ON b.borrower_id = l.borrower_id
            JOIN payment_status ps ON l.loan_id = ps.loan_id
        WHERE
            ps.loan_status IN (
                'Fully Paid',
                'Charged Off',
                'Default',
                'Does not meet the credit policy. Status:Fully Paid',
                'Does not meet the credit policy. Status:Charged Off'
            )
    )
SELECT
    CASE
        WHEN fico_range_low >= 680 THEN 'Above Cutoff (Approved)'
        ELSE 'Below Cutoff (Rejected)'
    END as policy_bucket,
    COUNT(*) AS total_loans,
    SUM(
        CASE
            WHEN loan_status in (
                'Charged Off',
                'Default',
                'Does not meet the credit policy. Status:Charged Off'
            ) THEN 1
            ELSE 0
        END
    ) AS defaults,
    SUM(
        CASE
            WHEN loan_status in (
                'Fully Paid',
                'Does not meet the credit policy. Status:Fully Paid'
            ) THEN 1
            ELSE 0
        END
    ) as good_loans_lost
FROM cutoff_sim
GROUP BY
    policy_bucket;

-- Insight: Setting a hard FICO 680 cutoff is a blunt instrument — for every default it prevents, it also turns
-- away roughly 3 borrowers who would have fully repaid their loans (344,129 good loans lost vs. 116,575 defaults
-- avoided), suggesting Lending Club's actual approach of risk-based pricing (variable interest rates by grade)
-- captures more value than an outright rejection policy would.