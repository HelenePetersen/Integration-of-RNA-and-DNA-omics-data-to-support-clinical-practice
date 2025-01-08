#!/bin/bash

All_patients="/path/to/output/directory/combined_analysis_all_BRAF/all_patient_RNA_support_diag_status.tab.gz"
All_patients_avg="/path/to/output/directory/combined_analysis_all_BRAF/all_patient_RNA_cov_avg.tab"

less $All_patients | awk -F'\t' '{
    if (length($10) > 1 && length($11) > 9){
        key = $10 "+" $11  # Create a unique key for GENEID and PATIENT_ID
        sum[key] += $5     # Add RNA_TOTAL to the sum for this key
        count[key]++       # Count occurrences for this key
    }
}
END {
    for (key in sum) {
        split(key, arr, "+")  # Split the key back into GENEID and PATIENT_ID
        print arr[1], arr[2], sum[key] / count[key]  # Print GENEID, PATIENT_ID, and average
    }
}' OFS='\t' > $All_patients_avg
