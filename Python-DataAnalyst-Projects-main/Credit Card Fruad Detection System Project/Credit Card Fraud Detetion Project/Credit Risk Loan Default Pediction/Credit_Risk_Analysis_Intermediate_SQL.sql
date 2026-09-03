-- ============================================================
-- CREDIT RISK & LOAN DEFAULT ANALYSIS
-- Intermediate SQL Project | MySQL 8+
-- Dataset: credit_risk_dataset.csv
--
-- Portfolio flow:
-- CSV -> MySQL -> Data Quality -> Risk Analysis -> Insights -> Power BI
--
-- MySQL 8+ is recommended because this project uses CTEs and
-- window functions.
-- ============================================================

-- ============================================================
-- 01. DATABASE SETUP
-- ============================================================

DROP DATABASE IF EXISTS credit_risk_analysis;
CREATE DATABASE credit_risk_analysis;
USE credit_risk_analysis;

DROP TABLE IF EXISTS credit_risk;

CREATE TABLE credit_risk (
    person_age INT,
    person_income INT,
    person_home_ownership VARCHAR(20),
    person_emp_length DECIMAL(5,2),
    loan_intent VARCHAR(30),
    loan_grade VARCHAR(5),
    loan_amnt INT,
    loan_int_rate DECIMAL(5,2),
    loan_status INT,
    loan_percent_income DECIMAL(6,4),
    cb_person_default_on_file CHAR(1),
    cb_person_cred_hist_length INT
);

-- ============================================================
-- 02. IMPORT CSV
-- ============================================================
-- Option A: Use MySQL Workbench:
-- Server -> Data Import -> Import CSV
--
-- Option B: LOAD DATA LOCAL INFILE
-- Update the path to your own CSV file.
--
-- SET GLOBAL local_infile = 1;
--
-- LOAD DATA LOCAL INFILE 'C:/path/credit_risk_dataset.csv'
-- INTO TABLE credit_risk
-- FIELDS TERMINATED BY ','
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS
-- (
--     person_age,
--     person_income,
--     person_home_ownership,
--     person_emp_length,
--     loan_intent,
--     loan_grade,
--     loan_amnt,
--     loan_int_rate,
--     loan_status,
--     loan_percent_income,
--     cb_person_default_on_file,
--     cb_person_cred_hist_length
-- );

-- ============================================================
-- 03. DATA VALIDATION
-- ============================================================

-- Total records
SELECT COUNT(*) AS total_records
FROM credit_risk;

-- Preview
SELECT *
FROM credit_risk
LIMIT 10;

-- Check data types / table structure
DESCRIBE credit_risk;

-- Duplicate rows
SELECT
    person_age,
    person_income,
    person_home_ownership,
    person_emp_length,
    loan_intent,
    loan_grade,
    loan_amnt,
    loan_int_rate,
    loan_status,
    loan_percent_income,
    cb_person_default_on_file,
    cb_person_cred_hist_length,
    COUNT(*) AS duplicate_count
FROM credit_risk
GROUP BY
    person_age,
    person_income,
    person_home_ownership,
    person_emp_length,
    loan_intent,
    loan_grade,
    loan_amnt,
    loan_int_rate,
    loan_status,
    loan_percent_income,
    cb_person_default_on_file,
    cb_person_cred_hist_length
HAVING COUNT(*) > 1;

-- Missing values
SELECT
    SUM(person_age IS NULL) AS missing_age,
    SUM(person_income IS NULL) AS missing_income,
    SUM(person_home_ownership IS NULL) AS missing_home_ownership,
    SUM(person_emp_length IS NULL) AS missing_emp_length,
    SUM(loan_intent IS NULL) AS missing_loan_intent,
    SUM(loan_grade IS NULL) AS missing_loan_grade,
    SUM(loan_amnt IS NULL) AS missing_loan_amount,
    SUM(loan_int_rate IS NULL) AS missing_interest_rate,
    SUM(loan_status IS NULL) AS missing_loan_status,
    SUM(loan_percent_income IS NULL) AS missing_percent_income,
    SUM(cb_person_default_on_file IS NULL) AS missing_previous_default,
    SUM(cb_person_cred_hist_length IS NULL) AS missing_credit_history
