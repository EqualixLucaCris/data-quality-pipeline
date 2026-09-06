# PIPELINE

## Purpose

This document describes the operational flow of the Data Quality
Pipeline from source ingestion to analytical outputs.

The pipeline currently reaches a completed Silver layer.

**Gold status:** Work in Progress.

------------------------------------------------------------------------

## End-to-End Flow

``` text
00-incoming
     |
     v
01-raw
     |
     v
02-bronze
     |
     v
03-silver
   /      \
clean   rejected
   |
   v
04-gold
WORK IN PROGRESS
```

------------------------------------------------------------------------

## 1. Incoming File Inventory

Source files are inspected before ingestion.

The inventory captures technical metadata such as:

-   file name;
-   extension;
-   size;
-   MIME/file type;
-   encoding;
-   BOM;
-   delimiter;
-   row count;
-   column count where applicable;
-   SHA-256 checksum.

Primary Bash script:

`01_file_inventory.sh`

------------------------------------------------------------------------

## 2. Raw Ingestion

Incoming source files are copied into the Raw layer.

Purpose:

-   preserve source data;
-   provide traceability;
-   separate ingestion from downstream transformation.

Primary Bash script:

`raw_ingestion.sh`

Pipeline activity is recorded in project logs.

------------------------------------------------------------------------

## 3. Bronze Standardization

Raw files are standardized for downstream processing.

Transformations may include:

-   encoding conversion to UTF-8;
-   delimiter normalization;
-   preservation of already compliant files;
-   preparation of structured/semi-structured sources.

Primary Bash script:

`bronze_standardization.sh`

Transformation decisions are documented in:

`docs/bronze_transformation_plan`

------------------------------------------------------------------------

## 4. Silver Preparation

Bronze datasets are prepared for SQL profiling and cleaning.

Silver work is performed primarily with DuckDB and SQL.

The Silver workflow follows this general pattern:

``` text
Bronze dataset
      |
      v
Profiling
      |
      v
Quality rules
   /       \
valid     invalid
  |          |
  v          v
clean     rejected
  |
  v
Parquet
```

------------------------------------------------------------------------

## 5. Silver Profiling

Each dataset is inspected before cleaning.

Typical checks include:

-   schema and data types;
-   row counts;
-   NULL values;
-   blank strings;
-   duplicate keys;
-   exact duplicates;
-   numeric ranges;
-   date validity;
-   dataset-specific business rules;
-   referential integrity.

Profiling decisions are preserved in SQL files rather than performed
silently.

------------------------------------------------------------------------

## 6. Silver Cleaning

Cleaning rules are based on profiling evidence.

Typical operations include:

-   column-name normalization;
-   type/date normalization;
-   confirmed duplicate removal;
-   business-rule enforcement;
-   orphan-reference detection;
-   separation of valid and rejected records.

Clean datasets use the suffix:

`_clean`

Rejected datasets use the suffix:

`_rejected`

Rejected records may include:

`rejection_reason`

------------------------------------------------------------------------

## 7. Referential Integrity Validation

Related Silver datasets are checked before analytical use.

Examples include:

-   order items → orders;
-   order items → products;
-   campaign products → products;
-   campaign relationships → campaigns.

Orphan references are excluded from trusted Silver output and preserved
as rejected data when applicable.

------------------------------------------------------------------------

## 8. Silver Parquet Export

Validated clean datasets are exported to:

`data/03-silver/clean/`

Rejected datasets are exported to:

`data/05-rejected/`

Parquet outputs are read back after export to verify that persisted data
is usable.

------------------------------------------------------------------------

## 9. Logging

Pipeline operations generate logs under:

`data/06-logs/`

Current logging covers file-oriented ingestion and standardization
steps.

Logging may be extended as the Gold layer is implemented.

------------------------------------------------------------------------

## 10. Gold Analytics

**Status: Work in Progress**

Gold will:

-   consume validated Silver datasets only;
-   apply documented business rules;
-   join trusted datasets;
-   calculate analytical measures;
-   answer the questions defined in `docs/business_questions.md`;
-   produce reusable analytical datasets/KPIs.

The current planned BI scope includes:

1.  net revenue by completed order;
2.  product performance;
3.  category performance;
4.  store performance;
5.  customer performance.

Gold implementation details will be added after the SQL datasets are
built and validated.

------------------------------------------------------------------------

## 11. Gold Validation

**Status: Work in Progress**

Gold validation will be defined alongside the analytical datasets.

Expected checks include:

-   correct Silver input dependencies;
-   expected grain;
-   duplicate prevention;
-   revenue-rule consistency;
-   reconciliation of analytical totals where applicable.

------------------------------------------------------------------------

## Pipeline Status

``` text
Incoming inventory       COMPLETE
Raw ingestion            COMPLETE
Bronze standardization   COMPLETE
Silver profiling         COMPLETE
Silver cleaning          COMPLETE
Silver rejected handling COMPLETE
Silver Parquet export    COMPLETE
Gold analytics           WORK IN PROGRESS
Gold validation          WORK IN PROGRESS
```

------------------------------------------------------------------------

## Maintenance

This document should be updated when:

-   a pipeline stage changes;
-   a new transformation is introduced;
-   quality/rejection logic materially changes;
-   Gold datasets are added;
-   execution or logging behavior changes.
