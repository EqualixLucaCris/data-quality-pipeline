# DATA CATALOG

## Purpose

This catalog provides a concise inventory of the datasets used by the
Data Quality Pipeline.

It documents: - dataset purpose; - Medallion layer; - storage format; -
logical grain; - keys and relationships; - main data-quality rules; -
lineage between validated Silver datasets.

Gold datasets will be added after the analytical layer is implemented.

------------------------------------------------------------------------

# Silver Layer

Silver contains validated, cleaned datasets used as the trusted input
for Gold analytics.

Clean Silver outputs are stored as Parquet files in:

`data/03-silver/clean/`

Rejected records are stored separately in:

`data/05-rejected/`

------------------------------------------------------------------------

## customers_clean

**Layer:** Silver\
**Format:** Parquet\
**Purpose:** Validated customer master data.\
**Grain:** One row per customer record after deduplication and cleaning.

### Main fields

-   `customer_id` --- customer identifier
-   `full_name` --- customer full name
-   `email_address` --- customer email address
-   `country` --- customer country
-   `city` --- customer city
-   `signup_date` --- normalized signup date
-   `segment` --- customer business segment

### Quality rules

-   Exact duplicate rows are removed.
-   Column names are standardized to `snake_case`.
-   Multiple source date formats are normalized to a valid date type.
-   Missing identifiers and email values are explicitly profiled.
-   Uncertain source values are not fabricated.

### Relationships

Customer references used by the order domain are validated during Silver
processing before analytical use.

------------------------------------------------------------------------

## orders_clean

**Layer:** Silver\
**Format:** Parquet\
**Purpose:** Validated order-header data.\
**Grain:** One row per order.

### Known business fields

-   `order_no` --- order identifier
-   `order_date` --- normalized order date
-   `status` --- order status

The table also contains the customer/store references required to
connect orders to their related master data.

### Quality rules

-   Dates are normalized.
-   Duplicate and missing values are profiled.
-   Customer/store references are investigated and validated where
    applicable.
-   Source values are not replaced without supporting evidence.

### Relationships

-   Parent of `order_items_clean` through `order_no`.
-   Provides customer and store references used by Gold analytics.

------------------------------------------------------------------------

## order_items_clean

**Layer:** Silver\
**Format:** Parquet\
**Purpose:** Validated order-line data used as the transactional basis
for sales analytics.\
**Grain:** One row per valid order line.\
**Business key:** `line_id`

### Columns

  Column           Type      Description
  ---------------- --------- -----------------------------------------
  `line_id`        VARCHAR   Unique order-line identifier
  `order_no`       VARCHAR   Order identifier
  `product_code`   VARCHAR   Product identifier
  `quantity`       BIGINT    Number of units on the order line
  `unit_price`     DOUBLE    Unit price recorded on the order line
  `discount`       BIGINT    Discount percentage applied to the line

### Relationships

-   `order_no` → `orders_clean.order_no`
-   `product_code` → `products_clean.prod_code`

### Quality rules

-   `line_id` must be unique in the clean dataset.
-   Exact duplicate rows are removed.
-   `quantity > 0`
-   `unit_price > 0`
-   `discount` must be between `0` and `100`.
-   `order_no` must exist in `orders_clean`.
-   `product_code` must exist in `products_clean`.

### Silver result

-   Source rows: 11
-   Clean rows: 5
-   Unique rejected rows: 5
-   Exact duplicate source row removed: 1

------------------------------------------------------------------------

## products_clean

**Layer:** Silver\
**Format:** Parquet\
**Purpose:** Validated product master data.\
**Grain:** One row per product.\
**Known product key:** `prod_code`

### Quality rules

-   Product identifiers are standardized and validated.
-   Product attributes and numeric values are cleaned before analytical
    use.
-   Product references from transactional/campaign datasets are
    validated against this table.

### Relationships

Referenced by:

-   `order_items_clean.product_code`
-   `campaign_products_clean.product_code`

------------------------------------------------------------------------

## stores_clean

**Layer:** Silver\
**Format:** Parquet\
**Purpose:** Validated store master data.\
**Grain:** One row per store.

### Quality rules

