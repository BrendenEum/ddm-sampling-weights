############################
# Preamble and inputs
############################

# Load data and transform it to time-series data
if (!exists("data_filled")) {
  source("analysis/helpers/model_free_analysis/ChoiceProcess_DataTransforming.R") 
}

# What proportion of trials has the participant decided yes at time t?
pdata = data_filled %>%
  group_by(parcode, time_elapsed, avgSampleSeen) %>%
  summarize(
    y_mean = mean(undecided)
  ) %>% ungroup() %>%
  group_by(time_elapsed, avgSampleSeen) %>%
  summarize(
    y = mean(y_mean),
    se = SE(y_mean)
  )


############################
# Plot
############################

plt = ggplot(data = pdata, aes(x=time_elapsed, y=y, group=avgSampleSeen)) +
  
  .myPlot+
  geom_vline(xintercept=0, color="grey", alpha=.75) +
  
  geom_ribbon(aes(ymin=y-se, ymax=y+se, fill=avgSampleSeen), alpha=.ribbonalpha*.75, show.legend=F) +
  geom_line(aes(color=avgSampleSeen), linewidth=.linewidth) +
  
  labs(y="Pr(Undecided)", x="Time Elapsed (s)", color="Sample") +
  coord_cartesian(xlim = c(0,12), ylim = c(0,1), expand=F) +
  .gradientOpt

plt = plt +
  theme(plot.background = element_rect(fill = .color_e, color = .color_e))

ggsave(file.path(.figdir, "ChoiceProcess_PrUnd_Time_AvgSample.pdf"), plt, width=.figw, height=.figh)