FROM credit_risk;

-- Check loan status values
SELECT
    loan_status,
    COUNT(*) AS record_count
FROM credit_risk
GROUP BY loan_status
ORDER BY loan_status;

-- Check loan grades
SELECT
    loan_grade,
    COUNT(*) AS record_count
FROM credit_risk
GROUP BY loan_grade
ORDER BY loan_grade;

-- Check unusually high ages
SELECT
    person_age,
    COUNT(*) AS customer_count
FROM credit_risk
GROUP BY person_age
ORDER BY person_age DESC;

-- Check invalid / unusual income and loan values
SELECT *
FROM credit_risk
WHERE person_income <= 0
   OR loan_amnt <= 0
   OR loan_percent_income < 0
   OR loan_int_rate < 0;

-- ============================================================
-- 04. OVERALL BUSINESS KPIs
-- ============================================================

SELECT
    COUNT(*) AS total_loans,
    SUM(loan_status) AS total_defaults,
    COUNT(*) - SUM(loan_status) AS non_default_loans,

    ROUND(
        SUM(loan_status) * 100.0 / COUNT(*),
        2
    ) AS default_rate_percent,

    ROUND(AVG(person_income), 2) AS avg_income,
    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(AVG(loan_int_rate), 2) AS avg_interest_rate,
    ROUND(AVG(loan_percent_income), 4) AS avg_loan_income_ratio
FROM credit_risk;

-- ============================================================
-- 05. DEFAULT VS NON-DEFAULT
-- ============================================================

SELECT
    CASE
        WHEN loan_status = 1 THEN 'Default'
        ELSE 'Non-Default'
    END AS loan_outcome,

    COUNT(*) AS total_loans,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM credit_risk),
        2
    ) AS portfolio_percentage,

    ROUND(AVG(person_income), 2) AS avg_income,
    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(AVG(loan_int_rate), 2) AS avg_interest_rate

FROM credit_risk
GROUP BY loan_status
ORDER BY loan_status DESC;

-- ============================================================
-- 06. LOAN GRADE RISK ANALYSIS
-- ============================================================

SELECT
    loan_grade,
    COUNT(*) AS total_loans,
    SUM(loan_status) AS defaults,

    COUNT(*) - SUM(loan_status) AS non_defaults,

    ROUND(
        SUM(loan_status) * 100.0 / COUNT(*),
        2
    ) AS default_rate_percent,

    ROUND(AVG(loan_int_rate), 2) AS avg_interest_rate,
    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(AVG(person_income), 2) AS avg_income

FROM credit_risk
GROUP BY loan_grade
ORDER BY loan_grade;

-- ============================================================
-- 07. LOAN INTENT ANALYSIS
-- ============================================================

SELECT
    loan_intent,
    COUNT(*) AS total_loans,
    SUM(loan_status) AS defaults,

    ROUND(
        SUM(loan_status) * 100.0 / COUNT(*),
        2
    ) AS default_rate_percent,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(AVG(loan_int_rate), 2) AS avg_interest_rate

FROM credit_risk
GROUP BY loan_intent
ORDER BY default_rate_percent DESC;

-- ============================================================
-- 08. HOME OWNERSHIP RISK
-- ============================================================

SELECT
    person_home_ownership,
    COUNT(*) AS total_loans,
    SUM(loan_status) AS defaults,

    ROUND(
        SUM(loan_status) * 100.0 / COUNT(*),
        2
    ) AS default_rate_percent,

    ROUND(AVG(person_income), 2) AS avg_income,
    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount

FROM credit_risk
GROUP BY person_home_ownership
ORDER BY default_rate_percent DESC;

-- ============================================================
-- 09. PREVIOUS DEFAULT ANALYSIS
-- ============================================================

SELECT
    cb_person_default_on_file AS previous_default,
    COUNT(*) AS total_loans,
    SUM(loan_status) AS defaults,

    ROUND(
        SUM(loan_status) * 100.0 / COUNT(*),
        2
    ) AS default_rate_percent

FROM credit_risk
GROUP BY cb_person_default_on_file
ORDER BY default_rate_percent DESC;

-- ============================================================
-- 10. LOAN-INCOME RATIO RISK
-- ============================================================

