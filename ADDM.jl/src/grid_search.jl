"""
    setup_fit_for_params(fixed_params, likelihood_fn, cur_grid_params, likelihood_fn_module=Main)

Return parameter container and likelihood function for given parameter combination.

# Arguments
- `fixed_params`: Model parameters that are fixed to a value and not fitted.
- `likelihood_fn`: Name of likelihood function.
- `cur_grid_params`: NamedTuple containing the parameter combination
- `likelihood_fn_module`: Default `Main`. Module where the likelihood function is defined.

# Returns
- `model`: Container holding parameter combination info.
- `likelihood_fn`: Likelihood function that computes trial likelihoods for a given parameter
  combination.

"""
function setup_fit_for_params(fixed_params, likelihood_fn, cur_grid_params, likelihood_fn_module = Main)
  
  model = ADDM.aDDM()
  for (k,v) in fixed_params setproperty!(model, k, v) end

  if likelihood_fn === nothing
    if :likelihood_fn in keys(cur_grid_params)
    likelihood_fn_str = cur_grid_params[:likelihood_fn]
      if (occursin(".", likelihood_fn_str))
      space, func = split(likelihood_fn_str, ".")
      likelihood_fn = getfield(getfield(Main, Symbol(space)), Symbol(func))
      else
      likelihood_fn = getfield(likelihood_fn_module, Symbol(likelihood_fn_str))
      end
    else
      println("likelihood_fn not specified or defined in param_grid")
    end
  end

  if !(cur_grid_params isa Dict)
    for (k,v) in pairs(cur_grid_params) setproperty!(model, k, v) end
  else
    for (k,v) in cur_grid_params setproperty!(model, k, v) end
  end

  # Make sure param names are converted to Greek symbols
  model = ADDM.convert_param_text_to_symbol(model)

  return model, likelihood_fn

end

"""
    get_trial_posteriors(param_grid, model_priors, trial_likelihoods)

Compute model posteriors after each trial given model priors and trialwise likelihoods.

# Arguments

- `param_grid`: Vector of NamedTuples defining parameter space.
- `model_priors`: Dictionary with parameter combinations as keys and prior model probability
  as values.
- `trial_likelihoods`: Nested dictionary with outer keys of parameter combinations, inner
  keys of trial numbers, and values of trial likelihoods.

# Returns 

- `trial_posteriors`: Nested dictionary with outer keys of parameter combinations, inner
  keys of trial numbers, and values of model posterior probabilities after each observation.

"""
function get_trial_posteriors(param_grid, model_priors, trial_likelihoods) 

  # Process trial likelihoods to compute model posteriors for each parameter combination
  nTrials = maximum(keys(trial_likelihoods[param_grid[1]]))
  nModels = length(param_grid)

  # Define posteriors as a dictionary with models as keys and Dicts with trial numbers keys as values
  trial_posteriors = Dict(k => Dict(zip(1:nTrials, zeros(nTrials))) for k in param_grid)

  if isnothing(model_priors)          
    model_priors = Dict(zip(keys(trial_likelihoods), repeat([1/nModels], outer = nModels)))
  end

  # Trialwise posterior updating. Cannot be parallelized.
  for t in 1:nTrials

    # Reset denominator p(data) for each trial
    denom = 0

    # Update denominator summing
    for comb_key in keys(trial_likelihoods)
      if t == 1
        # Changed the initial posteriors so use model_priors for first trial
        denom += (model_priors[comb_key] * trial_likelihoods[comb_key][t])
      else
        denom += (trial_posteriors[comb_key][t-1] * trial_likelihoods[comb_key][t])
      end
    end

    # Calculate the posteriors after this trial.
    for comb_key in keys(trial_likelihoods)
      if t == 1
        prior = model_priors[comb_key]
      else
        prior = trial_posteriors[comb_key][t-1]
      end
      trial_posteriors[comb_key][t] = (trial_likelihoods[comb_key][t] * prior / denom)
    end
  end

  return trial_posteriors
end

