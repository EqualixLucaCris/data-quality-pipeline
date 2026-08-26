-- ============================================================
-- PROFILING: orders
-- Purpose:
--   Inspect schema, row counts, missing values, duplicates,
--   categorical values and date quality before Silver cleaning.
-- ============================================================


-- 01. Schema
DESCRIBE orders;


-- 02. General profiling
-- Check customer/store references, order_date formats,
-- status consistency and currency values.
SUMMARIZE orders;


-- 03. Total rows
SELECT
    COUNT(*) AS total_rows
FROM orders;


-- 04. Missing or literal 'NULL' values
SELECT
    SUM(CASE WHEN order_no = 'NULL' OR order_no IS NULL
        THEN 1 ELSE 0 END) AS order_no_nulls,
    SUM(CASE WHEN cust_ref = 'NULL' OR cust_ref IS NULL
        THEN 1 ELSE 0 END) AS cust_ref_nulls,
    SUM(CASE WHEN store_ref = 'NULL' OR store_ref IS NULL
        THEN 1 ELSE 0 END) AS store_ref_nulls,
    SUM(CASE WHEN order_date = 'NULL' OR order_date IS NULL
        THEN 1 ELSE 0 END) AS order_date_nulls,
    SUM(CASE WHEN status = 'NULL' OR status IS NULL
        THEN 1 ELSE 0 END) AS status_nulls,
    SUM(CASE WHEN currency = 'NULL' OR currency IS NULL
        THEN 1 ELSE 0 END) AS currency_nulls
FROM orders;

-- Finding:
-- 1 true SQL NULL exists in order_date.


-- 05. Full-row duplicates
SELECT
    order_no,
    cust_ref,
    store_ref,
    order_date,
    status,
    currency,
    COUNT(*) AS occurrences
FROM orders
GROUP BY
    order_no,
    cust_ref,
    store_ref,
    order_date,
    status,
    currency
HAVING COUNT(*) > 1;

-- Finding:
-- One complete duplicated record exists.
-- duplicated order_no involved = O1008
-- occurrences = 2


-- 06. Duplicate order_no
SELECT
    order_no,
    COUNT(*) AS occurrences
FROM orders
GROUP BY order_no
HAVING COUNT(*) > 1;


-- 07. Distinct categorical/reference values

-- Number of distinct order numbers
SELECT
    COUNT(DISTINCT order_no) AS distinct_order_no
FROM orders;

-- Customer references
SELECT DISTINCT
    cust_ref
FROM orders
ORDER BY cust_ref;

-- Store references
SELECT DISTINCT
    store_ref
FROM orders
ORDER BY store_ref;

-- Raw order-date values
SELECT DISTINCT
    order_date
FROM orders
ORDER BY order_date;

-- Status values
SELECT DISTINCT
    status
FROM orders
ORDER BY status;

-- Currency values
SELECT DISTINCT
    currency
FROM orders
ORDER BY currency;


-- 08. Date profiling

-- Inspect all raw date values
SELECT
    order_date
FROM orders;


-- Test DuckDB automatic DATE conversion
SELECT
    order_date,
    TRY_CAST(order_date AS DATE) AS parsed_date
FROM orders;


-- Parse all known valid date representations
SELECT
    order_date,
    COALESCE(
        TRY_CAST(order_date AS DATE),
        TRY_STRPTIME(order_date, '%d/%m/%Y')::DATE,
        TRY_STRPTIME(order_date, '%d-%m-%Y')::DATE
    ) AS parsed_date
FROM orders;


-- Show non-NULL values that cannot be parsed using
-- any of the known date formats.
SELECT
    order_date
FROM orders
WHERE order_date IS NOT NULL
  AND TRY_CAST(order_date AS DATE) IS NULL
  AND TRY_STRPTIME(order_date, '%d/%m/%Y') IS NULL
  AND TRY_STRPTIME(order_date, '%d-%m-%Y') IS NULL;

-- Finding:
-- 2025-13-01 is an invalid calendar date.


-- ============================================================
-- PROFILING NOTES
--
-- Findings:
--
-- - total rows = 9
-- - missing order_date = 1 true SQL NULL
-- - full-row duplicate groups = 1
-- - duplicated order_no involved = O1008
-- - duplicate occurrences = 2
-- - distinct store_ref values = 4
-- - currency values = 1
-- - logical status values = Completed / Pending
-- - status formatting is inconsistent and requires normalization
-- - 4 date representations observed:
--     YYYY-MM-DD
--     DD/MM/YYYY
--     YYYY/MM/DD
--     DD-MM-YYYY
-- - valid alternative date formats can be parsed
-- - invalid calendar date found = 2025-13-01
--
-- Cleaning actions required:
--
-- - remove the confirmed full-row duplicate
-- - normalize status values
-- - normalize order_date to DATE
-- - preserve the existing NULL order_date
-- - convert invalid date 2025-13-01 to NULL unless a trusted
--   source provides the correct value
--
-- IMPORTANT:
-- No cleaning is performed in this file.
-- Transformations belong in orders_clean.sql.
-- ============================================================
