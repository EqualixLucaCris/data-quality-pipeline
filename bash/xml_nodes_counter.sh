#!/usr/bin/env bash

# Usage:
#   ./xml_nodes_counter.sh <xml_file> <xpath_node_path>
#
# Example:
#   ./xml_nodes_counter.sh stores.xml '/stores/store'
#
# Parameters:
#   $1 = path to the XML file
#   $2 = XPath identifying the nodes to count
#
# Output:
#   Prints the number of nodes found.

set -euo pipefail

xml_file="$1"
node_path="$2"

count=$(xmllint --xpath "count($node_path)" "$xml_file")

echo "$count"