-   Store attributes are standardized.
-   Text/encoding issues are resolved during Bronze/Silver processing.
-   Store references used by orders are validated before Gold analytics.

### Relationships

Used by the order domain to support store-performance analysis in Gold.

------------------------------------------------------------------------

## campaigns_clean

**Layer:** Silver\
**Format:** Parquet\
**Purpose:** Validated campaign master data derived from the nested
campaigns JSON source.\
**Grain:** One row per campaign.\
**Business key:** `campaign_id`

### Columns

-   `campaign_id` --- campaign identifier
-   `name` --- campaign name
-   `active` --- normalized BOOLEAN campaign status
-   `exported_at` --- source export timestamp

### Quality rules

-   Duplicate campaign business keys are resolved using documented
    source evidence.
-   JSON boolean variants such as `true` and `"yes"` are normalized to
    BOOLEAN.
-   Campaign identifiers must be unique in the clean dataset.

------------------------------------------------------------------------

## campaign_countries_clean

**Layer:** Silver\
**Format:** Parquet\
**Purpose:** Normalized campaign-to-country relationships produced by
JSON flattening.\
**Grain:** One row per `campaign_id + country`.

### Columns

-   `campaign_id` --- campaign identifier
-   `country` --- country associated with the campaign

### Relationships

-   `campaign_id` → `campaigns_clean.campaign_id`

### Quality rules

-   Duplicate campaign-country combinations are removed.
-   Campaign references must exist in `campaigns_clean`.
-   Invalid/orphan relationships are separated from clean data.

------------------------------------------------------------------------

## campaign_products_clean

**Layer:** Silver\
**Format:** Parquet\
**Purpose:** Normalized campaign-to-product relationships produced by
JSON flattening.\
**Grain:** One row per `campaign_id + product_code`.

### Columns

-   `campaign_id` --- campaign identifier
-   `product_code` --- referenced product identifier
-   `discount_pct` --- campaign discount percentage

### Relationships

-   `campaign_id` → `campaigns_clean.campaign_id`
-   `product_code` → `products_clean.prod_code`

### Quality rules

-   Duplicate campaign-product combinations are removed.
-   Campaign references must exist in `campaigns_clean`.
-   Product references must exist in `products_clean`.
-   Invalid relationships are preserved in rejected output.

------------------------------------------------------------------------

# Rejected Data

Rejected datasets preserve records that cannot safely enter the trusted
Silver analytical layer.

Rejected records may contain a `rejection_reason` describing the failed
quality rule.

Current rejected outputs include campaign relationship rejects and
order-item rejects.

Examples of rejection reasons used by the project:

-   `invalid_quantity`
-   `invalid_unit_price`
-   `invalid_discount`
-   `orphan_order_no`
-   `orphan_product_code`

Rejected records are excluded from Gold analytics.

------------------------------------------------------------------------

# Silver Relationship Map

``` text
customers_clean
      |
      | customer reference
      v
orders_clean -------------------- stores_clean
      |
      | order_no
      v
order_items_clean -------------- products_clean
                                     ^
                                     |
                                     | product_code
                                     |
campaigns_clean
      |
      +---- campaign_countries_clean
      |
      +---- campaign_products_clean --+
```

The exact order-to-customer and order-to-store reference column names
remain defined by the final Silver schema and should be kept
synchronized with the SQL transformations.

------------------------------------------------------------------------

# Gold Layer

**Status:** Work in Progress

Gold datasets will be documented here after implementation.

For every Gold dataset, this catalog will record:

-   dataset name;
-   business purpose;
-   source Silver tables;
-   grain;
-   dimensions;
-   metrics/KPIs;
-   business rules;
-   output format;
-   important relationships.

The analytical requirements are defined in:

`docs/business_questions.md`

------------------------------------------------------------------------

# Catalog Maintenance

This file should be updated whenever:

-   a new trusted dataset is added;
-   a schema or key changes;
-   a new relationship is introduced;
-   a quality rule materially changes;
-   a Gold analytical dataset is created.

The catalog describes the current trusted data model. Transformation
implementation details remain in the SQL scripts and pipeline
documentation.
