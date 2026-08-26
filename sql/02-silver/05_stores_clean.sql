-- ============================================================
-- CLEANING: stores
-- Purpose:
--   Create a cleaned Silver version of stores,
--   normalize missing values and dates,
--   remove the confirmed duplicate,
--   validate the final result,
--   export to Parquet.
-- ============================================================


-- 01. Create cleaned table
-- Convert literal 'NULL' into a true SQL NULL.
-- Normalize valid date formats.
-- Invalid calendar dates become NULL.

CREATE OR REPLACE TABLE stores_clean AS
SELECT
    NULLIF(store_id, 'NULL') AS store_id,
    name,
    country,
    city,
    CASE
        WHEN TRY_CAST(opened AS DATE) IS NOT NULL
            THEN TRY_CAST(opened AS DATE)

        WHEN TRY_STRPTIME(opened, '%d-%m-%Y') IS NOT NULL
            THEN TRY_STRPTIME(opened, '%d-%m-%Y')::DATE

        ELSE NULL
    END AS opened,
    manager
FROM stores;


-- 02. Remove confirmed duplicate record

DELETE FROM stores_clean
WHERE name = 'Antwerpen Zuid Duplicate';


-- 03. Check cleaned table

SELECT *
FROM stores_clean;


-- 04. Validate final schema

DESCRIBE stores_clean;


-- 05. Check total rows after cleaning

SELECT
    COUNT(*) AS total_rows
FROM stores_clean;


-- 06. Check real SQL NULLs

SELECT
    SUM(CASE WHEN store_id IS NULL THEN 1 ELSE 0 END) AS store_id_nulls,
    SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS name_nulls,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS country_nulls,
    SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS city_nulls,
    SUM(CASE WHEN opened IS NULL THEN 1 ELSE 0 END) AS opened_nulls,
    SUM(CASE WHEN manager IS NULL THEN 1 ELSE 0 END) AS manager_nulls
FROM stores_clean;


-- 07. Verify store_id duplicates are gone

SELECT
    store_id,
    COUNT(*) AS occurrences
FROM stores_clean
WHERE store_id IS NOT NULL
GROUP BY store_id
HAVING COUNT(*) > 1;


-- 08. Export certified Silver table to Parquet

COPY stores_clean
TO 'data/03-silver/clean/stores_clean.parquet'
(FORMAT PARQUET);


-- 09. Verify exported Parquet

DESCRIBE
SELECT *
FROM read_parquet(
    'data/03-silver/clean/stores_clean.parquet'
);


-- ============================================================
-- CLEANING RESULT
--
-- - Literal 'NULL' converted to SQL NULL
-- - opened converted from VARCHAR to DATE
-- - DD-MM-YYYY date parsed explicitly
-- - Invalid date 2025-02-30 converted to NULL
-- - Confirmed duplicate store S03 removed
-- - Clean Silver dataset exported as Parquet
-- ============================================================
