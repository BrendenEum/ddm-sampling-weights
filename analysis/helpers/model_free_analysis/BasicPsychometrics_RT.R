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
# Data for plot
############################

pdata = data %>%
  group_by(parcode, slot_mean) %>%
  summarize(
    mean_rt = mean(rt)
  ) %>%
  group_by(slot_mean) %>%
  summarize(
    y = mean(mean_rt),
    se = SE(mean_rt)
  )

############################
# Plot
############################

plt = ggplot(data = pdata, aes(x=slot_mean, y=y)) +
  
  .myPlot+
  geom_vline(xintercept=0, color="grey", alpha=.75) +
  
  geom_ribbon(aes(ymin=y-se, ymax=y+se), alpha=.ribbonalpha) +
  geom_line(linewidth=.linewidth) +
  
  labs(y="RT (s)", x="Slot Machine Mean (SD = 2)") +
  coord_cartesian(xlim=c(-2,2), expand=F)

plt = plt +
  theme(plot.background = element_rect(fill = .color_e, color = .color_e))

ggsave(file.path(.figdir, "BasicPsycho_RT.pdf"), plt, width=.figw, height=.figh)