configfile: "config/config.yaml"

SAMPLES = config["samples"]
RAW = config["raw_dir"]
RESULTS = config["results_dir"]

GENOME = config["reference"]["genome"]
TRANSCRIPTOME = config["reference"]["transcriptome"]
ANNOTATION = config["reference"]["annotation"]

HISAT2_INDEX = config["hisat2_index"]
KALLISTO_INDEX = config["kallisto_index"]
GENE_MODEL_BED = config["gene_model_bed"]

READS = [1, 2]

rule all:
	input:
		expand(RESULTS + "/01_fastqc_raw/{sample}_{read}_fastqc.html", sample=SAMPLES, read=READS),
		expand(RESULTS + "/03_fastqc_trimmed/{sample}_{read}_val_{read}_fastqc.html", sample=SAMPLES, read=READS),
		"reference/genome/GRCh38.genome.fa",
		"reference/transcriptome/gencode.v50.transcripts.fa",
		"reference/annotation/gencode.v50.annotation.gtf",
		RESULTS + "/05_featureCounts/counts.txt",
		expand(RESULTS + "/06_kallisto/{sample}/abundance.tsv", sample=SAMPLES),
		expand(RESULTS + "/07_rseqc/{sample}/{sample}.bam_stat.txt", sample=SAMPLES),
		expand(RESULTS + "/07_rseqc/{sample}/{sample}.infer_experiment.txt", sample=SAMPLES),
		expand(RESULTS + "/07_rseqc/{sample}/{sample}.read_distribution.txt", sample=SAMPLES),
		expand(RESULTS + "/07_rseqc/{sample}/{sample}.geneBodyCoverage.txt", sample=SAMPLES),
		expand(RESULTS + "/07_rseqc/{sample}/{sample}.inner_distance_freq.txt", sample=SAMPLES)

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


rule unpack_genome:
	input:
		"reference/genome/GRCh38.genome.fa.gz"
	output:
		"reference/genome/GRCh38.genome.fa"
	shell:
		"zcat {input} > {output}"


rule unpack_transcriptome:
	input:
		"reference/transcriptome/gencode.v50.transcripts.fa.gz"
	output:
		"reference/transcriptome/gencode.v50.transcripts.fa"
	shell:
		"zcat {input} > {output}"

rule unpack_annotation:
	input:
		"reference/annotation/gencode.v50.annotation.gtf.gz"
	output:
		"reference/annotation/gencode.v50.annotation.gtf"
	shell:
		"zcat {input} > {output}"


# 2.2 Alignment-based quantification ==========================================

# 04. Build a reference genome index genome if it is not present. 

rule index_genome:
	input:
		GENOME
	output:
		expand(HISAT2_INDEX + ".{i}.ht2", i=range(1, 9))
	params:
		PREFIX = HISAT2_INDEX
	threads: 8
	resources:
		mem_mb = 24000,
		runtime = 120
	conda: "envs/hisat2_env.yaml"
	log: "logs/hisat2_index/hisat2_index.log"
	shell:
		"hisat2-build -p {threads} {input} {params.PREFIX} > {log} 2>&1"

# 05. Align the processed reads to the reference genome.

rule align_reads:
	input:
		r1 = RESULTS + "/02_trimmed/{sample}_1_val_1.fq.gz",
		r2 = RESULTS + "/02_trimmed/{sample}_2_val_2.fq.gz",
		index = expand(HISAT2_INDEX + ".{i}.ht2", i=range(1, 9))
	output:
		bam = RESULTS + "/04_mapping/{sample}.bam"
	params:
		PREFIX = HISAT2_INDEX
	threads: 4
	resources:
		mem_mb = 24000,
		runtime = 120
	conda: "envs/hisat2_env.yaml"
	log: "logs/hisat2/{sample}.log"
	shell:
		"hisat2 -p {threads} -x {params.PREFIX} -1 {input.r1} -2 {input.r2} 2> {log} | samtools sort -@ {threads} -o {output.bam} -"

# 06. Quantify gene expression using featureCounts.

rule quantify_expression:
	input:
		bams = expand(RESULTS + "/04_mapping/{sample}.bam", sample=SAMPLES),
		annotation = ANNOTATION
	output:
		counts = RESULTS + "/05_featureCounts/counts.txt",
		summary = RESULTS + "/05_featureCounts/counts.txt.summary"
	params:
		feature = config["featureCounts"]["feature"],
		attribute = config["featureCounts"]["attribute"]
	threads: 4
	resources:
		mem_mb = 24000,
		runtime = 120
	conda: "envs/featureCounts_env.yaml"
	log: "logs/featureCounts/featureCounts.log"
	shell:
		"featureCounts -p --countReadPairs -T {threads} -t {params.feature} -g {params.attribute} -a {input.annotation} -o {output.counts} {input.bams} > {log} 2>&1"

# 2.3 Alignment-free quantification ===========================================

# 07. Build a kallisto/salmon index if it is not present.

rule kallisto_index:
	input:
		TRANSCRIPTOME
	output:
		KALLISTO_INDEX
	threads: 8
	resources:
		mem_mb = 24000,
		runtime = 120
	conda: "envs/kallisto_env.yaml"
	log: "logs/kallisto_index/kallisto_index.log"
	shell:
		"kallisto index -t {threads} -i {output} {input} > {log} 2>&1"

# 08. Quantify transcript abundance for all samples using kallisto.

