"""
    aDDM_simulate_trial(model::aDDM, fixationData::FixationData, 
                        valueLeft::Number, valueRight::Number; timeStep::Number=10.0, 
                        numFixDists::Int64=3 , fixationDist=nothing, timeBins=nothing, 
                        cutOff::Number=100000)

Generate a DDM trial given the item values.

# Arguments
- `model`: aDDM object.
- `fixationData`: FixationData object. `Required even when using fixationDist`
  because it specifies latencies and transitions as well.
- `valueLeft`: value of the left item.
- `valueRight`: value of the right item.
- `timeStep`: Number, value in milliseconds to be used for binning
    time axis.
- `numFixDists`: Int64, number of fixation types to use in the fixation
    distributions. For instance, if numFixDists equals 3, then 3
    separate fixation types will be used, corresponding to the 1st,
    2nd and other (3rd and up) fixations in each trial.
- `fixationDist`: distribution of fixations which, when provided, will be
    used instead of fixationData.fixations. This should be a dict of
    dicts of dicts, corresponding to the probability distributions of
    fixation durations. Indexed first by fixation type (1st, 2nd, etc),
    then by the value difference between the fixated and unfixated 
    items, then by time bin. Each entry is a number between 0 and 1 
    corresponding to the probability assigned to the particular time
    bin (i.e. given a particular fixation type and value difference,
    probabilities for all bins should add up to 1). Can be obtained from
    `fixationData` using `convert_to_fixationDist`. If using this instead
    of `fixationData` to sample fixations make sure to specify latency and 
    transition info in `fixationData`.
- `timeBins`: array containing the time bins used in fixationDist. Can be
    obtained from`fixationData` using `convert_to_fixationDist`

# Returns
- An Trial object resulting from the simulation.
"""
function aDDM_simulate_trial(;model::aDDM, fixationData::FixationData, 
                        valueLeft::Number, valueRight::Number, 
                        sample_vector::Vector{Number},
                        timeStep::Number=10.0, numFixDists::Int64=3, fixationDist=nothing, 
                        timeBins=nothing, cutOff::Number=100000)
    
    fixItem = Number[]
    fixTime = Number[]
    fixRDV = Number[]
    samplesSeen = Number[]

    RDV = model.bias
    trialTime = 0
    choice = 0
    tRDV = Number[RDV]
    RT = 0
    uninterruptedLastFixTime = 0

    # The values of the barriers can change over time.
    barrierUp = model.barrier ./ (1 .+ model.decay .* (0:cutOff-1))
    barrierDown = -model.barrier ./ (1 .+ model.decay .* (0:cutOff-1))

    # Begin decision related accummulation
    currFixLocation = 0
    decisionReached = false
    cumTimeStep = 0
    while true
        
        # Fixation patterns
        currFixLocation += 1
        currFixTime = 300

        # Iterate over the duration of the current fixation.
        # Does not move RDV if there is no fixation time left due to NDT
        for t in 1:Int64(currFixTime ÷ timeStep)
            
            # Sample new samples if you run out before decision reached.
            if currFixLocation > length(sample_vector)
                push!(sample_vector, sample(sample_vector))
            end
            
            # Drift rate
            #μ = ( model.d + ((model.α/10000)*cumTimeStep) ) * sample_vector[currFixLocation]
            μ = model.d * sample_vector[currFixLocation]

            # Sample the change in RDV from the distribution.
            RDV += rand(Normal(μ, model.σ))
            push!(tRDV, RDV)

            # Increment cumulative timestep to look up the correct barrier value in case there has been a decay
            # Decay in this case only happens during decision-related accummulation (not before)
            # Don't want to use t here because this is reset for each fixation throughout a trial but the barrier is not
            cumTimeStep += 1

            # If the RDV hit one of the barriers, the trial is over.
            # Decision related accummulation here so barrier might have decayed
            if abs(RDV) >= barrierUp[cumTimeStep]
                choice = RDV >= 0 ? -1 : 1
                push!(samplesSeen, sample_vector[currFixLocation])
                push!(fixRDV, RDV)
                push!(fixItem, currFixLocation)
                push!(fixTime, t * timeStep)
                trialTime += t * timeStep
                RT = trialTime
                uninterruptedLastFixTime = currFixTime
                decisionReached = true
                break
            end

        end

        # Break out of the while loop if decision reached during NDT
        # The break above only breaks from the curFixTime for loop
        if decisionReached
            break
        end

        # Add fixation to this trial's data.
        push!(samplesSeen, sample_vector[currFixLocation])
        push!(fixRDV, RDV)
        push!(fixItem, currFixLocation)
        push!(fixTime, currFixTime - (currFixTime % timeStep))
        trialTime += currFixTime - (currFixTime % timeStep)

    end

    # Because the last stimulus seems to have no impact on choices, I believe a lot of the processes captured by non-decision time is happening at the end of the decision in this task. Therefore, I incorporate non-decision time as time added to the final RT of the simulation.
    #ndt = sample(fixationData.fixations[maximum(keys(fixationData.fixations))][1])
    #RT += model.nonDecisionTime

    trial = Trial(choice = choice, RT = RT, valueLeft = valueLeft, valueRight = valueRight)
    trial.sample_vector = samplesSeen
    trial.fixItem = fixItem 
    trial.fixTime = fixTime 
    trial.fixRDV = fixRDV
    trial.uninterruptedLastFixTime = uninterruptedLastFixTime
    trial.RDV = tRDV
    return trial
