"""
    aDDM_get_trial_likelihood(;addm::aDDM, trial::Trial, timeStep::Number = 10.0, 
                              stateStep::Number = 0.01)

Compute the likelihood of the data from a single aDDM trial for these particular aDDM 
  parameters.

# Arguments:

## Keyword arguments
- `model`: aDDM object.
- `trial`: Trial object.
- `timeStep`: Number, value in milliseconds to be used for binning the
    time axis.
- `stateStep`: Number, to be used for binning the RDV axis.
Returns:
- The likelihood obtained for the given trial and model.
"""
function aDDM_get_trial_likelihood(;model::aDDM, trial::Trial, timeStep::Number = 10.0, 
                                   stateStep::Number = 0.01, debug = false)
    
    # Iterate over the fixations and discount the non-decision time.
    if model.nonDecisionTime > 0
        correctedFixItem = Number[]
        correctedFixTime = Number[]
        remainingNDT = model.nonDecisionTime
        for (fItem, fTime) in zip(trial.fixItem, trial.fixTime) # iterate through each fixation in the trial
            if remainingNDT > 0
                push!(correctedFixItem, 0)
                push!(correctedFixTime, min(remainingNDT, fTime)) # if the fTime is smaller push that otherwise push ndt
                push!(correctedFixItem, fItem)
                push!(correctedFixTime, max(fTime - remainingNDT, 0))
                remainingNDT = remainingNDT - fTime
            else
                push!(correctedFixItem, fItem)
                push!(correctedFixTime, fTime)
            end
        end
    else
        correctedFixItem = trial.fixItem
        correctedFixTime = trial.fixTime
    end
    
    # Iterate over the fixations and get the number of time steps for this trial.
    numTimeSteps = 0
    
    for fTime in correctedFixTime
        numTimeSteps += Int64(fTime ÷ timeStep)
    end
    
    if numTimeSteps < 1
        throw(RuntimeError("Trial response time is smaller than time step."))
    end
    numTimeSteps += 1
    
    # The values of the barriers can change over time.
    barrierUp = model.barrier ./ (1 .+ model.decay .* (0:numTimeSteps-1))
    barrierDown = -model.barrier ./ (1 .+ model.decay .* (0:numTimeSteps-1))
    
    # Obtain correct state step.
    halfNumStateBins = ceil(model.barrier / stateStep)
    stateStep = model.barrier / (halfNumStateBins + 0.5)
    
    # The vertical axis is divided into states.
    states = range(-1*(model.barrier) + stateStep / 2, 1*(model.barrier) - stateStep/2, step=stateStep)
    
    # Find the state corresponding to the bias parameter.
    biasState = argmin(abs.(states .- model.bias))
    
    # Initial probability for all states is zero, except the bias state,
    # for which the initial probability is one.
    prStates = zeros(length(states), numTimeSteps)
    prStates[biasState,1] = 1
    
    # The probability of crossing each barrier over the time of the trial.
    probUpCrossing = zeros(numTimeSteps)
    probDownCrossing = zeros(numTimeSteps)
    
    time = 1
    
    # Dictionary of μ values from fItem.
    μDict = Dict{Number, Number}()
    for fItem in 0:2
        if fItem == 1
            μ = model.d * ((trial.valueLeft + model.η) - (model.θ * trial.valueRight))
        elseif fItem == 2
            μ = model.d * ((model.θ * trial.valueLeft) - (trial.valueRight + model.η))
        else
            μ = 0
        end
        
        μDict[fItem] = μ
    end 
    
    changeMatrix = states .- reshape(states, 1, :)
    changeUp = (barrierUp .- reshape(states, 1, :))'
    changeDown = (barrierDown .- reshape(states, 1, :) )'
    
    pdfDict = Dict{Number, Any}()
    cdfUpDict = Dict{Number, Any}()
    cdfDownDict = Dict{Number, Any}() 
    
    for fItem in 0:2
        normpdf = similar(changeMatrix)
        cdfUp = similar(changeUp[:, time])
        cdfDown = similar(changeDown[:, time])
        
        @. normpdf = pdf(Normal(μDict[fItem], model.σ), changeMatrix)
        @. cdfUp = cdf(Normal(μDict[fItem], model.σ), changeUp[:, time])
        @. cdfDown = cdf(Normal(μDict[fItem], model.σ), changeDown[:, time])
        pdfDict[fItem] = normpdf
        cdfUpDict[fItem] = cdfUp
        cdfDownDict[fItem] = cdfDown
    end
    
    # Iterate over all fixations in this trial.
    for (fItem, fTime) in zip(correctedFixItem, correctedFixTime)
        # We use a normal distribution to model changes in RDV
        # stochastically. The mean of the distribution (the change most
        # likely to occur) is calculated from the model parameters and from
        # the item values.
        μ = μDict[fItem]
        normpdf = pdfDict[fItem]
        cdfUp = cdfUpDict[fItem]
        cdfDown = cdfDownDict[fItem]
        
        # Iterate over the time interval of this fixation.
        for t in 1:Int64(fTime ÷ timeStep)
            # Update the probability of the states that remain inside the 
            # barriers. The probability of being in state B is the sum, 
            # over all states A, of the probability of being in A at the 
            # previous timestep times the probability of changing from A to
            # B. We multiply the probability by the stateStep to ensure
            # that the area under the curves for the probability 
            # distributions probUpCrossing and probDownCrossing add up to 1.
            prStatesNew = stateStep * (normpdf * prStates[:,time])
            prStatesNew[(states .>= barrierUp[time]) .| (states .<= barrierDown[time])] .= 0
            
            # Calculate the probabilities of crossing the up barrier and
            # the down barrier. This is given by the sum, over all states
            # A, of the proability of being in A at the previous timestep
            # times the probability of crossing the barrier if A is the
            # previous state.
            tempUpCross = dot(prStates[:,time], 1 .- cdfUp)
            tempDownCross = dot(prStates[:,time], cdfDown)
            
            # Renormalize to cope with numerical approximations.
            sumIn = sum(prStates[:,time])
            sumCurrent = sum(prStatesNew) + tempUpCross + tempDownCross
            prStatesNew = prStatesNew * sumIn / sumCurrent
            tempUpCross = tempUpCross * sumIn / sumCurrent
            tempDownCross = tempDownCross * sumIn / sumCurrent

            # Update the probabilities of each state and the probabilities of
            # crossing each barrier at this timestep
            prStates[:,time+1] = prStatesNew
            probUpCrossing[time+1] = tempUpCross
            probDownCrossing[time+1] = tempDownCross
            
            time += 1
        end
    end
    
    # Compute the likelihood contribution of this trial based on the final
    # choice.
    likelihood = 0
    if trial.choice == -1 # Choice was left.
        if probUpCrossing[end] > 0
            likelihood = probUpCrossing[end]
        end
    elseif trial.choice == 1 # Choice was right.
        if probDownCrossing[end] > 0 
            likelihood = probDownCrossing[end]
        end
    end
    
    if debug
      return (likelihood, prStates, probUpCrossing, probDownCrossing)
    else
      return likelihood
    end
