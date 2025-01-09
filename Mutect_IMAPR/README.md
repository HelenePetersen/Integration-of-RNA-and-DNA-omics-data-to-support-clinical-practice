#Run script using
snakemake -s Snakefile --profile /path/to/Mutect_IMAPR/pbs-default -j 4 --cores 10 -k -p

###
Follow build_reference.sh script from https://github.com/wang-lab/IMAPR/blob/main/build_reference.sh
To use GM reference for hisat2 realignment run the following commands:

module load java/1.8.0 picard-tools/2.25.2

java -jar $PICARD CreateSequenceDictionary -R /path/to/fasta_reference/file.fasta -O GRCh38_no_alt.dict

module load anaconda2/4.4.0 hisat2/2.2.0

hisat2-build -p 8 /path/to/fasta_reference/file.fasta hisat2_GRCh38_no_alt
