#!/usr/bin/bash
set -euo pipefail

INPUT_FILE="datasets.txt"
OUTPUT_FILE="accession_IDs.txt"

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: $INPUT_FILE not found."
    exit 1
fi

> "$OUTPUT_FILE"

while read accession_id
do
    echo "===== Processing: $accession_id ====="

    esearch -db sra -query "$accession_id" < /dev/null | efetch -format runinfo | cut -d ',' -f 1 | tail -n +2 >> "$OUTPUT_FILE"
done < "$INPUT_FILE"

echo "===== Done writing. ====="

