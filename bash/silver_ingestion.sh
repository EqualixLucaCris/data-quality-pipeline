#!/usr/bin/env bash

set -euo pipefail

incoming_dir="data/02-bronze"
silver_dir="data/03-silver"
log_file="logs/silver_ingestion.log"

echo "timestamp,source_file,target_file,source_checksum,target_checksum,status" > "$log_file"

for source_file in "$incoming_dir"/*; do
    file_name=$(basename "$source_file")
    target_file="$silver_dir/$file_name"

    cp "$source_file" "$target_file"

    source_hash=$(sha256sum "$source_file" | cut -d' ' -f1)
    target_hash=$(sha256sum "$target_file" | cut -d' ' -f1)
    timestamp=$(date -Iseconds)

    if [ "$source_hash" = "$target_hash" ]; then
        status="SUCCESS"
    else
        status="FAILED"
    fi

    echo "$timestamp,$source_file,$target_file,$source_hash,$target_hash,$status" >> "$log_file"
done
