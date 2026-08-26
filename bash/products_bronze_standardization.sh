#!/usr/bin/env bash

set -euo pipefail

raw_file="data/01-raw/products.csv"
bronze_file="data/02-bronze/products.csv"
tmp_file="data/02-bronze/products.tmp"
log_file="logs/products_bronze_standardization.log"

echo "timestamp,file,action,status" > "$log_file"

log_action() {
    local file_name="$1"
    local action="$2"
    local status="$3"

    echo "$(date -Iseconds),$file_name,$action,$status" >> "$log_file"
}

# products.csv:
# UTF-16LE -> UTF-8
# TAB -> ;

if [ -f "$raw_file" ]; then

    iconv -f UTF-16LE -t UTF-8 "$raw_file" |
        tr '\t' ';' > "$tmp_file"

    mv "$tmp_file" "$bronze_file"

    log_action \
        "products.csv" \
        "UTF-16LE_to_UTF-8_and_TAB_to_semicolon" \
        "SUCCESS"
fi

echo "products.csv Bronze standardization completed."
