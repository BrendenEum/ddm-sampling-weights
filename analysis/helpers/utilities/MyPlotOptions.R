.gainlosscolors = c("green4", "red3", "blue2", "deeppink", "purple2", "orange2", "cyan3", "bisque")

.color_e = 'lightcyan1'
.color_c = 'mistyrose1'
.color_j = 'lightcyan2'

.myPlot = list(
  theme_bw(),
  coord_cartesian(expand=F),
  #scale_color_manual(values=.gainlosscolors),
  #scale_fill_manual(values=.gainlosscolors),
  theme(
    legend.position="None",
    legend.background=element_blank(),
    legend.key = element_rect(fill = NA),
    #legend.spacing.x = unit(0.1, 'cm'),
    #legend.spacing.y = unit(0.1, 'cm'),
    plot.margin = unit(c(.5,.5,.5,.5), "cm"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    plot.title = element_text(size = 22),
    axis.title = element_text(size = 18),
    axis.text = element_text(size = 14),
    legend.title = element_text(size = 12),
    legend.text = element_text(size = 12)
  )
)

.linewidth = 1.5
.markersize = .01
.errsize = 1.5
.ribbonalpha = 0.3
.figw = 6
.figh = 4