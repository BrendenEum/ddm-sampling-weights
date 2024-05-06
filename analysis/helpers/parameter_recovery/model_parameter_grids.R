####################################
# Standard aDDM
####################################

# Gain
grid = list(
    d = c(.003, .0045, .006, .0075),
    sigma = c(.03, .045, .06, .075),
    theta = c(0, .25, .5, .75, .9),
    bias = c(-.2, -.1, 0, .1, .2)
    #decay = c(0, .001, .002, .003, .004)
)
grid = expand.grid(grid)
write.csv(grid, file="parameter_grids/aDDM_Gain.csv", row.names=F)

# Loss
grid = list(
    d = c(.003, .0045, .006, .0075),
    sigma = c(.03, .045, .06, .075),
    theta = c(1.1, 1.25, 1.5, 1.75, 2),
    bias = c(-.2, -.1, 0, .1, .2)
)
grid = expand.grid(grid)
write.csv(grid, file="parameter_grids/aDDM_Loss.csv", row.names=F)


####################################
# Additive aDDM
####################################

# Gain and Loss
grid = list(
    d = c(.003, .0045, .006, .0075),
    sigma = c(.03, .045, .06, .075),
    eta = c(.005, .01, .015, .02),
    bias = c(-.2, -.1, 0, .1, .2)
)
grid = expand.grid(grid)
write.csv(grid, file="parameter_grids/AddDDM_Gain.csv", row.names=F)
write.csv(grid, file="parameter_grids/AddDDM_Loss.csv", row.names=F)


####################################
# Reference-Dependent aDDM
####################################

# Gain
grid = list(
    d = c(.003, .0045, .006, .0075),
    sigma = c(.03, .045, .06, .075),
    theta = c(0, .25, .5, .75, .9),
    bias = c(-.2, -.1, 0, .1, .2),
    reference = c(1,0,-1)
)
grid = expand.grid(grid)
write.csv(grid, file="parameter_grids/RaDDM_Gain.csv", row.names=F)

# Loss
grid = list(
    d = c(.003, .0045, .006, .0075),
    sigma = c(.03, .045, .06, .075),
    theta = c(0, .25, .5, .75, .9),
    bias = c(-.2, -.1, 0, .1, .2),
    reference = c(-6,0,-8)
)
grid = expand.grid(grid)
write.csv(grid, file="parameter_grids/RaDDM_Loss.csv", row.names=F)