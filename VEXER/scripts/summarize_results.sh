#!/bin/bash
#PBS -W group_list=gm_ext
#PBS -A gm_ext
#PBS -j oe
#PBS -l nodes=1:ppn=40
#PBS -l mem=160g
#PBS -l walltime=5:00:00

module load htslib/1.16
module load gcc/9.4.0 intel/perflibs/2020_update4 tools R/4.4.0

INDIR=/path/to/output/directory/combined_analysis_all_BRAF
SCRIPTDIR=/path/to/VEXER/scripts/plotting
METADATA=/path/to/VEXER/metadata

# Change parameter if plots should not be created.
TEST_DATASET=true

########################################################
# Output file for concatenated data
concat_out="all_patient_RNA_support.tab"

# Get a list of all the files
files=($INDIR/*/*_mpileup_support_ID_RNA_FILTER.tab.gz)

# Flag to track if we're processing the first file
first_file=true

# Loop through each file for concatenation
for file in "${files[@]}"; do
    if $first_file; then
        # Copy the entire first file including the header
        less "$file" > "$INDIR/$concat_out"
        first_file=false
    else
        # Skip the first line (header) and append the rest of the file
        less "$file" |tail -n +2  >> "$INDIR/$concat_out"
    fi
done

# Repeat for filtered output files.
concat_filt_out="all_patient_RNA_support_filt.tab"
files_filt=($INDIR/*/*_mpileup_RNAsupport.tab.gz)

first_file=true

for file in "${files_filt[@]}"; do
    if $first_file; then
        less "$file" > "$INDIR/$concat_filt_out"
        first_file=false
    else
        less "$file" |tail -n +2  >> "$INDIR/$concat_filt_out"
    fi
done

#####################################################################
# Add cancer diagnosis to concatenated files

Cancer_table=$METADATA/"Fase1_groundtruth_2024-10-07.tsv"
Cancer_diagnosis="/path/to/VEXER/metadata/diagnosis.txt"

concat_out_diagnosis=$INDIR/all_patient_RNA_support_diag.tab
concat_filt_out_diagnosis=$INDIR/all_patient_RNA_support_filt_diag.tab
concat_min_support=$INDIR/all_patient_RNA_min_support_diag.tab

awk -F'\t' '{print $1 "\t" $4}' $Cancer_table | uniq > $Cancer_diagnosis

#NR==FNR: This condition is true only while reading the first file (Cancer_table).
#diagnosis[$1] = $2; next: Stores the Diagnosis with patient_ID as the key, skips to the next line.
#$12 = diagnosis[$11]: Sets column 12 to the Diagnosis that corresponds to the patient_ID found in column 11.

awk -F'\t' 'BEGIN {print "#CHROM" "\t" "POS" "\t" "REF" "\t" "ALT" "\t" "RNA_TOTAL" "\t" "RNA_ALT_COUNT" "\t" "PERCENTAGE" "\t" "QUALITY_SUPPORT_AVG" "\t" "FILTER" "\t" "GENEID" "\t" "PATIENT_ID" "\t" "DIAGNOSIS"}
     NR==FNR { diagnosis[$1] = $2; next } FNR > 1 { $12 = diagnosis[$11]; print }' OFS='\t' $Cancer_diagnosis $INDIR/$concat_out > $concat_out_diagnosis
     
# Subset to only contain variants with at least 1 read support to the alternative allele.
awk '$6 >= 1' $concat_out_diagnosis > $concat_min_support

bgzip --force $INDIR/$concat_out
bgzip --force $INDIR/$concat_filt_out
bgzip --force $concat_out_diagnosis
bgzip --force $concat_filt_out_diagnosis
bgzip --force $concat_min_support

Rscript $SCRIPTDIR/diagnosis_investigation.R $concat_out_diagnosis.gz $INDIR

#####################################################################
if $TEST_DATASET; then
    # Sinaplot of distribution of variants in FITLER categories
    Rscript $SCRIPTDIR/numVariantsPerEvidence.R $INDIR/$concat_out.gz All $INDIR

    Rscript $SCRIPTDIR/numVariantsPerEvidence.R $INDIR/$concat_filt_out.gz Filt $INDIR

    ######################################################################
    # Plot of summed variants when changing the filtering threshold
    # Return slope calculations and decided threshold
    Rscript $SCRIPTDIR/numVariantsPerThreshold.R $INDIR/$concat_out.gz $INDIR

    ######################################################################
    # Sinaplot and create list of clinically relevant genes present per patient
    Clinical_geneID=$METADATA/fase1_cancer_genes_87.txt
    Rscript $SCRIPTDIR/sina_clin_per_patient.R $concat_min_support.gz $Clinical_geneID min $INDIR
    Rscript $SCRIPTDIR/sina_clin_per_patient.R $INDIR/$concat_filt_out.gz $Clinical_geneID filt $INDIR

fi
