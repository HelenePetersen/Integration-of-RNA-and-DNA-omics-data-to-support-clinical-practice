# Integration-of-RNA-and-DNA-omics-data-to-support-clinical-practice

This Master project has been performed in colaboration between Technical University of Denmark and Department of Genomic Medicine at Rigshospitalet.
Two main Snakemake pipelines have been developed for the algorithms Mutect-IMAPR and Variant Extraction and Expression Reporting (VEXER).

The aim of Mutect-IMAPR was to quantify the recall of somatic variant calling using tumor RNA-seq and normal WGS. This has been tested using a Sentieon implementation of GATK Mutect2 and an implementation of wang-lab IMAPR.

The aim of VEXER was to develop a method for improved integrating of RNA-seq data in variant calling and propose a variant annotation when both DNA and RNA information is considered. 

The implementation of the two algorithm are described further in the README files in the respective folders. The data used are not publicly available and outputs from the algorithms are therefore not include in the repositories.
