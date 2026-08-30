-- ============================================================
-- SILVER CLEANING: campaign JSON tables
-- File: 13_campaigns_clean.sql
-- ============================================================

-- 01. Clean campaign master
-- MKT-002 appears twice. One source row is explicitly labelled
-- "Belle Été duplicate", so that explicit duplicate record is
-- excluded. active is normalized from JSON to BOOLEAN.

CREATE OR REPLACE TABLE campaigns_clean AS
SELECT
    TRIM(campaign_id) AS campaign_id,
    TRIM(name) AS name,
    CASE
        WHEN LOWER(REPLACE(CAST(active AS VARCHAR), '"', ''))
             IN ('true', 'yes', 'y', '1') THEN TRUE
        WHEN LOWER(REPLACE(CAST(active AS VARCHAR), '"', ''))
             IN ('false', 'no', 'n', '0') THEN FALSE
        ELSE NULL
    END AS active,
    exported_at
FROM campaigns_flat
WHERE NOT (
    campaign_id = 'MKT-002'
    AND LOWER(name) LIKE '%duplicate%'
);

-- Validate master
DESCRIBE campaigns_clean;

SELECT *
FROM campaigns_clean
ORDER BY campaign_id;

SELECT campaign_id, COUNT(*) AS occurrences
FROM campaigns_clean
GROUP BY campaign_id
HAVING COUNT(*) > 1;


-- 02. Clean campaign-country relationships
CREATE OR REPLACE TABLE campaign_countries_clean AS
SELECT DISTINCT
    TRIM(cc.campaign_id) AS campaign_id,
    UPPER(TRIM(cc.country)) AS country
FROM campaign_countries AS cc
INNER JOIN campaigns_clean AS c
    ON cc.campaign_id = c.campaign_id
WHERE cc.campaign_id IS NOT NULL
  AND cc.country IS NOT NULL
  AND TRIM(cc.campaign_id) <> ''
  AND TRIM(cc.country) <> '';

-- Preserve rejected campaign-country records
CREATE OR REPLACE TABLE campaign_countries_rejected AS
SELECT
    cc.*,
    'orphan_or_invalid_campaign_country_relationship' AS rejection_reason
FROM campaign_countries AS cc
LEFT JOIN campaigns_clean AS c
    ON cc.campaign_id = c.campaign_id
WHERE c.campaign_id IS NULL
   OR cc.campaign_id IS NULL
   OR cc.country IS NULL
   OR TRIM(cc.campaign_id) = ''
   OR TRIM(cc.country) = '';

-- Validate
SELECT campaign_id, country, COUNT(*) AS occurrences
FROM campaign_countries_clean
GROUP BY campaign_id, country
HAVING COUNT(*) > 1;


-- 03. Preserve rejected campaign-product records
CREATE OR REPLACE TABLE campaign_products_rejected AS
SELECT
    cp.*,
    CASE
        WHEN c.campaign_id IS NULL THEN 'orphan_campaign_id'
        WHEN p.prod_code IS NULL THEN 'orphan_product_code'
        WHEN cp.discount_pct IS NULL THEN 'missing_discount_pct'
        ELSE 'invalid_campaign_product_relationship'
    END AS rejection_reason
FROM campaign_products AS cp
LEFT JOIN campaigns_clean AS c
    ON cp.campaign_id = c.campaign_id
LEFT JOIN products_clean AS p
    ON cp.product_code = p.prod_code
WHERE c.campaign_id IS NULL
   OR p.prod_code IS NULL
   OR cp.discount_pct IS NULL;

-- Observed rejected relationship: MKT-002 / P999.


-- 04. Clean campaign-product relationships
CREATE OR REPLACE TABLE campaign_products_clean AS
SELECT DISTINCT
    TRIM(cp.campaign_id) AS campaign_id,
    TRIM(cp.product_code) AS product_code,
    cp.discount_pct
FROM campaign_products AS cp
INNER JOIN campaigns_clean AS c
    ON cp.campaign_id = c.campaign_id
INNER JOIN products_clean AS p
    ON cp.product_code = p.prod_code
WHERE cp.campaign_id IS NOT NULL
  AND cp.product_code IS NOT NULL
  AND cp.discount_pct IS NOT NULL
  AND TRIM(cp.campaign_id) <> ''
  AND TRIM(cp.product_code) <> '';

-- Validate
SELECT campaign_id, product_code, COUNT(*) AS occurrences
FROM campaign_products_clean
GROUP BY campaign_id, product_code
HAVING COUNT(*) > 1;


-- 05. Final referential-integrity checks
SELECT cc.campaign_id, cc.country
FROM campaign_countries_clean AS cc
LEFT JOIN campaigns_clean AS c
    ON cc.campaign_id = c.campaign_id
WHERE c.campaign_id IS NULL;

SELECT cp.campaign_id, cp.product_code
FROM campaign_products_clean AS cp
LEFT JOIN campaigns_clean AS c
    ON cp.campaign_id = c.campaign_id
WHERE c.campaign_id IS NULL;

SELECT cp.campaign_id, cp.product_code
FROM campaign_products_clean AS cp
LEFT JOIN products_clean AS p
    ON cp.product_code = p.prod_code
WHERE p.prod_code IS NULL;


-- 06. Export clean Silver Parquet
COPY campaigns_clean
TO 'data/03-silver/clean/campaigns_clean.parquet'
(FORMAT PARQUET);

COPY campaign_countries_clean
TO 'data/03-silver/clean/campaign_countries_clean.parquet'
(FORMAT PARQUET);

COPY campaign_products_clean
TO 'data/03-silver/clean/campaign_products_clean.parquet'
(FORMAT PARQUET);


-- 07. Export rejected rows
COPY campaign_countries_rejected
TO 'data/05-rejected/campaign_countries_rejected.parquet'
(FORMAT PARQUET);

COPY campaign_products_rejected
TO 'data/05-rejected/campaign_products_rejected.parquet'
(FORMAT PARQUET);


-- 08. Verify exports
SELECT *
FROM read_parquet('data/03-silver/clean/campaigns_clean.parquet')
ORDER BY campaign_id;

SELECT *
FROM read_parquet('data/03-silver/clean/campaign_countries_clean.parquet')
ORDER BY campaign_id, country;

SELECT *
FROM read_parquet('data/03-silver/clean/campaign_products_clean.parquet')
ORDER BY campaign_id, product_code;


-- ============================================================
-- FINAL SUMMARY
-- ============================================================
-- - active normalized JSON -> BOOLEAN
-- - explicit duplicate MKT-002 record removed
-- - child-table grains preserved
-- - only valid campaign references retained
-- - only valid product references retained
-- - orphan P999 preserved in rejected output
-- - no invalid identifiers fabricated
-- ============================================================
