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
OUT=$3

# Print Header
#NR == FNR; when total number of lines read so far accross all files == number of lines read in the currect file.
#When NR == FNR the first file are read and key value pairs are saved from the ChrPosRefAlt file.
# When reading the second file check if the [CHROM, POS] key is present, then get total RNA reads and average phred quality.
# If total is not zero and phred_quality is a numeric value count the support of the alternative alle and calculate the percentage support,
# else report support and percentage as zero

awk -F'\t' 'BEGIN {print "#CHROM" "\t" "POS" "\t" "REF" "\t" "ALT" "\t" "RNA_TOTAL" "\t" "RNA_ALT_COUNT" "\t" "PERCENTAGE" "\t" "QUALITY_SUPPORT_AVG" "\t" "FILTER" "\t" "GENEID"}
     NR==FNR {key[$1,$2]=$4; ref[$1,$2]=$3; filter[$1,$2]=$5; GeneID[$1,$2]=$6; next}
     ($1,$2) in key {
         total=$3;
         Phred_quality=$4;
         if (total != 0) {if (Phred_quality ~ /^[0-9]+$/) {
            support=0;
            for (i=6; i<=NF; i+=2) {
                if ($i == key[$1,$2]) {
                    support=$(i-1);
                    break;
                }
            }
            percentage = (support / total)*100;}
            else {
                support = 0;
                percentage = 0;}}
         
         print $1 "\t" $2 "\t" ref[$1,$2] "\t" key[$1,$2] "\t" total "\t" support "\t" percentage "\t" Phred_quality "\t" filter[$1,$2] "\t" GeneID[$1,$2];
     }' $ChrPosRefAlt $mpileup_count_tab > $OUT
