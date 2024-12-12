#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
library('tidyverse')
df <- data.frame(read.delim(args[1], sep = "\t"))
PATH <- args[2]

# Create function to find the total variants at different thresholds per patient
quality_threshold <- function(df, quality_metric, Threshold_range){
  results <- list()
  for (Threshold in Threshold_range) {
    filtered_df <- df %>%
      filter({{quality_metric}} >= Threshold) # use {{}} to access the variable passed from the function input
    
    # Count the number of rows per patient
    Variant_Count <- filtered_df %>%
      group_by(PATIENT_ID) %>%
      summarise(Variant_Count = n()) %>%
      mutate(Threshold = Threshold)

    results[[as.character(Threshold)]] <- Variant_Count
  }
  # Combine the results into one dataframe
  final_results <- bind_rows(results)
  
  # Reorder the columns to have 'Threshold', 'PATIENT_ID', and 'Variant_Count'
  final_results <- final_results %>%
    select(Threshold, PATIENT_ID, Variant_Count)
  
  return(final_results)
}

######################################################
# Apply function at the different quality metrics
q_RNA_TOTAL <- quality_threshold(df = df, quality_metric = RNA_TOTAL, seq(0, 25, by = 1))
q_RNA_ALT_COUNT <- quality_threshold(df = df, quality_metric = RNA_ALT_COUNT, seq(1, 20, by = 1))
q_PERCENTAGE <- quality_threshold(df = df, quality_metric = PERCENTAGE, seq(1e-300, 25, by = 1))
q_QUALITY_SUPPORT_AVG <- quality_threshold(df = df, quality_metric = QUALITY_SUPPORT_AVG, seq(0, 30, by = 5))

# Create scatter plots
scatter_q_RNA_TOTAL <- ggplot(data = q_RNA_TOTAL,
                    mapping = aes(x = Threshold,
                                  y = Variant_Count)) +
  geom_point(shape = ".") +
  facet_wrap(~PATIENT_ID, scales = "free") +
  labs(title = "Total variants after filtering total number of RNA reads") +
  theme(strip.text.x = element_blank())

ggsave(paste(PATH,"/scatter_q_RNA_TOTAL.pdf",sep=""), plot = scatter_q_RNA_TOTAL, width = 30, height = 15, units = "cm")

scatter_q_RNA_ALT_COUNT <- ggplot(data = q_RNA_ALT_COUNT,
                    mapping = aes(x = Threshold,
                                  y = Variant_Count)) +
  geom_point(shape = ".") +
  facet_wrap(~PATIENT_ID, scales = "free") +
  labs(title = "Total variants after filtering counts of the alternative allele") +
  theme(strip.text.x = element_blank())

ggsave(paste(PATH,"/scatter_q_RNA_ALT_COUNT.pdf",sep=""), plot = scatter_q_RNA_ALT_COUNT, width = 30, height = 15, units = "cm")

scatter_q_PERCENTAGE <- ggplot(data = q_PERCENTAGE,
                    mapping = aes(x = Threshold,
                                  y = Variant_Count)) +
  geom_point(shape = ".") +
  facet_wrap(~PATIENT_ID, scales = "free") +
  labs(title = "Total variants after filtering percentage of support") +
  theme(strip.text.x = element_blank())

ggsave(paste(PATH,"/scatter_q_PERCENTAGE.pdf",sep=""), plot = scatter_q_PERCENTAGE, width = 30, height = 15, units = "cm")

scatter_q_QUALITY_SUPPORT_AVG <- ggplot(data = q_QUALITY_SUPPORT_AVG,
                    mapping = aes(x = Threshold,
                                  y = Variant_Count)) +
  geom_point(shape = ".") +
  facet_wrap(~PATIENT_ID, scales = "free") +
  labs(title = "Total variants after filtering average phred score for supporting reads") +
  theme(strip.text.x = element_blank())

ggsave(paste(PATH,"/scatter_q_QUALITY_SUPPORT_AVG.pdf",sep=""), plot = scatter_q_QUALITY_SUPPORT_AVG, width = 30, height = 15, units = "cm")

######################################################
# Calculate slope to determine threshold
calculate_slope <- function(df){
  slope_df <- df %>%
    arrange(PATIENT_ID, Threshold) %>%                    # Sort by PATIENT_ID and cutoff
    group_by(PATIENT_ID) %>%                              
    mutate(
      slope = (Variant_Count - lag(Variant_Count)) /      # Calculate slope for each pair
        (Threshold - lag(Threshold))
    ) %>%
    ungroup()
  return(slope_df)
}

get_threshold_45deg <- function(df, max_x){
  # Estimate what slope appear as a 45degree differential quotient.
  yscale <- df %>% 
    group_by(PATIENT_ID) %>%
    summarise(max_y = max(Variant_Count)) %>%
    mutate(slope_45deg = -(max_y/max_x)) %>%
    ungroup()
  
  # Join the information about the estimated slope to give a 45 degree differential quotient
  # with the cutoff and calculated slope
  result <- df %>%
    inner_join(yscale, by = "PATIENT_ID") %>%
    filter(Threshold > 1) %>%
    mutate(diff = abs(slope - slope_45deg)) %>%
    group_by(PATIENT_ID) %>%
    filter(diff == min(diff)) %>%
    ungroup() %>%
    select(PATIENT_ID, Threshold, slope, slope_45deg)
  
  return(result)
}

# Get threshold for RNA_TOTAL and RNA_ALT_COUNT
slope_RNA_TOTAL <- calculate_slope(q_RNA_TOTAL) %>%
			get_threshold_45deg(25) %>%
			data.frame()
write_delim(slope_RNA_TOTAL, file = paste(PATH,"/slope_RNA_TOTAL.txt", sep=""), delim = "\t")

slope_RNA_ALT_COUNT <- calculate_slope(q_RNA_ALT_COUNT) %>%
			get_threshold_45deg(20) %>%
			data.frame()
write_delim(slope_RNA_ALT_COUNT, file = paste(PATH,"/slope_RNA_ALT_COUNT.txt", sep=""), delim = "\t")

# Report thresholds
write(paste("Threshold for total RNA reads \t", median(slope_RNA_TOTAL$Threshold),
        "\nThreshold for reads support alternative allele \t", median(slope_RNA_ALT_COUNT$Threshold), sep=""),
file = paste(PATH,"/Thresholds.txt", sep=""))
