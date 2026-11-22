#!/usr/bin/bash
#SBATCH --job-name=raw_unpaired_data_download
#SBATCH --cpus-per-task=10
#SBATCH --mem=8G
#SBATCH --time=04:00:00

set -euo pipefail

id="SRR1039516"
OUTPUT_DIR="raw_data/$id"

echo "===== Downloading $id. ====="
mkdir -p "$OUTPUT_DIR"
fasterq-dump "$id" --split-3 -e "$SLURM_CPUS_PER_TASK" --outdir "$OUTPUT_DIR"

echo "===== Compressing $id. ====="
pigz -p "$SLURM_CPUS_PER_TASK" "$OUTPUT_DIR"/*.fastq

echo "===== Downloaded $id. ====="

