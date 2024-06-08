####################################
# Standard aDDM
####################################

# Gain
grid = list(
    d = c(.001, .003),
    sigma = c(.02, .04),
    bias = c(-.1, 0, .1),
    alpha = c(3, 6)
)
grid = expand.grid(grid)
write.csv(grid, file="analysis/helpers/parameter_recovery/param_grid.csv", row.names=F)