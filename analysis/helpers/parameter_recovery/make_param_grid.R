####################################
# Standard aDDM
####################################

# Gain
grid = list(
    d = seq(.001, .009, .001),
    sigma = seq(.03, .09, .01),
    bias = seq(-.2, .2, .1),
    k = seq(.25, 1.5, .25)
)
grid = expand.grid(grid)
write.csv(grid, file="analysis/helpers/parameter_recovery/param_grid.csv", row.names=F)