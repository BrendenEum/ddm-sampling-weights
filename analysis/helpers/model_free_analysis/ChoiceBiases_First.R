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

pdata = data[data$firstSample==T, ] %>%
  group_by(parcode, slot_mean, sample_bin) %>%
  summarize(
    mean_choice = mean(choice)
  ) %>%
  group_by(slot_mean, sample_bin) %>%
  summarize(
    y = mean(mean_choice),
    se = SE(mean_choice)
  )

pdata = na.omit(pdata)

############################
# Plot
############################

plt = ggplot(data = pdata, aes(x=slot_mean, y=y, group=sample_bin)) +
  
  .myPlot+
  geom_vline(xintercept=0, color="grey", alpha=.75) +
  
  geom_ribbon(aes(ymin=y-se, ymax=y+se, fill=sample_bin), alpha=.ribbonalpha*.75, show.legend=F) +
  geom_line(aes(color=sample_bin), linewidth=.linewidth) +
  
  labs(y="Pr(Play)", x="Slot Machine Mean (SD = 2)", color="Sample") +
  coord_cartesian(xlim=c(-2,2), ylim=c(0,1), expand=F) + 
  .gradientOpt +
  theme(
    legend.position = c(.88, .3)
  ) +
  annotate("text", x = -1.99, y = .99, label="First Sample", color="Black", hjust=0, vjust=1, size=8)

plt = plt +
  theme(plot.background = element_rect(fill = .color_e, color = .color_e))

ggsave(file.path(.figdir, "ChoiceBiases_FirstSampleBias.pdf"), plt, width=.figw, height=.figh)