SELECT
    CASE
        WHEN loan_percent_income >= 0.50 THEN 'High Exposure'
        WHEN loan_percent_income >= 0.30 THEN 'Medium Exposure'
        ELSE 'Low Exposure'
    END AS exposure_category,

    COUNT(*) AS total_loans,
    SUM(loan_status) AS defaults,

    ROUND(
        SUM(loan_status) * 100.0 / COUNT(*),
        2
    ) AS default_rate_percent,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(AVG(person_income), 2) AS avg_income

FROM credit_risk

GROUP BY
    CASE
        WHEN loan_percent_income >= 0.50 THEN 'High Exposure'
        WHEN loan_percent_income >= 0.30 THEN 'Medium Exposure'
        ELSE 'Low Exposure'
    END

ORDER BY default_rate_percent DESC;

-- ============================================================
-- 11. EMPLOYMENT LENGTH ANALYSIS
-- ============================================================

SELECT
    CASE
        WHEN person_emp_length < 2 THEN '0-1 Years'
        WHEN person_emp_length < 5 THEN '2-4 Years'
        WHEN person_emp_length < 10 THEN '5-9 Years'
        ELSE '10+ Years'
    END AS employment_group,

    COUNT(*) AS total_loans,
    SUM(loan_status) AS defaults,

    ROUND(
        SUM(loan_status) * 100.0 / COUNT(*),
        2
    ) AS default_rate_percent,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount

FROM credit_risk

WHERE person_emp_length IS NOT NULL

GROUP BY
    CASE
        WHEN person_emp_length < 2 THEN '0-1 Years'
        WHEN person_emp_length < 5 THEN '2-4 Years'
        WHEN person_emp_length < 10 THEN '5-9 Years'
        ELSE '10+ Years'
    END

ORDER BY default_rate_percent DESC;

-- ============================================================
-- 12. AGE GROUP ANALYSIS
-- ============================================================

SELECT
    CASE
        WHEN person_age < 25 THEN 'Under 25'
        WHEN person_age < 35 THEN '25-34'
        WHEN person_age < 45 THEN '35-44'
        WHEN person_age < 55 THEN '45-54'
        ELSE '55+'
    END AS age_group,

    COUNT(*) AS total_loans,
    SUM(loan_status) AS defaults,

    ROUND(
        SUM(loan_status) * 100.0 / COUNT(*),
        2
    ) AS default_rate_percent,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(AVG(person_income), 2) AS avg_income

FROM credit_risk

GROUP BY
    CASE
        WHEN person_age < 25 THEN 'Under 25'
        WHEN person_age < 35 THEN '25-34'
        WHEN person_age < 45 THEN '35-44'
        WHEN person_age < 55 THEN '45-54'
        ELSE '55+'
    END

ORDER BY default_rate_percent DESC;

-- ============================================================
-- 13. INTEREST RATE BAND ANALYSIS
-- ============================================================

SELECT
    CASE
        WHEN loan_int_rate < 8 THEN 'Below 8%'
        WHEN loan_int_rate < 12 THEN '8% - 11.99%'
        WHEN loan_int_rate < 16 THEN '12% - 15.99%'
        WHEN loan_int_rate < 20 THEN '16% - 19.99%'
        ELSE '20%+'
    END AS interest_rate_band,

    COUNT(*) AS total_loans,
    SUM(loan_status) AS defaults,

    ROUND(
        SUM(loan_status) * 100.0 / COUNT(*),
        2
    ) AS default_rate_percent

FROM credit_risk

WHERE loan_int_rate IS NOT NULL

GROUP BY
    CASE
        WHEN loan_int_rate < 8 THEN 'Below 8%'
        WHEN loan_int_rate < 12 THEN '8% - 11.99%'
        WHEN loan_int_rate < 16 THEN '12% - 15.99%'
        WHEN loan_int_rate < 20 THEN '16% - 19.99%'
        ELSE '20%+'
    END

ORDER BY default_rate_percent DESC;

-- ============================================================
-- 14. SUBQUERY: ABOVE-AVERAGE LOANS
-- ============================================================

SELECT
    person_age,
    person_income,
    loan_amnt,
    loan_grade,
    loan_int_rate,
    loan_status

