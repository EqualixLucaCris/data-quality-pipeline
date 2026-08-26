#!/usr/bin/env bash

set -euo pipefail

bronze_dir="data/02-bronze"
log_file="logs/bronze_standardization.log"

echo "timestamp,file,action,status" > "$log_file"

log_action() {
    local file_name="$1"
    local action="$2"
    local status="$3"

    echo "$(date -Iseconds),$file_name,$action,$status" >> "$log_file"
}

# customers.csv: semicolon -> comma
if [ -f "$bronze_dir/customers.csv" ]; then
    sed 's/;/,/g' "$bronze_dir/customers.csv" > "$bronze_dir/customers.tmp"
    mv "$bronze_dir/customers.tmp" "$bronze_dir/customers.csv"
    log_action "customers.csv" "delimiter ; to ," "SUCCESS"
fi

# order_items.csv: pipe -> comma
if [ -f "$bronze_dir/order_items.csv" ]; then
    tr '|' ',' < "$bronze_dir/order_items.csv" > "$bronze_dir/order_items.tmp"
    mv "$bronze_dir/order_items.tmp" "$bronze_dir/order_items.csv"
    log_action "order_items.csv" "delimiter pipe to comma" "SUCCESS"
fi

# products.csv: TAB -> comma
if [ -f "$bronze_dir/products.csv" ]; then
    tr '\t' ',' < "$bronze_dir/products.csv" > "$bronze_dir/products.tmp"
    mv "$bronze_dir/products.tmp" "$bronze_dir/products.csv"
    log_action "products.csv" "delimiter TAB to comma" "SUCCESS"
fi

# orders.csv: remove UTF-8 BOM if present
if [ -f "$bronze_dir/orders.csv" ]; then
    if head -c 3 "$bronze_dir/orders.csv" | od -An -tx1 | grep -qi "ef bb bf"; then
        tail -c +4 "$bronze_dir/orders.csv" > "$bronze_dir/orders.tmp"
        mv "$bronze_dir/orders.tmp" "$bronze_dir/orders.csv"
        log_action "orders.csv" "UTF-8 BOM removed" "SUCCESS"
    else
        log_action "orders.csv" "No BOM detected" "SKIPPED"
    fi
fi

echo "Bronze standardization completed."