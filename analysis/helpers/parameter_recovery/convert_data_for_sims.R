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
source(file.path(.utildir,"getAllUtilities.R"))

load(file.path(.datadir, dataset, "data.RData"))


############################
# Check which participant has all 300 trials
############################

check = data %>%
  group_by(parcode, trial) %>%
  summarize() %>% ungroup() %>%
  group_by(parcode) %>%
  summarize(count = n())

par_for_sim = check$parcode[ which(check$count==300)[1] ] # The first participant with 300 trials. Just need their stimuli for simulations, which is why this is fine. Code will break if nobody has 300 trials, but this isn't the case in my data so I'm leaving this as is.

simdata = data[data$parcode == par_for_sim, ]


############################
# Make expdata
############################

expsimdata = simdata %>%
  group_by(parcode, trial) %>%
  summarize(
    choice = ifelse(first(choice)==1, 1, -1),
    rt = floor(first(rt)*1000),
    sample_vector = first(sample_vector),
    last_fix_time = floor(last(fix_dur)*1000),
    item_left = 0, # The toolbox requires values for left and right items since it's built for estimating the aDDM. Set these to 0 to ignore.
    item_right = 0 
  )

write.csv(expsimdata, file = paste0("data/processed_data/", dataset, "/expsimdata.csv"), row.names=F)


############################
# Make fixations
############################

fixsimdata = data.frame(
  parcode = data$parcode,
  trial = data$trial,
  fix_item = data$sample_num,
  fix_time = floor(data$fix_dur*1000)
)

write.csv(fixsimdata, file = paste0("data/processed_data/", dataset, "/fixsimdata.csv"), row.names=F)