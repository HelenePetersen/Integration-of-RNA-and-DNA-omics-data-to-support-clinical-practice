#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

library('tidyverse')
library('ggforce')
library('scales')
library('gridExtra')
library('patchwork')

# Read in data
Percentage_calculation <- readRDS(args[1])
PATH <- args[2]

# Transform data for easier plotting
plot_percent_data <- Percentage_calculation %>%
  pivot_longer(cols = c(RNA_PASS, RNA_ALT_COVERAGE),
               names_to = "Type",
               values_to = "Percent")

plot_count_data <- Percentage_calculation %>%
  pivot_longer(cols = c(pass_count, pass_nopass_count),
               names_to = "Type",
               values_to = "count")

# Scatter plot of number of SNV with RNA expression of ALT versus total SNV 
plot_scatter <- ggplot(data = plot_percent_data,
                       mapping = aes(x = pass_nopass_count,
                                     y = total_count,
                                     )) +
  geom_point() +
  labs(title = "Correlation between total SNV from DNA and number of SNV with RNA\n expression of ALT") +
  xlab("RNA_NOPASS + RNA_PASS variants [count]") +
  ylab("Total SNV from DNA per patient [count]")
ggsave(paste(PATH,"/Scatter_total_vs_pass_nopass",".pdf",sep=""), plot = plot_scatter, width = 18, height = 9, units = "cm")

########################################################################
# Investigated if there are differences between the cancer types’ tendencies to express their variants in RNA

# Initialize a results data frame
results <- data.frame(DIAGNOSIS = character(),
                      t_stat = numeric(),
                      p_val = numeric(),
                      stringsAsFactors = FALSE)

# Get unique cancer diagnoses with at least two samples (otherwise will t.test fail)
count_diagnosis <- Percentage_calculation %>%
  group_by(DIAGNOSIS) %>%
  summarise(num = n()) %>%
  filter(num > 1)
  
cancer_types <- count_diagnosis$DIAGNOSIS

# Perform t-tests for each cancer type
for (cancer_type in cancer_types) {
  # Subset the data
  group <- Percentage_calculation[Percentage_calculation$DIAGNOSIS == cancer_type, "RNA_ALT_COVERAGE"]
  others <- Percentage_calculation[Percentage_calculation$DIAGNOSIS != cancer_type, "RNA_ALT_COVERAGE"]
  
  # Perform the t-test
  t_test <- t.test(group, others)
  
  # Store results
  results <- rbind(results, data.frame(
    DIAGNOSIS = cancer_type,
    t_stat = t_test$statistic,
    p_val = t_test$p.value
  ))
}

# save results in a comma-separated table
write_delim(results, delim = ",", file = paste(PATH,"/t_test_diagnosis.txt",sep=""))

# create box plot for significant cancers found from t-test
significant_cancers <- c("Prostate cancer", "Melanoma", "Ovarian cancer", "Esophageal cancer", "Appendiceal cancer", "Biliary tract cancer", "Peritoneal cancer", "NUT carcinoma" )
plotlist = list()
num_plot <- 1
for (cancer_type in significant_cancers) {
  
  df_in <- Percentage_calculation %>% filter(DIAGNOSIS != cancer_type) %>% mutate(Cancer = paste ("All Cancers except", cancer_type))
  
  plotlist[[num_plot]] <- ggplot(data = df_in, mapping = aes(x = Cancer, y = RNA_ALT_COVERAGE)) +
    geom_boxplot() +
    geom_boxplot(data = Percentage_calculation %>% filter(DIAGNOSIS == cancer_type ),
                 aes(x = DIAGNOSIS, y = RNA_ALT_COVERAGE)) +
    scale_x_discrete(labels = label_wrap(22)) + 
    ylab("RNA_NOPASS + RNA_PASS\nOut of TOTAL_RNA ") +
    scale_y_continuous(labels = function(x) paste0(x, "%"))
  
  num_plot <- num_plot + 1
}

boxplot1 <- (plotlist[[1]] | plotlist[[2]]) / (plotlist[[3]] | plotlist[[4]])
boxplot2 <- (plotlist[[5]] | plotlist[[6]]) / (plotlist[[7]] | plotlist[[8]])
ggsave(paste(PATH,"/Boxplot_all_vs_significant1",".pdf",sep=""), plot = boxplot1, width = 20, height = 15, units = "cm")
ggsave(paste(PATH,"/Boxplot_all_vs_significant2",".pdf",sep=""), plot = boxplot2, width = 20, height = 15, units = "cm")

