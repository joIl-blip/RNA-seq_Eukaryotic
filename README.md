# RNA-seq_Eukaryotic project description

The projects contains Bash scripts and a Snakemake workflow for RNA-seq analysis.

Main project directory is **RNA-seq_Eukaryotic**. All commands should be executed from here.
**Example**: `bash scripts/get_accession_id.sh`

# RNA-seq_Eukaryotic dataset description

The sequencing data used in this project come from the GEO dataset **GSE52778**, titled ***Human Airway Smooth Muscle Transcriptome Changes in Response to Asthma Medications***.

The study was done by researchers led by **Blanca E. Himes** and investigated how asthma medications affect gene expression in human airway smooth muscle cells. The sequencing data were published in 2014 in a scientific journal *PLOS ONE*.

There are four samples from human genome:
- **SRR1039508** (N61311_untreated)
- **SRR1039516** (N080611_untreated)
- **SRR1039518** (N080611_Alb)
- **SRR1039521** (N061011_Dex)

The untreated samples (**SRR1039508** and **SRR1039516**) were used as control samples as they were not exposed to any asthma medications.

The treatment samples (**SRR1039518** and **SRR1039521**) were exposed to different medications used to treat asthma. There are two treatments used:
- **Albuterol (Alb):** relaxes airway smooth muscle, helping to increase airflow.
- **Dexamethasone (Dex):** reduces inflammation.

This treatment is useful to compare medications of asthma to know which genes had their expression changed.

