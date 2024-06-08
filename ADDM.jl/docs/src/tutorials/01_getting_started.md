# Getting started with ADDM.jl

In this tutorial we will introduce some of the core functionality of the toolbox. We will define an aDDM with specific parameters, simulate choice and response time using those parameters and recover the known parameters from the simulated data.

## Load package

We begin with loading the packages we'll use in this tutorial.

```@repl 1
using ADDM, CSV, DataFrames, DataFramesMeta
using Plots, StatsPlots, Random
Random.seed!(38435)
```

!!! note

    Note that the `CSV` and `DataFrames` modules must be loaded in addition to `ADDM`. These are dependencies for the `ADDM` module *but* the precompiled module gives access to these dependencies only in the scope of `ADDM`. In other words, `ADDM.load_data_from_csv` that requires both of these packages would still work but directly calling functions from these packages would not without importing these modules to the current scope.    


## Parameter recovery on simulated data

### Define model

The first component of the toolbox is a parameter container for the model class. This is a key-value pair mapping of parameter names to parameter values. It is a specific kind of dictionary of class `ADDM.aDDM`. We can create a model container using the `ADDM.define_model` function.

```@repl 1
MyModel = ADDM.define_model(d = 0.007, σ = 0.03, θ = .6, barrier = 1, 
                decay = 0, nonDecisionTime = 100, bias = 0.0)
```

### Define stimuli

The second ingredient to simulating data is to define stimuli. For the pre-defined model in the module, stimuli consist of values associated with the options over which a decision is made. The stimuli should eventually be arranged into a `NamedTuple` with required field names (case sensitive): `valueLeft` and `valueRight`. There are several ways of defining the stimuli within this constraints. Below are a few examples. 

**Option 1: Load stimuli with corresponding fixation data**

