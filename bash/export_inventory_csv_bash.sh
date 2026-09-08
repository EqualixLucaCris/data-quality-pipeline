#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# export_inventory_csv.sh
#
# Purpose:
#   Convert reports/file_inventory.md into
#   reports/file_inventory.csv using Bash + awk only.
#
# Run from anywhere inside the project:
#   bash/export_inventory_csv.sh
#
# Or:
#   bash bash/export_inventory_csv.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

INPUT="$PROJECT_ROOT/reports/file_inventory.md"
OUTPUT="$PROJECT_ROOT/reports/file_inventory.csv"

if [[ ! -f "$INPUT" ]]; then
    echo "ERROR: input file not found: $INPUT" >&2
    exit 1
fi

awk '
BEGIN {
    FS="\\|"
    OFS=","
    found_header=0
}

function trim(s) {
    gsub(/^[ \t]+|[ \t]+$/, "", s)
    return s
}

function csv_escape(s) {
    s = trim(s)
    gsub(/\\\|/, "|", s)
    gsub(/"/, "\"\"", s)

    if (s ~ /[",]/) {
        s = "\"" s "\""
    }

    return s
}

# Detect the Markdown header row.
/^\|/ {
    # Extract fields excluding the empty first/last fields caused by leading/trailing |
    delete cols
    n=0
    for (i=2; i<NF; i++) {
        val=trim($i)
        cols[++n]=val
    }

    if (!found_header) {
        # Normalize expected header names
        header_line=""
        for (i=1; i<=n; i++) {
            h=tolower(cols[i])
            gsub(/[ -]+/, "_", h)
            gsub(/[^a-z0-9_]/, "", h)

            if (i==1) header_line=h
            else header_line=header_line OFS h
        }

        if (header_line ~ /file/ &&
            header_line ~ /extension/ &&
            header_line ~ /encoding/) {

            print header_line
            found_header=1
            next
        }
    }

    if (found_header) {
        # Skip Markdown separator rows like | --- | --- |
        separator=1
        for (i=1; i<=n; i++) {
            tmp=cols[i]
            gsub(/[ :-]/, "", tmp)
            if (tmp != "") {
                separator=0
                break
            }
        }
        if (separator) next

        row=""
        for (i=1; i<=n; i++) {
            val=csv_escape(cols[i])
            if (i==1) row=val
            else row=row OFS val
        }

        print row
    }
}
' "$INPUT" > "$OUTPUT"

if [[ ! -s "$OUTPUT" ]]; then
    echo "ERROR: CSV was not generated. Check the Markdown table format." >&2
    exit 1
fi

echo "Created: $OUTPUT"
echo
echo "Preview:"
head -n 5 "$OUTPUT"
