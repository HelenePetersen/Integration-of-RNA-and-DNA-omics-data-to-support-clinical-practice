library('tidyverse')
library('ggrepel')
library('ggforce')
library('patchwork')

PATH = "/path/to/VEXER/metadata/"

df_in <- data.frame(read.delim(paste(PATH,"BRAF_patients_glassnumber.tab", sep=""), sep = "\t", header = TRUE))

# join data with metadata information time of sequencing
seq_date <- data.frame(read.delim(paste(PATH,"BRAF_sequencing_date.tab", sep=""), sep = "\t", header = TRUE))
df <- full_join(df_in, seq_date, by = "PATIENT_ID.GLASSNUMBER")

df$BEST_RESPONSE <- factor(df$BEST_RESPONSE, levels = c("non evaluable", "progression disease", "stable disease" ,"partial response"))
df$RNA_FILTER <- factor(df$RNA_FILTER, levels = c("RNA_NOCOV", "RNA_NOALT" ,"RNA_NOPASS", "RNA_PASS"))

# Define treatment, progression and sequencing dates as a date
df$Treatment_start <- as.Date(df$Treatment_start, format = "%d-%m-%Y")
df$Second_treatment <- as.Date(df$Second_treatment, format = "%d-%m-%Y")
df$Date_of_Progression <- as.Date(df$Date_of_Progression, format = "%d-%m-%Y")
df$Seq_date <- as.Date(paste0("20", df$Seq_date), format = "%Y%m%d")

#####################################################################
# Create dataframe for bar plot
target_pos_counts <- df %>%
  count(RNA_FILTER, BEST_RESPONSE, name = "Count") %>%
  # Count the missing combinations of RNA_FILTER and STATUS as zero.
  complete(RNA_FILTER, BEST_RESPONSE, fill = list(Count = 0)) %>%
  remove_missing()

# Bar plot showing distribution across RNA_FILTER colored by BEST_RESPONSE
geom_bar_targets <- ggplot(data = target_pos_counts,
                           mapping = aes(x = RNA_FILTER, y = Count, fill = BEST_RESPONSE)) +
  geom_bar(stat = "identity", position = position_dodge(), color = "black") +
  scale_fill_manual(values = c("non evaluable" = "blue","progression disease" = "red", "partial response" = "green" , "stable disease" = "yellow")) + # Customize colors
  labs(title = "Patient duplicates interfere with RNA-seq V600E distribution\n in RNA filter cateogires") +
  xlab("RNA filter categories ") +
  ylab("Number of RNA-seq samples [count]") +
  scale_y_continuous(breaks = seq(1, 15, by = 2)) +
  theme(axis.title.x = element_text(size = 12), axis.title.y = element_text(size = 12),
        legend.title = element_text(size = 13), legend.text = element_text(size = 12),
        axis.text.x = element_text(size = 10), axis.text.y = element_text(size = 10))
ggsave(paste(PATH,"/geom_bar_targets.png",sep=""), plot = geom_bar_targets, width = 20, height = 15, units = "cm")

# Point plot showing RNA sequencing samples for same patient horizontally split by RNA_FILTER.
RNA_FILTER_wrap <- ggplot(data = df,
                          mapping = aes(y = PATIENT_ID, x = RNA_TOTAL, color = BEST_RESPONSE)) +
  geom_point(size = 4) +
  theme(axis.text.y = element_blank()) +
  scale_color_manual(values = c("non evaluable" = "blue","progression disease" = "red", "partial response" = "green" , "stable disease" = "yellow")) + # Customize colors
  labs(title = "Total RNA reads and percentage of reads supporting the alternative allele") +
  geom_text_repel(aes(label = str_c(round(PERCENTAGE, 0), "%")), color = "black", direction = "x") +
  scale_x_continuous(breaks = seq(0, 22, by = 2)) +
  facet_wrap(~RNA_FILTER, ncol = 4) +
  theme(strip.text = element_text(size = 12), axis.title.x = element_text(size = 12), axis.title.y = element_text(size = 12),
        axis.text.x = element_text(size = 10), legend.title = element_text(size = 13), legend.text = element_text(size = 12))
ggsave(paste(PATH,"/geom_scatter_RNA_FILTER_wrap.png",sep=""), plot = RNA_FILTER_wrap, width = 30, height = 20, units = "cm")

