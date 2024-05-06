@userplot State_Space_Plot

recipetype(::Val{:state_space_plot}, args...) = State_Space_Plot(args)

# state_space_plot(prStates, probUpCrossing, probDownCrossing, timeStep, stateStep)

@recipe function f(ssp::State_Space_Plot)

  # Input data
  prStates = ssp.args[1]
  probUpCrossing = ssp.args[2]
  probDownCrossing = ssp.args[3]
  timeStep = ssp.args[4]
  stateStep = ssp.args[5]
  likelihoodLims = ssp.args[6]
  prStateLims = ssp.args[7]

  # x = timeStep bins
  # y = stateStep bins
  halfNumStateBins = ceil(1 / stateStep)
  correctStateStep = 1 / (halfNumStateBins + 0.5)
  states = range(-1 + correctStateStep / 2, 1 - correctStateStep/2, step=correctStateStep)
  x = collect(range(0, size(prStates)[2], step=1)*timeStep)[2:end]
  y = collect(states)

  # Common to all plots
  legend --> false
  layout --> @layout [
      topProbCrossing
      middleProbStates{0.9h}
      bottomProbCrossing
  ]
  seriestype := :heatmap
  top_margin := -2mm
  bottom_margin := -2mm

  # Main plot: probStates
  @series begin
    subplot := 2
    yticks := -1:1:1
    xformatter --> (x -> "")
    clims := prStateLims
    x, y, prStates
  end

  # Common to the top and bottom plots
  clims := likelihoodLims

  # Top plot: probUpCrossing
  @series begin
    subplot := 1
    showaxis := false
    bottom_margin := -6mm
    z = reshape(probUpCrossing, 1, length(probUpCrossing))
    x, [1], z
  end

  # Bottom plot: probDownCrossing
  @series begin
    subplot := 3
    top_margin := -3.5mm
    xticks := :auto
    z = reshape(probDownCrossing, 1, length(probDownCrossing))
    yformatter --> (y -> "")
    x, [1], z
  end


end
