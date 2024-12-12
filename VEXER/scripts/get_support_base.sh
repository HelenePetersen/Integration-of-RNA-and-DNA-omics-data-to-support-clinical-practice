#!/bin/bash
#PBS -W group_list=gm_ext
#PBS -A gm_ext
#PBS -j oe
#PBS -l nodes=1:ppn=40
#PBS -l mem=160g
#PBS -l walltime=1:00:00

# Define input files from commandline
ChrPosRefAlt=$1
mpileup_count_tab=$2
cleaned_bases=$3
OUT=$4

# Clean up the mpileup_count_tab by removing globally ("g") everything from the read base pileup column except the bases and unknown bases (N and n)
# if the only registered read base is a deleted base compared to reference (*) the column 5 will be replaced by a tab to keep the correct separation.
awk '{ $5 = gensub(/[^ACTGNactgn]/, "", "g", $5); print }' OFS='\t' $mpileup_count_tab > $cleaned_bases

# Print Header
#NR == FNR; when total number of lines read so far accross all files == number of lines read in the currect file.
#When NR == FNR the first file are read and key value pairs are saved from the ChrPosRefAlt file.
# When reading the second file check each base from the cleaned pileup if it matches the recorded alternativ base, if then record the position

awk -F'\t' 'BEGIN {print "#CHROM" "\t" "POS" "\t" "RNA_TOTAL" "\t" "BASES" "\t" "Base_quality" "\t" "RNA_support_reads"}
     NR==FNR {key[$1,$2]=$4; ref[$1,$2]=$3; next}
     ($1,$2) in key {
         total=$4;
         bases=$5;
         quality=$6
         match_positions = "";
         for (i = 1; i <= length(bases); i++) {
            base = substr(bases, i, 1);  # Get the base at position i
            if (toupper(base) == toupper(key[$1,$2])) {
                    if (match_positions == ""){
                        match_positions = i
                    }
                    else{
                        match_positions = match_positions "," i;  # Record the position
                    }
            }
        }
         print $1 "\t" $2 "\t" total "\t" bases "\t" quality "\t" match_positions;
     }' $ChrPosRefAlt $cleaned_bases > $OUT
