# Reports

## Purpose

The `reports/` directory contains the reporting artifacts produced
during the **data-quality-pipeline** project.

Its purpose is to provide a clear record of the source-file inventory,
data-quality findings, and overall pipeline execution. These reports
complement the datasets, scripts, SQL, and project documentation by
making the results easier to inspect, audit, reproduce, and analyze.

## Contents

  -----------------------------------------------------------------------
  File                                Purpose
  ----------------------------------- -----------------------------------
  `file_inventory.csv`                Machine-readable inventory of
                                      source files and their technical
                                      metadata.

  `file_inventory.md`                 Human-readable version of the
                                      source file inventory for
                                      documentation and GitHub.

  `pipeline_summary.md`               End-to-end summary of the pipeline
                                      stages, transformations, outputs,
                                      and results.

  `quality_report.md`                 Summary of data-quality checks,
                                      detected issues, rejected data, and
                                      cleaning decisions.

  `README.md`                         Description of the purpose and
                                      organization of the `reports/`
                                      directory.
  -----------------------------------------------------------------------

## Why are there both `file_inventory.csv` and `file_inventory.md`?

The two files represent the inventory for two different uses.

### `file_inventory.csv` --- machine-readable

The CSV version stores structured metadata such as:

-   file name
-   extension
-   size
-   MIME type
-   encoding
-   BOM presence
-   delimiter
-   row count
-   column count
-   SHA-256 checksum

Because it is structured tabular data, it is ready to be queried or
processed with tools such as **DuckDB, SQL, Python/pandas, or
Databricks**.

### `file_inventory.md` --- human-readable

The Markdown version presents the inventory in a format that can be read
directly in GitHub or in a text editor. It is intended for documentation
and quick inspection without requiring a data-processing tool.

Therefore:

-   `.csv` = structured, queryable, reusable data
-   `.md` = readable project documentation

The Markdown report does not replace the CSV dataset, and the CSV
dataset does not replace the documentation. Keeping both makes the
inventory useful to both data tools and people reviewing the repository.

## Role within the project

The reporting layer complements the other project directories:

-   `data/` --- datasets across the pipeline layers
-   `scripts/` --- ingestion, standardization, and processing logic
-   `sql/` --- SQL transformations, validation, and Gold analytics
-   `docs/` --- architecture, pipeline, conventions, catalog, and
    project documentation
-   `reports/` --- inventory, quality findings, and pipeline execution
    summaries

This separation keeps the repository organized and provides a clear
audit trail from source-file inspection through data-quality validation
to analytics-ready outputs.
