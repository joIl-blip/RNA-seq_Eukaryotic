#!/usr/bin/bash
#SBATCH --job-name=snakemake
#SBATCH --partition=main
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=logs/snakemake_%j.log
#SBATCH --time=06:00:00

source ~/conda_setup.sh
conda activate snakemake
snakemake --use-conda --executor slurm --jobs 5 --latency-wait 60 --rerun-incomplete --default-resources slurm_partition=main mem_mb=2000 runtime=60
