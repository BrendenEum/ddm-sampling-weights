"""
    load_data_from_csv(expdataFileName, fixationsFileName; stimsOnly = false)

Load experimental data from two CSV files: an experimental data file and a
fixations file. Format expected for experimental data file: parcode, trial,
rt, choice, item_left, item_right. Format expected for fixations file:
parcode, trial, fix_item, fix_time.

# Arguments

## Positional
- `expdataFileName`: String, name of experimental data file.
- `fixationsFileName`: String, name of fixations file.
  - `parcode`: Subject identifier
  - `trial`: Trial number
  - `fix_item`: Fixation location. 0 = transition, 1 = left, 2 = right,
  3 = latency.
  - `fix_time`: Fixation duration.

## Keyword
- `stimsOnly`: Boolean, true if `expdataFileName` contains only stimuli info and
  no choice or rt info.
  
# Return
  A dict, indexed by subjectId, where each entry is a list of Trial
      objects.
"""
function load_data_from_csv(expdataFileName, fixationsFileName = nothing; stimsOnly = false)
    
    # Load experimental data from CSV file.
    try 
        df = DataFrame(CSV.File(expdataFileName, delim=","))
    catch
        print("Error while reading experimental data file " * expdataFileName)
        return nothing
    end
    
    df = DataFrame(CSV.File(expdataFileName, delim=","))
    
    if stimsOnly
      if (!("parcode" in names(df)) || !("trial" in names(df)) || !("item_left" in names(df)) || !("item_right" in names(df)))
        throw(error("Missing field in stims data file. Fields required: parcode, trial, item_left, item_right"))
      end
      cols = [:trial, :item_left, :item_right]
    else
      if (!("parcode" in names(df)) || !("trial" in names(df)) || !("rt" in names(df)) || !("choice" in names(df))
        || !("item_left" in names(df)) || !("item_right" in names(df)))
        throw(error("Missing field in experimental data file. Fields required: parcode, trial, rt, choice, item_left, item_right"))
      end
      cols = [:trial, :rt, :choice, :item_left, :item_right]
    end
    
    # Organize csv that was read in into a dictionary indexed by subject id's
    data = Dict()
    subjectIds = unique(df.parcode)
    for subjectId in subjectIds
        data[subjectId] = Trial[]
        parcode_df = df[df.parcode .== subjectId, cols]
        trialIds = unique(parcode_df.trial) 
        for trialId in trialIds
            trial_df = parcode_df[parcode_df.trial .== trialId, cols]
            itemLeft = trial_df.item_left[1]
            itemRight = trial_df.item_right[1]
            if stimsOnly
              push!(data[subjectId], Trial(choice = NaN, RT = NaN, valueLeft = itemLeft, valueRight = itemRight) ) 
            else
              push!(data[subjectId], Trial(choice = trial_df.choice[1], RT = trial_df.rt[1], valueLeft = itemLeft, valueRight = itemRight) ) 
            end
        end
    end
    
    # Add optional data here (reference-dependent values and amts and probabilities)
    if ( !("sample_vector" in names(df)) )
      throw(error("Missing field in experimental data file. Fields required: sample_vector."))
    end

    for subjectId in subjectIds
      parcode_df = df[df.parcode .== subjectId, :]
      trialIds = unique(parcode_df.trial)
      for (t, trialId) in enumerate(trialIds)
        trial_df = parcode_df[parcode_df.trial .== trialId, :]
        dataTrial = Matrix(trial_df)
        sample_vectorString = trial_df.sample_vector[1];
        split_string = split(sample_vectorString, ",");
        float_vector = [parse(Float64, str) for str in split_string];
        data[subjectId][t].sample_vector = float_vector;
      end
    end

    # Load fixation data from CSV file if specified.
    if fixationsFileName != nothing
      try
          df = DataFrame(CSV.File(fixationsFileName, delim=","))
      catch
          print("Error while reading fixations file " * fixationsFileName)
          return nothing
      end
        
      if (!("parcode" in names(df)) || !("trial" in names(df)) || !("fix_item" in names(df)) || !("fix_time" in names(df)))
          throw(error("Missing field in fixations file. Fields required: parcode, trial, fix_item, fix_time"))
      end
      
      # Add fixation data to the data dictionary indexed by subject id containing choice and response times
      # This adds the info into the dictionary only as the fixation locations and durations for each trial
      # It is not organized in any specific "FixationData" way yet (indexed by fixation number and value difference)
      subjectIds = unique(df.parcode)
      for subjectId in subjectIds
          if !(subjectId in keys(data))
              continue
          end
          parcode_df = df[df.parcode .== subjectId, [:trial, :fix_item, :fix_time]]
          trialIds = unique(parcode_df.trial)
          for (t, trialId) in enumerate(trialIds)
              trial_df = parcode_df[parcode_df.trial .== trialId, [:fix_item, :fix_time]]
              dataTrial = Matrix(trial_df)
              data[subjectId][t].fixItem = trial_df.fix_item
              data[subjectId][t].fixTime = trial_df.fix_time
          end
      end
    end
    

    data = Dict(string(subjectId) => trials for (subjectId, trials) in data)

    return data