"""
    save_intermediate_likelihoods(trial_likelihoods_for_grid_params, cur_grid_params, save_path)

Write out trial likelihoods as soon as they are computed for a given parameter combination. Intended
  to be used when running a large parameter grid and worried that job might fail unexpectedly. Saved
  trial likelihoods can later be read in to compute posteriors if necessary.

# Arguments

- `trial_likelihoods_for_grid_params`: Dictionary with keys of trial numbers and values of likelihoods
  for `cur_grid_params`.
- `cur_grid_params`: parameter combination, for which the likelihoods are being saved. NamedTuple entry in 
  `param_grid`.
- `save_path`: Path to save the intermediate output. Default to `"./outputs"` which saves output to directory
  from which the function is run (creates it if needed). 
- `fn`: File name for the saved output. ".csv" will be appended to this string.
"""
function save_intermediate_likelihoods_fn(trial_likelihoods_for_grid_params, cur_grid_params, save_path="./outputs/", fn = "trial_likelihoods_int_save")
  
  # Process intermediate output
  cur_df = DataFrame(Symbol(i) => j for (i, j) in pairs(trial_likelihoods_for_grid_params))
        
  rename!(cur_df, :first => :trial_num, :second => :likelihood)

  # Unpack parameter info
  for (a, b) in pairs(cur_grid_params)
    cur_df[!, a] .= b
  end

  # Change type of trial num col to sort by
  cur_df[!, :trial_num] = [parse(Int, (String(i))) for i in cur_df[!,:trial_num]]

  sort!(cur_df, :trial_num)

  # Save intermediate output
  mkpath(save_path)

  # How to deal with grids that have different models with different parameter names
  # Check existing file's columns? Do it at param_grid level before it gets here?
  # Currently, dealing with it at param_grid level with `match_param_grid_keys`
  trial_likelihoods_path = save_path * fn * ".csv"
  CSV.write(trial_likelihoods_path, cur_df, writeheader = !isfile(trial_likelihoods_path), append = true)
end

"""
    match_param_grid_keys(param_grid)

If param_grid contains models with different parameter names, ensure all entries in 
  param_grid have the same names and assigns a "NA" if that parameter names does not exist for
  a given model.

# Arguments

- `param_grid`: Vector of NamedTuples with parameter names as keys and parameter values as values.
"""
function match_param_grid_keys(param_grid)
  param_keys = []
  param_key_update = 0

  # Get all keys in param_grid
  for i in param_grid
    cur_keys = collect(keys(i))
    if param_keys != cur_keys
      for j in cur_keys
        if !(j in param_keys)
          param_keys = vcat(param_keys, j)
        end
      end
      param_key_update += 1
    end
  end

  # Expand param_grid for each entry to have all keys
  if param_key_update > 1
    expanded_param_grid = []
    for i in param_grid
      cur_param_values = []
      for j in param_keys
        if j in keys(i)
          cur_param_values = vcat(cur_param_values, i[j])
        else
          cur_param_values = vcat(cur_param_values, "NA")
        end
      end
      cur_params = (;zip(param_keys, cur_param_values)...)
      expanded_param_grid = vcat(expanded_param_grid, cur_params)
    end
    return expanded_param_grid
  else
    return param_grid
  end

end

"""
    get_mle(all_nll, likelihood_args)

Extract maximum likelihood estimate from `all_nll`

# Arguments

- `all_nll`: Dictionary containing parameter combinations as keys and sum of negative log likelihoods
    as values.
- `likelihood_args`: NamedTuple containing step size info.

# Return

- `best_pars`: MLE amongst the parameter combinations tried in `all_nll` for step sizes specified in 
  `likelihood_args`
"""
function get_mle(all_nll, likelihood_args, fixed_params)

  best_fit_pars = argmin(all_nll)
  best_pars = Dict(pairs(best_fit_pars))
  best_pars = merge(best_pars, fixed_params)
  best_pars = ADDM.convert_param_text_to_symbol(best_pars)
  best_pars[:timeStep] = likelihood_args.timeStep
  best_pars[:stateStep] = likelihood_args.stateStep
  best_pars[:nll] = all_nll[best_fit_pars]

  return best_pars

end

