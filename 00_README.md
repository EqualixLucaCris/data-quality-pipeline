# Data Quality Pipeline

End-to-end ingestion, standardization, validation and analytics pipeline for heterogeneous source files.

## Project Status

**Pipeline completed through Gold**

The project covers:

- heterogeneous file ingestion;
- technical standardization;
- Silver profiling and cleaning;
- rejected-record handling;
- referential-integrity validation;
- JSON flattening;
- Gold analytical modeling;
- Parquet export and read-back validation;
- project documentation and versioning.

The Gold layer is complete and contains five analytics-ready datasets.

## Technologies

- Linux / Bash
- DuckDB
- SQL
- Git / GitHub
- Parquet

## Architecture

```text
Incoming -> Raw -> Bronze -> Silver -> Gold -> BI / Analytics-ready outputs
```

## Data Sources

The pipeline processes heterogeneous source formats including:

- CSV
- JSON
- XML

The source files also contain different technical characteristics, including:

- multiple delimiters;
- UTF-8;
- UTF-8 BOM;
- UTF-16LE;
- ISO-8859-1.

## Pipeline Layers

### Incoming

Original source datasets are preserved unchanged for reproducibility.

### Raw

Source copies are ingested without business transformation.

Generated Raw data is not version-controlled.

### Bronze

Files are technically standardized for downstream processing.

Examples include:

- encoding conversion;
- delimiter normalization;
- BOM handling;
- preservation of source business meaning.

### Silver

Silver contains trusted, validated datasets.

Processing includes:

- profiling;
- type conversion;
- date normalization;
- NULL and blank-string checks;
- exact duplicate removal;
- business-key validation;
- business-rule validation;
- referential-integrity checks;
- clean/rejected separation;
- Parquet export and verification.

Handled issues include:

- malformed dates;
- NULL values;
- duplicate rows;
- duplicate business keys;
- inconsistent boolean values;
- invalid product references;
- orphan customer/order references;
- invalid quantities and discounts;
- JSON flattening;
- encoding problems.

### Gold

Gold contains analytics-ready datasets built only from validated Silver data.

Implemented Gold datasets:

```text
gold_completed_order_revenue
gold_product_performance
gold_category_performance
gold_store_performance
gold_customer_performance
```

The Gold layer answers five focused business questions covering:

- completed-order revenue;
- product performance;
- category performance;
- store performance;
- customer performance.

Revenue and margin calculations use documented business rules and only validated Silver records.

## JSON Flattening

The nested campaigns JSON source is normalized into:

```text
campaigns_clean
    |-- campaign_countries_clean
    `-- campaign_products_clean
```

The resulting child tables are validated against campaign and product master data.

## Data Quality Principles

- Source values are never silently invented.
- Invalid values remain `NULL` when no trusted correction exists.
- Unresolved foreign-key issues are documented.
- Rejected records are preserved separately when appropriate.
- Business-key duplicates are distinguished from exact-row duplicates.
- Gold analytics use validated Silver records only.

## Gold Output Inventory

```text
data/04-gold/
├── gold_completed_order_revenue.parquet
├── gold_product_performance.parquet
├── gold_category_performance.parquet
├── gold_store_performance.parquet
└── gold_customer_performance.parquet
```

Every Gold Parquet output was read back after export to verify persistence and consistency.

## Data Versioning Strategy

- `data/00-incoming/` — source datasets, version-controlled
- `data/01-raw/` — generated, excluded from Git
- `data/02-bronze/` — generated, excluded from Git
- `data/03-silver/` — generated, excluded from Git
- `data/04-gold/` — final Gold outputs, version-controlled
- `data/05-rejected/` — generated rejected records, excluded from Git

Scripts, SQL transformations, logs, reports and documentation are version-controlled.

Local DuckDB databases, temporary files and reproducible intermediate outputs are excluded through `.gitignore`.

## Repository Structure

```text
bash/        Bash ingestion and standardization scripts
data/        Medallion data layers
docs/        Project documentation
duckdb/      Local DuckDB workspace
logs/        Pipeline execution logs
reports/     Quality and pipeline reports
sql/         SQL profiling, cleaning and Gold analytics
tmp/         Temporary processing files
```

## Documentation

The repository includes:

- `architecture.md`
- `pipeline.md`
- `conventions.md`
- `data_catalog.md`
- `business_questions.md`
- `bronze_transformation_plan`
- quality and inventory reports

## Current Scope

This release demonstrates a complete local Data Engineering workflow from heterogeneous source ingestion through validated Gold analytical datasets.

The project intentionally focuses on data ingestion, quality, transformation, modeling and reproducibility. A BI/dashboard layer can consume the Gold outputs but is not required for the pipeline itself.
