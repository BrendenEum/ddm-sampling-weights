# Parameter estimation on empirical data

[Previously](https://addm-toolbox.github.io/ADDM.jl/dev/tutorials/01_getting_started/), we recovered known parameters on simulated data. But often, we do not know these parameters and instead work with empirical data. In this tutorial we will walk through how to organize empirical data to use the toolbox functions.

## Load packages

We begin with loading the modules for the tutorial.

```@repl 3
using ADDM, CSV, DataFrames, StatsPlots
```

## Read in data

Data in this tutorial are from 10 subjects in [Kraijbich et al (2010)](https://www.nature.com/articles/nn.2635). We will use the built-in data loading function `ADDM.load_data_from_csv` that expects a behavioral file with columns `parcode, trial, rt, choice, item_left, item_right` and fixations file with columns `parcode, trial, fix_item, fix_time`.

If your data is not organized in this way you could either preprocess it so it does or you can read in the data however you want and reshape it with Julia to ensure it is organized as a dictionary of `Trial` objects *indexed by subject/parcode*. A `Trial` looks like

```
ADDM.Trial(1, 1474.0, -5, 5, Number[3, 0, 1, 0, 2, 0], Number[270.0, 42.0, 246.0, 62.0, 558.0, 296.0], #undef, #undef, #undef)
```  

where the first element is choice (-1 for left, +1 for right), second element is response time in ms, third is value of left option, fourth is value of right option. Fixation data is specified in the fourth and fifth elements as fixation location (1 for left, 2 for right) and fixation duration (in ms) respectively. The remaning elements currently set to `#undef` can be ignored. These are for debugging/examining the relative decision value when simulating trials.


```@repl 3
data_path = joinpath(dirname(dirname(pathof(ADDM))), "data/") # hide
krajbich_data = ADDM.load_data_from_csv(data_path * "Krajbich2010_behavior.csv", data_path * "Krajbich2010_fixations.csv")
```
!!! note

    Note the organization of data. It is a dictionary where the keys are subject identifiers and values are arrays of `ADDM.Trial` objects.

    

## Grid search

Now that we have loaded our data, we define the parameter space over which we'll search to determine the best combination for each subject. We'll use a grid of 64 parameter combinations with `d` in {0.0001, 0.00015, 0.0002, 0.00025}, `μ` in {80, 100, 120, 140}, `θ` in {0.3, 0.5, 0.7, 0.9}  and `σ = d*μ`   

```@repl 3
fn = data_path * "Krajbich_grid.csv";
tmp = DataFrame(CSV.File(fn, delim=","));
param_grid = NamedTuple.(eachrow(tmp))
```

Since the dataset contains multiple subjects and we want to compute the best parameters for each subject, we loop through each subject's dataset and collect the estimated parameters in a single data frame for each subject. This is sufficiently fast for this small example but see the parallelization [tutorial](https://addm-toolbox.github.io/ADDM.jl/dev/tutorials/06_parallelization.md/) on how to do this with larger datasets and parameter spaces.

```@repl 3
all_nlls = DataFrame();
subj_mles = Dict();

for k in keys(krajbich_data)
  cur_subj_data = krajbich_data[k]
  
  output = ADDM.grid_search(cur_subj_data, param_grid, ADDM.aDDM_get_trial_likelihood, Dict(:η=>0.0, :barrier=>1, :decay=>0, :nonDecisionTime=>0, :bias=>0.0), return_grid_nlls = true)

  subj_mles[k] = output[:mle]
  
  # Add subject id
  output[:grid_nlls][!, "parcode"] .= k

  append!(all_nlls, output[:grid_nlls])
  
end;
```

To view best parameter estimates for each subject we can look at the `subj_mles` data frame, to which the output of `ADDM.grid_search` was pushed for each subject.

```@repl 3
subj_mles
```

As an example visualization below we plot variability in the negative log likelihoods for each parameter combination for each subject. This is not a plot that is typically used for any model diagnostics. The intention is only to show that the likelihood function did indeed compute different values for different parameter combinations.

```@repl 3
wide_nll_df = unstack(all_nlls, :parcode, :nll);
select!(wide_nll_df, Not([:d, :sigma, :theta]));
colnames = names(wide_nll_df);
colnames = string.("subj-", colnames);
N = length(colnames);

@df wide_nll_df histogram(cols(1:N); layout=grid(2,5), legend=false, title=permutedims(colnames), frame=:box, titlefontsize=11, c=:blues, bins = 20, size=(1800,1000), xrotation = 45)

savefig("plot_2_1.png"); nothing # hide
```
![plot](plot_2_1.png)