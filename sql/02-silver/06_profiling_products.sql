-- ============================================================
-- PROFILING: products
-- Purpose:
--   Inspect schema, row counts, missing values, duplicates,
--   categorical values and numeric data quality
--   before Silver cleaning.
-- ============================================================


-- 01. Schema
DESCRIBE products;


-- 02. General profiling
SUMMARIZE products;


-- 03. Total rows
SELECT
    COUNT(*) AS total_rows
FROM products;


-- 04. Missing values
SELECT
    SUM(CASE WHEN prod_code IS NULL THEN 1 ELSE 0 END) AS prod_code_nulls,
    SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END) AS product_name_nulls,
    SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS category_nulls,
    SUM(CASE WHEN unit_cost IS NULL THEN 1 ELSE 0 END) AS unit_cost_nulls,
    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS unit_price_nulls,
    SUM(CASE WHEN active IS NULL THEN 1 ELSE 0 END) AS active_nulls
FROM products;


-- 05. Full-row duplicates
SELECT
    prod_code,
    product_name,
    category,
    unit_cost,
    unit_price,
    active,
    COUNT(*) AS occurrences
FROM products
GROUP BY
    prod_code,
    product_name,
    category,
    unit_cost,
    unit_price,
    active
HAVING COUNT(*) > 1;


-- 06. Duplicate product codes
SELECT
    prod_code,
    COUNT(*) AS occurrences
FROM products
GROUP BY prod_code
HAVING COUNT(*) > 1;


-- 07. Check whether unit_cost and unit_price are convertible
--     to DECIMAL(10,2).
--     This is useful when the staging table still stores them
--     as VARCHAR with comma decimal separators.

SELECT *
FROM products
WHERE
    (
        unit_cost IS NOT NULL
        AND TRY_CAST(
            REPLACE(unit_cost, ',', '.')
            AS DECIMAL(10,2)
        ) IS NULL
    )
    OR
    (
        unit_price IS NOT NULL
        AND TRY_CAST(
            REPLACE(unit_price, ',', '.')
            AS DECIMAL(10,2)
        ) IS NULL
    );


-- 08. Check zero or negative prices/costs
--     Run this after unit_cost and unit_price are numeric.

SELECT *
FROM products
WHERE unit_cost <= 0
   OR unit_price <= 0;


-- 09. Check products sold below cost

SELECT *
FROM products
WHERE unit_cost > unit_price;


-- 10. Check products with missing cost or price

SELECT *
FROM products
WHERE unit_cost IS NULL
   OR unit_price IS NULL;


-- 11. Count products with missing cost or price

SELECT
    COUNT(*) AS products_with_missing_price_or_cost
FROM products
WHERE unit_cost IS NULL
   OR unit_price IS NULL;


-- 12. Distinct categories

SELECT DISTINCT
    category
FROM products
ORDER BY category;


-- 13. Category distribution

SELECT
    category,
    COUNT(*) AS products
FROM products
GROUP BY category
ORDER BY products DESC;


-- 14. Distinct active values

SELECT DISTINCT
    active
FROM products
ORDER BY active;


-- 15. Active value distribution

SELECT
    active,
    COUNT(*) AS products
FROM products
GROUP BY active
ORDER BY products DESC;


-- 16. Check unexpected active values
--     Adapt the allowed values if your business rule changes.

SELECT *
FROM products
WHERE active IS NOT NULL
  AND LOWER(active) NOT IN ('y', 'n', 'yes', 'no', 'true', 'false');


-- 17. Numeric range check

SELECT
    MIN(unit_cost) AS min_unit_cost,
    MAX(unit_cost) AS max_unit_cost,
    AVG(unit_cost) AS avg_unit_cost,
    MIN(unit_price) AS min_unit_price,
    MAX(unit_price) AS max_unit_price,
    AVG(unit_price) AS avg_unit_price
FROM products;


-- 18. Margin check
--     Shows the absolute margin for every valid product.

SELECT
    prod_code,
    product_name,
    unit_cost,
    unit_price,
    unit_price - unit_cost AS margin
FROM products
WHERE unit_cost IS NOT NULL
  AND unit_price IS NOT NULL
ORDER BY margin;


-- 19. Check blank strings
--     Useful for text columns where a missing value may be ''
--     instead of SQL NULL.

SELECT *
FROM products
WHERE TRIM(prod_code) = ''
   OR TRIM(product_name) = ''
   OR TRIM(category) = ''
   OR TRIM(active) = '';


-- 20. Final profiling summary

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT prod_code) AS distinct_product_codes,
    COUNT(DISTINCT category) AS distinct_categories,
    COUNT(DISTINCT active) AS distinct_active_values
FROM products;

-- 21. Products sold below cost - details

SELECT
    prod_code,
    product_name,
    unit_cost,
    unit_price,
    unit_price - unit_cost AS margin
FROM products
WHERE unit_cost > unit_price;

-- ============================================================
-- PROFILING NOTES
--
-- Findings:
--
-- - total row count = 8
-- - missing values: unit_cost = 1, other columns = 0
-- - full-row duplicates = 0
-- - duplicate prod_code = 0
-- - numeric conversion issues = 0
-- - zero / negative prices or costs = 0
-- - products sold below cost = 1
--     prod_code = P005
--     product_name = Lampada Øresund
--     unit_cost = 18.00
--     unit_price = 17.50
--     margin = -0.50
-- - category consistency = 6 distinct categories
-- - active values = 3 distinct values: Y, N, yes
-- - active normalization required = yes
-- - blank strings = 0
-- - unit_cost range = min 1.20 / max 18.00
-- - unit_price range = min 3.50 / max 17.50
-- - margin range = min -0.50 / max 7.49
--
-- Cleaning actions required:
--
-- - standardize column names
-- - convert unit_cost to DECIMAL(10,2)
-- - convert unit_price to DECIMAL(10,2)
-- - handle 1 missing unit_cost
-- - normalize active values
-- - investigate / resolve product P005 sold below cost
--
-- IMPORTANT:
-- No cleaning should be performed in this file.
-- Transformations belong in products_clean.sql.
-- ============================================================
