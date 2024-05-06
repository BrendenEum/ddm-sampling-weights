# Likelihood computation in ADDM.jl

In the [previous tutorial](https://addm-toolbox.github.io/ADDM.jl/dev/tutorials/01_getting_started/) we were not able to recover the true parameters used for the simulated data when using `stateStep = 0.1`. Reducing this to `stateStep = 0.01` corrected the recovery. In this tutorial we will walk through how parameter estimation in ADDM.jl works to explain the effect of this change.

## Brief overview of parameter estimation methods for sequential sampling models

How do we estimate parameters? We choose a measure to quantify the difference between observed/empirical data and data that would be generated



For sequential sampling models these can be ...[^1]

A very common metric in all kinds of applications is likelihood

What is the likelihood in the context of sequential sampling models? It is the probability of observing the endorsed choice *at the observed response time*. This second part is what makes these models powerful. This is what we mean by the "joint" modeling of choice and response times.

 There are a few ways of calculating this value for sequential sampling models:
- The analytical solution of the Wiener First Passage Time distribution
- Trialwise simulations
- Approximate Bayesian Computation
- Solving the Fokker Planck Equation

The likelihood functions in `ADDM.jl` use the last method.

Briefly, the FPE describes how a probability distribution changes over time. Since it is an expression of change, formally it is written as a partial differential equation. We'll skip the details of the math here but for an in depth dive, please see Shinn et al.

Here, we'll try to keep things intuitive. 

[ADD Gabi's supplementary figure here]

Ok so what is the effect of the discretization step sizes (in both time and space)

```@repl 2
using ADDM, CSV, DataFrames, DataFramesMeta
using Plots, StatsPlots, Random, Plots.PlotMeasures
Random.seed!(38435)

MyModel = ADDM.define_model(d = 0.007, σ = 0.03, θ = .6, barrier = 1, 
                       decay = 0, nonDecisionTime = 100, bias = 0.0)

data_path = "./data/" 
data = ADDM.load_data_from_csv(data_path * "stimdata.csv", data_path * "fixations.csv"; stimsOnly = true);

nTrials = 1400;

MyStims = (valueLeft = reduce(vcat, [[i.valueLeft for i in data[j]] for j in keys(data)])[1:nTrials], valueRight = reduce(vcat, [[i.valueRight for i in data[j]] for j in keys(data)])[1:nTrials]);

vDiffs = sort(unique([x.valueLeft - x.valueRight for x in data["1"]]));

MyFixationData = ADDM.process_fixations(data, fixDistType="fixation", valueDiffs = vDiffs);

MyArgs = (timeStep = 10.0, cutOff = 20000, fixationData = MyFixationData);

SimData = ADDM.simulate_data(MyModel, MyStims, ADDM.aDDM_simulate_trial, MyArgs);
```

We can look at a few things. 

Save intermediate likelihoods for all trials with stepSize = .1 vs .01 for the correct and incorrect parameters

```@repl 2
param_grid = [(d = 0.007, sigma = 0.03, theta = 0.6), (d = 0.007, sigma = 0.05, theta = 0.6)];

output_large = ADDM.grid_search(SimData, param_grid, ADDM.aDDM_get_trial_likelihood, Dict(:η=>0.0, :barrier=>1, :decay=>0, :nonDecisionTime=>100, :bias=>0.0), likelihood_args = (timeStep = 10.0, stateStep = 0.1), save_intermediate_likelihoods = true , intermediate_likelihood_path="./outputs/", intermediate_likelihood_fn="large_stateStep_likelihoods");

output_small = ADDM.grid_search(SimData, param_grid, ADDM.aDDM_get_trial_likelihood, Dict(:η=>0.0, :barrier=>1, :decay=>0, :nonDecisionTime=>100, :bias=>0.0), likelihood_args = (timeStep = 10.0, stateStep = 0.01), save_intermediate_likelihoods = true, intermediate_likelihood_path="./outputs/", intermediate_likelihood_fn="small_stateStep_likelihoods");
```


```@repl 2
fns = ["large", "small"];

trial_likelihoods_for_sigmas = DataFrame();
for fn in fns
  trial_likelihoods = DataFrame(CSV.File("./outputs/"* fn *"_stateStep_likelihoods.csv", delim=","))
  cur_tlfs = unstack(trial_likelihoods, :trial_num, :sigma, :likelihood)
  cur_tlfs[!, :stateStep] .= fn * " stateStep"
  trial_likelihoods_for_sigmas = vcat(trial_likelihoods_for_sigmas, cur_tlfs)
end
rename!(trial_likelihoods_for_sigmas, [Symbol(0.05), Symbol(0.03)]  .=> [:incorrect_sigma, :correct_sigma])

ax_lims = (minimum(vcat(trial_likelihoods_for_sigmas.incorrect_sigma, trial_likelihoods_for_sigmas.correct_sigma)), maximum(vcat(trial_likelihoods_for_sigmas.incorrect_sigma, trial_likelihoods_for_sigmas.correct_sigma)))

@df trial_likelihoods_for_sigmas scatter(:correct_sigma, :incorrect_sigma,
                                          xlabel = "Likelihoods for true parameters", 
                                          ylabel = "Likelihoods for incorrect parameters", 
                                          lim = ax_lims,
                                          group = :stateStep,
                                          m = (0.5, [:x :+], 4))
Plots.abline!(1, 0, line=:dash, color=:black, label="")

```

Pick a few trials where the likelihoods differ a lot between the correct and incorrect parameters. Use the debug option in the `aDDM_get_trial_likelihood` to plot the propogation of the probability distribution across timeSteps

```@repl 2
# make new column for the difference in likelihoods for correct vs incorrect sigma 
@transform!(trial_likelihoods_for_sigmas, :diff_likelihood = :incorrect_sigma - :correct_sigma)

# order by that difference column
@orderby(trial_likelihoods_for_sigmas, -:diff_likelihood)

# Pick top 4 trials (or maybe just one)
diff_trial_nums = [@orderby(trial_likelihoods_for_sigmas, -:diff_likelihood)[1,:trial_num]];

# extract these from the data
diff_trials = SimData[diff_trial_nums];
```

Plot probStates for each trial with small vs large stateStep for correct and incorrect model

```@repl 2
# 2 x 2 plot
# Rows are stepsize
# Cols are models
# Point is to show that likelihood value changes depending on stepsize
# Colors must match across the four plots
# Need a legend common to all
# Why are the prStates plots with small stepsize so dark?
# Because the values in each bin are very small. 
# They values in each bin are small because they are spread over 10 times as many bins.

correct_model = MyModel
incorrect_model = ADDM.define_model(d = 0.007, σ = 0.05, θ = .6, barrier = 1, 
                decay = 0, nonDecisionTime = 100, bias = 0.0)


# Use aDDM_get_trial_likelihood with debug = true to get probStates and probUp and 
_, prStates_cm_ls, probUpCrossing_cm_ls, probDownCrossing_cm_ls = ADDM.aDDM_get_trial_likelihood(;model = correct_model, trial = diff_trials[1], timeStep = 10.0, stateStep = 0.1, debug = true)

_, prStates_cm_ss, probUpCrossing_cm_ss, probDownCrossing_cm_ss = ADDM.aDDM_get_trial_likelihood(;model = correct_model, trial = diff_trials[1], timeStep = 10.0, stateStep = 0.01, debug = true)

_, prStates_im_ls, probUpCrossing_im_ls, probDownCrossing_im_ls = ADDM.aDDM_get_trial_likelihood(;model = incorrect_model, trial = diff_trials[1], timeStep = 10.0, stateStep = 0.1, debug = true)

_, prStates_im_ss, probUpCrossing_im_ss, probDownCrossing_im_ss = ADDM.aDDM_get_trial_likelihood(;model = incorrect_model, trial = diff_trials[1], timeStep = 10.0, stateStep = 0.01, debug = true)

likMax = maximum(vcat(probUpCrossing_cm_ls, probDownCrossing_cm_ls, probUpCrossing_cm_ss, probDownCrossing_cm_ss, probUpCrossing_im_ls, probDownCrossing_im_ls, probUpCrossing_im_ss, probDownCrossing_im_ss))
likelihoodLims = (0, likMax);
prStateLims = (0, 0.05);

p1 = state_space_plot(prStates_cm_ls, probUpCrossing_cm_ls, probDownCrossing_cm_ls, 10, 0.1, likelihoodLims, prStateLims);
p2 = state_space_plot(prStates_cm_ss, probUpCrossing_cm_ss, probDownCrossing_cm_ss, 10, 0.01, likelihoodLims, prStateLims);
p3 = state_space_plot(prStates_im_ls, probUpCrossing_im_ls, probDownCrossing_im_ls, 10, 0.1, likelihoodLims, prStateLims);
p4 = state_space_plot(prStates_im_ss, probUpCrossing_im_ss, probDownCrossing_im_ss, 10, 0.01, likelihoodLims, prStateLims);

plot_array = Any[];
push!(plot_array, p1);
push!(plot_array, p2);
push!(plot_array, p3);
push!(plot_array, p4);
plot(plot_array...)
```

[^1]: For a more detailed overview see *Shinn, M., Lam, N. H., & Murray, J. D. (2020). A flexible framework for simulating and fitting generalized drift-diffusion models. ELife, 9, e56938.*