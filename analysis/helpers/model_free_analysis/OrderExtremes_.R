# Compare lotteries within the same slot_mean group. Why did choices differ?

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
# Order
############################

## slot_mean = 1

dataOne = data[data$slot_mean==1, ]

