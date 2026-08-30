-- ============================================================
-- PROFILING: campaign JSON tables
-- File: 12_profiling_campaigns.sql
-- ============================================================

-- 01. campaigns_flat
DESCRIBE campaigns_flat;

SELECT COUNT(*) AS total_rows
FROM campaigns_flat;

SELECT *
FROM campaigns_flat
ORDER BY campaign_id, name;

SELECT
    SUM(CASE WHEN campaign_id IS NULL OR campaign_id = 'NULL' THEN 1 ELSE 0 END) AS campaign_id_nulls,
    SUM(CASE WHEN name IS NULL OR name = 'NULL' THEN 1 ELSE 0 END) AS name_nulls,
    SUM(CASE WHEN active IS NULL THEN 1 ELSE 0 END) AS active_nulls,
    SUM(CASE WHEN exported_at IS NULL THEN 1 ELSE 0 END) AS exported_at_nulls
FROM campaigns_flat;

SELECT
    SUM(CASE WHEN TRIM(campaign_id) = '' THEN 1 ELSE 0 END) AS blank_campaign_id,
    SUM(CASE WHEN TRIM(name) = '' THEN 1 ELSE 0 END) AS blank_name
FROM campaigns_flat;

SELECT
    campaign_id,
    COUNT(*) AS occurrences
FROM campaigns_flat
WHERE campaign_id IS NOT NULL
GROUP BY campaign_id
HAVING COUNT(*) > 1;

-- Observed: MKT-002 -> 2 occurrences.
-- These are duplicate business keys, not exact duplicate rows.

SELECT DISTINCT active
FROM campaigns_flat;

-- Observed JSON values: true, false, "yes".
-- Silver target type: BOOLEAN.


-- 02. campaign_countries
DESCRIBE campaign_countries;

SELECT COUNT(*) AS total_rows
FROM campaign_countries;

SELECT *
FROM campaign_countries
ORDER BY campaign_id, country;

SELECT
    SUM(CASE WHEN campaign_id IS NULL OR TRIM(campaign_id) = '' THEN 1 ELSE 0 END) AS campaign_id_issues,
    SUM(CASE WHEN country IS NULL OR TRIM(country) = '' THEN 1 ELSE 0 END) AS country_issues
FROM campaign_countries;

-- Grain: campaign_id + country
SELECT
    campaign_id,
    country,
    COUNT(*) AS occurrences
FROM campaign_countries
GROUP BY campaign_id, country
HAVING COUNT(*) > 1;

-- Orphan campaign references
SELECT DISTINCT
    cc.campaign_id,
    cf.campaign_id AS matched_campaign_id
FROM campaign_countries AS cc
LEFT JOIN campaigns_flat AS cf
    ON cc.campaign_id = cf.campaign_id
WHERE cf.campaign_id IS NULL;


-- 03. campaign_products
DESCRIBE campaign_products;

SELECT COUNT(*) AS total_rows
FROM campaign_products;

SELECT *
FROM campaign_products
ORDER BY campaign_id, product_code;

SELECT
    SUM(CASE WHEN campaign_id IS NULL OR TRIM(campaign_id) = '' THEN 1 ELSE 0 END) AS campaign_id_issues,
    SUM(CASE WHEN product_code IS NULL OR TRIM(product_code) = '' THEN 1 ELSE 0 END) AS product_code_issues,
    SUM(CASE WHEN discount_pct IS NULL THEN 1 ELSE 0 END) AS discount_pct_nulls
FROM campaign_products;

-- Grain: campaign_id + product_code
SELECT
    campaign_id,
    product_code,
    COUNT(*) AS occurrences
FROM campaign_products
GROUP BY campaign_id, product_code
HAVING COUNT(*) > 1;

SELECT
    MIN(discount_pct) AS min_discount_pct,
    MAX(discount_pct) AS max_discount_pct
FROM campaign_products;

-- Orphan product references
SELECT
    cp.campaign_id,
    cp.product_code,
    p.prod_code
FROM campaign_products AS cp
LEFT JOIN products_clean AS p
    ON cp.product_code = p.prod_code
WHERE p.prod_code IS NULL;

-- Observed: MKT-002 | P999 | NULL

-- Orphan campaign references
SELECT DISTINCT
    cp.campaign_id,
    cf.campaign_id AS matched_campaign_id
FROM campaign_products AS cp
LEFT JOIN campaigns_flat AS cf
    ON cp.campaign_id = cf.campaign_id
WHERE cf.campaign_id IS NULL;


-- ============================================================
-- PROFILING SUMMARY
-- ============================================================
-- campaigns_flat:
-- - 3 rows
-- - duplicate business key: MKT-002
-- - active is JSON and contains true, false, "yes"
-- - campaign_id/name blank strings observed: 0
--
-- campaign_countries:
-- - child table from JSON flattening
-- - campaign_id repetition is expected
-- - logical grain: campaign_id + country
--
-- campaign_products:
-- - 4 rows observed
-- - logical grain: campaign_id + product_code
-- - P999 is an orphan product reference
-- ============================================================
