#!/bin/bash

module purge
module load anaconda2/4.4.0
module load tools
module load perl/5.20.1
module load hap.py/0.3.10
module load bcftools/1.16
module load htslib/1.16


TRUE_VCF=$1
TRUE_VCF_NORM=$2
TEST=$3
REF=$4
OUT=$5
OUTDIR=$6
TEST_NORM=$7

som.py $TRUE_VCF $TEST --quiet -r $REF -P -N -o $OUT
bcftools norm -f $REF $TEST -o ${OUT}_$TEST_NORM
bgzip ${OUT}_$TEST_NORM
bcftools index -t ${OUT}_${TEST_NORM}.gz -f -o ${OUT}_${TEST_NORM}.gz.tbi
bcftools isec -p $OUTDIR $TRUE_VCF_NORM ${OUT}_${TEST_NORM}.gz