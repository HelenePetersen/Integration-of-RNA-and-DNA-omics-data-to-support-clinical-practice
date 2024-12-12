#!/bin/bash

# Define input files from commandline
MIN_DEPTH=$1
MIN_ALT_SUPPORT=$2
MIN_PERC=$3
MIN_QUAL=$4
input=$5
output=$6

# Print Header
#When NR > 1 the first line is skipped.
# Check if conditions for min_depth, min_alt_support, min_perc and min_qual are satisfied and append the corret label to the FILTER column.

awk -F'\t' -v min_depth=$MIN_DEPTH -v min_alt_support=$MIN_ALT_SUPPORT -v min_perc=$MIN_PERC -v min_qual=$MIN_QUAL '
BEGIN {print "#CHROM" "\t" "POS" "\t" "REF" "\t" "ALT" "\t" "RNA_TOTAL" "\t" "RNA_ALT_COUNT" "\t" "PERCENTAGE" "\t" "QUALITY_SUPPORT_AVG" "\t" "FILTER" "\t" "GENEID" "\t" "PATIENT_ID"}
NR > 1 {
	{if ($5 >= min_depth && $6 >= min_alt_support && $7 > min_perc && $8 >= min_qual){
		$9 = $9 ";RNA_PASS"}
	else if ($5 > 0 && $6 == 0 && $7 == 0) {
		$9 = $9 ";RNA_NOALT"}
	else if ($5 == 0){
		$9 = $9}
	else {
		$9 = $9 ";RNA_NOPASS"}
	print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
	}}' OFS='\t' $input > $output