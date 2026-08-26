-- ============================================================
-- CLEANING: products
-- ============================================================

-- 01. Create cleaned table

CREATE OR REPLACE TABLE products_clean AS
SELECT
    prod_code,
    product_name,
    category,
    unit_cost,
    unit_price,
    CASE
        WHEN LOWER(active) IN ('y', 'yes', 'true') THEN 'Y'
        WHEN LOWER(active) IN ('n', 'no', 'false') THEN 'N'
        ELSE NULL
    END AS active
FROM products;


-- 02. Check cleaned table

SELECT *
FROM products_clean;


-- 03. Validate schema

DESCRIBE products_clean;


-- 04. Check NULL values

SELECT
    SUM(CASE WHEN prod_code IS NULL THEN 1 ELSE 0 END) AS prod_code_nulls,
    SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END) AS product_name_nulls,
    SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS category_nulls,
    SUM(CASE WHEN unit_cost IS NULL THEN 1 ELSE 0 END) AS unit_cost_nulls,
    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS unit_price_nulls,
    SUM(CASE WHEN active IS NULL THEN 1 ELSE 0 END) AS active_nulls
FROM products_clean;


-- 05. Check duplicate product codes

SELECT
    prod_code,
    COUNT(*) AS occurrences
FROM products_clean
GROUP BY prod_code
HAVING COUNT(*) > 1;


-- 06. Check products sold below cost

SELECT
    prod_code,
    product_name,
    unit_cost,
    unit_price,
    unit_price - unit_cost AS margin
FROM products_clean
WHERE unit_cost > unit_price;


-- 07. Export Silver clean table to Parquet

COPY products_clean
TO 'data/03-silver/clean/products_clean.parquet'
(FORMAT PARQUET);


-- 08. Verify exported Parquet

DESCRIBE
SELECT *
FROM read_parquet(
    'data/03-silver/clean/products_clean.parquet'
);
