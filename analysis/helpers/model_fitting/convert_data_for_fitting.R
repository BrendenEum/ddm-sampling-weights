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
# Make expdata
############################

expdata = data %>%
  group_by(parcode, trial) %>%
  summarize(
    choice = ifelse(first(choice)==1, 1, -1),
    rt = floor(first(rt)*1000),
    sample_vector = first(sample_vector),
    item_left = 0, # The toolbox requires values for left and right items since it's built for estimating the aDDM. Set these to 0 to ignore.
    item_right = 0 
  )

write.csv(expdata, file = paste0("data/processed_data/", dataset, "/expdata.csv"), row.names=F)


############################
# Make fixations
############################

fixations = data.frame(
  parcode = data$parcode,
  trial = data$trial,
  fix_item = data$sample_num,
  fix_time = floor(data$fix_dur*1000)
)

write.csv(fixations, file = paste0("data/processed_data/", dataset, "/fixdata.csv"), row.names=F)