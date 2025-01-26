#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
library('tidyverse')
library('ggforce')
data <- read.csv(args[1], sep = ",")
PATH <- args[2]

outname <- args[3]
variant_caller <- args[4]

# Create recall performance plot
sub <- data.frame(Type = data$type, Recall = data$recall, Precision = data$precision)
df_Stat <- sub |> pivot_longer(cols=Recall,
                     names_to = "Statistic",
                     values_to = "Value")
                     
level_order <- c('indels','MNPs', 'SNVs','records')
sina <- ggplot(data = df_Stat,
                   mapping = aes(x = Type,
                                 y = Value)) +
  geom_sina(aes(x = factor(Type, level = level_order))) +
  labs(title = paste("Recall pr. variant type called with", variant_caller, sep=" ")) +
  ylim(0,1)
ggsave(paste(PATH,outname,sep="/"), plot = sina, width = 10, height = 10, units = "cm")
