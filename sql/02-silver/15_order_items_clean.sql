-- ============================================================
-- SILVER CLEANING: order_items
-- File: 15_order_items_clean.sql
-- Purpose:
--   Clean order item records after profiling by removing exact
--   duplicates, enforcing business rules, validating references
--   to orders/products, preserving rejected records, validating
--   the final table and exporting Silver output to Parquet.
-- ============================================================

-- 01. CREATE REJECTED TABLE
CREATE OR REPLACE TABLE order_items_rejected AS
SELECT
    oi.*,
    CASE
        WHEN oi.quantity <= 0 THEN 'invalid_quantity'
        WHEN oi.unit_price <= 0 THEN 'invalid_unit_price'
        WHEN oi.discount < 0 OR oi.discount > 100 THEN 'invalid_discount'
        WHEN o.order_no IS NULL THEN 'orphan_order_no'
        WHEN p.prod_code IS NULL THEN 'orphan_product_code'
        ELSE 'unknown_rejection_reason'
    END AS rejection_reason
FROM order_items AS oi
LEFT JOIN orders_clean AS o
    ON oi.order_no = o.order_no
LEFT JOIN products_clean AS p
    ON oi.product_code = p.prod_code
WHERE oi.quantity <= 0
   OR oi.unit_price <= 0
   OR oi.discount < 0
   OR oi.discount > 100
   OR o.order_no IS NULL
   OR p.prod_code IS NULL;

-- 02. CREATE CLEAN TABLE
CREATE OR REPLACE TABLE order_items_clean AS
SELECT DISTINCT
    oi.line_id,
    oi.order_no,
    oi.product_code,
    oi.quantity,
    oi.unit_price,
    oi.discount
FROM order_items AS oi
INNER JOIN orders_clean AS o
    ON oi.order_no = o.order_no
INNER JOIN products_clean AS p
    ON oi.product_code = p.prod_code
WHERE oi.quantity > 0
  AND oi.unit_price > 0
  AND oi.discount BETWEEN 0 AND 100;

-- 03. VALIDATE FINAL ROW COUNT
SELECT COUNT(*) AS total_rows
FROM order_items_clean;
-- Expected: 5 rows

-- 04. VALIDATE FINAL DATA
SELECT *
FROM order_items_clean
ORDER BY line_id;

-- 05. VALIDATE EXACT DUPLICATES
SELECT
    line_id,
    order_no,
    product_code,
    quantity,
    unit_price,
    discount,
    COUNT(*) AS total_duplicates
FROM order_items_clean
GROUP BY
    line_id,
    order_no,
    product_code,
    quantity,
    unit_price,
    discount
HAVING COUNT(*) > 1;
-- Expected: 0 rows

-- 06. VALIDATE LINE_ID UNIQUENESS
SELECT
    line_id,
    COUNT(*) AS occurrences
FROM order_items_clean
GROUP BY line_id
HAVING COUNT(*) > 1;
-- Expected: 0 rows

-- 07. VALIDATE BUSINESS RULES
SELECT
    COUNT(*) AS invalid_rows
FROM order_items_clean
WHERE quantity <= 0
   OR unit_price <= 0
   OR discount < 0
   OR discount > 100;
-- Expected: 0

-- 08. VALIDATE PRODUCT REFERENTIAL INTEGRITY
SELECT
    oic.line_id,
    oic.order_no,
    oic.product_code,
    pc.prod_code AS matched_product_code
FROM order_items_clean AS oic
LEFT JOIN products_clean AS pc
    ON oic.product_code = pc.prod_code
WHERE pc.prod_code IS NULL;
-- Expected: 0 rows

-- 09. VALIDATE ORDER REFERENTIAL INTEGRITY
SELECT
    oic.line_id,
    oic.order_no,
    oc.order_no AS matched_order_no
FROM order_items_clean AS oic
LEFT JOIN orders_clean AS oc
    ON oic.order_no = oc.order_no
WHERE oc.order_no IS NULL;
-- Expected: 0 rows

-- 10. REVIEW REJECTED RECORDS
SELECT *
FROM order_items_rejected
ORDER BY line_id;

-- 11. EXPORT CLEAN SILVER DATA TO PARQUET
COPY order_items_clean
TO 'data/03-silver/clean/order_items_clean.parquet'
(FORMAT PARQUET);

-- 12. EXPORT REJECTED DATA TO PARQUET
COPY order_items_rejected
TO 'data/05-rejected/order_items_rejected.parquet'
(FORMAT PARQUET);

-- 13. VERIFY CLEAN PARQUET OUTPUT
SELECT *
FROM read_parquet(
    'data/03-silver/clean/order_items_clean.parquet'
)
ORDER BY line_id;

-- 14. VERIFY REJECTED PARQUET OUTPUT
SELECT *
FROM read_parquet(
    'data/05-rejected/order_items_rejected.parquet'
)
ORDER BY line_id;

-- ============================================================
-- FINAL CLEANING SUMMARY
-- ============================================================
-- Source rows: 11
-- Final clean rows: 5
--
-- Findings handled:
-- - exact duplicate: L010 duplicated in source
-- - L007 -> quantity = 0
-- - L008 -> discount = 110
-- - L009 -> quantity = -1
-- - orphan product reference: P999
-- - orphan order reference: O1010
--
-- Final validation:
-- - duplicate rows = 0
-- - duplicate line_id values = 0
-- - invalid quantity/price/discount rows = 0
-- - orphan product references = 0
-- - orphan order references = 0
--
-- order_items_clean is now suitable for Gold-layer analytics.
-- ============================================================
