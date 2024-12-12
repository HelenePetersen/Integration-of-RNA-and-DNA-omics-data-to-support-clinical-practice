#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

library('tidyverse')
library('ggforce')
df <- data.frame(read.delim(args[1], sep = "\t"))
suffix <- args[2]
PATH <- args[3]

# Define function to count the number of variants per patient and plot separated on FILTER evidence.
variants_per_patient <- function(df){
  
  # Count the number of rows per patient
  variant_count <- df %>%
    group_by(PATIENT_ID, FILTER) %>%
    summarise(variant_count = n())
  
  plot <- ggplot(data = variant_count,
         mapping = aes(x = FILTER,
                       y = variant_count)) +
  geom_sina() +
  labs(title = "Variant count per patient divided into evidence categories") +
  xlab("Category") +
  ylab("Variant count") +
  scale_y_continuous(trans='log10') +
  theme(axis.text.x = element_text(angle = 90))
  
  return(plot)
}

plot1 <- variants_per_patient(df)
ggsave(paste(PATH,"/VariantsPerEvidence",suffix,".pdf",sep=""), plot = plot1)#, width = 28, height = 17, units = "cm")
