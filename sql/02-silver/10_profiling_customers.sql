-- ============================================================
-- PROFILING: customers
-- Purpose:
--   Inspect schema, row counts, missing values, duplicates,
--   categorical values and signup-date quality
--   before Silver cleaning.
-- ============================================================


-- 01. Schema
DESCRIBE customers;


-- 02. General profiling
SUMMARIZE customers;


-- 03. Total rows
SELECT
    COUNT(*) AS total_rows
FROM customers;


-- 04. Missing values
-- Check both true SQL NULLs and the literal string 'NULL'.

SELECT
    SUM(
        CASE
            WHEN customer_id = 'NULL' OR customer_id IS NULL
            THEN 1 ELSE 0
        END
    ) AS customer_id_nulls,

    SUM(
        CASE
            WHEN full_name = 'NULL' OR full_name IS NULL
            THEN 1 ELSE 0
        END
    ) AS full_name_nulls,

    SUM(
        CASE
            WHEN email_address = 'NULL' OR email_address IS NULL
            THEN 1 ELSE 0
        END
    ) AS email_nulls,

    SUM(
        CASE
            WHEN Country = 'NULL' OR Country IS NULL
            THEN 1 ELSE 0
        END
    ) AS country_nulls,

    SUM(
        CASE
            WHEN City = 'NULL' OR City IS NULL
            THEN 1 ELSE 0
        END
    ) AS city_nulls,

    SUM(
        CASE
            WHEN signup_date = 'NULL' OR signup_date IS NULL
            THEN 1 ELSE 0
        END
    ) AS signup_date_nulls,

    SUM(
        CASE
            WHEN Segment = 'NULL' OR Segment IS NULL
            THEN 1 ELSE 0
        END
    ) AS segment_nulls

FROM customers;


-- 05. Inspect records containing customer_id or email NULLs

SELECT *
FROM customers
WHERE customer_id IS NULL
   OR email_address IS NULL;


-- 06. Full-row duplicates

SELECT
    customer_id,
    full_name,
    email_address,
    Country,
    City,
    signup_date,
    Segment,
    COUNT(*) AS occurrences
FROM customers
GROUP BY
    customer_id,
    full_name,
    email_address,
    Country,
    City,
    signup_date,
    Segment
HAVING COUNT(*) > 1;


-- 07. Duplicate customer_id

SELECT
    customer_id,
    COUNT(*) AS occurrences
FROM customers
WHERE customer_id IS NOT NULL
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- 08. Inspect confirmed duplicate record

SELECT *
FROM customers
WHERE customer_id = 'C006';


-- 09. Distinct countries

SELECT DISTINCT
    Country
FROM customers
ORDER BY Country;


-- 10. Distinct cities

SELECT DISTINCT
    City
FROM customers
ORDER BY City;


-- 11. Distinct customer segments

SELECT DISTINCT
    Segment
FROM customers
ORDER BY Segment;


-- 12. Inspect raw signup-date values

SELECT DISTINCT
    signup_date
FROM customers
ORDER BY signup_date;


-- 13. Test parsing of all known signup-date formats
--
-- Known representations:
--   YYYY-MM-DD
--   DD/MM/YYYY
--   MM-DD-YYYY
--   YYYY/MM/DD
--
-- DuckDB TRY_CAST handles the ISO-style representations.
-- Alternative formats are attempted with TRY_STRPTIME.
-- COALESCE returns the first successful non-NULL conversion.

SELECT
    signup_date,
    COALESCE(
        TRY_CAST(signup_date AS DATE),
        TRY_STRPTIME(signup_date, '%d/%m/%Y')::DATE,
        TRY_STRPTIME(signup_date, '%m-%d-%Y')::DATE
    ) AS parsed_date
FROM customers;


-- 14. Identify non-NULL signup dates that cannot be parsed
--     using any of the known formats.

SELECT
    signup_date
FROM customers
WHERE signup_date IS NOT NULL
  AND COALESCE(
        TRY_CAST(signup_date AS DATE),
        TRY_STRPTIME(signup_date, '%d/%m/%Y')::DATE,
        TRY_STRPTIME(signup_date, '%m-%d-%Y')::DATE
      ) IS NULL;


-- ============================================================
-- PROFILING NOTES
--
-- Findings:
--
-- - total rows = 9
-- - total columns = 7
-- - source data types = all VARCHAR
--
-- - source column names containing spaces were standardized:
--     "Customer ID"   -> customer_id
--     "Full Name"     -> full_name
--     "Email Address" -> email_address
--     "Signup Date"   -> signup_date
--
-- - customer_id NULLs = 1
-- - email_address NULLs = 1
-- - other column NULLs = 0
-- - the missing customer_id and missing email occur
--   in two different records
--
-- - full-row duplicate groups = 1
-- - duplicated customer_id involved = C006
-- - duplicate occurrences = 2
-- - duplicated record:
--     C006
--     Søren Jensen
--     soren.jensen@example.com
--     DK
--     København
--     2024-05-12
--     Corporate
--
-- - distinct countries = 6
--     BE, DE, DK, ES, FR, IT
--
-- - distinct cities = 8
--
-- - distinct segments = 3
--     Corporate
--     Consumer
--     Home Office
--
-- - signup_date source type = VARCHAR
-- - 4 signup-date representations observed:
--     YYYY-MM-DD
--     DD/MM/YYYY
--     MM-DD-YYYY
--     YYYY/MM/DD
--
-- - invalid calendar date found = 31/06/2024
--
-- Cleaning actions required:
--
-- - remove one occurrence of the confirmed full-row duplicate C006
-- - preserve/investigate the record with missing customer_id
-- - preserve/investigate the record with missing email_address
-- - normalize signup_date to DATE
-- - convert invalid signup date 31/06/2024 to NULL unless a
--   trusted source provides the correct value
-- - preserve standardized snake_case column names in customers_clean
--
-- IMPORTANT:
-- No cleaning is performed in this file.
-- Transformations belong in customers_clean.sql.
-- ============================================================