FROM credit_risk

WHERE loan_amnt >
(
    SELECT AVG(loan_amnt)
    FROM credit_risk
)

ORDER BY loan_amnt DESC;

-- ============================================================
-- 15. SUBQUERY: ABOVE-AVERAGE INCOME BORROWERS
-- ============================================================

SELECT
    person_age,
    person_income,
    loan_amnt,
    loan_grade,
    loan_status

FROM credit_risk

WHERE person_income >
(
    SELECT AVG(person_income)
    FROM credit_risk
)

ORDER BY person_income DESC;

-- ============================================================
-- 16. CTE: CUSTOMER RISK SEGMENTATION
-- ============================================================

WITH customer_risk AS (

    SELECT
        person_age,
        person_income,
        loan_amnt,
        loan_int_rate,
        loan_grade,
        loan_percent_income,
        loan_status,

        CASE
            WHEN loan_percent_income >= 0.50
                 OR loan_grade IN ('E','F','G')
            THEN 'High Risk'

            WHEN loan_percent_income >= 0.30
                 OR loan_grade IN ('C','D')
            THEN 'Medium Risk'

            ELSE 'Low Risk'
        END AS risk_category

    FROM credit_risk
)

SELECT
    risk_category,
    COUNT(*) AS total_loans,
    SUM(loan_status) AS defaults,

    ROUND(
        SUM(loan_status) * 100.0 / COUNT(*),
        2
    ) AS default_rate_percent,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(AVG(person_income), 2) AS avg_income

FROM customer_risk

GROUP BY risk_category

ORDER BY default_rate_percent DESC;

-- ============================================================
-- 17. CTE: RISK SCORE
-- ============================================================

WITH risk_scoring AS (

    SELECT
        person_age,
        person_income,
        loan_amnt,
        loan_grade,
        loan_percent_income,
        cb_person_default_on_file,
        loan_status,

        (
            CASE
                WHEN loan_grade IN ('E','F','G') THEN 3
                WHEN loan_grade IN ('C','D') THEN 2
                ELSE 1
            END

            +

            CASE
                WHEN loan_percent_income >= 0.50 THEN 3
                WHEN loan_percent_income >= 0.30 THEN 2
                ELSE 1
            END

            +

            CASE
                WHEN cb_person_default_on_file = 'Y' THEN 2
                ELSE 0
            END

        ) AS risk_score

    FROM credit_risk
)

SELECT
    *,
    CASE
        WHEN risk_score >= 7 THEN 'High Risk'
        WHEN risk_score >= 4 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category

FROM risk_scoring

ORDER BY risk_score DESC;

-- ============================================================
-- 18. WINDOW FUNCTION: RANK BY LOAN AMOUNT
-- ============================================================

SELECT
    person_age,
    person_income,
    loan_amnt,
    loan_grade,
    loan_status,

    RANK() OVER (
        ORDER BY loan_amnt DESC
    ) AS loan_rank

FROM credit_risk;

-- ============================================================
-- 19. WINDOW FUNCTION: RANK WITHIN EACH LOAN GRADE
-- ============================================================

SELECT
    loan_grade,
    person_income,
    loan_amnt,
    loan_status,

    RANK() OVER (
        PARTITION BY loan_grade
        ORDER BY loan_amnt DESC
    ) AS grade_rank

FROM credit_risk;

-- ============================================================
-- 20. TOP 3 BORROWERS WITHIN EACH GRADE
-- ============================================================

WITH ranked_borrowers AS (

    SELECT
        loan_grade,
        person_income,
        loan_amnt,
        loan_int_rate,
        loan_status,

        ROW_NUMBER() OVER (
            PARTITION BY loan_grade
            ORDER BY loan_amnt DESC
        ) AS rn

    FROM credit_risk
)

SELECT
    loan_grade,
    person_income,
    loan_amnt,
    loan_int_rate,
    loan_status

FROM ranked_borrowers

WHERE rn <= 3

ORDER BY loan_grade, loan_amnt DESC;

-- ============================================================
-- 21. WINDOW FUNCTION: GRADE AVERAGE COMPARISON
-- ============================================================

