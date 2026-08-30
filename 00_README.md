# Data Quality Pipeline

End-to-end ingestion, standardization, validation and analytics pipeline for heterogeneous source files.

## Project Status

**Silver layer: completed**

The current published version covers ingestion, Bronze standardization, Silver profiling, cleaning, validation, JSON flattening, referential-integrity checks and Parquet outputs.

**Gold layer: Work in Progress**

Gold analytical models and business KPIs are intentionally left as the next project phase. The repository is published as a working Data Engineering project rather than presenting unfinished analytical work as complete.

## Technologies

- Linux / Bash
- DuckDB
- SQL
- Git / GitHub
- Parquet

## Architecture

```text
Incoming -> Raw -> Bronze -> Silver -> Gold (Work in Progress) -> BI / Analytics
```

## Data Sources

The pipeline processes heterogeneous source formats including CSV, JSON and XML, with different delimiters and encodings such as UTF-8, UTF-8 BOM, UTF-16LE and ISO-8859-1.

## Pipeline Layers

### Incoming
Original source datasets are preserved unchanged for reproducibility.

### Raw
Source copies are ingested by Bash scripts. Generated Raw data is not version-controlled.

### Bronze
Files are standardized for encoding, delimiters and structural consistency.

### Silver
Silver contains profiling, cleaning, type conversion, deduplication, validation, referential-integrity checks and Parquet exports.

Handled issues include malformed dates, NULLs, duplicate rows, duplicate business keys, inconsistent boolean values, invalid product references, orphan customer references, JSON flattening and encoding problems.

### Gold — Work in Progress
Planned work includes analytical joins, revenue and margin metrics, sales by product/store/time, campaign analytics and a final BI layer.

## JSON Flattening

The nested campaigns JSON source is normalized into:

```text
campaigns_clean
    |-- campaign_countries_clean
    `-- campaign_products_clean
```

## Data Quality Principles

- source values are never silently invented
- invalid values remain NULL when no trusted correction exists
- unresolved foreign-key issues are documented
- rejected records are retained separately when appropriate
- business-key duplicates are distinguished from exact-row duplicates

## Data Versioning Strategy

- `data/00-incoming/` — source datasets, version-controlled
- `data/01-raw/` — generated, excluded from Git
- `data/02-bronze/` — generated, excluded from Git
- `data/03-silver/` — generated, excluded from Git
- `data/04-gold/` — Gold outputs will be version-controlled when implemented
- `data/05-rejected/` — generated rejected records, excluded from Git

Scripts, SQL transformations, logs, reports and documentation are version-controlled. Local DuckDB databases and temporary files are excluded through `.gitignore`.

## Repository Structure

```text
bash/        Bash ingestion and standardization scripts
data/        Medallion data layers
docs/        Project documentation
duckdb/      Local DuckDB workspace
logs/        Pipeline execution logs
reports/     Quality and pipeline reports
sql/         SQL profiling and transformation scripts
tmp/         Temporary processing files
```

## Current Scope

This release demonstrates the completed ingestion-to-Silver portion of the pipeline. Gold modeling is explicitly marked **Work in Progress** so joins, analytical modeling and BI can be developed as the next phase.
