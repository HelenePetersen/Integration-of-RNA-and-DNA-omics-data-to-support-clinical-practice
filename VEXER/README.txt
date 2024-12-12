#Run script using
snakemake -s Snakefile --profile /ngc/projects/gm_ext/hblpet/scripts/Mutect_IMAPR_pipeline/pbs-default -j 4 --cores 10 -k -p

###
Follow build_reference.sh script from https://github.com/wang-lab/IMAPR/blob/main/build_reference.sh
To use GM reference for hisat2 realignment run the following commands:

module load java/1.8.0 picard-tools/2.25.2
java -jar $PICARD CreateSequenceDictionary -R /ngc/shared/resources/h.sapiens/hg38/genomes/GCA_000001405.15_GRCh38_no_alt_analysis_set/20210411/GCA_000001405.15_GRCh38_no_alt_analysis_set_maskedGRC_exclusions.fasta -O GRCh38_no_alt.dict

module load anaconda2/4.4.0 hisat2/2.2.0
hisat2-build -p 8 /ngc/shared/resources/h.sapiens/hg38/genomes/GCA_000001405.15_GRCh38_no_alt_analysis_set/20210411/GCA_000001405.15_GRCh38_no_alt_analysis_set_maskedGRC_exclusions.fasta hisat2_GRCh38_no_alt
