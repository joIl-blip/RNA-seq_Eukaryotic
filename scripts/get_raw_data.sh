#!/usr/bin/bash
set -euo pipefail

INPUT_FILE="accession_IDs.txt"
OUTPUT_FILE="raw_data"

if [ ! -s "$INPUT_FILE" ]; then
        echo "===== ERROR: $INPUT_FILE is missing or empty. ====="
        exit 1
fi

mkdir -p "$OUTPUT_FILE"

while read -r id; do

	if [ -d "$OUTPUT_FILE/$id" ] && [ "$(ls "$OUTPUT_FILE/$id" | wc -l)" -eq 2 ]; then
                echo "===== $id already exists with 2 files. Skipping. ====="
                continue
        fi

	echo "===== Downloading $id. ====="
	mkdir -p "$OUTPUT_FILE/$id"
	fastq-dump --gzip --split-files -O "$OUTPUT_FILE/$id" "$id" < /dev/null
	echo "===== Downloaded $id. ====="
done < "$INPUT_FILE"
