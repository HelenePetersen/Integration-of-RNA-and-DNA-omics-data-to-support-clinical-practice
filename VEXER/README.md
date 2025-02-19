This README file describes the funcionalities of the VEXER pipeline, the BRAF and Cancer type analysis.

# Snakemake
Edit config file paths to change input and output folders. Run snakemake pipeline by following command. Change the value for -j in the command to the number of parallel jobs you wish to run.
``` bash
module load snakemake/7.25.0
snakemake -s Snakefile --profile path/to/VEXER/pbs-default -j 40 --cores 1 -k -p
```
## Description of snakemake rules:
**rule extract_vcf**

Read in the true VCF file and extract variant call column informations for SNVs.

**rule add_geneID**

Read in the annotated true VCF file and find the assigned gene annotation for each SNV

**rule join_alt_geneID**

Apply script join_alt_geneID.sh to join the information from the two previous rules.

**rule mpileup**

Create a pileup file of the RNA tumor

**rule get_quality**

Apply script get_support_base.sh to check which variants have RNA reads supporting the alternative allele.
Apply script quality_score.py to calculate an average Phred score per variant for RNA reads supporting the alternative allele and append as column to pileup file. Variants without supporting RNA reads remain blank for this column.

**rule count_nucleotide**

In the pileup file the column with read bases are summarized into a tab-separated count format. Letter case is ignored so forward and reverse reads fall into the same group. A read base column is eg. transformed from tTat to 3 T 1 A.

**rule get_alt_coverage**

Apply script get_alt_coverage.sh to calculate the percentage of RNA reads supporting the alternative allele. Variants with no ALT RNA support are assigned 0 percent.
Add PATIENT_ID column to the output.
The output contains the following columns; "#CHROM" "POS" "REF" "ALT" "RNA_TOTAL" "RNA_ALT_COUNT" "PERCENTAGE" "QUALITY_SUPPORT_AVG" "FILTER" "GENEID" "PATIENT_ID"

**rule annotate_RNA_support**

Apply script annotate_RNA_support.sh to edit the FILTER column according to the supporting evidence of the variant by RNA_TOTAL, RNA_ALT_COUNT, and QUALITY_SUPPORT_AVG.
A file with only the variants passing the filtering requirements are saved (\*_mpileup_RNAsupport.tab.gz) and a file with all variants are saved (\*_mpileup_support_ID_RNA_FILTER.tab.gz).

**rule annotate_vcf**

The true VCF file is updated with annotations from the RNA, this includes RNA_TOTAL, RNA_ALT_COUNT, PERCENTAGE, QUALITY_SUPPORT_AVG and FILTER. With these informations added is it possible to access each variant's support from RNA data.

**rule clean_up_tmp**

Output files from rule get_alt_coverage, annotate_RNA_support and annotate_vcf are kept, all other intermediary files are removed from the output directory.

# Analyze results
## Concatenate files
When the snakemake pipeline has finished, concatenate all the result files using summarize_results.sh.

### summarize_results.sh

Run script with command:
``` bash
qsub summarize_results.sh
```
input files:
-   *_mpileup_support_ID_RNA_FILTER.tab.gz
-   *_mpileup_RNAsupport.tab.gz
-   Fase1_groundtruth_2024-10-07.tsv

The RNA information is concatenated for all patients in the file: all_patient_RNA_support.tab.gz.
The corresponding file where variants have the filter RNA_PASS are saved in the file: all_patient_RNA_support_filt.tab.gz.
The two files have the cancer diagnosis added and saved as: all_patient_RNA_support_diag.tab.gz and all_patient_RNA_support_filt_diag.tab.gz.
The non filtered information are filtered for at least having one read supporting the alternative allele and saved as: all_patient_RNA_min_support_diag.tab.gz.
The patient-ID and assigned diagnosis is saved in: metadata/diagnosis.txt.

If the TEST_DATASET parameter is set to true in summarize_results following R scripts are run:

**sina_clin_per_patient.R**

Plot variant distribution per patient-ID using a sinaplot with quality metrics on y-axis (PERCENTAGE, RNA_TOTAL, RNA_ALT_COUNT, QUALTY_SUPPORT_AVG),
both for variants with at least one alternative allele (_min) and filtered data (_filt).
-   sina_clin_patient_filt.pdf
-   sina_clin_patient_min.pdf
-   sina_qual_patient_filt.pdf
-   sina_qual_patient_min.pdf
-   sina_supportRNA_patient_filt.pdf
-   sina_supportRNA_patient_min.pdf
-   sina_totRNA_patient_filt.pdf
-   sina_totRNA_patient_min.pdf

Return list of clinically relevant genes for variants with at least one alternative allele and filtered data
-   clinical_gene_overview_filt.txt
-   clinical_gene_overview_min.txt

**numVariantsPerThreshold.R**

Plot of summed variants per patient when changing the filtering threshold of the quality metrics
-   scatter_q_PERCENTAGE.pdf
-   scatter_q_QUALITY_SUPPORT_AVG.pdf
-   scatter_q_RNA_ALT_COUNT.pdf
-   scatter_q_RNA_TOTAL.pdf

