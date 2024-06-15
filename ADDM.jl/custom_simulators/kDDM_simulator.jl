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
function kDDM_simulate_trial(;model::ADDM.aDDM, fixationData::ADDM.FixationData, 
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
            compressed_value = (sample_vector[currFixLocation]/abs(sample_vector[currFixLocation])) * (abs(sample_vector[currFixLocation])^model.k)
            μ = model.d * compressed_value

            # Sample the change in RDV from the distribution.
            μ_new = μ #* ((1 + model.α) * (cumTimeStep + 1))
            σ_new = model.σ #* ((1 + model.α) * (cumTimeStep + 1))
            RDV += rand(Normal(μ_new, σ_new)) 
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

    trial = ADDM.Trial(choice = choice, RT = RT, valueLeft = valueLeft, valueRight = valueRight)
    trial.sample_vector = samplesSeen
    trial.fixItem = fixItem 
    trial.fixTime = fixTime 
    trial.fixRDV = fixRDV
    trial.uninterruptedLastFixTime = uninterruptedLastFixTime
    trial.RDV = tRDV
    return trial
end