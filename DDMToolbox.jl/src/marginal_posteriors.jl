"""
    marginal_posteriors(posteriors_dict, two_d_marginals)

Compute the marginal posterior distributions for the fitted parameters specified in `param_grid`.

# Arguments

## Required 

- `posteriors_dict`: Dictionary of posterior model probabilities. Keys of this dictionary are 
  the parameter combinations specified in `param_grid`. Values are the posterior probabilties 
  after accounting for each observation.
- `two_d_marginals`: Boolean. Whether to compute posteriors to plot heatmaps of posteriors.
  Default is false.

# Returns
- Vector of `DataFrame`s. If `two_d_marginals` is false, return only dataframes containing
  posteriors for each parameter. Otherwise, also includes posteriors for pairwise combinations of 
  parameters as well.

"""
function marginal_posteriors(posteriors_dict; two_d_marginals = false)

  posteriors_df = DataFrame()

  for (k, v) in posteriors_dict
    cur_row = DataFrame([k])
    cur_row.posterior = [v]
    posteriors_df = vcat(posteriors_df, cur_row, cols=:union)
  end;

  par_names = names(posteriors_df)[names(posteriors_df) .!= "posterior"]
  
  if two_d_marginals
    par_combs = combinations(par_names, 2)
    out = Vector{}(undef, (length(par_names)+length(par_combs)))
  else
    out = Vector{}(undef, length(par_names))
  end

  # this is only for single parameters, diagonal plots
  for (i,n) in enumerate(par_names)
    gdf = groupby(posteriors_df, n)
    combdf = combine(gdf, :posterior => sum)
    out[i] = combdf
  end

  if two_d_marginals
    l = length(par_names)
    for (j,c) in enumerate(par_combs)
      gdf = groupby(posteriors_df, c)
      combdf = combine(gdf, :posterior => sum)
      out[l + j] = combdf
    end
  end

  return out

end

"""
    marginal_posterior_plot

This plot type shows the posteriors for each parameter individually,
    as well as the posterior probabilities of pairwise combinations.  

The input is an array of dataframes resulting from `ADDM.marginal_posteriors`
  with the third positional argument set to true.

```
best_pars, nll_df, model_posteriors = ADDM.grid_search(subj_data, ADDM.aDDM_get_trial_likelihood, param_grid, 
    Dict(:η=>0.0, :barrier=>1, :decay=>0, :nonDecisionTime=>0, :bias=>0.0), 
    likelihood_args=my_likelihood_args, 
    return_model_posteriors = true)

ADDM.marginal_posteriors(param_grid, model_posteriors, true)
```

Recipe modified from 
https://github.com/JuliaPlots/StatsPlots.jl/blob/master/src/corrplot.jl
"""
@userplot Marginal_Posterior_Plot

recipetype(::Val{:marginal_posterior_plot}, args...) = Marginal_Posterior_Plot(args)

function update_ticks_guides(d::KW, labs, i, j, n)
    d[:xguide] = (i == n ? _cycle(labs, j) : "")
    d[:yguide] = (j == 1 ? _cycle(labs, i) : "")
end

@recipe function f(mpp::Marginal_Posterior_Plot)
    # Wrangle input data of marginal posteriors
    mps = mpp.args[1]
    n = 0
    for i in mps
      if length(names(i)) == 2
        n += 1
      end
    end
    mps1 = mps[1:n]
    mps2 = mps[n+1:length(mps)]

    # Get labels
    labs = []
    for i in mps1
      append!(labs, names(i))
    end
    labs = unique(labs)
    labs = [i for i in labs if i != "posterior_sum"]

    # Specify layout
    g = grid(n, n)
    indices = zeros(Int8, (n, n))
    s = 1
    # Make upper triangle blank
    for i = 1:n, j = 1:n
      isblank = i < j
      g[i, j].attr[:blank] = isblank
      if !isblank
        indices[i, j] = s
        s += 1
      end
    end

    link := :x  
    layout := g
    legend := false
    foreground_color_border := nothing
    margin := 1mm
    titlefont := font(11)
    xrotation := 25

    title = get(plotattributes, :title, "")
    title_location = get(plotattributes, :title_location, :center)
    title := "" # does this over-write user-specific titles? No. It gets overwritten later if needed.

    # barplots for individual parameters on the diagonal
    for i = 1:n
        @series begin
            if title != "" && title_location === :left && i == 1
                title := title
            end
            seriestype := :bar
            subplot := indices[i, i]
            grid := false
            xformatter --> ((i == n) ? :auto : (x -> ""))
            yformatter --> ((i == 1) ? :auto : (y -> ""))
            update_ticks_guides(plotattributes, labs, i, i, n)
            # data that will be plotted using the seriestype
            vx = view(mps1[i], :, 1) # param column
            vy = view(mps1[i], :, 2) # posterior_sum column
            vx, vy
        end
    end

    # heatmaps below diagonal
    for j = 1:n
        for i = 1:n
            j == i && continue
            subplot := indices[i, j]
            update_ticks_guides(plotattributes, labs, i, j, n)
            if i > j
                # heatmaps below diagonal
                @series begin
                    seriestype := :heatmap
                    xformatter --> ((i == n) ? :auto : (x -> ""))
                    yformatter --> ((j == 1) ? :auto : (y -> ""))

                    # Reshape data for heatmap
                    cur_mp2 = popfirst!(mps2)
                    vx = sort(unique(view(cur_mp2, :, 1)))
                    vy = sort(unique(view(cur_mp2, :, 2)))
                    vz = fill(NaN, size(vy, 1), size(vx, 1))
                    for k in eachindex(vx), l in eachindex(vy)
                      cur_row = subset(cur_mp2, 1 => a -> a .== vx[k],  2 => b -> b .== vy[l])
                      if nrow(cur_row) > 0
                        vz[l, k] = cur_row.posterior_sum[1]
                      end
                    end
                    vx, vy, vz
                end
            end
        end
    end
  end