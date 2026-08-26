-- ============================================================
-- 00 - CREATE STAGING TABLES
--
-- Purpose:
--   Load the standardized Silver source files into persistent
--   DuckDB staging tables.
--
-- Run DuckDB from the project root:
--   duckdb duckdb/data_quality.duckdb
--
-- These tables are staging/input tables.
-- Cleaning is performed later in dedicated *_clean.sql files.
-- ============================================================


-- ============================================================
-- 01. CUSTOMERS
-- Source:
--   CSV UTF-8
--   delimiter: comma
-- ============================================================

CREATE OR REPLACE TABLE customers AS
SELECT *
FROM read_csv_auto(
    'data/03-silver/customers.csv'
);


-- ============================================================
-- 02. ORDERS
-- Source:
--   CSV UTF-8
--   delimiter: comma
--   BOM already removed during Bronze standardization
-- ============================================================

CREATE OR REPLACE TABLE orders AS
SELECT *
FROM read_csv_auto(
    'data/03-silver/orders.csv'
);


-- ============================================================
-- 03. ORDER ITEMS
-- Source:
--   originally pipe-delimited
--   standardized to comma in Bronze
-- ============================================================

CREATE OR REPLACE TABLE order_items AS
SELECT *
FROM read_csv_auto(
    'data/03-silver/order_items.csv'
);


-- ============================================================
-- 04. PRODUCTS
-- Source:
--   originally UTF-16LE + TAB
--
-- Bronze correction:
--   UTF-16LE -> UTF-8
--   TAB -> semicolon
--
-- Semicolon is preserved because numeric values use
-- comma as decimal separator (example: 4,20).
-- ============================================================

CREATE OR REPLACE TABLE products AS
SELECT *
FROM read_csv(
    'data/03-silver/products.csv',
    delim = ';',
    header = true
);


-- ============================================================
-- 05. STORES
-- Source:
--   stores.xml
--
-- XML was parsed with xmllint/XPath, extracted into temporary
-- column files and reconstructed as stores.csv.
--
-- Final CSV delimiter: semicolon
-- ============================================================

CREATE OR REPLACE TABLE stores AS
SELECT *
FROM read_csv(
    'data/03-silver/stores.csv',
    delim = ';',
    header = true
);


-- ============================================================
-- 06. CAMPAIGNS JSON - STAGING
--
-- Keep the original nested JSON structure here.
-- Flattening is performed later by:
--
--   01_campaigns_flat.sql
--   02_campaign_countries.sql
--   03_campaign_products.sql
-- ============================================================

CREATE OR REPLACE TABLE campaigns AS
SELECT *
FROM read_json_auto(
    'data/03-silver/campaigns.json'
);


-- ============================================================
-- 07. FINAL CHECK
-- ============================================================

SHOW TABLES;
