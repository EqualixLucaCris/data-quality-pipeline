# PROJECT ARCHITECTURE

## Purpose

This document describes the current architecture of the Data Quality
Pipeline.

The project follows a Medallion-style architecture and processes
heterogeneous source files through Raw, Bronze, Silver and Gold layers.

**Gold status:** Work in Progress.

------------------------------------------------------------------------

## Architecture Overview

``` text
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
Encoding / delimiters / source preparation
      |
      v
03-silver
Profiling / cleaning / validation
      |
      +--------------------> 05-rejected
      |                      Invalid / orphan records
      v
04-gold
Analytics / KPIs / BI
WORK IN PROGRESS
```

------------------------------------------------------------------------

## Main Technologies

### Bash

Used for file-oriented pipeline operations such as:

-   project scaffolding;
-   incoming-file inventory;
-   Raw ingestion;
-   Bronze standardization;
-   file-system operations;
-   pipeline logging.

### DuckDB and SQL

Used for:

-   loading and inspecting datasets;
-   profiling;
-   data-quality checks;
-   type and value validation;
-   duplicate detection;
-   relational-integrity checks;
-   Silver cleaning;
-   analytical transformations.

### Parquet

Used as the primary persisted format for validated Silver outputs and
rejected datasets.

------------------------------------------------------------------------

## Layer Responsibilities

### 00 --- Incoming

Landing area for source files.

Sources may arrive with different:

-   formats;
-   encodings;
-   delimiters;
-   schemas.

Incoming data is treated as source input and is not used directly for
analytics.

### 01 --- Raw

Preserves a copy of the source data before transformation.

The Raw layer provides traceability back to the ingested source.

### 02 --- Bronze

Performs technical standardization while preserving business meaning.

Examples include:

-   encoding conversion;
-   delimiter standardization;
-   preparation of heterogeneous source formats;
-   JSON source preparation/flattening where required by downstream
    processing.

Bronze does not contain BI aggregations.

### 03 --- Silver

Produces trusted analytical source datasets.

Silver processing includes:

-   profiling;
-   schema review;
-   column-name standardization;
-   data-type normalization where required;
-   NULL and blank-value checks;
-   duplicate handling;
-   business-rule validation;
-   referential-integrity validation;
-   clean/rejected separation;
-   Parquet export and verification.

### 05 --- Rejected

Preserves records that fail applicable Silver quality rules.

Rejected records may include a `rejection_reason` and are excluded from
Gold analytics.

### 04 --- Gold

**Status: Work in Progress**

Gold will consume validated Silver datasets only.

Its purpose is to produce analytical datasets and KPIs answering the
business questions documented in:

`docs/business_questions.md`

The final Gold architecture will be documented after implementation.

------------------------------------------------------------------------

## Trusted Data Flow

``` text
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

------------------------------------------------------------------------

## Supporting Documentation

-   `business_questions.md` --- analytical requirements and Gold
    business rules
-   `conventions.md` --- project, naming and quality conventions
-   `data_catalog.md` --- trusted datasets, fields, keys and
    relationships
-   `pipeline.md` --- operational pipeline sequence
-   `bronze_transformation_plan` --- Bronze transformation decisions

------------------------------------------------------------------------

## Future Update

After Gold implementation, this document should be updated with:

-   final Gold datasets;
-   Gold-to-Silver dependencies;
-   analytical output structure;
-   final end-to-end architecture diagram.
