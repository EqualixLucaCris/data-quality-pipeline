# DATA CATALOG

## Purpose

This catalog provides a concise inventory of the trusted datasets used by the Data Quality Pipeline.

It documents dataset purpose, Medallion layer, storage format, logical grain, keys, relationships, quality rules and Gold analytical outputs.

---

# Silver Layer

Silver contains validated, cleaned datasets used as the trusted input for Gold analytics.

Clean Silver outputs are persisted as Parquet under:

`data/03-silver/clean/`

Rejected records are persisted separately under:

`data/05-rejected/`

## customers_clean

**Layer:** Silver  
**Format:** Parquet  
**Purpose:** Validated customer master data.  
**Grain:** One row per customer after deduplication and cleaning.

Main fields:
- `customer_id`
- `full_name`
- `email_address`
- `country`
- `city`
- `signup_date`
- `segment`

Relationship:
- `customers_clean.customer_id` ← `orders_clean.cust_ref`

Quality notes:
- exact duplicates removed;
- dates normalized;
- missing identifiers/emails profiled;
- uncertain values are not fabricated.

## orders_clean

**Layer:** Silver  
**Format:** Parquet  
**Purpose:** Validated order-header data.  
**Grain:** One row per order.  
**Business key:** `order_no`

Main fields:
- `order_no`
- `cust_ref`
- `store_ref`
- `order_date`
- `status`
- `currency`

Relationships:
- `cust_ref` → `customers_clean.customer_id`
- `store_ref` → `stores_clean.store_id`
- `order_no` ← `order_items_clean.order_no`

Quality notes:
- dates normalized;
- duplicates removed;
- status normalized;
- invalid source dates become `NULL` when no trusted correction exists.

## order_items_clean

**Layer:** Silver  
**Format:** Parquet  
**Purpose:** Validated transactional order-line data used as the sales basis for Gold analytics.  
**Grain:** One row per valid order line.  
**Business key:** `line_id`

| Column | Type | Description |
|---|---|---|
| `line_id` | VARCHAR | Order-line identifier |
| `order_no` | VARCHAR | Order identifier |
| `product_code` | VARCHAR | Product identifier |
| `quantity` | BIGINT | Number of units |
| `unit_price` | DOUBLE | Unit price on the order line |
| `discount` | BIGINT | Discount percentage |

Relationships:
- `order_no` → `orders_clean.order_no`
- `product_code` → `products_clean.prod_code`

Quality rules:
- `line_id` unique;
- exact duplicates removed;
- `quantity > 0`;
- `unit_price > 0`;
- `discount` between `0` and `100`;
- valid order and product references required.

Silver result:
- source rows: 11
- clean rows: 5
- unique rejected rows: 5
- exact duplicate source row removed: 1

## products_clean

**Layer:** Silver  
**Format:** Parquet  
**Purpose:** Validated product master data.  
**Grain:** One row per product.  
**Business key:** `prod_code`

Main fields:
- `prod_code`
- `product_name`
- `category`
- `unit_cost`
- `unit_price`
- `active`

Relationships:
- `prod_code` ← `order_items_clean.product_code`
- `prod_code` ← `campaign_products_clean.product_code`

## stores_clean

**Layer:** Silver  
**Format:** Parquet  
**Purpose:** Validated store master data.  
**Grain:** One row per store.  
**Business key:** `store_id`

Relationship:
- `store_id` ← `orders_clean.store_ref`

## campaigns_clean

**Layer:** Silver  
**Format:** Parquet  
**Purpose:** Validated campaign master data derived from nested JSON.  
**Grain:** One row per campaign.  
**Business key:** `campaign_id`

Main fields:
- `campaign_id`
- `name`
- `active`
- `exported_at`

## campaign_countries_clean

**Layer:** Silver  
**Format:** Parquet  
**Purpose:** Campaign-to-country relationships.  
**Grain:** One row per `campaign_id + country`.

Relationship:
- `campaign_id` → `campaigns_clean.campaign_id`

## campaign_products_clean

**Layer:** Silver  
**Format:** Parquet  
**Purpose:** Campaign-to-product relationships.  
**Grain:** One row per `campaign_id + product_code`.

Main fields:
- `campaign_id`
- `product_code`
- `discount_pct`

Relationships:
- `campaign_id` → `campaigns_clean.campaign_id`
- `product_code` → `products_clean.prod_code`

---

# Rejected Data

Rejected datasets preserve records that cannot safely enter trusted Silver outputs.

Examples of rejection reasons:
- `invalid_quantity`
- `invalid_unit_price`
- `invalid_discount`
- `orphan_order_no`
- `orphan_product_code`

Rejected records are excluded from Gold analytics.

---

# Silver Relationship Map

```text
customers_clean
      |
      | customer_id = cust_ref
      v
orders_clean --------------------> stores_clean
      |                              ^
      | order_no                     | store_ref = store_id
      v
order_items_clean ----------------> products_clean
                                        ^
                                        |
                                        | product_code = prod_code
                                        |
campaigns_clean
      |
      +----> campaign_countries_clean
      |
      +----> campaign_products_clean --+
```

---

# Gold Layer

Gold consumes validated Silver data only and answers the business questions defined in `docs/business_questions.md`.

Gold Parquet outputs are stored under:

`data/04-gold/`

## gold_completed_order_revenue

**Purpose:** Net revenue by completed order.  
**Grain:** One row per completed order.

Sources:
- `orders_clean`
- `order_items_clean`

Fields:
- `order_no`
- `order_date`
- `net_revenue`

Rule:
- only completed orders;
- `net_revenue = quantity * unit_price * (1 - discount / 100)`.

## gold_product_performance

**Purpose:** Product sales and profitability analysis.  
**Grain:** One row per active product with completed-order activity.

Sources:
- `products_clean`
- `order_items_clean`
- `orders_clean`

Metrics:
- `units_sold`
- `net_revenue`
- `total_margin`
- `margin_per_unit`

## gold_category_performance

**Purpose:** Category-level sales and profitability analysis.  
**Grain:** One row per product category.

Sources:
- `products_clean`
- `order_items_clean`
- `orders_clean`

Metrics:
- `units_sold`
- `net_revenue`
- `total_margin`
- `margin_per_unit`

## gold_store_performance

**Purpose:** Store-level revenue and profitability analysis.  
**Grain:** One row per store with completed-order activity.

Sources:
- `stores_clean`
- `orders_clean`
- `order_items_clean`
- `products_clean`

Metrics:
- `completed_orders`
- `units_sold`
- `net_revenue`
- `total_margin`

## gold_customer_performance

**Purpose:** Customer-level sales and profitability analysis.  
**Grain:** One row per customer with completed-order activity.

Sources:
- `customers_clean`
- `orders_clean`
- `order_items_clean`
- `products_clean`

Metrics:
- `completed_orders`
- `units_sold`
- `net_revenue`
- `total_margin`

---

# Gold Output Inventory

```text
data/04-gold/
├── gold_completed_order_revenue.parquet
├── gold_product_performance.parquet
├── gold_category_performance.parquet
├── gold_store_performance.parquet
└── gold_customer_performance.parquet
```

---

# Catalog Maintenance

Update this file whenever a trusted dataset, schema, key, relationship, quality rule or Gold output changes.