Return slope calculations and decided threshold
-   slope_RNA_ALT_COUNT.txt
-   slope_RNA_TOTAL.txt
-   Thresholds.txt

**numVariantsPerEvidence.R**

Return total variant count distribution per patient-ID using a sinaplot with FITLER categories on x-axis
-   VariantsPerEvidenceAll.pdf
-   VariantsPerEvidenceFilt.pdf

## BRAF analysis
After concatenation of BRAF data outputs from the Snakemake pipeline, run the following scripts

**add_treatment_response.sh**

Run script with command:
``` bash
bash add_treatment_response.sh
```
input files:
-   all_patient_RNA_support_diag.tab.gz
-   BRAF_patients.tab

The script adds Best response for BRAF patients and saves it in the output file: all_patient_RNA_support_diag_status.tab.
Then subset the data to only contain the patients from the BRAF study in the output file: BRAF_patient_RNA_support_diag_status.tab.

**Snakefile_pileup_RNA**

Edit config file paths to change input and output folders. Run snakemake pipeline with follwing command. Change the value for -j in the command to the number of parallel jobs you wish to run.

``` bash
module load snakemake/7.25.0
snakemake -s Snakefile_pileup_RNA --profile path/to/VEXER/pbs-default -j 40 --cores 1 -k -p
```
This script is run to ensure all available RNA data is used in the analysis.

rule mpileup
-   Create a pileup file of the RNA tumor for chromosome 7

rule add_patientID_glassID
-   Add patient-ID_Glass-number (PidGn) information to the pileup file

**get_RNA_BRAF.sh**

Run script with command:
``` bash
qsub get_RNA_BRAF.sh
```
Concatenates the output files from Snakefile_pileup_RNA and saves the output for position 1407533 in: all_patient_RNA_chr7-1407533.tab.

In the terminal run:
``` bash
less all_patient_RNA_chr7-1407533.tab | grep 140753336
```
Afterwards manually convert pileup results to RNA_TOTAL, RNA_ALT_COUNT, PERCENTAGE and RNA_FILTER. Compare PidGn in terminal output with present folders from pileup generation and registrer PidGn with RNA_NOCOV.
Merge the information output from VEXER and join with BRAF_patients.tab metadata to add Treatment_start. Save file as BRAF_patients_glassnumber.tab with columns: PATIENT_ID, PATIENT_ID.GLASSNUMBER, BEST_RESPONSE, RNA_FILTER, RNA_TOTAL, RNA_ALT_COUNT, PERCENTAGE and Treatment_start.

Update BRAF_patients_glassnumber.tab with Second_treatment and Date_of_Progression from BRAF_patients.tab metadata.

**date_of_sequencing.sh**

Run script with command:
``` bash
bash date_of_sequencing.sh
```
Extract information about sequencing date from Fase1_groundtruth_2024-10-07.tsv for each PidGn and save output in metadata folder as BRAF_sequencing_date.tab.

**BRAF_visualization**

Read in BRAF_patients_glassnumber.tab join with metadata from BRAF_sequencing_date.tab.

return plots showing:
-   RNA_FILTER distribution as bar plot colored by BEST_RESPONSE
-   RNA_TOTAL vs PATIENT_ID colored by BEST_RESPONSE and split by RNA_FITLER
-   Sequencing date relative to treatment start vs PATIENT_ID, shape by RNA_FILTER, colored by BEST_RESPONSE and assigned lower opacity to Pre-treatment samples to help distinguish from Post-treatment samples close to the treatment start. Treatment start and second treatment shown as vertical lines and progression date as a star.
-   RNA_FILTER distribution of Pre-treatment RNA-Seq samples as bar plot colored by BEST_RESPONSE

## Cancer type analysis
**Snakefile_read_batches**

Edit config_batches file paths to change input and output folders. Snakemake pipeline is run by qsub of below script with resources; walltime=10.00.00, mem=10GB, nodes=1:ppn=40
``` bash
module load snakemake/7.25.0
snakemake -s /ngc/projects/gm_ext/hblpet/scripts/RNA_DNA_merge/production_run/Snakefile_read_batches -j 40 -k -p
```

**summarize_batches_results.sh**

When the snakemake pipeline has finished, concatenate all the result files, like in summarize_results.sh.

Run script with command:
``` bash
qsub summarize_batches_results.sh
```
After concatenation, output file all_patient_RNA_support_diag.tab is saved and used as input file for overview_diagnosis.R:

overview_diagnosis.R
-   Create a summarizing table per PidGn with total SNV, number of SNVs in RNA_PASS and number of SNVs in RNA_PASS+RNA_NOPASS. From these meterics the percentage of variants in RNA_PASS and RNA_PASS+RNA_NOPASS is calculated. Data are saved as an RDS object as Percent_overview.RDS.

diagnosis_investigation.R
-   Reads in Percent_overview.RDS and create a scatter plot showing the number of SNV with RNA expression of alternative variant (RNA_PASS+RNA_NOPASS) versus total DNA SNV.
-   Perform t-test for each cancer type against the remaining, to test if there are differences between the cancer types’ tendencies to express their SNV in RNA. Table with results are saved as t_test_diagnosis.txt and significant cancer types are plotted in boxplots to show distribution of RNA SNV expression.






