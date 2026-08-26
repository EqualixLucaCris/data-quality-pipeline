# DATA QUALITY WORKFLOW

## Checklist

- [ ] 00 - Incoming
- [ ] 01 - File Inventory
- [ ] 02 - File Type and MIME Inspection
- [ ] 03 - Encoding and BOM Inspection
- [ ] 04 - Temporary UTF-8 Inspection Copy (if required)
- [ ] 05 - Delimiter, Header and Structure Inspection
- [ ] 06 - Raw Ingestion
- [ ] 07 - Bronze Standardization
- [ ] 08 - Data Quality Checks
- [ ] 09 - Silver Cleaning and Validation
- [ ] 10 - Data Modeling and Business SQL
- [ ] 11 - Gold Datasets and KPIs
- [ ] 12 - Documentation

---

## 00 - Incoming

Receive source files.

Location:

data/00-incoming

Rules:

- Do not modify source files.
- Preserve original names.
- Store delivery as received.

---

## 01 - File Inventory

Collect:

- File name
- Extension
- Size
- MIME type
- Encoding
- BOM
- Delimiter
- Text lines
- Columns
- SHA-256 checksum

Output:

reports/file_inventory.md

---

## 02 - File Type and MIME Inspection

Identify:

- Real file type
- MIME type
- Text or binary format
- Compression (if present)

Main commands:

file filename
file -b filename
file -i filename

---

## 03 - Encoding and BOM Inspection

Identify:

- Character encoding
- BOM presence
- Line endings

Main commands:

file -i filename
hexdump -C -n 16 filename

---

## 04 - Temporary UTF-8 Inspection Copy (if required)

If the original encoding prevents proper inspection, create a temporary UTF-8 copy.

Example:

iconv -f UTF-16LE -t UTF-8 input.csv > temporary_utf8.csv

Rules:

- Never overwrite the original file.
- Use the temporary copy only for inspection.
- Delete it afterwards or clearly identify it as temporary.

---

## 05 - Delimiter, Header and Structure Inspection

Identify:

- Delimiter
- Header
- Number of columns
- Number of text lines
- Visible structure
- Malformed rows

Useful commands:

head filename
cat -A filename | head
hexdump -C -n 100 filename
wc -l filename

Useful hexadecimal values:

09 = TAB
20 = SPACE
0A = LF
0D = CR

---

## 06 - Raw Ingestion

Copy the original files without modification.

Destination:

data/01-raw

Validate integrity:

sha256sum original_file
sha256sum raw_file

Checksums must be identical.

---

## 07 - Bronze Standardization

Create standardized technical datasets.

Tasks:

- Convert text files to UTF-8 (when required)
- Remove or manage BOM
- Apply the correct delimiter
- Preserve source values
- Add technical metadata (if required)
- Load/export with DuckDB
- Keep data as close as possible to the source

Destination:

data/02-bronze

---

## 08 - Data Quality Checks

Validate:

- Completeness
- Uniqueness
- Validity
- Consistency
- Referential integrity
- Malformed records
- Unexpected values

Rejected records:

data/05-rejected

Documentation:

reports/quality_report.md

---

## 09 - Silver Cleaning and Validation

Business-ready cleaning.

Tasks:

- Normalize column names
- Assign correct data types
- Standardize dates
- Normalize text values
- Handle NULL values
- Remove duplicates
- Apply business rules
- Validate keys

Destination:

data/03-silver

---

## 10 - Data Modeling and Business SQL

Create analytical structures.

Tasks:

- Primary keys
- Foreign keys
- Relationships
- Joins
- Exploratory SQL
- Business queries
- SQL views

SQL location:

sql/

---

## 11 - Gold Datasets and KPIs

Create analytical outputs.

Tasks:

- Aggregations
- Metrics
- KPIs
- Dashboard-ready datasets
- Final validation

Destination:

data/04-gold

---

## 12 - Documentation

Complete project documentation.

Documents:

- README.md
- pipeline.md
- conventions.md
- architecture.md
- file_inventory.md
- quality_report.md
- data_dictionary.md
- business_questions.md
- lessons_learned.md
- screenshots