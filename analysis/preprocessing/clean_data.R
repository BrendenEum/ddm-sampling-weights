############################
# Preamble and inputs
############################

rm(list=ls())
set.seed(4)
.utildir = file.path("analysis/helpers/utilities")
.tempdir = file.path("analysis/output/temp")
library(tidyverse)
library(stringr)
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
breaks = c(-Inf, -2.75, -2.5, -2.25, -2, -1.75, -1.5, -1.25, -1, -0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, Inf) # see Ella_Analysis.Rmd for how raw_samples were converted to dot sizes.
labels = c(-2.875, -2.625, -2.375, -2.125, -1.875, -1.625, -1.375, -1.125, -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875, 1.125, 1.375, 1.625, 1.875, 2.125, 2.375, 2.625, 2.875)
data$sample <- cut(data$raw_sample, breaks=breaks, labels=labels) %>%
  as.character() %>%
  as.numeric()

breaks = c(-Inf, -2, -1, 0, 1, 2, Inf)
labels = c(-2.5, -1.5, -.5, .5, 1.5, 2.5)
data$sample_bin <- cut(data$sample, breaks=breaks, labels=labels) %>%
  as.character() %>% as.numeric()

#data = data %>%
#  group_by(IDnumber, trial) %>%
#  mutate(sample_num = row_number())
#data = data[data$sample_num <= 40, ] # there are a maximum of 40 samples per trial

sample_vector_df = data %>%
  group_by(IDnumber, trial) %>%
  summarize(sample_vector = str_c(sample, collapse=",")) # Length of this vector = the number of fixations in fixation data (ie. max(sample_num)).)
data = merge(data, sample_vector_df, by=c("IDnumber", "trial"))

# Making simulation data only requires the 1st subject's data since all subjects see the same trials, in random order.
#simdata = data[data$IDnumber==first(unique(data$IDnumber)), ]
#save(simdata, file=file.path(.tempdir, "long_data_for_sims.RData"))


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

.voi = c("trial", "choice", "rt", "correct", "slot_mean", "slot_sd", "sample_bin", "sample_num", "fix_dur", "firstSample", "middleSample", "lastSample", "IDnumber", "sample", "raw_sample", "sample_vector")
data = data[,.voi]
save(data, file=file.path(.tempdir, "cleaned_data.RData"))
print("[NAs introduced by coercion] error is ok!")
