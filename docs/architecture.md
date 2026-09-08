# PROJECT ARCHITECTURE

## Purpose

This document describes the final architecture of the Data Quality Pipeline.

The project follows a Medallion-style architecture and processes heterogeneous source files through Incoming, Raw, Bronze, Silver and Gold layers.

---

## Architecture Overview

```text
Source files
CSV / JSON / XML
      |
      v
00-incoming
      |
      v
01-raw
Source preservation
      |
      v
02-bronze
Technical standardization
      |
      v
03-silver
Profiling / cleaning / validation
      |
      +--------------------> 05-rejected
      |                      Invalid / orphan records
      v
04-gold
Analytics / KPIs
      |
      v
BI / Reporting
```

---

## Main Technologies

### Bash
Used for project scaffolding, inventory, Raw ingestion, Bronze standardization, file-system operations and logging.

### DuckDB and SQL
Used for staging, profiling, validation, duplicate detection, referential-integrity checks, Silver cleaning and Gold analytical transformations.

### Parquet
Used as the persisted format for validated Silver, rejected and Gold outputs.

### Git / GitHub
Used to version scripts, SQL, documentation, logs/reports, source inputs and final Gold deliverables.

Generated Raw/Bronze/Silver data and local DuckDB files are excluded according to the repository versioning strategy.

---

## Layer Responsibilities

### 00 — Incoming
Landing area for heterogeneous source files. Source inputs are preserved for reproducibility.

### 01 — Raw
Preserves a source copy before transformation for traceability and recovery.

### 02 — Bronze
Performs technical standardization while preserving business meaning:
- encoding conversion;
- delimiter normalization;
- BOM/format handling;
- preparation of structured and semi-structured sources.

### 03 — Silver
Produces trusted validated datasets:
- profiling;
- schema review;
- naming normalization;
- type/date normalization;
- NULL and blank checks;
- duplicate handling;
- business-rule validation;
- referential-integrity validation;
- clean/rejected separation;
- Parquet export and verification.

### 05 — Rejected
Preserves records that fail Silver quality rules. Rejected records are excluded from Gold analytics.

### 04 — Gold
Produces analytics-ready datasets from trusted Silver sources only.

Implemented Gold datasets:
- `gold_completed_order_revenue`
- `gold_product_performance`
- `gold_category_performance`
- `gold_store_performance`
- `gold_customer_performance`

---

## Trusted Data Flow

```text
Incoming
   |
   v
Raw
   |
   v
Bronze
   |
   v
Silver profiling
   |
   +---- invalid --------> Rejected
   |
   +---- valid ----------> Silver Clean
                                |
                                v
                              Gold
                                |
                                v
                           BI / Analytics
```

---

## Silver Analytical Model

```text
customers_clean
      |
      v
orders_clean --------------------> stores_clean
      |
      v
order_items_clean --------------> products_clean

campaigns_clean
      |
      +----> campaign_countries_clean
      |
      +----> campaign_products_clean ----> products_clean
```

---

## Gold Analytical Model

```text
orders_clean
     |
     +---- order_items_clean ---- products_clean
     |           |
     |           +------------------------------+
     |                                          |
customers_clean                            stores_clean
     |                                          |
     +---------------- Gold --------------------+
                        |
                        +-- completed order revenue
                        +-- product performance
                        +-- category performance
                        +-- store performance
                        +-- customer performance
```

Gold metrics consistently use completed orders and validated Silver records.

---

## Supporting Documentation

- `business_questions.md`
- `conventions.md`
- `data_catalog.md`
- `pipeline.md`
- `bronze_transformation_plan`

---

## Final Status

```text
Incoming                 COMPLETE
Raw                      COMPLETE
Bronze                   COMPLETE
Silver                   COMPLETE
Rejected handling        COMPLETE
Gold                     COMPLETE
Parquet validation       COMPLETE
Repository documentation COMPLETE
```
