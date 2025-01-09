This README file describes the funcionalities of the Mutect-IMAPR algorithm

# Snakemake pipeline
The Snakefile consist of one long rule run_pipeline which performs the variant calling from RNA-seq using a implementation of IMAPR and Mutect2.

Run Snakemake pipeline using command
``` bash
snakemake -s Snakefile --profile /path/to/Mutect_IMAPR/pbs-default -j 4 --cores 10 -k -p
```
Follow build_reference.sh script from https://github.com/wang-lab/IMAPR/blob/main/build_reference.sh to obtain reference files. To use department of Genomic Medicine reference for hisat2 realignment run the following commands:
``` bash
module load java/1.8.0 picard-tools/2.25.2
java -jar $PICARD CreateSequenceDictionary -R /path/to/fasta_reference/file.fasta -O GRCh38_no_alt.dict
module load anaconda2/4.4.0 hisat2/2.2.0
hisat2-build -p 8 /path/to/fasta_reference/file.fasta hisat2_GRCh38_no_alt
```
Location of all reference files and modules used as input to the Snakemake pipeline is defined in the config file.

**rule run_pipeline**

1.	Conversion of CRAM input files into bam format.
2.	Create text IMAPR input file (\*_input_IMAPR.txt) with input samples, tool locations and output directory.
3.	Run IMAPR pipeline by submitting the script IMAPR_full.sh, which runs detect_variants_Sentieon.pl for IMAPR input file.
  	``` bash
    bash IMAPR_full.sh *_input_IMAPR.txt
    ```
5.	Add header to first VCF from IMAPR 
6.	Run Sentieon somatic variant calling with tumor RNA and normal WGS.
7.	Run Sentieon filtering for somatic variant calling.
8.	IMAPR and Sentieon VCF comparison is performed using script get_stats_variants.sh.

# Visualization
After the Snakemake pipeline has finished run the command:
``` bash
bash concatenate_csv.sh 
```
Output files from the Snakefile are concatenated and results are summarized in plots created with stats_plotting.R
