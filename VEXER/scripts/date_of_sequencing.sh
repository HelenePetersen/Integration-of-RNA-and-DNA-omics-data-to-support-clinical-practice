#!/bin/bash

BRAF_patients="/ngc/projects/gm_ext/hblpet/scripts/RNA_DNA_merge/metadata/BRAF_patients_glassnumber.tab"
Fase_data="/ngc/projects/gm_ext/hblpet/scripts/RNA_DNA_merge/metadata/Fase1_groundtruth_2024-10-07.tsv"
OUT="/ngc/projects/gm_ext/hblpet/scripts/RNA_DNA_merge/metadata/BRAF_sequencing_date.tab"

awk -F'\t' 'BEGIN {print "PATIENT_ID.GLASSNUMBER" "\t" "Seq_date"}
NR==FNR {lookup[$2]; next} {
    split($8, parts, "-")
    ID=parts[1] "-" parts[2]
    date=match($8, /-RNA_.*-[0-9]{6}_/)}
    {if (ID in lookup && RSTART!=0)
        {RNA_date=substr($8, RSTART+1, RLENGTH-2)
        split(RNA_date, comp, "-")
        print ID, comp[2]}}' OFS='\t' $BRAF_patients $Fase_data | uniq > $OUT

#https://www3.physnet.uni-hamburg.de/physnet/Tru64-Unix/HTML/APS32DTE/WKXXXXXX.HTM
#The length of the string matched by match(); set to -1 if no match.
#The index (position within the string) of the first character matched by match(); set to 0 if no match.
