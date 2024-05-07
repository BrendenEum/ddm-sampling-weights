# include("analysis/helpers/parameter_recovery/parameter_recovery.jl")

#############
# Libraries and settings
#############
using ADDM
using CSV
using DataFrames
using Random, Distributions, StatsBase
using Base.Threads
using Dates
Random.seed!(1337);
dataset = replace(read("analysis/helpers/utilities/currentDataset.R", String), "dataset <- " => "", "'" => "");

## Prep output folder
prdir = "analysis/output/temp/parameter_recovery/" * Dates.format(now(), "yyyy.mm.dd-H.M") * "/";
mkpath(prdir);

## Settings (! ! !)
simCount = 4; # How many simulations?
timeStep = 10.0; # Time step size (ms) for support of time dimension.
stateStep = .01; # State step size for support of RDV space.
simCutoff = 100000;


#############
# Simulate
#############

## Prep simulation data
expdata = "data/processed_data/"*dataset*"/expsimdata.csv";
fixdata = "data/processed_data/"*dataset*"/fixsimdata.csv";
data = ADDM.load_data_from_csv(expdata, fixdata; stimsOnly=true);
nTrials = 300;
MyStims = (
    valueLeft = reduce(vcat, [[i.valueLeft for i in data[j]] for j in keys(data)])[1:nTrials], 
    valueRight = reduce(vcat, [[i.valueRight for i in data[j]] for j in keys(data)])[1:nTrials],
    sample_vector = reduce(vcat, [[i.sample_vector for i in data[j]] for j in keys(data)])[1:nTrials]
);
MyFixData = ADDM.process_fixations(data, fixDistType="simple");

## Simulate
#Threads.@threads for m in 1:simCount
MyModel = ADDM.define_model(
    d = .007, #sample([.005, .007, .009]),
    σ = .05, #sample([.03, .05, .07]),
    θ = 0.0,
    bias = 0, #sample([-.1, 0, .1]),
    barrier = 1,
    decay = 0.0,
    nonDecisionTime = 100
);
prettyModel = [MyModel.d, MyModel.σ, MyModel.bias, MyModel.nonDecisionTime];
MyArgs = (timeStep = timeStep, cutOff = simCutoff, fixationData = MyFixData);
SimData = ADDM.simulate_data(MyModel, MyStims, ADDM.aDDM_simulate_trial, MyArgs);

## Save model and simulation data
write(prdir*"model.txt", string(prettyModel));

global simput = DataFrame();
for (i, cur_trial) in enumerate(SimData)
    # "parcode","trial","rt","choice","sample_vector"
    cur_beh_df = DataFrame(:trial => i, :choice => cur_trial.choice, :rt => cur_trial.RT, :sample_vector => cur_trial.sample_vector);
    global simput = vcat(simput, cur_beh_df, cols=:union);
end
CSV.write(prdir * "SimData.csv", simput);
#end


#############
# Recover
#############

fn = "analysis/helpers/parameter_recovery/param_grid.csv";
tmp = DataFrame(CSV.File(fn, delim=","));
param_grid = NamedTuple.(eachrow(tmp));

fixed_params = Dict(:θ=>0.0, :η=>0.0, :barrier=>1, :decay=>0, :nonDecisionTime=>100);
output = ADDM.grid_search(SimData, param_grid, ADDM.aDDM_get_trial_likelihood, fixed_params; likelihood_args = (timeStep = timeStep, stateStep = stateStep), return_grid_nlls = true);
