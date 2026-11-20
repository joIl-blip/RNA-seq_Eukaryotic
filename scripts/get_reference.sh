#!/usr/bin/bash
set -euo pipefail

GENCODE_VERSION=50
GENOME_VERSION=GRCh38

URL=https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_${GENCODE_VERSION}

genome=reference/genome/${GENOME_VERSION}.genome.fa.gz
transcriptome=reference/transcriptome/gencode.v${GENCODE_VERSION}.transcripts.fa.gz
annotation=reference/annotation/gencode.v${GENCODE_VERSION}.annotation.gtf.gz

index=reference/index/$GENOME_VERSION

# Download genome =============================================================

if [ -s "$genome" ]; then
	echo "===== Genome already exists. Skipping. ====="
else
	mkdir -p reference/genome
	echo "===== Downloading human reference genome. ====="
	wget "$URL/${GENOME_VERSION}.p14.genome.fa.gz" -O "$genome"
fi

# Download transcriptome ======================================================

if [ -s "$transcriptome" ]; then
        echo "===== Transcriptome already exists. Skipping. ====="
else
        mkdir -p reference/transcriptome
        echo "===== Downloading human transcriptome. ====="
        wget "$URL/gencode.v${GENCODE_VERSION}.transcripts.fa.gz" -O "$transcriptome"
fi

# Download annotation =========================================================

# Build index =================================================================
