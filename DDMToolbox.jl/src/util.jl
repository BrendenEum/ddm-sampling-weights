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
            global trial_df = parcode_df[parcode_df.trial .== trialId, cols]
            itemLeft = trial_df.item_left[1]
            itemRight = trial_df.item_right[1]
            sample_vector = trial_df.sample_vector[1]
            if stimsOnly
              push!(data[subjectId], Trial(choice = NaN, RT = NaN, valueLeft = itemLeft, valueRight = itemRight, samples = sample_vector) ) 
            else
              push!(data[subjectId], Trial(choice = trial_df.choice[1], RT = trial_df.rt[1], valueLeft = itemLeft, valueRight = itemRight, samples = sample_vector) ) 
            end
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