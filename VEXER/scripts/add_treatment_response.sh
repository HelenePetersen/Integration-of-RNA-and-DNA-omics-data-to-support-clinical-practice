#!/bin/bash

# Define input files
All_patients=/path/to/output/directory/combined_analysis_all_BRAF/all_patient_RNA_support_diag.tab
BRAF_patients=/path/to/VEXER/metadata/BRAF_patients.tab
file_out=/path/to/output/directory/combined_analysis_all_BRAF/all_patient_RNA_support_diag_status.tab
BRAF_out=/path/to/output/directory/combined_analysis_all_BRAF/BRAF_patient_RNA_support_diag_status.tab

# Load modules
module load htslib/1.16

gunzip $All_patients.gz

# Print Header
# NR == FNR; when total number of lines read so far accross all files == number of lines read in the currect file.
#When NR == FNR the first file are read and a key value pair is saved from the BRAF_patients file.
# When FNR > 1 the first line in the second file is skipped.
# The patient_ID-Glass_number is split by "-". Check if the patient_id matches those from the progression dict and extract the best_response.

awk -F'\t' 'BEGIN {print "#CHROM" "\t" "POS" "\t" "REF" "\t" "ALT" "\t" "RNA_TOTAL" "\t" "RNA_ALT_COUNT" "\t" "PERCENTAGE" "\t" "QUALITY_SUPPORT_AVG" "\t" "FILTER" "\t" "GENEID" "\t" "PATIENT_ID" "\t" "DIAGNOSIS" "\t" "BEST_RESPONSE"}
NR==FNR {progression[$1] = $8
    next}
FNR > 1 {
    split($11, arr, "-"); patient_id = arr[1];
    if (patient_id in progression) {
        status = progression[patient_id]
    } else {
        status = ""
    }
    print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, status
}' OFS='\t' $BRAF_patients $All_patients > $file_out

# Subset file to contain only patients with BRAF targeted treatment
# BRAF patient IDs have been censored
less $file_out | grep -E '#CHROM|xxxxxxxxx|xxxxxxxxx' | grep -E '#CHROM|BRAF' > $BRAF_out

bgzip --force $All_patients
bgzip --force $file_out
bgzip --force $BRAF_out
