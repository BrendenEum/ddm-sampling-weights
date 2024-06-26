# julia --project=/Users/brenden/Desktop/ddm-sampling-weights/ADDM.jl --threads=4
# include("analysis/helpers/parameter_recovery/parameter_recovery.jl")

#################################################################
# Libraries and settings
#################################################################
using ADDM
using CSV
using DataFrames
using DataFramesMeta, Distributed, LinearAlgebra, StatsPlots
using Random, Distributions, StatsBase
using Base.Threads
using Dates
Random.seed!(1337);
dataset = replace(read("analysis/helpers/utilities/currentDataset.R", String), "dataset <- " => "", "'" => "");

## Prep output folder
prdir = "analysis/output/temp/parameter_recovery/" * Dates.format(now(), "yyyy.mm.dd-H.M") * "/";
mkpath(prdir);

# ------------------------------------------------------------------------------------
# Things to change
nStimTrials = 300; # How many trials in your expdata?
simCount = 4; # How many simulations?
# ------------------------------------------------------------------------------------

## Settings (! ! !)
timeStep = 10.0; # Time step size (ms) for support of time dimension.
stateStep = 0.01; # State step size for support of RDV space.
simCutoff = 100000;


#################################################################
# Simulate
#################################################################

# Prep simulator function
include("/Users/brenden/Desktop/ddm-sampling-weights/ADDM.jl/custom_simulators/kDDM_simulator.jl")
simulator_fn = kDDM_simulate_trial;

# Prep simulation data
expdata = "data/processed_data/"*dataset*"/expsimdata.csv";
fixdata = "data/processed_data/"*dataset*"/fixsimdata.csv";
data = ADDM.load_data_from_csv(expdata, fixdata; stimsOnly=true);
MyStims = (
    valueLeft = reduce(vcat, [[i.valueLeft for i in data[j]] for j in keys(data)])[1:nStimTrials], 
    valueRight = reduce(vcat, [[i.valueRight for i in data[j]] for j in keys(data)])[1:nStimTrials],
    sample_vector = reduce(vcat, [[i.sample_vector for i in data[j]] for j in keys(data)])[1:nStimTrials]
);
MyFixData = ADDM.process_fixations(data, fixDistType="simple");

# Simulate
m = 1;
MyModel = ADDM.define_model(
    d = .004,
    σ = .06,
    θ = 1.0,
    bias = 0, 
    barrier = 1,
    decay = 0.0,
    nonDecisionTime = 0 # We fix NDT to the duration of the last stimulus on a trial-by-trial basis instead.
);
MyModel.k = .5;
MyArgs = (timeStep = timeStep, cutOff = simCutoff, fixationData = MyFixData);
SimData = ADDM.simulate_data(MyModel, MyStims, simulator_fn, MyArgs);

# Save model and simulation data
write(prdir*"model_$(m).txt", string(MyModel));

global simput = DataFrame();
for (i, cur_trial) in enumerate(SimData)
    # "parcode", "trial", "rt", "choice", "sample_vector"
    cur_beh_df = DataFrame(:trial => i, :choice => cur_trial.choice, :rt => cur_trial.RT, :sample_vector => cur_trial.sample_vector);
    global simput = vcat(simput, cur_beh_df);
end
CSV.write(prdir * "SimData_$(m).csv", simput);


#################################################################
# Recover
#################################################################

# Prep likelihood fn.
include("/Users/brenden/Desktop/ddm-sampling-weights/ADDM.jl/custom_likelihoods/kDDM_likelihood.jl");

# Prep parameter grid.
tmp = DataFrame(CSV.File("analysis/helpers/parameter_recovery/param_grid.csv", delim=","));
tmp.likelihood_fn .= "kDDM_likelihood";
param_grid = NamedTuple.(eachrow(tmp));

# Grid search.
fixed_params = Dict(:θ=>1.0, :η=>0.0, :barrier=>1, :decay=>0.0, :nonDecisionTime=>0.0);
output = ADDM.grid_search(
    SimData, param_grid, nothing, fixed_params; 
    likelihood_args = (timeStep = timeStep, stateStep = stateStep), 
    return_grid_nlls = true, return_trial_posteriors = false, return_model_posteriors = true
);

# Store outputs.
mle = output[:mle];
nll_df =  sort!(output[:grid_nlls]);
sort!(nll_df, :nll);
#trial_posteriors = output[:trial_posteriors];
model_posteriors = output[:model_posteriors];

# Attach names to the posteriors for each parameter combo.
combo_posteriors = DataFrame();
for (k, v) in model_posteriors
    cur_row = DataFrame([k])
    cur_row.posterior = [v]
    combo_posteriors = vcat(combo_posteriors, cur_row, cols=:union)
end;
sort!(combo_posteriors, :posterior, rev=true);

# Save.
CSV.write(prdir * "MLE_$(m).csv", mle);
CSV.write(prdir * "NLL_$(m).csv", nll_df);
CSV.write(prdir * "posteriors_$(m).csv", combo_posteriors);