end

"""
    convert_param_text_to_symbols(model)

Convert parameter names that are specified in text into greek/latex symbols. Used by `ADDM.grid_search`
"""
function convert_param_text_to_symbol(model)

  sym_dict = REPL.REPLCompletions.latex_symbols
  
  if model isa ADDM.aDDM
    for p in propertynames(model)
      v = getproperty(model, p)
      p = "\\".* String(p)
      if p in keys(sym_dict)
        s = Symbol(sym_dict[p])
        # Add/replace greek letter property with 
        setproperty!(model, s, v)
      end
    end
  end

  if model isa Dict
    for p in keys(model)
      v = model[p]
      p = "\\".* String(p)
      if p in keys(sym_dict)
        s = Symbol(sym_dict[p])
        # Add/replace greek letter property with 
        model[s] = v
      end
    end
  end

  return model
end

"""
Get stimuli from expdata to use in simulations
"""
function process_stimuli(data, nTrials)
  
  Stims = (
    valueLeft = reduce(vcat, [[i.valueLeft for i in data[j]] for j in keys(data)])[1:nTrials], 
    valueRight = reduce(vcat, [[i.valueRight for i in data[j]] for j in keys(data)])[1:nTrials], 
    LProb = reduce(vcat, [[i.LProb for i in data[j]] for j in keys(data)])[1:nTrials], 
    LAmt = reduce(vcat, [[i.LAmt for i in data[j]] for j in keys(data)])[1:nTrials], 
    RProb = reduce(vcat, [[i.RProb for i in data[j]] for j in keys(data)])[1:nTrials], 
    RAmt = reduce(vcat, [[i.RAmt for i in data[j]] for j in keys(data)])[1:nTrials]
  );
  
  return Stims
end

"""
Convert simulated data to behavioral and fixation dataframes
"""
function process_simulations(SimulatedData::Vector{ADDM.Trial}, Details::Bool = false)
  
  SimDataBehDf = DataFrame()
  SimDataFixDf = DataFrame()
  for (i, cur_trial) in enumerate(SimulatedData)
      # "parcode","trial","fix_time","fix_item"
      cur_fix_df = DataFrame(:fix_item => cur_trial.fixItem, :fix_time => cur_trial.fixTime)
      cur_fix_df[!, :parcode] .= 1
      cur_fix_df[!, :trial] .= i  
      SimDataFixDf = vcat(SimDataFixDf, cur_fix_df, cols=:union)
      # "parcode","trial","rt","choice","LProb","LAmt","RProb","RAmt"
      if Details
        cur_beh_df = DataFrame(
          :parcode => 1, :trial => i, :choice => cur_trial.choice, :rt => cur_trial.RT, 
          :LProb => cur_trial.LProb, :LAmt => cur_trial.LAmt, :RProb => cur_trial.RProb, :RAmt => cur_trial.RAmt
        )
      else
        cur_beh_df = DataFrame(
          :parcode => 1, :trial => i, :choice => cur_trial.choice, :rt => cur_trial.RT, 
          :valueLeft => cur_trial.valueLeft, :valueRight => cur_trial.valueRight
        )
      end
      
      SimDataBehDf = vcat(SimDataBehDf, cur_beh_df, cols=:union)
  end
  
  return [SimDataBehDf, SimDataFixDf]
end

"""
Convert trial_likelihoods to something that can be stored sensibly in a csv.
"""
function process_trial_likelihoods(trial_likelihoods::Dict)
  
  trial_posteriors_df = DataFrame()

  for (k,v) in trial_likelihoods
    cur_df = DataFrame(Symbol(i) => j for (i, j) in pairs(v))

    rename!(cur_df, :first => :trial_num, :second => :)

    # Unpack parameter info
    for (a, b) in pairs(k)
      cur_df[!, a] .= b
    end

    # Change type of trial num col to sort by
    cur_df[!, :trial_num] = [parse(Int, (String(i))) for i in cur_df[!,:trial_num]]

    sort!(cur_df, :trial_num)

    # trial_posteriors_df = vcat(trial_posteriors_df, cur_df, cols=:union)
    append!(trial_posteriors_df, cur_df, cols=:union)
  end

  return trial_posteriors_df

end