#######################################################################################
# make patient_ID vs sequence data as a relative x-axis
df_relative <- df %>%
  mutate(Relative_Seq_date = Seq_date - Treatment_start,
         Relative_Second_treatment = Second_treatment - Treatment_start,
         Relative_Date_of_Progression = Date_of_Progression - Treatment_start) %>%
  mutate(Time_Group = ifelse(Relative_Seq_date < 0, "Pre-Treatment", "Post-Treatment")) %>%
  remove_missing(vars = "Time_Group")

df_relative$Time_Group <- factor(df_relative$Time_Group, levels = c("Pre-Treatment", "Post-Treatment"))

# pre-treatment and post-treatment showed with transparency
pre_post_plot <- ggplot(data = df_relative,
       mapping = aes(y = PATIENT_ID, x = Relative_Seq_date, color = BEST_RESPONSE, shape = RNA_FILTER)) +
  geom_point(data = df_relative,
             aes(alpha = Time_Group, color = BEST_RESPONSE), size = 5) +
  scale_color_manual(values = c("non evaluable" = "blue", "progression disease" = "red", 
                                "partial response" = "green", "stable disease" = "yellow")) +
  scale_alpha_manual(values = c("Pre-Treatment" = 0.5, "Post-Treatment" = 1 ), guide = "none") +
  scale_shape_manual(values = c("RNA_NOCOV" = 16, "RNA_NOALT" = 17 ,"RNA_NOPASS" = 15, "RNA_PASS" = 18)) +
  geom_point(data = df_relative,
             aes(y = PATIENT_ID, x = 0), color = "black", shape = "|", size = 5) + # Treatment_start now at x = 0
  geom_point(data = df_relative,
             aes(y = PATIENT_ID, x = Relative_Second_treatment), color = "red", shape = "|", size = 5) +
  geom_point(data = df_relative,
             aes(y = PATIENT_ID, x = Relative_Date_of_Progression), color = "red", shape = "*", size = 7) +
  geom_text_repel(aes(label = str_c(round(PERCENTAGE, 0), "%")), color = "black", direction = "x") +
  scale_x_continuous(breaks = NULL) +
  xlab("Seq date relative to treatment start [days]") +
  theme(axis.text.y = element_blank(), strip.text = element_text(size = 12), axis.title.x = element_text(size = 12),
        axis.title.y = element_text(size = 12), legend.title = element_text(size = 13), legend.text = element_text(size = 12))
ggsave(paste(PATH,"/geom_scatter_pre_post.png",sep=""), plot = pre_post_plot, width = 34, height = 20, units = "cm")


###################################################################################
#investigate seq-samples before treatment

df_seq_info <- df_relative %>%
  mutate( seq_before_treatment = case_when(
    Seq_date < Treatment_start ~ "Yes",
    Seq_date > Treatment_start ~ "No",
  ))

# Create dataframe for bar plot counting RNA_FILTER before treatment start
pre_treatment_counts <- filter(df_seq_info, seq_before_treatment == "Yes") %>%
  count(RNA_FILTER, BEST_RESPONSE, name = "Count") %>%
  # Count the missing combinations of RNA_FILTER and STATUS as zero.
  complete(RNA_FILTER, BEST_RESPONSE, fill = list(Count = 0)) %>%
  remove_missing()

geom_bar_seq_before_treat <- ggplot(data = pre_treatment_counts,
                                    mapping = aes(x = RNA_FILTER, y = Count, fill = BEST_RESPONSE)) +
  geom_bar(stat = "identity", position = position_dodge(), color = "black") +
  scale_fill_manual(values = c("non evaluable" = "blue","progression disease" = "red", "partial response" = "green" , "stable disease" = "yellow")) + # Customize colors
  labs(title = "Pre-treatment RNA-seq data shows support of the alternative allele\n is associated with stable disease and partial response") +
  xlab("RNA filter categories ") +
  ylab("Number of Pre-treatment RNA-seq samples\n[count]") +
  theme(axis.title.x = element_text(size = 12), axis.title.y = element_text(size = 12),
        legend.title = element_text(size = 13), legend.text = element_text(size = 12),
        axis.text.x = element_text(size = 10), axis.text.y = element_text(size = 10))
geom_bar_seq_before_treat
ggsave(paste(PATH,"/geom_bar_pre-treatment.png",sep=""), plot = geom_bar_seq_before_treat, width = 20, height = 15, units = "cm")
