# DATA QUALITY REPORT

## Project

**Data Quality Pipeline**

## Purpose

This report summarizes the data-quality controls, issues, decisions and validation activities performed across the pipeline.

The project processes heterogeneous CSV, JSON and XML sources through Incoming, Raw, Bronze, Silver, Rejected and Gold layers.

The guiding principle is that source values are never silently invented or corrected without trusted evidence.

---

## Quality Dimensions

The pipeline evaluates the following dimensions:

- completeness;
- uniqueness;
- validity;
- consistency;
- structural conformity;
- referential integrity;
- business-rule conformity.

---

## 1. Source and File-Level Quality

Before transformation, source files were inspected for:

- file type;
- MIME type;
- encoding;
- BOM;
- delimiter;
- row count;
- column structure;
- SHA-256 checksum.

The source delivery contained heterogeneous technical formats, including:

- UTF-8;
- UTF-8 BOM;
- UTF-16LE;
- ISO-8859-1;
- comma-separated data;
- semicolon-separated data;
- pipe-separated data;
- tab-separated data;
- JSON;
- XML.

These differences were treated as technical standardization issues rather than business-data errors.

Detailed source metadata is documented in:

`reports/file_inventory.md`

---

## 2. Raw Integrity

Incoming files were copied to the Raw layer without business transformation.

Where applicable, checksums were used to verify that Raw copies matched the original source files.

Purpose:

- source preservation;
- traceability;
- reproducibility;
- recovery from downstream transformation errors.

---

## 3. Bronze Standardization

Bronze resolved technical incompatibilities while preserving source business values.

Examples included:

- ISO-8859-1 to UTF-8 conversion;
- UTF-16LE to UTF-8 conversion;
- delimiter normalization;
- handling of UTF-8 BOM;
- preservation of JSON and XML structure where conversion was unnecessary.

Bronze transformations are documented separately in:

`docs/bronze_transformation_plan`

---

## 4. Silver Profiling

Silver datasets were profiled before cleaning.

Checks included:

- schema inspection;
- inferred data types;
- row counts;
- NULL values;
- blank strings;
- duplicate rows;
- duplicate business keys;
- invalid dates;
- invalid numeric values;
- unexpected categorical values;
- business-rule violations;
- foreign-key/orphan checks.

Cleaning decisions were based on profiling results rather than assumptions.

---

## 5. Duplicate Handling

The project distinguishes between:

### Exact duplicates

Rows that are identical across all relevant columns.

Confirmed exact duplicates can be safely removed from trusted Silver outputs.

### Business-key duplicates

Rows sharing the same business identifier but containing different values.

These require investigation and must not be silently deleted simply because the identifier is repeated.

This distinction was applied during Silver profiling and cleaning.

---

## 6. NULL and Invalid Values

The project does not fabricate replacements for values that cannot be reliably reconstructed.

Examples:

- malformed or untrusted dates may become `NULL`;
- missing identifiers are investigated before inclusion;
- invalid numeric values are rejected when they violate business rules.

This preserves data lineage and avoids introducing unsupported information.

---

## 7. Referential Integrity

Relationships between cleaned datasets were validated before Gold analytics.

Important relationships include:

```text
customers_clean.customer_id
        |
        v
orders_clean.cust_ref

orders_clean.order_no
        |
        v
order_items_clean.order_no

stores_clean.store_id
        ^
        |
orders_clean.store_ref

products_clean.prod_code
        ^
        |
order_items_clean.product_code

campaigns_clean.campaign_id
        |
        +--> campaign_countries_clean.campaign_id
        |
        +--> campaign_products_clean.campaign_id

products_clean.prod_code
        ^
        |
campaign_products_clean.product_code
```

Invalid or orphan relationships are excluded from trusted analytical outputs when required.

---

## 8. Order Items Quality Controls

`order_items` required transaction-level validation because it directly feeds revenue and margin calculations.

Quality rules included:

