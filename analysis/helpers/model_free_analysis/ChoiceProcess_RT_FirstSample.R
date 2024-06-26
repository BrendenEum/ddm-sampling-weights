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
library(ggsci)
source(file.path(.utildir,"getAllUtilities.R"))

load(file.path(.datadir, dataset, "data.RData"))


############################
# Data for plot
############################

data$sample = round(data$sample)

pdata = data[data$firstSample==T, ] %>%
  group_by(parcode, sample) %>%
  summarize(
    mean_rt = mean(rt)
  ) %>%
  group_by(sample) %>%
  summarize(
    y = mean(mean_rt),
    se = SE(mean_rt)
  )

pdata = na.omit(pdata)

############################
# Plot
############################

plt = ggplot(data = pdata, aes(x=sample, y=y)) +
  
  .myPlot+
  geom_vline(xintercept=0, color="grey", alpha=.75) +
  
  geom_ribbon(aes(ymin=y-se, ymax=y+se), alpha=.ribbonalpha*.75, show.legend=F) +
  geom_line(linewidth=.linewidth) +
  
  labs(y="RT (s)", x="Rounded First Sample", color="Sample") +
  coord_cartesian(expand=F)

plt = plt +
  theme(plot.background = element_rect(fill = .color_e, color = .color_e))

ggsave(file.path(.figdir, "ChoiceProcess_RT_FirstSample.pdf"), plt, width=.figw, height=.figh)