-- ============================================================
-- SILVER CLEANING: customers
-- File: 11_customers_clean.sql
-- Purpose:
--   Create the cleaned customers table from the profiled source,
--   standardize column names and signup dates, remove exact
--   duplicate rows, validate remaining quality issues, and
--   export the Silver result to Parquet.
-- ============================================================

-- 01. CREATE CLEAN TABLE
CREATE OR REPLACE TABLE customers_clean AS
SELECT
    customer_id,
    full_name,
    email_address,
    Country AS country,
    City AS city,
    COALESCE(
        TRY_CAST(signup_date AS DATE),
        TRY_STRPTIME(signup_date, '%d/%m/%Y')::DATE,
        TRY_STRPTIME(signup_date, '%m-%d-%Y')::DATE
    ) AS signup_date,
    Segment AS segment
FROM customers;

-- 02. REMOVE EXACT DUPLICATES
-- Profiling identified one complete duplicate for customer_id C006.
-- Source rows: 9
-- Expected rows after deduplication: 8
CREATE OR REPLACE TABLE customers_clean AS
SELECT DISTINCT *
FROM customers_clean;

-- 03. VALIDATE SCHEMA
DESCRIBE customers_clean;

-- 04. VALIDATE ROW COUNT
SELECT COUNT(*) AS total_rows
FROM customers_clean;

-- Expected: 8 rows

-- 05. VALIDATE DUPLICATES
SELECT
    customer_id,
    full_name,
    email_address,
    country,
    city,
    signup_date,
    segment,
    COUNT(*) AS occurrences
FROM customers_clean
GROUP BY
    customer_id,
    full_name,
    email_address,
    country,
    city,
    signup_date,
    segment
HAVING COUNT(*) > 1;

-- Expected: 0 rows

-- 06. VALIDATE REMAINING NULL VALUES
SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS customer_id_nulls,
    SUM(CASE WHEN full_name IS NULL THEN 1 ELSE 0 END) AS full_name_nulls,
    SUM(CASE WHEN email_address IS NULL THEN 1 ELSE 0 END) AS email_address_nulls,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS country_nulls,
    SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS city_nulls,
    SUM(CASE WHEN signup_date IS NULL THEN 1 ELSE 0 END) AS signup_date_nulls,
    SUM(CASE WHEN segment IS NULL THEN 1 ELSE 0 END) AS segment_nulls
FROM customers_clean;

-- Expected remaining quality issues:
-- - José Álvarez: customer_id IS NULL
-- - Élodie Bernard (C005): email_address IS NULL
-- - invalid source signup date 31/06/2024 becomes NULL

-- 07. INSPECT RECORDS WITH REMAINING NULLS
SELECT *
FROM customers_clean
WHERE customer_id IS NULL
   OR email_address IS NULL
   OR signup_date IS NULL
ORDER BY customer_id;

-- 08. REFERENTIAL INTEGRITY CHECK: orders -> customers
-- Find customer references in orders_clean with no matching customer.
SELECT DISTINCT
    o.cust_ref,
    c.customer_id
FROM orders_clean AS o
LEFT JOIN customers_clean AS c
    ON o.cust_ref = c.customer_id
WHERE c.customer_id IS NULL;

-- Observed finding:
-- - C999 is referenced by orders_clean but has no matching customer_id.

-- 09. REVERSE CHECK: customers -> orders
SELECT
    c.customer_id,
    c.full_name,
    c.email_address
FROM customers_clean AS c
LEFT JOIN orders_clean AS o
    ON c.customer_id = o.cust_ref
WHERE o.cust_ref IS NULL;

-- Observed finding:
-- - José Álvarez has customer_id = NULL and therefore cannot be
--   matched to orders using the available business key.
-- - There is insufficient evidence to conclude that C999 belongs
--   to José Álvarez. No identifier is fabricated or inferred.

-- 10. EXPORT CLEAN SILVER DATA TO PARQUET
COPY customers_clean
TO 'data/03-silver/clean/customers_clean.parquet'
(FORMAT PARQUET);

-- 11. VERIFY EXPORTED PARQUET
SELECT *
FROM read_parquet(
    'data/03-silver/clean/customers_clean.parquet'
)
ORDER BY customer_id;

-- ============================================================
-- FINAL CLEANING SUMMARY
-- ============================================================
-- Source rows: 9
-- Final rows:  8
--
-- Completed:
-- - standardized remaining column names
-- - converted signup_date from VARCHAR to DATE
-- - handled multiple source date representations
-- - invalid date 31/06/2024 converted to NULL
-- - removed one exact duplicate row for C006
-- - preserved the valid customer record with missing email
-- - preserved unresolved record with missing customer_id
-- - identified orphan customer reference C999 in orders_clean
-- - avoided unsupported inference between C999 and José Álvarez
-- - exported customers_clean to Parquet
--
-- Remaining documented issues:
-- - 1 missing customer_id
-- - 1 missing email_address
-- - 1 NULL signup_date caused by an invalid source date
-- - 1 orphan customer reference in orders_clean: C999
--
-- Unresolved values are documented rather than replaced with
-- invented data.
-- ============================================================
