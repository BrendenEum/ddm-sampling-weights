############################
# Preamble and inputs
############################

rm(list=ls())
set.seed(4)
.utildir = file.path("analysis/helpers/utilities")
.tempdir = file.path("analysis/output/temp")
library(tidyverse)
source(file.path(.utildir,"getAllUtilities.R"))

.raw_data = read.csv("data/raw_data/data_exp_135720-v6/data_exp_135720-v6_task-ute6.csv")
data = .raw_data


############################
# Variables
############################

# ID number (parcode is handled in filter script)
data$IDnumber = data$Participant.Private.ID

# trial
data$trial = as.numeric(data$Trial.Number) - 10 # subtract practice trials

# rt
data$rt = data$Reaction.Time/1000 # in seconds

# choice (1 = yes, 0 = no, NA = took too long)
data$choice <- ifelse(
  data$Response == "YES", 1,
    ifelse(data$Response == "NO", 0, NA)
)

# slot statistics (see Gorilla script)
data$slot_mean = as.numeric(data$s) - 3 # categories 1:5 map to means of -2:2
data$slot_sd = 2 # sd fixed at 2

# correct (1 = yes, 0 = no, if choice matches with mean positive or negative)
data$correct = ifelse(
  (data$choice==1 & data$slot_mean>=0) | (data$choice==0 & data$slot_mean<=0), 1,
    ifelse(!is.na(data$choice), 0, NA)
)

# screen update speed
data$stimulus_refresh_rate = .3 # in seconds

# sample
data$raw_sample = data$e


############################
# Subsetting necessary data
############################

data = data[data$Screen.Name == "stim 1",] # the screen where the decision happens
data = data[!grepl("p", data$t), ] # drop practice trials
.voi = c("IDnumber", "trial", "choice", "rt", "correct", "slot_mean", "slot_sd", "stimulus_refresh_rate", "raw_sample")
data = data[,.voi]


############################
# Wide-to-Long evid
############################

data$raw_sample = gsub("c|\\(|\n|\\)", "", data$raw_sample)
data = separate_rows(data, raw_sample, sep = ",")
data$raw_sample = as.numeric(data$raw_sample)
data$sample = data$raw_sample %>% round(0)


############################
# Drop evid obs that weren't observed
############################

data = data %>%
  group_by(IDnumber, trial) %>%
  mutate(time_elapsed = cumsum(stimulus_refresh_rate))
data = data[data$time_elapsed<(data$rt+.3),] # keep the last observed stimulus by +.3
data$fix_dur = ifelse(data$time_elapsed > data$rt, data$time_elapsed - data$rt, .3)

# evidence number
data = data %>%
  group_by(IDnumber, trial) %>%
  mutate(sample_num = row_number())

# First, last, and middle evidence
# evidence number
data = data %>%
  group_by(IDnumber, trial) %>%
  mutate(
    firstSample = sample_num==1,
    lastSample = sample_num==n(),
    middleSample = !(firstSample | lastSample)
  )


############################
# Save the final dataset as temp (need to filter and split)
############################

.voi = c("IDnumber", "trial", "choice", "rt", "correct", "slot_mean", "slot_sd", "sample", "raw_sample", "sample_num", "fix_dur", "firstSample", "middleSample", "lastSample")
data = data[,.voi]
save(data, file=file.path(.tempdir, "cleaned_data.RData"))
print("[NAs introduced by coercion] error is ok!")
