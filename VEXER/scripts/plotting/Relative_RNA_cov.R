#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

library('tidyverse')
library('ggforce')

df_somatic <- data.frame(read.delim(args[1], sep = "\t", header = FALSE))
df_germline <- data.frame(read.delim(args[2], sep = "\t", header = FALSE))
PATH <- args[3]
clinical_genes_list <- read.table(args[4], sep="", header = TRUE)

colnames(df_somatic) <- c('Gene', 'Patient', 'Somatic_RNA_avg')
colnames(df_germline) <- c('Gene', 'Patient', 'Germline_RNA_avg')

df_relative <- inner_join(df_somatic, df_germline) %>%
  mutate(relative_avg = Somatic_RNA_avg/Germline_RNA_avg)

# Check which genes are in the clinical gene list and filter for these rows
df <- mutate(df_relative, Clinical_Gene = if_else(Gene %in% clinical_genes_list$gene, TRUE, FALSE))
df_clin <- filter(df, Clinical_Gene == TRUE)

# Create plots
RNA_avg <- ggplot(data = df_clin,
                  mapping = aes(x = Gene,
                                y = relative_avg)) +
  geom_sina(shape = ".") +
  scale_y_continuous(trans='log10') +
  labs(title = "Average RNA coverage for Somatic relative to germline SNVs across clinical genes and BRAF") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=0.5, size = 5))
ggsave(paste(PATH,"/Relative_RNA_avg.pdf",sep=""), plot = RNA_avg, width = 30, height = 15, units = "cm")

RNA_avg_all <- ggplot(data = df,
                      mapping = aes(x = Gene,
                                    y = relative_avg)) +
  geom_sina(shape = ".") +
  scale_y_continuous(trans='log10') +
  labs(title = "Average RNA coverage for Somatic relative to germline SNVs across all genes") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=0.5, size = 5))
ggsave(paste(PATH,"/Relative_RNA_avg_allgenes.pdf",sep=""), plot = RNA_avg_all, width = 30, height = 15, units = "cm")
