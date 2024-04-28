############################
# Preamble and inputs
############################

rm(list=ls())
set.seed(4)
.utildir = file.path("analysis/helpers/utilities")
.tempdir = file.path("analysis/output/temp")
library(tidyverse)
source(file.path(.utildir,"getAllUtilities.R"))


############################
# Data
############################

load(file.path(.tempdir, "cleaned_data.RData"))
data = data[!is.na(data$correct),] # remove the trials where subjects took too long to respond
rawdata = data
data = data %>% distinct(IDnumber, trial, .keep_all=T)
filter_df = data.frame(IDnumber = sort(unique(data$IDnumber)))


############################
# Trial-Level Filters
############################

# Drop Trials
# minRT: Response time must be greater than 0.3 (which accounts for NDT).
cutoff_rt = .325 # Cutoff is based on worst performing subject under speed condition in Milosavljevic et al 2010.
if (any(data$rt<cutoff_rt)) {warning("At least 1 trial failed the min(RT) filter.")}
data = data[data$rt>cutoff_rt,]
rawdata = rawdata[rawdata$rt>cutoff_rt,]


############################
# Participant-Level Filters
############################

# Drop Participants
# Non-missing: Must have responded on at least 95% of trials. Missing if (1) hit time constraint, (2) made decision too quickly.
.nTrials = 300
.cutoff = .95*.nTrials # 95% of trials
filter_mis = data %>%
  group_by(IDnumber) %>%
  summarize(
    n = n(),
    filter_missing = n<.cutoff
  )
filter_df = merge(filter_df, filter_mis, by="IDnumber")
if (any(filter_df$filter_missing)) {warning("At least 1 subject failed the non-missing filter.")}

# Accuracy: Perform significantly better than chance on the trials that they responded on.
filter_acc = data %>%
  group_by(IDnumber) %>%
  summarize(
    x = sum(correct, na.rm=T),
    n = n())
.test_results = filter_df$IDnumber
.ind = 1
for (.i in filter_df$IDnumber){
  .x = unlist(filter_acc[filter_acc$IDnumber==.i, "x"])
  .n = unlist(filter_acc[filter_acc$IDnumber==.i, "n"])
  .test_results[.ind] = binom.test(.x, .n, p = 0.5, alternative = "greater")$p.value
  .ind = .ind+1
}
filter_df$filter_accuracy = .test_results>0.05
if (any(filter_df$filter_accuracy)) {warning("At least 1 subject failed the accuracy filter.")}

# Speed: Average RT must be greater than typical NDT under time pressure (based on mean(T_mean) in Milosavljevic et al 2010).
cutoff_spe = mean(c(.245, .397, .434, .301, .336, .456, .351, .280, .350))
filter_spe = data %>%
  group_by(IDnumber) %>%
  summarize(
    speed = mean(rt),
    filter_speed = speed < cutoff_spe
  )
filter_df = merge(filter_df, filter_spe, by="IDnumber")
if (any(filter_df$filter_speed)) {warning("At least 1 subject failed the speed filter.")}


############################
# Filter out subjects who failed.
############################

# Filter the original data
filter_df$passed = !(filter_df$filter_missing | filter_df$filter_accuracy | filter_df$filter_speed)
.passed = data.frame(IDnumber = filter_df[filter_df$passed==T, "IDnumber"])
passed_subject_count = length(.passed$IDnumber)
data = merge(.passed, rawdata, by="IDnumber")

# parcode
data = data %>%
  group_by(IDnumber) %>%
  mutate(parcode = cur_group_id())

# make it pretty
.voi = c("IDnumber", "parcode", "trial", "choice", "rt", "correct", "slot_mean", "slot_sd", "sample", "raw_sample", "sample_num", "fix_dur", "firstSample", "middleSample", "lastSample")
data = data[order(data$parcode, data$trial, data$sample_num), .voi]

# save
save(data, file=file.path(.tempdir, "filtered_data.RData"))
