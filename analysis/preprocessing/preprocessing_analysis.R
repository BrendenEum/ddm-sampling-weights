############################
# Preamble and inputs
############################

rm(list=ls())
set.seed(4)
.utildir = file.path("analysis/helpers/utilities")
.tempdir = file.path("analysis/output/temp")
.textdir = file.path("analysis/output/text")
.datadir = file.path("data/processed_data")
library(tidyverse)
source(file.path(.utildir,"getAllUtilities.R"))


############################
# Data
############################

load(file.path(.tempdir, "cleaned_data.RData"))
rawdata=data
load(file.path(.datadir, "joint", "data.RData"))


############################
# Analysis
############################

# How many participants did not make it through the filter?
started_with = length(unique(rawdata$IDnumber))
ended_with = length(unique(data$parcode))
write.text(started_with-ended_with, file.path(.textdir, "Preprocessing-count_participants_dropped.txt"))

# How many missing trials per participant?
nTrials = 300
.test = data %>% distinct(parcode, trial, .keep_all=T)
.test = .test[!is.na(.test$choice), ]
.test = .test %>%
  group_by(parcode) %>%
  summarize(trials = n())
.test$missing = nTrials - .test$trials
write.text(min(.test$missing), file.path(.textdir, "Preprocessing-min_missing_trials.txt"))
write.text(max(.test$missing), file.path(.textdir, "Preprocessing-max_missing_trials.txt"))
write.text(mean(.test$missing) %>% round(2), file.path(.textdir, "Preprocessing-mean_missing_trials.txt"))
