#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

library('tidyverse')
library('ggforce')

df <- data.frame(read.delim(args[1], sep = "\t", header = FALSE))
PATH <- args[2]
selected_genes_list <- c("BRAF", "PIK3CA", "TP53")
colnames(df) <- c('Gene', 'Patient', 'RNA_avg')

# Check which genes are in the selected gene list and filter for these rows
df <- mutate(df, Selected_Genes = if_else(Gene %in% selected_genes_list, TRUE, FALSE))
df_select <- filter(df, Selected_Genes == TRUE)

# Create plot
RNA_avg <- ggplot(data = df_select,
                    mapping = aes(x = Gene,
                                  y = RNA_avg)) +
  geom_sina()+
  labs(title = "Higher somatic SNV average RNA coverage seen in TP53") +
  theme(axis.title.x = element_text(size = 12), axis.title.y = element_text(size = 12),
        axis.text.x = element_text(size = 10), axis.text.y = element_text(size = 10)) +
  scale_y_continuous(breaks = seq(0, 60, by = 10)) +
  ylab("RNA average per patient")
ggsave(paste(PATH,"/RNA_somatic_avg_selected.pdf",sep=""), plot = RNA_avg, width = 15, height = 15, units = "cm")
