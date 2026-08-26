#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <file> <delimiter>"
    echo "Example: $0 data/02-bronze/products.csv ';'"
    exit 1
fi

file_path="$1"
delimiter="$2"
sample_limit="${3:-5}"

if [ ! -f "$file_path" ]; then
    echo "ERROR: file not found: $file_path"
    exit 1
fi

echo "File: $file_path"
echo "Delimiter: $delimiter"
echo

expected_fields=$(
    awk -F"$delimiter" 'NR==1 {print NF; exit}' "$file_path"
)

total_rows=$(
    awk 'END {print NR-1}' "$file_path"
)

invalid_rows=$(
    awk -F"$delimiter" -v expected="$expected_fields" '
        NR > 1 && NF != expected {bad++}
        END {print bad+0}
    ' "$file_path"
)

echo "Field distribution:"
awk -F"$delimiter" '
{
    count[NF]++
}
END {
    for (n in count)
        print "  fields=" n ", rows=" count[n]
}
' "$file_path"

echo
echo "Summary:"
echo "  expected_fields: $expected_fields"
echo "  data_rows:       $total_rows"
echo "  invalid_rows:    $invalid_rows"

if [ "$invalid_rows" -eq 0 ]; then
    echo "  status:          PASS"
    exit 0
fi

echo "  status:          FAIL"
echo
echo "First $sample_limit malformed rows:"

awk -F"$delimiter" \
    -v expected="$expected_fields" \
    -v limit="$sample_limit" '
NR > 1 && NF != expected {
    print "line=" NR ", fields=" NF ", content=" $0
    shown++
    if (shown >= limit)
        exit
}
' "$file_path"

exit 2
