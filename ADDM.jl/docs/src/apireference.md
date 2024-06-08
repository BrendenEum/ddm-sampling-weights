# API Reference

## Core types

```@docs
ADDM.Trial
ADDM.aDDM
ADDM.define_model
```

## Fixation data

```@docs
ADDM.FixationData   
ADDM.process_fixations  
ADDM.convert_to_fixationDist  
```

## Data simulation

```@docs
ADDM.aDDM_simulate_trial
ADDM.DDM_simulate_trial
ADDM.simulate_data
```

## Likelihood computation

```@docs
ADDM.aDDM_get_trial_likelihood
ADDM.DDM_get_trial_likelihood
ADDM.compute_trials_nll
```

## Grid search

```@docs
ADDM.setup_fit_for_params
ADDM.get_trial_posteriors
ADDM.save_intermediate_likelihoods_fn
ADDM.match_param_grid_keys
ADDM.get_mle
ADDM.grid_search
```

## Marginal posteriors

```@docs
ADDM.marginal_posteriors
ADDM.marginal_posterior_plot
```

## Helpers

```@docs
ADDM.load_data_from_csv
ADDM.convert_param_text_to_symbol
```