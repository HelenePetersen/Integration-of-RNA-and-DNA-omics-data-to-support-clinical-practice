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
    coverage_count = sum(variant_count[RNA_FILTER %in% c("RNA_PASS", "RNA_NOPASS")])
  ) %>%
  mutate(
    RNA_PASS = (pass_count / coverage_count)*100,
    RNA_ALT_COVERAGE = (coverage_count / total_count)*100
  ) #%>%
  #select(PATIENT_ID, DIAGNOSIS, RNA_PASS, RNA_ALT_COVERAGE)

# Transform data for easier plotting
plot_percent_data <- Percentage_calculation %>%
  pivot_longer(cols = c(RNA_PASS, RNA_ALT_COVERAGE),
               names_to = "Type",
               values_to = "Percent")

plot_count_data <- Percentage_calculation %>%
  pivot_longer(cols = c(pass_count, coverage_count),
               names_to = "Type",
               values_to = "count")

# Create percentage plot
plot1 <- ggplot(data = plot_percent_data,
                              mapping = aes(x = DIAGNOSIS,
                                            y = Percent, color = total_count)) +
  scale_colour_gradient(low = "yellow", high = "red") +
  geom_sina() +
  labs(title = "Distribution of identified RNA patient variants") +
  xlab("Cancer diagnosis") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=0.5)) +
  scale_x_discrete(labels = label_wrap(30)) +
  facet_wrap(~Type)
ggsave(paste(PATH,"/Variants_Percent_PerDiagnosis",".pdf",sep=""), plot = plot1, width = 20, height = 15, units = "cm")

# Create count plot
plot2 <- ggplot(data = plot_count_data,
       mapping = aes(x = DIAGNOSIS,
                     y = count, color = total_count)) +
  scale_colour_gradient(low = "yellow", high = "red") +
  geom_sina() +
  labs(title = "Distribution of identified RNA patient variants") +
  xlab("Cancer diagnosis") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=0.5)) +
  scale_x_discrete(labels = label_wrap(30)) +
  facet_wrap(~Type, scales = "free")
ggsave(paste(PATH,"/Variants_Count_PerDiagnosis_free",".pdf",sep=""), plot = plot2, width = 20, height = 15, units = "cm")

library(gridExtra)
Table_count <- Percentage_calculation %>% select(DIAGNOSIS, total_count, pass_count, coverage_count) %>% data.frame()

pdf(file = paste(PATH, "/diagnosis_table_count.pdf", sep=""), height=20, width=18)
grid.table(Table_count)
dev.off()
