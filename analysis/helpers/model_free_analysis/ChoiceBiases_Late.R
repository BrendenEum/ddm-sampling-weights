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

load(file.path(.datadir, "exploratory", "data.RData"))


############################
# Data for plot
############################

breaks <- seq(-5, 5, 2)#breaks <- seq(-2.5, 2.5, 1)
labels <- seq(-4, 4, 2)#labels <- seq(-2, 2, 1)
data$sample_bin <- cut(data$sample, breaks=breaks, labels=labels) %>%
  as.character() %>%
  as.numeric()

data = data %>%
  group_by(parcode, trial) %>%
  slice_tail(n=4) 

pdata = data[data$lastSample!=T, ] %>%
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

p.ChoiceBiases.LateSampleBias = ggplot(data = pdata, aes(x=slot_mean, y=y, group=sample_bin)) +
  
  .myPlot+
  geom_vline(xintercept=0, color="grey", alpha=.75) +
  
  geom_ribbon(aes(ymin=y-se, ymax=y+se, fill=sample_bin), alpha=.ribbonalpha*.75, show.legend=F) +
  geom_line(aes(color=sample_bin), linewidth=.linewidth) +
  
  labs(y="Pr(Play)", x="Slot Machine Mean (SD = 2)", color="Sample") +
  coord_cartesian(xlim=c(-2,2), ylim=c(0,1), expand=F) +
  scale_color_gradient(low="#FF0000", high="#00FF00") +
  scale_fill_gradient(low="#FF0000", high="#00FF00")

p.ChoiceBiases.LateSampleBias = p.ChoiceBiases.LateSampleBias +
  theme(plot.background = element_rect(fill = .color_e, color = .color_e))

ggsave(file.path(.figdir, "ChoiceBiases_LateSampleBias.pdf"), p.ChoiceBiases.LateSampleBias, width=.figw, height=.figh)