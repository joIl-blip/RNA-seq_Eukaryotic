configfile: "config/config.yaml"

SAMPLES = config["samples"]
RAW = config["raw_dir"]
RESULTS = config["results_dir"]

rule all:
	input:
		expand(RESULTS + "/01_fastqc_raw/{sample}_{read}_fastqc.html", sample=SAMPLES, read=[1, 2])	

# 2.1 Read preprocessing ======================================================

	# 01. Evaluate the quality of raw reads using FastQC.

rule fastqc_raw:
	input:
		RAW + "/{sample}/{sample}_{read}.fastq.gz"
	output:
		html = RESULTS + "/01_fastqc_raw/{sample}_{read}_fastqc.html",
		zip = RESULTS + "/01_fastqc_raw/{sample}_{read}_fastqc.zip"
	params:
		OUT_DIR = RESULTS + "/01_fastqc_raw"
	threads: 2
	resources:
		mem_mb = 2000,
		runtime = 60
	conda: "envs/FastQC_env.yaml"
	log: "logs/fastqc_raw/{sample}_{read}.log"
	shell:
		"fastqc -t {threads} --outdir {params.OUT_DIR} {input} > {log} 2>&1"

	# 02. Trim adapters and low-quality sequences using the tool of your choice.

	# 03. Evaluate the quality of processed reads.	


# 2.2 Alignment-based quantification ==========================================

	# 04. Build a reference genome index genome if it is not present. 

	# 05. Align the processed reads to the reference genome.
 
	# 06. Quantify gene expression using featureCounts.


# 2.3 Alignment-free quantification ===========================================

	# 07. Build a kallisto/salmon index if it is not present.

	# 08. Quantify transcript abundance for all samples using kallisto.

# 2.4 Alignment quality assessment (using RSeQC and deepTools) ================

	# 09. Alignment statistics

	# 10. RNA-seq library strandedness

	# 11. Read distribution across genomic features

	# 12. Gene body coverage

	# 13. Insert size/fragment length distribution

	# 14. Correlation between samples

	# 15. Principal component analysis (PCA)


