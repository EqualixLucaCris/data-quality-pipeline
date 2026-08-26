-- ============================================================
-- PROFILING: stores
-- Purpose:
--   Inspect schema, row counts, missing values, duplicates,
--   categorical values and date quality before Silver cleaning.
-- ============================================================


-- 01. Schema
DESCRIBE stores;


-- 02. General profiling
SUMMARIZE stores;


-- 03. Total rows
SELECT
    COUNT(*) AS total_rows
FROM stores;


-- 04. Missing values
-- NOTE:
-- store_id currently contains the literal string 'NULL'
-- rather than a true SQL NULL.

SELECT
    SUM(CASE WHEN store_id = 'NULL' THEN 1 ELSE 0 END) AS store_id_nulls,
    SUM(CASE WHEN name = 'NULL' THEN 1 ELSE 0 END) AS name_nulls,
    SUM(CASE WHEN country = 'NULL' THEN 1 ELSE 0 END) AS country_nulls,
    SUM(CASE WHEN city = 'NULL' THEN 1 ELSE 0 END) AS city_nulls,
    SUM(CASE WHEN opened = 'NULL' THEN 1 ELSE 0 END) AS opened_nulls,
    SUM(CASE WHEN manager = 'NULL' THEN 1 ELSE 0 END) AS manager_nulls
FROM stores;


-- 05. Full-row duplicates
SELECT
    store_id,
    name,
    country,
    city,
    opened,
    manager,
    COUNT(*) AS occurrences
FROM stores
GROUP BY
    store_id,
    name,
    country,
    city,
    opened,
    manager
HAVING COUNT(*) > 1;


-- 06. Duplicate store_id
SELECT
    store_id,
    COUNT(*) AS occurrences
FROM stores
GROUP BY store_id
HAVING COUNT(*) > 1;


-- 07. Distinct categorical values

-- Countries
SELECT DISTINCT
    country
FROM stores
ORDER BY country;


-- Cities
SELECT DISTINCT
    city
FROM stores
ORDER BY city;


-- Managers
SELECT DISTINCT
    manager
FROM stores
ORDER BY manager;


-- 08. Date profiling
-- First inspect all raw values.

SELECT
    opened
FROM stores
ORDER BY opened;


-- Try DuckDB automatic DATE conversion.
-- TRY_CAST returns NULL instead of failing when conversion is impossible.

SELECT
    opened,
    TRY_CAST(opened AS DATE) AS parsed_date
FROM stores;


-- Show only values that DuckDB cannot directly interpret as DATE.

SELECT
    opened
FROM stores
WHERE TRY_CAST(opened AS DATE) IS NULL;


-- ============================================================
-- PROFILING NOTES
--
-- Observed so far:
-- - 5 total records
-- - 1 logical missing store_id ('NULL' string)
-- - duplicate store_id: S03
-- - no full-row duplicates
-- - 1 country: BE
-- - 4 distinct cities
-- - 4 distinct managers
-- - opened is VARCHAR
-- - opened contains multiple date formats
-- - at least one invalid calendar date exists
--
-- No cleaning is performed in this file.
-- Transformations belong in clean_stores.sql.
-- ============================================================

-- 08. Date profiling
-- Findings:
-- 2019-03-15 -> valid
-- 2020/07/01 -> valid, automatically parsed by DuckDB
-- 01-11-2021 -> valid DD-MM-YYYY, requires explicit parsing
-- 2021-11-01 -> valid
-- 2025-02-30 -> invalid calendar date that will be registered as NULL

SELECT
    opened,
    TRY_STRPTIME(opened, '%d-%m-%Y')::DATE AS parsed_date
FROM stores;

