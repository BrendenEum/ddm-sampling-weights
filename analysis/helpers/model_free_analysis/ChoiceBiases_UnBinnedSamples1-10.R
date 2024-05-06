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


for (i in c(1:10)) {
  
  ############################
  # Data for plot
  ############################
  
  .n_df = data[data$sample_num==i, ] %>%
    group_by(parcode) %>%
    summarize(n = n())
  n = mean(.n_df$n) %>% round()
  n_se = SE(.n_df$n) %>% round()
  
  pdata = data[data$sample_num==i, ] %>%
    group_by(parcode, slot_mean, sample) %>%
    summarize(
      mean_choice = mean(choice)
    ) %>%
    group_by(slot_mean, sample) %>%
    summarize(
      y = mean(mean_choice),
      se = SE(mean_choice)
    )
  
  pdata = na.omit(pdata)
  
  ############################
  # Plot
  ############################
  
  plt = ggplot(data = pdata, aes(x=slot_mean, y=y, group=sample)) +
    
    .myPlot+
    geom_vline(xintercept=0, color="grey", alpha=.75) +
    
    #geom_ribbon(aes(ymin=y-se, ymax=y+se, fill=sample), alpha=.ribbonalpha*.75, show.legend=F) +
    geom_line(aes(color=sample), linewidth=.linewidth) +
    
    labs(y="Pr(Play)", x="Slot Machine Mean (SD = 2)", color="Rnd. Sample") +
    coord_cartesian(xlim=c(-2,2), ylim=c(0,1), expand=F) + 
    scale_color_gradient(low="#FF0000", high="#00FF00") +
    annotate("text", x = -1.99, y = .99, label=paste("Sample", i), color="Black", hjust=0, vjust=1, size=8) +
    annotate("text", x=1.99, y=.01, label=paste0("n = ",n," (",n_se,")"), color="Black", hjust=1, vjust=0, size=6)
  
  plt = plt +
    theme(plot.background = element_rect(fill = .color_e, color = .color_e))
  
  ggsave(
    file.path(.figdir, paste0("ChoiceBiases_UnBinnedSample-",toString(i),".pdf")), 
    plt, 
    width=.figw, height=.figh
  )
  
}
