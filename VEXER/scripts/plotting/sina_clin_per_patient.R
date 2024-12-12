#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# Load libraries
library('tidyverse')
library('ggrepel')
library('ggforce')

# Read in data
data <- data.frame(read.delim(args[1], sep = "\t"))
clinical_genes <- read.table(args[2], header = TRUE)
suffix <- args[3]
PATH <- args[4]
data <- mutate(data, Clinical_Gene = if_else(GENEID %in% clinical_genes$gene, TRUE, FALSE))

# Create sinaplots per quality metric
sina_clin <- ggplot(data = data,
                    mapping = aes(x = PATIENT_ID,
                                  y = PERCENTAGE)) +
	geom_sina(shape = ".") +
	labs(title = "Percentage support of the alternative allele") +
	theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=0.5)) #new
#	theme(axis.text.x = element_blank()) #old

ggsave(paste(PATH,"/sina_clin_patient_", suffix, ".pdf",sep=""), plot = sina_clin, width = 30, height = 15, units = "cm")

sina_totRNA <- ggplot(data = data,
                    mapping = aes(x = PATIENT_ID,
                                  y = RNA_TOTAL)) +
  geom_sina(shape = ".") +
  scale_y_continuous(trans='log10') +
  labs(title = "Total RNA count") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=0.5)) #new
#  theme(axis.text.x = element_blank()) #old
ggsave(paste(PATH,"/sina_totRNA_patient_", suffix, ".pdf",sep=""), plot = sina_totRNA, width = 30, height = 15, units = "cm")

sina_supportRNA <- ggplot(data = data,
                      mapping = aes(x = PATIENT_ID,
                                    y = RNA_ALT_COUNT)) +
  geom_sina(shape = ".") +
  scale_y_continuous(trans='log10') +
  labs(title = "RNA count supporting alternative allele") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=0.5)) #new
#  theme(axis.text.x = element_blank()) #old
ggsave(paste(PATH,"/sina_supportRNA_patient_", suffix, ".pdf",sep=""), plot = sina_supportRNA, width = 30, height = 15, units = "cm")

sina_qualRNA <- ggplot(data = data,
                          mapping = aes(x = PATIENT_ID,
                                        y = QUALITY_SUPPORT_AVG)) +
  geom_sina(shape = ".") +
  labs(title = "Average Phred quality score for reads supporting the alternative allele") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=0.5)) #new
#  theme(axis.text.x = element_blank()) #old
ggsave(paste(PATH,"/sina_qual_patient_", suffix, ".pdf",sep=""), plot = sina_qualRNA, width = 30, height = 15, units = "cm")

# Extract unique genes that has Clinical_Gene == True
data_clin <- filter(data, Clinical_Gene == TRUE)
result <- data_clin |>
  group_by(PATIENT_ID) |>
  summarise(GENE_LIST = paste(unique(GENEID), collapse = " ")) |>
  arrange(PATIENT_ID)

# Write results of clinically relevant genes
write_delim(result, file = paste(PATH,"/clinical_gene_overview_", suffix, ".txt",sep=""))
