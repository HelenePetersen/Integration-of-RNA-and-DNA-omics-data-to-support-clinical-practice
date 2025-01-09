#!/bin/bash
# Get a list of all the CSV files (assuming they are all in the INDIR directory)
INDIR=/path/to/output/directory/Mutect_IMAPR/BRAF

# Output file for Mutect concatenated data
output_file_Mutect="all_patient_Mutect2_concat.stats.csv"

csv_files=($INDIR/*/Mutect/*_comparison.stats.csv)

# Flag to track if we're processing the first file
first_file=true

# Loop through each CSV file
for csv_file in "${csv_files[@]}"; do
    if $first_file; then
        # Copy the entire first file including the header
        cat "$csv_file" > "$INDIR/$output_file_Mutect"
        first_file=false
    else
        # Skip the first line (header) and append the rest of the file
        tail -n +2 "$csv_file" >> "$INDIR/$output_file_Mutect"
    fi
done

echo "All CSV files concatenated into $output_file_Mutect"

# Output file for IMAPR concatenated data
output_file_IMAPR="all_patient_IMAPR_concat.stats.csv"

csv_files=($INDIR/*/IMAPR/*_comparison.stats.csv)

# Flag to track if we're processing the first file
first_file=true

# Loop through each CSV file
for csv_file in "${csv_files[@]}"; do
    if $first_file; then
        # Copy the entire first file including the header
        cat "$csv_file" > "$INDIR/$output_file_IMAPR"
        first_file=false
    else
        # Skip the first line (header) and append the rest of the file
        tail -n +2 "$csv_file" >> "$INDIR/$output_file_IMAPR"
    fi
done

echo "All CSV files concatenated into $output_file_IMAPR"

# Create plot for the concatenated file.
module load gcc/9.4.0 intel/perflibs/2020_update4 tools R/4.4.0
Rscript stats_plotting.R $INDIR/$output_file_Mutect $INDIR sinaplot_Mutect2.stats.pdf Mutect2
Rscript stats_plotting.R $INDIR/$output_file_IMAPR $INDIR sinaplot_IMAPR.stats.pdf IMAPR
