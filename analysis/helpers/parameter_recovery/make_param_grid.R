####################################
# Standard aDDM
####################################

# Gain
grid = list(
    d = c(.005, .007, .009),
    sigma = c(.03, .05, .07),
    bias = c(-.1, 0, .1)
)
grid = expand.grid(grid)
write.csv(grid, file="analysis/helpers/parameter_recovery/param_grid.csv", row.names=F)