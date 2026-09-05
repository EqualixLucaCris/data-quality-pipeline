-- ============================================================
-- PROFILING: order_items
-- File: 14_profiling_order_items.sql
-- ============================================================

-- 01. Schema
DESCRIBE order_items;

-- 02. General profiling
SUMMARIZE order_items;

-- 03. Total rows
SELECT COUNT(*) AS total_rows
FROM order_items;
-- Observed: 11

-- 04. Missing values
SELECT
    SUM(CASE WHEN line_id IS NULL OR TRIM(line_id) = '' THEN 1 ELSE 0 END) AS line_id_issues,
    SUM(CASE WHEN order_no IS NULL OR TRIM(order_no) = '' THEN 1 ELSE 0 END) AS order_no_issues,
    SUM(CASE WHEN product_code IS NULL OR TRIM(product_code) = '' THEN 1 ELSE 0 END) AS product_code_issues,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS quantity_nulls,
    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS unit_price_nulls,
    SUM(CASE WHEN discount IS NULL THEN 1 ELSE 0 END) AS discount_nulls
FROM order_items;

-- 05. line_id uniqueness
SELECT COUNT(DISTINCT line_id) AS unique_line_ids
FROM order_items;
-- Observed: 10

SELECT line_id, COUNT(*) AS occurrences
FROM order_items
GROUP BY line_id
HAVING COUNT(*) > 1;
-- Observed: L010 -> 2

-- 06. Full-row duplicates
SELECT
    line_id,
    order_no,
    product_code,
    quantity,
    unit_price,
    discount,
    COUNT(*) AS duplicate_rows
FROM order_items
GROUP BY
    line_id,
    order_no,
    product_code,
    quantity,
    unit_price,
    discount
HAVING COUNT(*) > 1;
-- Observed exact duplicate: L010 -> 2 occurrences

-- 07. Business-rule violations
-- Rules:
-- quantity > 0
-- unit_price > 0
-- discount between 0 and 100
SELECT *
FROM order_items
WHERE quantity <= 0
   OR unit_price <= 0
   OR discount < 0
   OR discount > 100;

-- Observed:
-- L007 -> quantity = 0
-- L008 -> discount = 110
-- L009 -> quantity = -1

-- 08. Numeric ranges
SELECT
    MIN(quantity) AS min_quantity,
    MAX(quantity) AS max_quantity,
    MIN(unit_price) AS min_unit_price,
    MAX(unit_price) AS max_unit_price,
    MIN(discount) AS min_discount,
    MAX(discount) AS max_discount
FROM order_items;

-- 09. Referential integrity: order_no -> orders_clean.order_no
SELECT DISTINCT
    oi.order_no,
    o.order_no AS matched_order_no
FROM order_items AS oi
LEFT JOIN orders_clean AS o
    ON oi.order_no = o.order_no
WHERE o.order_no IS NULL;

-- 10. Referential integrity: product_code -> products_clean.prod_code
SELECT DISTINCT
    oi.product_code,
    p.prod_code AS matched_prod_code
FROM order_items AS oi
LEFT JOIN products_clean AS p
    ON oi.product_code = p.prod_code
WHERE p.prod_code IS NULL;

-- ============================================================
-- PROFILING NOTES
-- ============================================================
-- total rows = 11
-- current column names:
--   line_id, order_no, product_code, quantity, unit_price, discount
-- unique line_id values = 10
-- duplicate line_id = L010
-- L010 is also an exact full-row duplicate
-- business-rule violations:
--   L007 -> quantity = 0
--   L008 -> discount = 110
--   L009 -> quantity = -1
-- unit_price values are positive in observed data
-- suspected orphan product reference = P999
-- confirm orphan order/product references with checks above
--
-- Cleaning belongs in 15_order_items_clean.sql
-- ============================================================