end

"""
    DDM_get_trial_likelihood(;ddm::aDDM, trial::Trial, timeStep::Number = 10, 
                             stateStep::Number = 0.01)

Compute the likelihood of the data from a single DDM trial for these
particular DDM parameters.

# Arguments

## Keyword arguments
- `model`: aDDM object.
- `trial`: Trial object.
- `timeStep`: Number, value in milliseconds to be used for binning the
    time axis.
- `stateStep`: Number, to be used for binning the RDV axis.
# Returns
- The likelihood obtained for the given trial and model.
"""
function DDM_get_trial_likelihood(;model::aDDM, trial::Trial, timeStep::Number = 10, 
                                  stateStep::Number = 0.01)
    
    # Get the number of time steps for this trial.
    numTimeSteps = Int64(trial.RT ÷ timeStep)
    if numTimeSteps < 1
        throw(RuntimeError("Trial response time is smaller than time step."))
    end

    # The values of the barriers can change over time.
    barrierUp = model.barrier ./ (1 .+ model.decay .* (0:numTimeSteps-1))
    barrierDown = -model.barrier ./ (1 .+ model.decay .* (0:numTimeSteps-1))

    # Obtain correct state step.
    halfNumStateBins = ceil(model.barrier / stateStep)
    stateStep = model.barrier / (halfNumStateBins + 0.5)
    
    # The vertical axis is divided into states.
    states = range(-1*(model.barrier) + stateStep / 2, 1*(model.barrier) - stateStep/2, step=stateStep)
    
    # Find the state corresponding to the bias parameter.
    biasState = argmin(abs.(states .- model.bias))
    
    # Initial probability for all states is zero, except the bias state,
    # for which the initial probability is one.
    prStates = zeros(length(states), numTimeSteps)
    prStates[biasState,1] = 1
    
    # The probability of crossing each barrier over the time of the trial.
    probUpCrossing = zeros(numTimeSteps)
    probDownCrossing = zeros(numTimeSteps)
    
    changeMatrix = states .- reshape(states, 1, :)
    changeUp = (barrierUp .- reshape(states, 1, :))'
    changeDown = (barrierDown .- reshape(states, 1, :) )'
    
    normpdf = similar(changeMatrix)
    
    elapsedNDT = 0
    
    # Iterate over the time of this trial.
    for time in 1:numTimeSteps-1
        # We use a normal distribution to model changes in RDV
        # stochastically. The mean of the distribution (the change most
        # likely to occur) is calculated from the model parameter d and
        # from the item values, except during non-decision time, in which
        # the mean is zero.
        if elapsedNDT < model.nonDecisionTime ÷ timeStep
            μ = 0
            elapsedNDT += 1
        else
            μ = model.d * (trial.valueLeft - trial.valueRight)
        end
        
        # Update the probability of the states that remain inside the
        # barriers. The probability of being in state B is the sum, over
        # all states A, of the probability of being in A at the previous
        # time step times the probability of changing from A to B. We
        # multiply the probability by the stateStep to ensure that the area
        # under the curves for the probability distributions probUpCrossing
        # and probDownCrossing add up to 1.
        @. normpdf = pdf(Normal(μ, model.σ), changeMatrix)
        prStatesNew = stateStep * (normpdf * prStates[:,time])
        prStatesNew[(states .>= barrierUp[time]) .| (states .<= barrierDown[time])] .= 0
        
        # Calculate the probabilities of crossing the up barrier and the
        # down barrier. This is given by the sum, over all states A, of the
        # probability of being in A at the previous timestep times the
        # probability of crossing the barrier if A is the previous state.
        cdfUp = similar(changeUp[:, time])
        cdfDown = similar(changeDown[:, time])
        @. cdfUp = cdf(Normal(μ, model.σ), changeUp[:, time])
        @. cdfDown = cdf(Normal(μ, model.σ), changeDown[:, time])
        
        tempUpCross = dot(prStates[:,time], 1 .- cdfUp)
        tempDownCross = dot(prStates[:,time], cdfDown)

        # Renormalize to cope with numerical approximations.
        sumIn = sum(prStates[:,time])
        sumCurrent = sum(prStatesNew) + tempUpCross + tempDownCross
        prStatesNew = prStatesNew * sumIn / sumCurrent
        tempUpCross = tempUpCross * sumIn / sumCurrent
        tempDownCross = tempDownCross * sumIn / sumCurrent

        # Update the probabilities of each state and the probabilities of
        # crossing each barrier at this timestep.
        prStates[:,time+1] = prStatesNew
        probUpCrossing[time+1] = tempUpCross
        probDownCrossing[time+1] = tempDownCross
    end
    
    # Compute the likelihood contribution of this trial based on the final choice.
    likelihood = 0
    if trial.choice == -1 # Choice was left.
        if probUpCrossing[end] > 0
            likelihood = probUpCrossing[end]
        end
    elseif trial.choice == 1 # Choice was right.
        if probDownCrossing[end] > 0
            likelihood = probDownCrossing[end]
        end
    end
  
    
    return likelihood
