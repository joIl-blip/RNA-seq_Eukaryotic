#!/usr/bin/bash
#SBATCH --job-name=raw_data_download
#SBATCH --cpus-per-task=10
#SBATCH --mem=8G
#SBATCH --time=04:00:00
set -euo pipefail

INPUT_FILE="accession_IDs.txt"
OUTPUT_DIR="raw_data"

if [ ! -s "$INPUT_FILE" ]; then
        echo "===== ERROR: $INPUT_FILE is missing or empty. ====="
        exit 1
fi

mkdir -p "$OUTPUT_DIR"

while read -r id; do

	if [ -s "$OUTPUT_DIR/$id/${id}_1.fastq.gz" ] && [ -s "$OUTPUT_DIR/$id/${id}_2.fastq.gz" ]; then
        	echo "===== $id already downloaded. Skipping. ====="
        	continue
    	fi


	echo "===== Downloading $id. ====="
	mkdir -p "$OUTPUT_DIR/$id"
	fasterq-dump "$id" --split-files -e "$SLURM_CPUS_PER_TASK" -O "$OUTPUT_DIR/$id"

	echo "===== Compressing $id ======"
	pigz -p "$SLURM_CPUS_PER_TASK" "$OUTPUT_DIR/$id"/*.fastq

	echo "===== Done $id. ====="
done < "$INPUT_FILE"
