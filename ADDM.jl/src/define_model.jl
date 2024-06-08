"""
    Trial(choice, RT, valueLeft, valueRight)

# Arguments
## Required keyword arguments
- `choice`: either -1 (for left item) or +1 (for right item).
- `RT`: response time in milliseconds.
- `valueLeft`: value of the left item.
- `valueRight`: value of the right item.

## Optional 
- `fixItem`: list of items fixated during the trial in chronological
    order; 1 correponds to left, 2 corresponds to right, and any
    other value is considered a transition/blank fixation.
- `fixTime`: list of fixation durations (in milliseconds) in
    chronological order.
- `fixRDV`: list of Float64 corresponding to the RDV values at the end of
    each fixation in the trial.
- `uninterruptedLastFixTime`: Int64 corresponding to the duration, in
    milliseconds, that the last fixation in the trial would have if it
    had not been interrupted when a decision was made.
- `RDV`: vector of RDV over time.

# Example

```julia
julia> t = Trial(choice = 1, RT = 2145, valueLeft = 1, valueRight = 3)
Trial(1, 2145, 1, 3, #undef, #undef, #undef, #undef, #undef)

julia> t.RT
2145

julia> t.uninterruptedLastFixTime
ERROR: UndefRefError: access to undefined reference
Stacktrace:
 [1] getproperty(x::Trial, f::Symbol)
   @ Base ./Base.jl:37
 [2] top-level scope
   @ REPL[4]:1

julia> t.uninterruptedLastFixTime = 189
189

julia> t
Trial(1, 2145, 1, 3, #undef, #undef, #undef, 189, #undef)
```
"""
mutable struct Trial
    
    # Required components of a Trial
    # They are keyword arguments without defaults which makes them required
    choice::Number
    RT::Number
    valueLeft::Number
    valueRight::Number

    # Optional components
    fixItem::Vector{Number}
    fixTime::Vector{Number}
    fixRDV::Vector{Number}
    uninterruptedLastFixTime::Number
    RDV::Vector{Number}
    dynamicValue::Vector{Number}
    LAmt::Number
    LProb::Number
    RAmt::Number
    RProb::Number
    vL_StatusQuo::Number
    vR_StatusQuo::Number
    vL_MaxMin::Number
    vR_MaxMin::Number
    vL_MinOutcome::Number
    vR_MinOutcome::Number

    # Incomplete initialization allows for defining optional components later
    # To create a Trial one must only provide the choice, RT and values
    Trial(;choice, RT, valueLeft, valueRight) = new(choice, RT, valueLeft, valueRight)
end

"""
Constructor for model definitions that will contain model parameter and parameter value
  mapping. Not intended to be used alone but as part of `define_model`

# Example

```julia
julia> MyModel = ADDM.aDDM()
aDDM(Dict{Symbol, Any}())

julia> MyModel.d = 0.005
0.005

julia> MyModel.σ = .06
0.06

julia> MyModel
aDDM(Dict{Symbol, Any}(:σ => 0.06, :d => 0.005))
```
"""
struct aDDM
  properties::Dict{Symbol, Any}
end
aDDM() = aDDM(Dict{Symbol, Any}())

Base.getproperty(x::aDDM, property::Symbol) = getfield(x, :properties)[property]
Base.setproperty!(x::aDDM, property::Symbol, value) = getfield(x, :properties)[property] = value
Base.propertynames(x::aDDM) = keys(getfield(x, :properties))

"""
    define_model(d, σ, θ = 1, η = 0, barrier = 1, decay = 0, nonDecisionTime = 0, bias = 0.0)

Create attentional drift diffusion model with parameters described in 
  Krajbich et al. (2010).

# Arguments 
## Required parameters
- `d`: Number, parameter of the model which controls the speed of
    integration of the signal.
- `σ`: Number, parameter of the model, standard deviation for the
    normal distribution.

## Optional parameters
- `θ`: Float64 Traditionally between 0 and 1, parameter of the model which controls
    the attentional discounting. Default at 1 makes it a ddm.
- `η`: Float64 Additive attentional enhancement the attentional discounting. 
    Default at 0 makes it a ddm.
- `barrier`: positive Int64, boundary separation in each direction from 0. Default at 1.
- `decay`: constant for linear barrier decay at each time step. Default at 0.
- `nonDecisionTime`: non-negative Number, the amount of time in
    milliseconds during which processes other than evidence accummulation occurs. 
    Default at 0.
- `bias`: Number, corresponds to the initial value of the relative decision value
    variable. Must be smaller than barrier.

# Todo
- Tests
- Change decay parameter to function instead of scalar

# Example

```julia
julia> MyModel = define_model(d = .006, σ = 0.05)
aDDM(Dict{Symbol, Any}(:nonDecisionTime => 0, :σ => 0.05, :d => 0.006, :bias => 0.0, :barrier => 1, :decay => 0, :θ => 1.0, :η => 0.0))
````

"""
function define_model(;d::Number, σ::Number, θ::Float64 = 1.0, η::Float64 = 0.0, barrier::Number = 1, 
  decay::Number = 0, nonDecisionTime::Number = 0, bias::Number = 0.0)
  
  # Required parameters
  m = aDDM()

  ## Requires definitions
  m.d = d # drift rate
  m.σ = σ # sampling noise

  ## Has default value
  m.θ = θ # multiplicative attentional discounting
  m.η = η # additive attentional enhancement
  m.barrier = barrier # threshold
  m.decay = decay # barrier decay
  m.nonDecisionTime = nonDecisionTime 
  m.bias = bias # starting point bias

  return m
end