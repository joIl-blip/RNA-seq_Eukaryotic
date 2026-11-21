# 2.1 Read preprocessing ======================================================

	# 01. Evaluate the quality of raw reads using FastQC.

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


