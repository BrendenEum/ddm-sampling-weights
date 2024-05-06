############################
# Preamble and inputs
############################

rm(list=ls())
set.seed(4)
.utildir = file.path("analysis/helpers/utilities")
.tempdir = file.path("analysis/output/temp/loss_aversion")
.figdir = file.path("analysis/output/figures/")
.textdir = file.path("analysis/output/text/")
.datadir = file.path("data/processed_data")
library(tidyverse)
library(stats)
source(file.path(.utildir,"getAllUtilities.R"))


############################
# Logistic Regression Method
############################

load(file.path(.datadir, "exploratory", "data.RData"))
data$only_positive = ifelse(data$sample>0, data$sample, NA)
data$only_negative = ifelse(data$sample<=0, data$sample, NA)
data = data %>% 
  group_by(parcode, trial) %>%
  summarize(
    choice = first(choice),
    mean_positive = mean(only_positive, na.rm=T),
    mean_negative = mean(only_negative, na.rm=T)
  )
data$mean_negative[is.na(data$mean_negative)] = 0
data$mean_positive[is.na(data$mean_positive)] = 0

lambda_list_logistic = rep(NA, length(unique(data$parcode)))

for (j in unique(data$parcode)) {
  subj_data = data[data$parcode==j,]
  model <- glm(choice ~ 1 + mean_positive + mean_negative, data = subj_data, family = binomial())
  lambda = model$coefficients[3]/model$coefficients[2]
  lambda_list_logistic[j] = lambda
}

hist(lambda_list_logistic)


############################
# Point-of-Indifference Method
############################

load(file.path(.datadir, "exploratory", "data.RData"))
data = data[data$firstSample==T,]
poi_list = rep(NA, length(unique(data$parcode)))

lambda_list_poi = rep(NA, length(unique(data$parcode)))

for (j in unique(data$parcode)) {
  subj_data = data[data$parcode==j,]
  model <- glm(choice ~ 1 + slot_mean, data = subj_data, family = binomial())
  poi = (0.5-model$coefficients[1])/model$coefficients[2]
  poi_list[j] = poi
  
  cdfx = pnorm(0, mean=poi, sd=2)
  lambda = (1-cdfx)/cdfx
  lambda_list_poi[j] = lambda
}

hist(lambda_list_poi)