The toolbox comes with [some datasets](https://github.com/aDDM-Toolbox/ADDM.jl/tree/main/data) from published research. It also includes a function, `ADDM.load_data_from_csv()`, that can read in datasets stored in CSVs and wrangles it into a format expected by other functions.

`ADDM.load_data_from_csv()` expects columns `parcode`,`trial`, `rt` (optional), `choice` (optional), `item_left`, `item_right` in the CSVs and convert `item_left` and`item_right` to `valueLeft` and `valueRight`. It organizes both the behavioral and the fixation data as a dictionary of `ADDM.Trial` objects indexed by subject. 

Here, we are reading in empirical data that comes with the package but we will not be making use of the observed choices and response times. This is specified with the `stimsOnly` argument. The empirical data is only used to extract value difference information to index the fixation data correctly. The choices and response times will be simulated below based on the parameters we specified above.

```@repl 1
data_path = joinpath(dirname(dirname(pathof(ADDM))), "data/"); # hide
data = ADDM.load_data_from_csv(data_path * "stimdata.csv", data_path * "fixations.csv"; stimsOnly = true);
```

`data` is organized as a dictionary with keys corresponding to subject id's and values of arrays containing `ADDM.Trial`s for each subject. Since we are only interested in the values associated with the stimuli, we specify the number of trials we want to simulate (`nTrials`) and extract that many trials' value information from the data as `MyStims`.

```@repl 1
nTrials = 1400;
MyStims = (valueLeft = reduce(vcat, [[i.valueLeft for i in data[j]] for j in keys(data)])[1:nTrials], valueRight = reduce(vcat, [[i.valueRight for i in data[j]] for j in keys(data)])[1:nTrials]);
```

**Option 2: Read in from CSV**  

Stimuli can also be read in directly from a file. This approach is simpler to define only the stimuli but would require additional steps to define and organize fixation data.

```
fn = data_path * "rawstims.csv"
tmp = DataFrame(CSV.File(fn, delim=","))
MyStims = (valueLeft = tmp.valueLeft, valueRight = tmp.valueRight)
```

**Option 3: Create random stimuli**

Alternatively, one can simulate stimuli with random values. Similar to reading in stimulus values directly, this approach would also require additional steps to defne and organize fixation data.

!!! note

    If you're going to create random stimuli you should make sure to have value differences that correspond to what you plan to fit in for fixation data.

```
Random.seed!(38535)
MyStims = (valueLeft = randn(1000), valueRight = randn(1000))
```

### Define fixation data

The last ingredient to simulate data is fixation patterns. These are necessary because the distinguishing feature of the aDDM is its ability to use eyetracking data to account for attentional biases in choice behavior. Importantly, aDDM treats fixation data as exogenous. This means, that the model does not describe how the fixation patterns arise, but only takes them as given to examine their effects on choice behavior.

The toolbox has a specific structure for fixation data organized in the  [`FixationData`](https://addm-toolbox.github.io/ADDM.jl/dev/apireference/#Fixation-data) type. This type organizes empirical fixations to distributions conditional on fixation type (first, second etc.) and value difference.

First, we extract value difference information from the dataset to use in processing the fixations.

```@repl 1
vDiffs = sort(unique([x.valueLeft - x.valueRight for x in data["1"]]));
```

Then we summarize the empricial data from all subjects as distributions from which the model samples from depending on the value difference and the fixation type (1st, 2nd etc.) using `ADDM.process_fixations`.

```@repl 1
MyFixationData = ADDM.process_fixations(data, fixDistType="fixation", valueDiffs = vDiffs);
```

### Simulate data

Finally, we define additional arguments for the second component of the model, the trial simulator. Here, these are the fixation data, time step for simulations and the maximum length a trial is allowed (in ms). These arguments need to be specified as a `NamedTuple`, and must have at least two elements. Otherwise the function tries to apply `iterate` to the single element which would likely end with a  `MethodError`. In this example, we specify `timeStep` and `cutoff` in addition to the  only required argument without a default `fixationData` to avoid this.

```@repl 1
MyArgs = (timeStep = 10.0, cutOff = 20000, fixationData = MyFixationData);
```

Note that these are *positional* arguments for code efficiency.

```@repl 1
SimData = ADDM.simulate_data(MyModel, MyStims, ADDM.aDDM_simulate_trial, MyArgs);
```

### Recover parameters using a grid search

Now that we have simulated data with known parameters we can use the third component of the module, the likelihood function to invert the model and recover those parameters from the data.

The built-in optimization algorithm function for this is `ADDM.grid_search`. It computes the sum of negative log likelihood across all trials in the data, for each parameter combination specified in `param_grid`. The parameter space defined in `param_grid` is organized as an array of `NamedTuple`s indicating the parameter names and their specific values for each combination. For this toy example, the parameter space consists of 27 parameter combinations.

```@repl 1
fn = data_path * "addm_grid.csv";
tmp = DataFrame(CSV.File(fn, delim=","));
param_grid = NamedTuple.(eachrow(tmp))
```

Having defined the parameter space, we can compute the sum of negative log likelihoods (NLL) for each data point and select the parameter combination with the lowest NLL, which is equivalent to maximizing the likelihood. This combination of parameters is called the maximum likelihood estimate, or the MLE. `ADDM.grid_search` expects the data, the parameter space, the likelihood function and any fixed parameters for the model as its positional arguments. Additionaly, as a keyword argument, one can specify `likelihood_args` for values that should be passed onto the likelihood function. Here, we specify the `timeStep` and the `stateStep` for solving the Fokker-Planck Equation. The function returns an `output` dictionary with various components depending on additional arguments that are detailed in other tutorials and the API Reference.

```@repl 1
output = ADDM.grid_search(SimData, param_grid, ADDM.aDDM_get_trial_likelihood, Dict(:η=>0.0, :barrier=>1, :decay=>0, :nonDecisionTime=>100, :bias=>0.0); likelihood_args = (timeStep = 10.0, stateStep = 0.1), return_grid_nlls = true);

mle = output[:mle];
all_nll_df = output[:grid_nlls];
```

Below we display the sum of negative log likelihoods for each parameter combination.

```@repl 1
sort!(all_nll_df, [:nll])
```

!!! note

    You can save the data containing the negative log likelihood info for all parameter combinations you searched for. Make sure that you have mounted a local directory to your container if you're working through this tutorial in a docker container. The output path below is the one specified in the installation instructions. You should change it if you want to save your output elsewhere.

    ```
    output_path = '/home/jovyan/work/all_nll_df.csv'
    CSV.write(output_path, all_nll_df)
    ```

You might have noticed that the grid search did not identify the true parameters (`d = 0.007, σ = 0.03, θ = .6`) as the ones with the highest likelihood. This highlights the importance of choosing good stepsizes for the temporal and spatial discretization. Let's reduce the spatial step size and see if we can recover the corect parameter combination.

```@repl 1
my_likelihood_args = (timeStep = 10.0, stateStep = 0.01)

output = ADDM.grid_search(SimData, param_grid, ADDM.aDDM_get_trial_likelihood, Dict(:η=>0.0, :barrier=>1, :decay=>0, :nonDecisionTime=>100, :bias=>0.0), likelihood_args=my_likelihood_args);

mle = output[:mle];
mle
```

Success! Reducing the state step size was sufficient to recover the true parameter combination for the simulated dataset. 

Ok, but what happened there? That's what we detail in the [next tutorial](https://addm-toolbox.github.io/ADDM.jl/dev/tutorials/02_likelihood_computation/).
