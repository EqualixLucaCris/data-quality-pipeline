-- ============================================================
-- CLEANING: orders
-- Purpose:
--   Create a cleaned Silver version of orders,
--   normalize dates and status values,
--   remove confirmed full-row duplicates,
--   validate the final dataset,
--   export to Parquet.
-- ============================================================


-- 01. Create cleaned table
-- Normalize all valid order_date formats to DATE.
-- Invalid calendar dates become NULL.
-- Normalize status values to lowercase.

CREATE OR REPLACE TABLE orders_clean AS
SELECT
    order_no,
    cust_ref,
    store_ref,

    CASE
        WHEN TRY_CAST(order_date AS DATE) IS NOT NULL
            THEN TRY_CAST(order_date AS DATE)

        WHEN TRY_STRPTIME(order_date, '%d/%m/%Y') IS NOT NULL
            THEN TRY_STRPTIME(order_date, '%d/%m/%Y')::DATE

        WHEN TRY_STRPTIME(order_date, '%d-%m-%Y') IS NOT NULL
            THEN TRY_STRPTIME(order_date, '%d-%m-%Y')::DATE

        ELSE NULL
    END AS order_date,

    CASE
        WHEN LOWER(status) = 'completed' THEN 'completed'
        WHEN LOWER(status) = 'pending'   THEN 'pending'
        WHEN LOWER(status) = 'cancelled' THEN 'cancelled'
        ELSE LOWER(status)
    END AS status,

    currency

FROM orders;


-- 02. Remove confirmed full-row duplicate
-- Profiling showed two completely identical O1008 records.
-- SELECT DISTINCT preserves one valid occurrence.

CREATE OR REPLACE TABLE orders_clean AS
SELECT DISTINCT *
FROM orders_clean;


-- 03. Verify O1008 duplicate removal
-- Expected result: 1 row.

SELECT *
FROM orders_clean
WHERE order_no = 'O1008';


-- 04. Check cleaned table

SELECT *
FROM orders_clean;


-- 05. Validate final schema
-- order_date should now be DATE.

DESCRIBE orders_clean;


-- 06. Check total rows
-- Expected result: 8.

SELECT
    COUNT(*) AS total_rows
FROM orders_clean;


-- 07. Check SQL NULL values

SELECT
    SUM(CASE WHEN order_no IS NULL THEN 1 ELSE 0 END)
        AS order_no_nulls,

    SUM(CASE WHEN cust_ref IS NULL THEN 1 ELSE 0 END)
        AS cust_ref_nulls,

    SUM(CASE WHEN store_ref IS NULL THEN 1 ELSE 0 END)
        AS store_ref_nulls,

    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END)
        AS order_date_nulls,

    SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END)
        AS status_nulls,

    SUM(CASE WHEN currency IS NULL THEN 1 ELSE 0 END)
        AS currency_nulls

FROM orders_clean;


-- 08. Final full-row duplicate validation
-- Expected result: 0 rows.

SELECT
    order_no,
    cust_ref,
    store_ref,
    order_date,
    status,
    currency,
    COUNT(*) AS occurrences
FROM orders_clean
GROUP BY
    order_no,
    cust_ref,
    store_ref,
    order_date,
    status,
    currency
HAVING COUNT(*) > 1;


-- 09. Validate normalized status values

SELECT DISTINCT
    status
FROM orders_clean
ORDER BY status;


-- 10. Export certified Silver table to Parquet

COPY orders_clean
TO 'data/03-silver/clean/orders_clean.parquet'
(FORMAT PARQUET);


-- 11. Verify exported Parquet

DESCRIBE
SELECT *
FROM read_parquet(
    'data/03-silver/clean/orders_clean.parquet'
);


-- 12. Read exported Parquet

SELECT *
FROM read_parquet(
    'data/03-silver/clean/orders_clean.parquet'
);


-- ============================================================
-- CLEANING RESULT
--
-- - Valid order_date values normalized to DATE
-- - Multiple source date formats normalized
-- - Existing NULL order_date preserved
-- - Invalid date 2025-13-01 converted to NULL
-- - Status values normalized to lowercase
-- - Duplicate occurrence of order_no O1008 removed
-- - One valid O1008 record preserved
-- - Full-row duplicates after cleaning = 0
-- - Clean Silver dataset exported as Parquet
-- ============================================================
