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

load(file.path(.datadir, "exploratory", "data.RData"))


############################
# Data for plot
############################

pdata = data[data$lastSample==T, ] %>%
  group_by(parcode, slot_mean) %>%
  summarize(
    mean_sample_num = mean(sample_num)
  ) %>%
  group_by(slot_mean) %>%
  summarize(
    y = mean(mean_sample_num),
    se = SE(mean_sample_num)
  )

############################
# Plot
############################

p.BasicPsycho.NumSamples = ggplot(data = pdata, aes(x=slot_mean, y=y)) +
  
  .myPlot+
  geom_vline(xintercept=0, color="grey", alpha=.75) +
  
  geom_ribbon(aes(ymin=y-se, ymax=y+se), alpha=.ribbonalpha) +
  geom_line(linewidth=.linewidth) +
  
  labs(y="Number of Samples", x="Slot Machine Mean (SD = 2)") +
  coord_cartesian(xlim=c(-2,2), expand=F)

p.BasicPsycho.NumSamples = p.BasicPsycho.NumSamples +
  theme(plot.background = element_rect(fill = .color_e, color = .color_e))

ggsave(file.path(.figdir, "BasicPsycho_NumSamples.pdf"), p.BasicPsycho.NumSamples, width=.figw, height=.figh)