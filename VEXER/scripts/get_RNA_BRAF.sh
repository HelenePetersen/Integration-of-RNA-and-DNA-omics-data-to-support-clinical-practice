#!/bin/bash
#PBS -W group_list=gm_ext
#PBS -A gm_ext
#PBS -j oe
#PBS -l nodes=1:ppn=40
#PBS -l mem=160g
#PBS -l walltime=2:00:00

# Load modules
module load htslib/1.16
module load gcc/9.4.0 intel/perflibs/2020_update4 tools R/4.4.0

INDIR=/path/to/output/directory/combined_analysis_all_BRAF

# Output file for concatenated data
concat_out="all_patient_RNA_chr7-140753336.tab"

# Get a list of all the files
files=($INDIR/*/*_chr7Mpileup_patientID.tab)

# Flag to track if we're processing the first file
first_file=true
# Loop through each file for concatenation
for file in "${files[@]}"; do
    if $first_file; then
        # Copy the entries of the first file
        less "$file" | grep -E '140753336' > "$INDIR/$concat_out"
        first_file=false
    else
        # append the rest of the files
        less "$file" | grep -E '140753336' >> "$INDIR/$concat_out"
    fi
done
bgzip $INDIR/$concat_out
