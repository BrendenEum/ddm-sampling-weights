############################
# Preamble and inputs
############################

rm(list=ls())
set.seed(4)
.utildir = file.path("analysis/helpers/utilities")
.tempdir = file.path("analysis/output/temp")
.figdir = file.path("analysis/output/figures/")
.textdir = file.path("analysis/output/text/")
.datadir = file.path("data/processed_data")
library(tidyverse)
library(zoo)
library(ggsci)
source(file.path(.utildir,"getAllUtilities.R"))

load(file.path(.datadir, dataset, "data.RData"))


############################
# Data for plot
############################

# Ensure each subject-trial has exactly 40 observations
data_filled = data %>% 
  group_by(parcode, trial) %>%
  mutate(sample_num_decided = max(sample_num)) %>%
  complete(sample_num = seq(1,40,1))

# Get ready to make pdata
data_filled = data_filled %>%
  mutate(timeStep = .3) %>% # this will help us round up to nearest .3
  group_by(parcode, trial) %>%
  mutate(
    choice = na.locf(choice), # repeat last non-NA value within group
    time_elapsed = cumsum(timeStep), # rounded up to nearest .3 using timeStep
    sample_num_decided = max(sample_num_decided, na.rm=T),
    decided = sample_num>=max(sample_num_decided),
    decidedPlay = decided==T & choice==1,
    decidedSkip = decided==T & choice==0,
    undecided = !decided,
    avgSampleSeen = na.locf(cumsum(sample)/sample_num) %>% plyr::round_any(1) # repeat last non-NA value within group
  ) %>% ungroup() %>%
  group_by(parcode) %>%
  mutate(nTrial = length(unique(trial)))

breaks = c(-Inf, -2, -1, 0, 1, 2, Inf)
labels = c(-2.5, -1.5, -.5, .5, 1.5, 2.5)
data_filled$avgSampleSeen = cut(data_filled$avgSampleSeen, breaks=breaks, labels=labels) %>%
  as.character() %>%
  as.numeric()