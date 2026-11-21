configfile: "config/config.yaml"

SAMPLES = config["samples"]
RAW = config["raw_dir"]
RESULTS = config["results_dir"]

READS = [1, 2]

rule all:
	input:
		expand(RESULTS + "/01_fastqc_raw/{sample}_{read}_fastqc.html", sample=SAMPLES, read=READS),
		expand(RESULTS + "/03_fastqc_trimmed/{sample}_{read}_val_{read}_fastqc.html", sample=SAMPLES, read=READS)

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

rule trim:
        input:
                r1 = RAW + "/{sample}/{sample}_1.fastq.gz",
                r2 = RAW + "/{sample}/{sample}_2.fastq.gz"
        output:
                r1 = RESULTS + "/02_trimmed/{sample}_1_val_1.fq.gz",
                r2 = RESULTS + "/02_trimmed/{sample}_2_val_2.fq.gz",
                report1 = RESULTS + "/02_trimmed/{sample}_1.fastq.gz_trimming_report.txt",
                report2 = RESULTS + "/02_trimmed/{sample}_2.fastq.gz_trimming_report.txt"
        params:
                OUT_DIR = RESULTS + "/02_trimmed",
                quality = config["trimming"]["quality"],
                length = config["trimming"]["length"]
        threads: 8
        resources:
                mem_mb = 6000,
                runtime = 120
        conda: "envs/Trim_Galore_env.yaml"
        log: "logs/raw_trimmed/{sample}.log"
        shell:
                "trim_galore --paired --illumina -q {params.quality} --length {params.length} --cores {threads} -o {params.OUT_DIR} {input.r1} {input.r2} > {log} 2>&1"



	# 03. Evaluate the quality of processed reads.	

rule fastqc_trimmed:
        input:
                RESULTS + "/02_trimmed/{sample}_{read}_val_{read}.fq.gz"
        output:
                html = RESULTS + "/03_fastqc_trimmed/{sample}_{read}_val_{read}_fastqc.html",
                zip = RESULTS + "/03_fastqc_trimmed/{sample}_{read}_val_{read}_fastqc.zip"
        params:
                OUT_DIR = RESULTS + "/03_fastqc_trimmed"
        threads: 2
        resources:
                mem_mb = 6000,
                runtime = 60
        conda: "envs/FastQC_env.yaml"
        log: "logs/fastqc_trimmed/{sample}_{read}.log"
        shell:
                "fastqc -t {threads} --outdir {params.OUT_DIR} {input} > {log} 2>&1"

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


