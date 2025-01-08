#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

library('tidyverse')
library('ggforce')
library('scales')
df <- data.frame(read.delim(args[1], sep = "\t"))
PATH <- args[2]

Percentage_calculation <- df %>%
  mutate(
    RNA_FILTER = str_extract(FILTER, "RNA_[\\w]+"),   # Extract the pattern ";RNA_" followed by characters
    RNA_FILTER = str_replace_na(RNA_FILTER)
  ) %>%
  group_by(PATIENT_ID, DIAGNOSIS, RNA_FILTER) %>%
  summarise(variant_count = n()) %>%
  summarise(
    total_count = sum(variant_count),
    pass_count = sum(variant_count[RNA_FILTER == "RNA_PASS"]),
    pass_nopass_count = sum(variant_count[RNA_FILTER %in% c("RNA_PASS", "RNA_NOPASS")])
  ) %>%
  mutate(
    RNA_PASS = (pass_count / pass_nopass_count)*100,
    RNA_ALT_COVERAGE = (pass_nopass_count / total_count)*100
  )

saveRDS(Percentage_calculation, file = paste(PATH,"/Percent_overview.RDS", sep=""))