SELECT
    loan_grade,
    person_income,
    loan_amnt,

    ROUND(
        AVG(loan_amnt) OVER (
            PARTITION BY loan_grade
        ),
        2
    ) AS grade_avg_loan,

    ROUND(
        loan_amnt -
        AVG(loan_amnt) OVER (
            PARTITION BY loan_grade
        ),
        2
    ) AS difference_from_grade_avg

FROM credit_risk

ORDER BY loan_grade, difference_from_grade_avg DESC;

-- ============================================================
-- 22. WINDOW FUNCTION: PORTFOLIO DEFAULT RATE
-- ============================================================

SELECT
    loan_grade,
    loan_status,

    COUNT(*) OVER (
        PARTITION BY loan_grade
    ) AS grade_total_loans,

    SUM(loan_status) OVER (
        PARTITION BY loan_grade
    ) AS grade_total_defaults,

    ROUND(
        SUM(loan_status) OVER (
            PARTITION BY loan_grade
        ) * 100.0
        /
        COUNT(*) OVER (
            PARTITION BY loan_grade
        ),
        2
    ) AS grade_default_rate

FROM credit_risk;

-- ============================================================
-- 23. MULTI-DIMENSIONAL RISK ANALYSIS
-- ============================================================

SELECT
    loan_grade,
    loan_intent,

    COUNT(*) AS total_loans,
    SUM(loan_status) AS defaults,

    ROUND(
        SUM(loan_status) * 100.0 / COUNT(*),
        2
    ) AS default_rate_percent,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(AVG(loan_int_rate), 2) AS avg_interest_rate

FROM credit_risk

GROUP BY
    loan_grade,
    loan_intent

HAVING COUNT(*) >= 50

ORDER BY default_rate_percent DESC;

-- ============================================================
-- 24. HIGH-RISK BORROWER PROFILE
-- ============================================================

SELECT
    loan_grade,
    loan_intent,
    person_home_ownership,
    cb_person_default_on_file,

    COUNT(*) AS total_loans,
    SUM(loan_status) AS defaults,

    ROUND(
        SUM(loan_status) * 100.0 / COUNT(*),
        2
    ) AS default_rate_percent,

    ROUND(AVG(loan_percent_income), 4) AS avg_loan_income_ratio,
    ROUND(AVG(loan_int_rate), 2) AS avg_interest_rate

FROM credit_risk

GROUP BY
    loan_grade,
    loan_intent,
    person_home_ownership,
    cb_person_default_on_file

HAVING COUNT(*) >= 30

ORDER BY default_rate_percent DESC
LIMIT 20;

-- ============================================================
-- 25. BUSINESS INSIGHT QUERY
-- Highest-risk loan grades
-- ============================================================

SELECT
    loan_grade,
    COUNT(*) AS total_loans,
    SUM(loan_status) AS defaults,

    ROUND(
        SUM(loan_status) * 100.0 / COUNT(*),
        2
    ) AS default_rate_percent

FROM credit_risk

GROUP BY loan_grade

HAVING COUNT(*) >= 100

ORDER BY default_rate_percent DESC
LIMIT 3;

-- ============================================================
-- 26. BUSINESS INSIGHT QUERY
-- Highest-risk loan intents
-- ============================================================

SELECT
    loan_intent,
    COUNT(*) AS total_loans,
    SUM(loan_status) AS defaults,

    ROUND(
        SUM(loan_status) * 100.0 / COUNT(*),
        2
    ) AS default_rate_percent

FROM credit_risk

GROUP BY loan_intent

HAVING COUNT(*) >= 100

ORDER BY default_rate_percent DESC;

-- ============================================================
-- 27. FINAL MANAGEMENT SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS total_loans,

    SUM(loan_status) AS total_defaults,

    ROUND(
        SUM(loan_status) * 100.0 / COUNT(*),
        2
    ) AS overall_default_rate,

    ROUND(AVG(person_income), 2) AS average_income,

    ROUND(AVG(loan_amnt), 2) AS average_loan_amount,

    ROUND(AVG(loan_int_rate), 2) AS average_interest_rate,

    ROUND(
        MAX(loan_amnt),
        2
    ) AS maximum_loan_amount

FROM credit_risk;

-- ============================================================
-- END OF PROJECT
-- ============================================================
