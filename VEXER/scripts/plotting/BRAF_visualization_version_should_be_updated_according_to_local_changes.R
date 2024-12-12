#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

library('tidyverse')
library('ggforce')

df <- data.frame(read.delim(args[1], sep = "\t"))
target <-data.frame(read.delim(args[2], sep = "\t"))
PATH <- args[3]

df_RNA_FILTER <- df %>% 
  mutate(
    RNA_FILTER = str_extract(FILTER, "RNA_[\\w]+"),   # Extract the pattern ";RNA_" followed by characters
    RNA_FILTER = str_replace_na(RNA_FILTER, replacement = "NO_RNA_Coverage")
  )
# define factor levels
df_RNA_FILTER$BEST_RESPONSE <- factor(df_RNA_FILTER$BEST_RESPONSE, levels = c("non evaluable","progression disease" ,"partial response", "stable disease"))

#Edit the PATIENT_ID column so it can be matched with the patient information in the target dataframe
df_RNA_FILTER$PatientID_Glass <- df_RNA_FILTER$PATIENT_ID
df_RNA_FILTER$PATIENT_ID <- sub("-.*", "", df_RNA_FILTER$PATIENT_ID)

target_pos <- inner_join(df_RNA_FILTER,target, by = c("PATIENT_ID", "POS"))

target_pos_counts <- target_pos %>%
  count(RNA_FILTER, BEST_RESPONSE, name = "Count") %>%
  # Count the missing combinations of RNA_FILTER and BEST_RESPONSE as zero.
  complete(RNA_FILTER, BEST_RESPONSE, fill = list(Count = 0))

write.table(target_pos, file=paste(PATH,"/patient_with_targets.txt",sep=""))

# Create barplot
geom_bar_targets <- ggplot(data = target_pos_counts,
                              mapping = aes(x = RNA_FILTER, y = Count, fill = BEST_RESPONSE)) +
  geom_bar(stat = "identity", position = position_dodge(), color = "black") +
  scale_fill_manual(values = c("non evaluable" = "blue","progression disease" = "red", "partial response" = "yellow" , "stable disease" = "green")) +
  labs(title = "Counting and categorizing targeted variants")

ggsave(paste(PATH,"/geom_bar_targets.pdf", sep=""), plot = geom_bar_targets)

# Create plot split by RNA_FILTER
RNA_FILTER_wrap <- ggplot(data = target_pos,
       mapping = aes(y = PATIENT_ID, x = RNA_TOTAL, color = BEST_RESPONSE)) +
  geom_point(size = 4) +
  theme(axis.text.y = element_blank()) +
  scale_color_manual(values = c("non evaluable" = "blue","progression disease" = "red", "partial response" = "yellow" , "stable disease" = "green")) +
  labs(title = "Total RNA reads and percentage of reads supporting the alternative allele") +
  geom_text(aes(label = str_c(round(PERCENTAGE,0), "%")), hjust = -0.4, color = "black") +
  scale_x_continuous(breaks = seq(1, 22, by = 2), limits = c(0,22)) +
  facet_wrap(~RNA_FILTER, ncol = 4)

ggsave(paste(PATH,"/geom_scatter_RNA_FILTER_wrap.pdf",sep=""), plot = RNA_FILTER_wrap, width = 30, height = 15, units = "cm")
