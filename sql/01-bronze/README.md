# Bronze Layer

The Bronze layer of this project is managed primarily with Bash scripts rather than SQL.

Main operations:
- raw ingestion
- encoding standardization
- delimiter normalization
- BOM handling
- checksum validation
- ingestion logging

Relevant scripts:

- `bash/raw_ingestion.sh`
- `bash/bronze_standardization.sh`
- `bash/products_bronze_standardization.sh`

Relevant logs:

- `logs/raw_ingestion.log`
- `logs/bronze_standardization.log`
- `logs/products_bronze_standardization.log`

SQL transformations begin mainly in the Silver layer.

