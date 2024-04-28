############################
# Preamble and inputs
############################

rm(list=ls())
set.seed(4)
.utildir = file.path("analysis/helpers/utilities")
.tempdir = file.path("analysis/output/temp")
.datadir = file.path("data/processed_data")
library(tidyverse)
source(file.path(.utildir,"getAllUtilities.R"))


############################
# Data
############################

load(file.path(.tempdir, "filtered_data.RData"))


############################
# Split
############################

.parcodes = unique(data$parcode)
.half = floor(length(.parcodes)/2)
exploratory_parcodes = .parcodes[1:.half]
confirmatory_parcodes = .parcodes[(.half+1):length(.parcodes)]
edata = data[data$parcode %in% exploratory_parcodes, ]
cdata = data[data$parcode %in% confirmatory_parcodes, ]

edata$dataset = "E"
cdata$dataset = "C"

# exploratory
data = edata
save(data, file=file.path(.datadir, "exploratory", "data.RData"))

# confirmatory
data = cdata
save(data, file=file.path(.datadir, "confirmatory", "data.RData"))

# joint
data = rbind(edata, cdata)
data$dataset = "J"
save(data, file=file.path(.datadir, "joint", "data.RData"))