end


"""
    compute_trials_nll(model::aDDM, data, likelihood_fn, likelihood_args = (timeStep = 10.0, cutOff = 20000))

Compute likelihood of a dataset for a given model.

# Arguments
- `model`: aDDM object. Holds info on the parameter values for the likelihood function.
- `data`: Vector of `ADDM.Trial` objects. 
- `likelihood_fn`: Name of the function that computes the likelhoods of a trial for the given model.
- `likelihood_args`: Named tuple containing kwargs that should be fed to `likelihood_fn`
- `return_trial_likelihoods`: Boolean to specify whether to return the likelihoods for each trial
- `sequential_model`: Boolean to specify if the model requires all data concurrently (e.g. RL-DDM). If `true` model cannot be multithreaded

# Returns
- Negative log likelihood of data
- (Optional) Dictionary of trial likelihoods keyed by the trial number
"""
function compute_trials_nll(model::ADDM.aDDM, data, likelihood_fn, likelihood_args = (timeStep = 10.0, stateStep = 0.1); 
  return_trial_likelihoods = false, sequential_model = false, compute_trials_exec = ThreadedEx())

  n_trials = length(data)
  data_dict = Dict(zip(1:length(data), data))
  likelihoods = Ref{Dict{Int64, Float64}}(Dict(zip(1:n_trials, zeros(n_trials))))

  # Redundant but maybe more foolproof in case there is confusion about the executor
  if sequential_model
   cur_exe = SequentialEx()
  else
   cur_exe = compute_trials_exec
  end

  @floop cur_exe for trial_number in collect(eachindex(data_dict))
    likelihoods[][trial_number] = likelihood_fn(;model = model, trial = data_dict[trial_number], likelihood_args...)
  end

  # If likelihood is 0, set it to 1e-64 to avoid taking the log of a 0.
  likelihoods[] = Dict(k => max(v, 1e-64) for (k,v) in likelihoods[])

  # Sum over all of the negative log likelihoods.
  negative_log_likelihood = -sum(log.(values(likelihoods[])))

  if return_trial_likelihoods
    return negative_log_likelihood, likelihoods[]
  else
    return negative_log_likelihood
  end
end