rule quantify_kallisto:
	input:
		index = KALLISTO_INDEX,
		r1 = RESULTS + "/02_trimmed/{sample}_1_val_1.fq.gz",
		r2 = RESULTS + "/02_trimmed/{sample}_2_val_2.fq.gz"
	output:
		abundance = RESULTS + "/06_kallisto/{sample}/abundance.tsv",
		run_info = RESULTS + "/06_kallisto/{sample}/run_info.json"
	params:
		OUT_DIR = RESULTS + "/06_kallisto/{sample}"
	threads: 8
	resources:
		mem_mb = 12000,
		runtime = 120
	conda: "envs/kallisto_env.yaml"
	log: "logs/kallisto_quant/{sample}.log"
	shell:
		"kallisto quant -i {input.index} -o {params.OUT_DIR} -t {threads} {input.r1} {input.r2} 2> {log}"

# 2.4 Alignment quality assessment (using RSeQC and deepTools) ================

rule index_bam:
	input:
		RESULTS + "/04_mapping/{sample}.bam"
	output:
		RESULTS + "/04_mapping/{sample}.bam.bai"
	resources:
		mem_mb = 6000,
		runtime = 120
	conda: "envs/hisat2_env.yaml"
	log: "logs/index_bam/{sample}.log"
	shell:
		"samtools index {input} > {log} 2>&1"

# BED file needed for RSeQC.
rule gtf_to_bed:
	input:
		ANNOTATION
	output:
		bed = GENE_MODEL_BED,
		genepred = temp(GENE_MODEL_BED + ".genePred")
	resources:
		mem_mb = 6000,
		runtime = 120
	conda: "envs/ucsc_env.yaml"
	log: "logs/gtf_to_bed/gtf_to_bed.log"
	shell:
		"gtfToGenePred -genePredExt {input} {output.genepred} > {log} 2>&1 && genePredToBed {output.genepred} {output.bed} >> {log} 2>&1"

# 09. Alignment statistics

rule rseqc_align_stat:
	input:
		RESULTS + "/04_mapping/{sample}.bam"
	output:
		RESULTS + "/07_rseqc/{sample}/{sample}.bam_stat.txt"
	resources:
		mem_mb = 6000,
		runtime = 120
	conda: "envs/RSeQC_env.yaml"
	log: "logs/rseqc_align_stat/{sample}.log"
	shell:
		"bam_stat.py -i {input} > {output} 2> {log}"

# 10. RNA-seq library strandedness

rule rseqc_infer_experiment:
	input:
		bam = RESULTS + "/04_mapping/{sample}.bam",
		bai = RESULTS + "/04_mapping/{sample}.bam.bai",
		bed = GENE_MODEL_BED
	output:
		RESULTS + "/07_rseqc/{sample}/{sample}.infer_experiment.txt"
	resources:
		mem_mb = 6000,
		runtime = 120
	conda: "envs/RSeQC_env.yaml"
	log: "logs/rseqc_infer_experiment/{sample}.log"
	shell:
		"infer_experiment.py -r {input.bed} -i {input.bam} > {output} 2> {log}"

# 11. Read distribution across genomic features

rule rseqc_read_distrubution:
	input:
		bam = RESULTS + "/04_mapping/{sample}.bam",
		bai = RESULTS + "/04_mapping/{sample}.bam.bai",
		bed = GENE_MODEL_BED
	output:
		RESULTS + "/07_rseqc/{sample}/{sample}.read_distribution.txt"
	resources:
		mem_mb = 6000,
		runtime = 120
	conda: "envs/RSeQC_env.yaml"
	log: "logs/rseqc_read_distribution/{sample}.log"
	shell:
		"read_distribution.py -r {input.bed} -i {input.bam} > {output} 2> {log}"

# 12. Gene body coverage

rule rseqc_gene_body_coverage:
	input:
		bam = RESULTS + "/04_mapping/{sample}.bam",
		bai = RESULTS + "/04_mapping/{sample}.bam.bai",
		bed = GENE_MODEL_BED
	output:
		RESULTS + "/07_rseqc/{sample}/{sample}.geneBodyCoverage.txt"
	params:
		PREFIX = RESULTS + "/07_rseqc/{sample}/{sample}"
	resources:
		mem_mb = 6000,
		runtime = 120
	conda: "envs/RSeQC_env.yaml"
	log: "logs/rseqc_gene_body_coverage/{sample}.log"
	shell:
		"geneBody_coverage.py -r {input.bed} -i {input.bam} -o {params.PREFIX} > {log} 2>&1"

# 13. Insert size/fragment length distribution

rule rseqc_length_distribution:
	input:
		bam = RESULTS + "/04_mapping/{sample}.bam",
		bai = RESULTS + "/04_mapping/{sample}.bam.bai",
		bed = GENE_MODEL_BED
	output:
		RESULTS + "/07_rseqc/{sample}/{sample}.inner_distance_freq.txt"
	params:
		PREFIX = RESULTS + "/07_rseqc/{sample}/{sample}"
	resources:
		mem_mb = 12000,
		runtime = 120
	conda: "envs/RSeQC_env.yaml"
	log: "logs/rseqc_length_distribution/{sample}.log"
	shell:
		"inner_distance.py -r {input.bed} -i {input.bam} -o {params.PREFIX} > {log} 2>&1"

# 14. Correlation between samples
# 15. Principal component analysis (PCA)