"""
    grid_search(data, param_grid, likelihood_fn = nothing, 
                fixed_params = Dict(:θ=>1.0, :η=>0.0, :barrier=>1, :decay=>0, :nonDecisionTime=>0, :bias=>0.0); 
                likelihood_args = (timeStep = 10.0, stateStep = 0.01), 
                model_priors = nothing,
                likelihood_fn_module = Main,
                sequential_model = false,
                grid_search_exec = ThreadedEx(),
                compute_trials_exec = ThreadedEx(),
                return_grid_nlls = false,
                return_model_posteriors = false,
                return_trial_posteriors = false,
                save_intermediate_likelihoods = false,
                noise_param_name = "sigma")

Compute the likelihood of either observed or simulated data for all parameter combinations in `param_grid`.

# Arguments

## Required 

- `data`: Data for which the sum of negative log likelihoods will be computed for each trial.
  Should be a vector of `ADDM.Trial` objects.
- `param_grid`: Parameter combinations for which the sum of nll's for the `data` is 
  computed. Vector of NamedTuples. E.g.
  ```
 15-element Vector{@NamedTuple{d::Float64, sigma::Float64, theta::Float64, likelihood_fn::String}}:
  (d = 0.001, sigma = 0.01, theta = 0.12, likelihood_fn = "ADDM.aDDM_get_trial_likelihood")
  (d = 0.002, sigma = 0.01, theta = 0.12, likelihood_fn = "ADDM.aDDM_get_trial_likelihood")
  ...
 ```
- `likelihood_fn`: Name of likelihood function to be used to compute likelihoods. 
  The toolbox has `ADDM.aDDM_get_trial_likelihood` and `ADDM.DDM_get_trial_likelihood` defined.
  If comparing different generative processes then leave at default value of `nothing`
  and make sure to define a `likelihood_fn` in the `param_grid`.
- `fixed_params`: Default `Dict(:θ=>1.0, :η=>0.0, :barrier=>1, :decay=>0, :nonDecisionTime=>0, :bias=>0.0)`.
  Parameters required by the `likelihood_fn` that are not specified to vary across likelihood 
  computations.
- `likelihood_args`: Default `(timeStep = 10.0, stateStep = 0.01)`. Additional 
  arguments to be passed onto `likelihood_fn`. 

## Optional 

- `model_priors`: priors for each model probability if not assummed to be uniform. Should be
  specified as a `Dict` with values of probabilities matching the keys for the parameter combinations
  specified in `param_grid`.
- `likelihood_fn_module`: Default `Main`. Scope from which to pull the likelihood function. Default works
  for custom functions defined inline or in a script, as well as, the built-in functions.
- `sequential_model`: Boolean to specify if the model requires all data concurrently (e.g. RL-DDM). If `true` 
  likelihood computation for model cannot be multithreaded (though grid search still can be).
- `grid_search_exec`: Executor used by `FLoops.jl` to parallelize computation of nll for each parameter 
  combination over threads. Default is `ThreadedEx()`. Other options are `DistributedEx()` and `SequentialEx()`.
  See `FLoops.jl` documentation for more details.
- `compute_trials_exec`: Executor used by `FLoops.jl` to parallelize computation of each trial's likelihood over
  threads. Default is `ThreadedEx()`. Other options are `DistributedEx()` and `SequentialEx()`. See `FLoops.jl` 
  documentation for more details.
- `return_grid_nlls`: Default `false`. If true, will return a `DataFrame` containing the sum of nll's for 
  each parameter combination in the grid search.
- `return_model_posteriors`: Default `false`. If true, will return the posterior probability 
  for each parameter combination in `param_grid`.
- `return_trial_posteriors`: Default `false`. If true, will return the posterior probability 
  for each parameter combination in `param_grid` after each trial in `data`.  
- `save_intermediate_likelihoods`: Default `false`. If true, will crate a csv containing the likelihoods for each 
  trial after it is computed for a given parameter combination. Could be useful if doing a large parameter sweep 
  and are worried about the job terminating unexpectedly. Job could be restarted for parameter combinations, for 
  which the trial likelihoods have not been saved, instead of all parameter combinations. 
- `noise_param_name`: Default `"sigma"`. String specifying the name of the noise parameter in the model. Used 
  to check stability criterion for Forward Euler.

# Returns
- `output`: `Dict` with keys:
  - `best_pars`: `Dict` containing the parameter combination with the lowest nll.
  - `grid_nlls`: (Optional) `DataFrame` containing sum of nll's for each parameter combination.
  - `trial_posteriors`: (Optional) Posterior probability for each parameter combination after each trial.
  - `model_posteriors`: (Optional) Posterior probability for each parameter combination after all trials.

"""
function grid_search(data, param_grid, likelihood_fn = nothing, 
  fixed_params = Dict(:θ=>1.0, :η=>0.0, :barrier=>1, :decay=>0, :nonDecisionTime=>0, :bias=>0.0); 
  likelihood_args = (timeStep = 10.0, stateStep = 0.01), 
  model_priors = nothing,
  likelihood_fn_module = Main,
  sequential_model = false,
  grid_search_exec = ThreadedEx(),
  compute_trials_exec = ThreadedEx(),
  return_grid_nlls = false,
  return_model_posteriors = false,
  return_trial_posteriors = false,
  return_trial_likelihoods = false,
  save_intermediate_likelihoods = false,
  intermediate_likelihood_path= "./outputs/",
  intermediate_likelihood_fn= "trial_likelihoods_int_save",
  noise_param_name = "sigma")

  # Make sure param_grid has all param names in all entries
  param_grid = match_param_grid_keys(param_grid)

  # Indexed with model param information instead of param_grid rows using NamedTuple keys.
  # Defined with a specific length for performance.
  # Ref is an allocation for FLoops.jl
  n = length(param_grid)
  all_nll = Ref(Dict(zip(param_grid, zeros(n))))

  # compute_trials_nll returns a dict indexed by trial numbers 
  # so trial_likelihoods are initialized with keys as parameter combinations and values of empty dictionaries
  # Ref is an allocation for FLoops.jl
  n_trials = length(data)
  trial_likelihoods = Ref(Dict(k => Dict(zip(1:n_trials, zeros(n_trials))) for k in param_grid))


  ## Check if there are multiple likelihood_fn's
  ## Split param_grid for each likelihood_fn if there are multiple
  if :likelihood_fn in keys(param_grid[1])
    lik_fns = unique([i.likelihood_fn for i in param_grid])
    all_param_grids = [param_grid] # likelihood_fn defined in param_grid but there's only one
    if length(lik_fns) > 1
      all_param_grids = Vector{Any}(undef, length(lik_fns))
      for (i, cur_lik_fn) in enumerate(lik_fns)
        all_param_grids[i] = [p for p in param_grid if p.likelihood_fn == cur_lik_fn]
      end
    end
  else #if likelihood_fn not defined in param_grid
    all_param_grids = [param_grid]
  end

  #### START OF PARALLELIZABLE PROCESSES

  for cur_param_grid in all_param_grids

    @floop grid_search_exec for cur_grid_params in cur_param_grid

      ## Check stability criterion for the parameter combination
      unstable = !(((likelihood_args.timeStep/1000)/(likelihood_args.stateStep^2)) < 1/(cur_grid_params[Symbol(noise_param_name)]^2))
      if unstable
        println("dt/(dx^2) < 1/(σ^2) not satisfied. Try reducing timestep.")
        println("sigma = " * string(cur_grid_params[Symbol(noise_param_name)]))
        println("timeStep (dt) = " * string((likelihood_args.timeStep/1000)) * " s")
        println("stateStep (dx) = " * string(likelihood_args.stateStep))
      end

      # Give an update on where things run if running a big grid remotely
      if save_intermediate_likelihoods
        println(cur_grid_params)
        flush(stdout)
      end

      # Setup the parameter container and the likelihood function
      cur_model, cur_likelihood_fn = ADDM.setup_fit_for_params(fixed_params, likelihood_fn, cur_grid_params, likelihood_fn_module)

      if (return_model_posteriors || save_intermediate_likelihoods)
      # Trial likelihoods will be a dict indexed by trial numbers
        all_nll[][cur_grid_params], trial_likelihoods[][cur_grid_params] = ADDM.compute_trials_nll(cur_model, data, cur_likelihood_fn, likelihood_args; 
                    return_trial_likelihoods = true,  sequential_model = sequential_model, compute_trials_exec = compute_trials_exec)

        if save_intermediate_likelihoods
          save_intermediate_likelihoods_fn(trial_likelihoods[][cur_grid_params], cur_grid_params, intermediate_likelihood_path, intermediate_likelihood_fn)
        end
        
      else
        all_nll[][cur_grid_params] = compute_trials_nll(cur_model, data, cur_likelihood_fn, likelihood_args, sequential_model = sequential_model, compute_trials_exec = compute_trials_exec)
      end

    end
  end

  #### END OF PARALLELIZABLE PROCESSES

  # Begin collecting output
  output = Dict()
  output[:mle] = get_mle(all_nll[], likelihood_args, fixed_params)

  if return_grid_nlls
    # Add param info to all_nll
    all_nll_df = DataFrame()
    for (k, v) in all_nll[]
      row = DataFrame(Dict(pairs(k)))
      row.nll .= v
      # vcat can bind rows with different columns
      all_nll_df = vcat(all_nll_df, row, cols=:union)
    end

    output[:grid_nlls] = all_nll_df
  end

  if return_model_posteriors

    trial_posteriors = get_trial_posteriors(param_grid, model_priors, trial_likelihoods[])

    if return_trial_posteriors
      output[:trial_posteriors] = trial_posteriors
    end

    model_posteriors = Dict(k => trial_posteriors[k][n_trials] for k in keys(trial_posteriors))
    output[:model_posteriors] = model_posteriors

  end

  if return_trial_likelihoods
    output[:trial_likelihoods] = trial_likelihoods[]
  end

  return output

end