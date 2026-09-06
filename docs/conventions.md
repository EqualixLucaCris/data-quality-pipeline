# PROJECT CONVENTIONS

## File Size

\< 1 KB → B or Bytes

≥ 1 KB → KB

≥ 1 MB → MB

≥ 1 GB → GB

## BOM

Yes

No

## Delimiter

, → CSV

; → CSV

TAB → TSV

| → Pipe separated

N/A → JSON, XML, Parquet, Excel

## Rows

CSV → Number of records

JSON → Text lines

XML → Text lines

## Columns

CSV → Number of columns

JSON → N/A

XML → N/A

## Encoding

UTF-8

UTF-16 LE

UTF-16 BE

Windows-1252

ISO-8859-1

ASCII

## Checksum

SHA-256

## SQL Naming

-   Table and column names use `snake_case`.
-   Clean Silver tables use the suffix `_clean`.
-   Rejected Silver tables use the suffix `_rejected`.
-   Rejected records include a `rejection_reason` column when
    applicable.
-   SQL aliases should be short but descriptive and consistent within
    each query.

## Medallion Layer Conventions

### Raw

-   Preserve source data without business transformations.
-   Source files are copied into the Raw layer before transformation.

### Bronze

-   Standardize technical file characteristics such as encoding and
    delimiters.
-   Preserve the original business meaning of the data.
-   No analytical aggregations are performed.

### Silver

-   Perform data profiling and quality validation.
-   Standardize column names and data types where required.
-   Remove exact duplicate records when duplicates are confirmed to be
    invalid.
-   Validate NULL and blank values where applicable.
-   Validate business-rule ranges.
-   Validate referential integrity between related datasets.
-   Separate valid records from rejected records.
-   Export validated datasets to Parquet.

### Gold

-   Use validated Silver data only.
-   Apply documented business rules consistently.
-   Build analytical datasets and KPIs that answer the questions defined
    in `business_questions.md`.
-   Rejected records must not contribute to Gold analytics.

## Data Quality Conventions

A record may be rejected when it violates one or more applicable quality
rules, including:

-   invalid or missing required values;
-   invalid numeric ranges;
-   duplicate records confirmed to be invalid;
-   orphan foreign-key references;
-   other dataset-specific validation rules.

Rejected records should be preserved when useful for traceability rather
than silently discarded.

## Output Format

-   Silver clean datasets → Parquet
-   Rejected datasets → Parquet
-   Gold datasets → analytical tables and/or Parquet outputs as required
