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

pdata = data %>%
  group_by(parcode, slot_mean) %>%
  summarize(
    mean_choice = mean(choice)
  ) %>%
  group_by(slot_mean) %>%
  summarize(
    y = mean(mean_choice),
    se = SE(mean_choice)
  )

############################
# Plot
############################

p.BasicPsycho.Choice = ggplot(data = pdata, aes(x=slot_mean, y=y)) +
  
  .myPlot+
  geom_hline(yintercept=.5, color="grey", alpha=.75) +
  geom_vline(xintercept=0, color="grey", alpha=.75) +
  
  geom_ribbon(aes(ymin=y-se, ymax=y+se), alpha=.ribbonalpha) +
  geom_line(linewidth=.linewidth) +
  
  labs(y="Pr(Play)", x="Slot Machine Mean (SD = 2)") +
  coord_cartesian(xlim=c(-2,2), ylim=c(0,1), expand=F) + 
  scale_y_continuous(breaks=c(0, .5, 1))

p.BasicPsycho.Choice = p.BasicPsycho.Choice +
  theme(plot.background = element_rect(fill = .color_e, color = .color_e))

ggsave(file.path(.figdir, "BasicPsycho_Choice.pdf"), p.BasicPsycho.Choice, width=.figw, height=.figh)
