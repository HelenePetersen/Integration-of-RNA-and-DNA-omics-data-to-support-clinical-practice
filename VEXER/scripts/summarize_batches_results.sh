#!/bin/bash
#PBS -W group_list=gm_ext
#PBS -A gm_ext
#PBS -j oe
#PBS -l nodes=1:ppn=40
#PBS -l mem=160g
#PBS -l walltime=5:00:00

## This summarize results take all the samples from the production run

module load htslib/1.16
module load gcc/9.4.0 intel/perflibs/2020_update4 tools R/4.4.0

INDIR=/path/to/output/directory/results/snv_VEXER
OUTDIR=/path/to/output/directory/results
SCRIPTDIR=/path/to/VEXER/scripts/plotting
METADATA=/path/to/VEXER/metadata

# Change parameter if plots should not be created.
TEST_DATASET=false
########################################################
# Output file for concatenated data
concat_out="all_patient_RNA_support.tab"

# Get a list of all the files
files=($INDIR/*-Tumor_Tissue_VEXER.tab.gz)

# Flag to track if we're processing the first file
first_file=true

# Loop through each file for concatenation
for file in "${files[@]}"; do
    if $first_file; then
        # Copy the entire first file including the header
        less "$file" > "$OUTDIR/$concat_out"
        first_file=false
    else
        # Skip the first line (header) and append the rest of the file
        less "$file" |tail -n +2  >> "$OUTDIR/$concat_out"
    fi
done

#####################################################################
# Add cancer diagnosis to concatenated files

Cancer_table=$METADATA/"Fase1_groundtruth_2024-10-07.tsv"
Cancer_diagnosis="/path/to/VEXER/metadata/diagnosis.txt"
concat_out_diagnosis=$OUTDIR/all_patient_RNA_support_diag.tab

awk -F'\t' '{print $1 "\t" $4}' $Cancer_table | uniq > $Cancer_diagnosis

#NR==FNR: This condition is true only while reading the first file (Cancer_table).
#diagnosis[$1] = $2; next: Stores the Diagnosis with patient_ID as the key, skips to the next line.
#$12 = diagnosis[$11]: Sets column 12 to the Diagnosis that corresponds to the patient_ID found in column 11.
awk -F'\t' 'BEGIN {print "#CHROM" "\t" "POS" "\t" "REF" "\t" "ALT" "\t" "RNA_TOTAL" "\t" "RNA_ALT_COUNT" "\t" "PERCENTAGE" "\t" "QUALITY_SUPPORT_AVG" "\t" "FILTER" "\t" "GENEID" "\t" "PATIENT_ID" "\t" "DIAGNOSIS"}
     NR==FNR { diagnosis[$1] = $2; next } FNR > 1 { split($11, arr, "-"); $12 = diagnosis[arr[1]]; print}' OFS='\t' $Cancer_diagnosis $OUTDIR/$concat_out > $concat_out_diagnosis
     
bgzip --force $OUTDIR/$concat_out
bgzip --force $concat_out_diagnosis

#Summarize result and save as RDS object
Rscript $SCRIPTDIR/overview_diagnosis.R $concat_out_diagnosis $OUTDIR

# Read in RDS object and save plot and t-test results
Rscript $SCRIPTDIR/diagnosis_investigation.R $OUTDIR/Percent_overview.RDS $OUTDIR

