#!/usr/bin/env python

# Formula to calculate phred_scores_avg is from https://gigabaseorgigabyte.wordpress.com/2017/06/26/averaging-basecall-quality-scores-the-right-way/

# Load libraries
import argparse
from math import log

# Define function to convert a string of ASCII characters to Phred quality scores.
def ascii_to_phred(ascii_str):
    return ord(ascii_str) - 33

# Define function to extract base qualities and calculate average quality, if the positions of the alternative allele is recorded (x number of columns) and if the variant is as SNP.
def process_mpileup(file_path):
    with open(file_path, 'r') as file:
        next(file)  # Skip the first line 
        for line in file:
            columns = line.strip().split('\t')
            # only if we have x number of columns get the base quality and if the base is a single nucleotide (length of bases == total reads)
            if (len(columns) > 5) and (len(columns[3]) == int(columns[2])):
                phred_scores = list()
                base_quality_support = columns[5].split(',')
                base_quality = [x for x in columns[4]]
                # Covert ascii to phred quality
                for quality in base_quality_support:
                    phred_scores.append(ascii_to_phred(base_quality[int(quality)-1]))
                # Calculate average for phred scores
                phred_scores_avg = round(-10 * log(sum([10**(q / -10) for q in phred_scores]) / len(phred_scores), 10))
            else:
                phred_scores_avg = ''
            print(columns[0], columns[1], columns[2], columns[3], phred_scores_avg, sep="\t")

if __name__ == "__main__":
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Convert ASCII base qualities to Phred scores.")
    parser.add_argument('input_file', help="Path to the mpileup input file")
    
    # Get the file path from command line arguments
    args = parser.parse_args()
    
    # Call the process function with the provided file path
    process_mpileup(args.input_file)
