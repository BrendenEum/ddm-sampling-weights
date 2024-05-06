# parcode trial rt choice item_left item_right
# parcode trial fix_item fix_time

############################
# Preamble and inputs
############################

rm(list=ls())
set.seed(4)
.utildir = file.path("analysis/helpers/utilities")
.tempdir = file.path("analysis/output/temp")
library(tidyverse)
source(file.path(.utildir,"getAllUtilities.R"))

load(file.path(.tempdir, "long_data_for_sims.RData"))


############################
# Make expdata
############################

expdata = data %>%
  group_by(IDnumber, trial)