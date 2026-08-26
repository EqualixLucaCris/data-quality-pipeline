#!/usr/bin/env bash

# Usage:
#   ./xml_extract_column.sh <xml_file> <record_xpath> <field_xpath>
#
# Example attribute:
#   ./xml_extract_column.sh stores.xml '/stores/store' '@id'
#
# Example child element:
#   ./xml_extract_column.sh stores.xml '/stores/store' 'name'
#
# Parameters:
#   $1 = XML file path
#   $2 = XPath of the repeated record node
#   $3 = Relative XPath of the value to extract
#
# Output:
#   One value per record, preserving order.
#   Missing values are written as NULL.

set -euo pipefail

xml_file="$1"
record_path="$2"
field_path="$3"

count=$(xmllint --xpath "count($record_path)" "$xml_file")

for ((i=1; i<=count; i++)); do

    value=$(xmllint --xpath \
        "string($record_path[$i]/$field_path)" \
        "$xml_file")

    if [ -z "$value" ]; then
        echo "NULL"
    else
        echo "$value"
    fi

done