end

"""
    DDM_simulate_trial(model::aDDM, valueLeft::Number, valueRight::Number; timeStep::Number = 10.0, 
                       cutOff::Int64 = 20000)

Generate a DDM trial given the item values.

# Arguments
- `model`: aDDM object.
- `valueLeft`: value of the left item.
- `valueRight`: value of the right item.
- `timeStep`: Number, value in milliseconds to be used for binning the
    time axis.
- `cutOff`: Number, value in milliseconds to be used as a cap if trial
    response time is too long.

    # Returns
- A Trial object resulting from the simulation.
"""
function DDM_simulate_trial(;model::aDDM, valueLeft::Number, valueRight::Number,
                            timeStep::Number = 10.0, cutOff::Int64 = 20000)
    
    RDV = model.bias
    elapsedNDT = 0
    ndtTimeSteps = round(model.nonDecisionTime ÷ timeStep)
    tRDV = Vector{Number}(undef, cutOff)
    valueDiff = model.d * (valueLeft - valueRight)

    # The values of the barriers can change over time.
    barrierUp = model.barrier ./ (1 .+ model.decay .* (0:cutOff-1))
    barrierDown = -model.barrier ./ (1 .+ model.decay .* (0:cutOff-1))

    for time in 0:cutOff-1
        tRDV[time + 1] = RDV

        # If the RDV hit one of the barriers, the trial is over.
        # Barrier decays only for decision related timesteps
        if abs(RDV) >= barrierUp[time - ndtTimeSteps]
            choice = RDV >= 0 ? -1 : 1
            RT =  time * timeStep
            trial = Trial(choice = choice, RT = RT, valueLeft = valueLeft, valueRight = valueRight)
            trial.RDV = tRDV[1:time + 1]
            return trial
        end

        # If the response time is higher than the cutoff, the trial is over.
        if time * timeStep >= cutOff
            choice = RDV >= 0 ? -1 : 1
            RT =  time * timeStep
            trial = Trial(choice = choice, RT = RT, valueLeft = valueLeft, valueRight = valueRight)
            trial.RDV = tRDV[1:time + 1]
            return trial
        end

        # Sample the change in RDV from the distribution.
        if elapsedNDT < ndtTimeSteps
            μ = 0
            elapsedNDT += 1
        else
            μ = valueDiff
        end

        RDV += rand(Normal(μ, model.σ))
    end

    choice = RDV >= 0 ? -1 : 1
    RT = cutOff * timeStep
    trial = Trial(choice = choice, RT = RT, valueLeft = valueLeft, valueRight = valueRight)
    trial.RDV = tRDV
    return trial
end

"""
    simulate_data(model::aDDM, stimuli, simulator_fn, simulator_args = (timeStep = 10.0, cutOff = 20000))

Simulate data using the model for the given stimuli.

# Arguments
- `model`: aDDM object.
- `stimuli`: Named tuple with `valueLeft` and `valueRight` specifying the values of options.
- `simulator_fn`: Name of the function that simulates a trial for the given model.
- `simulator_args`: Named tuple containing kwargs that should be fed to `simulator_fn`

# Returns
- Vector of Trial objects containing simulated data.
"""
function simulate_data(model::aDDM, stimuli, simulator_fn, simulator_args = (timeStep = 10.0, cutOff = 20000))
  
   # Check stimuli has the valueLeft and valueRight
  if !(:valueLeft in keys(stimuli))
    # throw(RuntimeError("valueLeft not specified in stimuli"))
    error("valueLeft not specified in stimuli")
  end

  if !(:valueRight in keys(stimuli))
    # throw(RuntimeError("valueRight not specified in stimuli"))
    error("valueRight not specified in stimuli")
  end

  # Extract valueLeft and valueRight from stimuli
  valueLefts = stimuli.valueLeft
  valueRights = stimuli.valueRight

  # BE: Custom extracts from stimuli
  sample_vectors = stimuli.sample_vector

  # Feed the model and the stimuli to the simulator function
  n = length(valueLefts) # length of stimuli
  SimData = Vector{Trial}(undef, n)

  # how does this define how many threads are used?
  # afaiu this needs to be specific *before* julia is started e.g. by `julia --threads 4`
  # @threads for i in 1:n 
  for i in 1:n 

    # The `simulator_args...` notation maps the NamedTuple to the kwargs of the simulator_fn
    # The named tuple `simulator_args` does not have to have all the kwargs
    # Additional kwargs can be specified before or after `simulator_args`
    SimData[i] = simulator_fn(
        ;model = model, 
        valueLeft = valueLefts[i], valueRight = valueRights[i], 
        sample_vector = sample_vectors[i],
        simulator_args...)
  end

  return SimData

end