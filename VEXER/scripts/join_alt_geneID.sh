#!/bin/bash
#PBS -W group_list=gm_ext
#PBS -A gm_ext
#PBS -j oe
#PBS -l nodes=1:ppn=40
#PBS -l mem=160g
#PBS -l walltime=1:00:00

# Define input files from commandline
ChrPosRefAlt=$1
GeneId=$2
OUT=$3

#NR == FNR; when total number of lines read so far accross all files == number of lines read in the currect file.
#When NR == FNR the first file are read and key value pairs are saved from the ChrPosRefAlt file.
# When reading the second file check if the [CHROM, POS] key is present, then print lines with CHROM, POS, REF, ALT, FILTER, GeneID information.

awk -F'\t' 'NR==FNR {key[$1,$2]=$4; ref[$1,$2]=$3; filter[$1,$2]=$5; next}
     ($1,$2) in key {
         GeneID=$5;
         print $1 "\t" $2 "\t" ref[$1,$2] "\t" key[$1,$2] "\t" filter[$1,$2] "\t" GeneID;
     }' $ChrPosRefAlt $GeneId > $OUT
