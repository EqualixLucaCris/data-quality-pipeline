#!/usr/bin/env bash

set -euo pipefail

source_file="tmp/xml_stores/stores.csv"
silver_dir="data/03-silver"
log_file="logs/silver_ingestion.log"

file_name="stores.csv"
target_file="$silver_dir/$file_name"

# Create log header only if the log does not exist or is empty
if [ ! -s "$log_file" ]; then
    echo "timestamp,source_file,target_file,source_checksum,target_checksum,status" > "$log_file"
fi

# Copy generated XML-derived CSV to Silver
cp "$source_file" "$target_file"

# Calculate checksums
source_hash=$(sha256sum "$source_file" | cut -d' ' -f1)
target_hash=$(sha256sum "$target_file" | cut -d' ' -f1)

timestamp=$(date -Iseconds)

# Validate copy
if [ "$source_hash" = "$target_hash" ]; then
    status="SUCCESS"
else
    status="FAILED"
fi

# Append new ingestion event to existing log
echo "$timestamp,$source_file,$target_file,$source_hash,$target_hash,$status" >> "$log_file"

echo "stores.csv tmp -> Silver ingestion: $status"