- unique `line_id`;
- `quantity > 0`;
- `unit_price > 0`;
- `discount` between `0` and `100`;
- valid `order_no`;
- valid `product_code`;
- exact duplicate detection.

Observed processing result:

```text
Source rows:                 11
Clean rows:                   5
Unique rejected rows:         5
Exact duplicate removed:      1
```

Examples of rejection reasons:

- `invalid_quantity`
- `invalid_unit_price`
- `invalid_discount`
- `orphan_order_no`
- `orphan_product_code`

Rejected records were kept outside trusted Silver analytics.

---

## 9. JSON Quality and Normalization

The nested campaign JSON source was normalized into relational structures:

```text
campaigns_clean
campaign_countries_clean
campaign_products_clean
```

The child datasets were validated for:

- campaign references;
- product references;
- duplicate relationships;
- structural consistency.

This allowed nested JSON data to participate safely in relational analysis.

---

## 10. Silver Output Validation

Trusted Silver datasets were exported to Parquet.

Clean outputs are stored under:

`data/03-silver/clean/`

Rejected outputs are stored under:

`data/05-rejected/`

Parquet outputs were read back after export to verify persistence and usability.

---

## 11. Gold Quality Rules

Gold analytics consume validated Silver datasets only.

Common analytical rules:

- only `completed` orders contribute to revenue;
- active products are used where applicable;
- rejected records are excluded;
- net revenue accounts for discount;
- margin uses effective selling price minus unit cost.

Net revenue formula:

```text
quantity * unit_price * (1 - discount / 100)
```

Unit economics:

```text
effective_selling_price = unit_price * (1 - discount / 100)

unit_margin = effective_selling_price - unit_cost
```

Total margin:

```text
quantity * (effective_selling_price - unit_cost)
```

Monetary metrics are rounded to two decimal places in Gold outputs.

---

## 12. Gold Validation

Five Gold datasets were created and validated:

```text
gold_completed_order_revenue
gold_product_performance
gold_category_performance
gold_store_performance
gold_customer_performance
```

Validation included:

- row-count checks;
- distinct business-key checks;
- duplicate detection;
- expected analytical grain;
- metric sanity checks;
- Parquet export;
- Parquet read-back verification.

---

## 13. Gold Analytical Observations

The final validated Gold outputs revealed meaningful differences between revenue and profitability.

Examples from the validated project results:

- a product can generate relatively high revenue while producing a negative margin;
- the highest-revenue category is not necessarily the category with the strongest margin per unit;
- store performance differs depending on whether it is evaluated by revenue or total margin;
- customer performance can be ranked using both net revenue and total margin.

This demonstrates why revenue alone is insufficient for profitability analysis.

---

## 14. Data Quality Decisions

The project follows these rules consistently:

1. Never modify Incoming source files.
2. Preserve Raw copies before transformation.
3. Separate technical standardization from business cleaning.
4. Profile before cleaning.
5. Do not silently invent missing values.
6. Distinguish exact duplicates from business-key duplicates.
7. Validate relationships before analytical joins.
8. Preserve rejected records when appropriate.
9. Build Gold only from trusted Silver data.
10. Validate persisted Parquet outputs after export.

---

## 15. Final Quality Status

```text
File inspection             COMPLETE
Raw integrity               COMPLETE
Bronze standardization      COMPLETE
Silver profiling            COMPLETE
Duplicate analysis          COMPLETE
Business-rule validation    COMPLETE
Referential integrity       COMPLETE
Rejected-record handling    COMPLETE
Silver Parquet validation   COMPLETE
Gold metric validation      COMPLETE
Gold uniqueness checks      COMPLETE
Gold Parquet validation     COMPLETE
```

---

## Conclusion

The final Gold datasets are built from records that passed the project's Silver validation rules and documented business constraints.

Known invalid or orphan records are not silently propagated into the analytical layer.

The pipeline therefore provides a traceable path from heterogeneous source files to validated, analytics-ready Parquet datasets while preserving rejected data and the reasoning behind quality decisions.
