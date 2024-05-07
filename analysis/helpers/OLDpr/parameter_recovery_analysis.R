######################################################
# Preamble
######################################################

rm(list=ls())
set.seed(4)
library(tidyverse)
library(plotrix)
library(gridExtra)
library(ggpubr)
library(ggsci)
library(readr)
library(latex2exp)

#------------- Things you should edit at the start -------------
simCount = 20 # How many simulated datasets per model-condition?
date_folder = "2024.04.02.15.51" # yyyy.mm.dd.H.M of the results you want to look at.
colors = list(Gain="Green4", Loss="Red3")
#---------------------------------------------------------------

codedir = getwd()
datadir = file.path("../../outputs/temp/parameter_recovery", date_folder)
figdir = datadir
optdir = file.path("../plot_options/")
source(file.path(optdir, "GainLossColorPalette.R"))
source(file.path(optdir, "MyPlotOptions.R"))

aDDM_folder = file.path(datadir, "aDDM")
AddDDM_folder = file.path(datadir, "AddDDM")
RaDDM_folder = file.path(datadir, "RaDDM")


######################################################
# Load Data
######################################################

getRecoveryData = function(folder) {
  gain_compare = list()
  loss_compare = list()
  gain_posterior = list()
  loss_posterior = list()
  
  for (i in 1:simCount) {
    gain_compare[[i]] = read.csv(file = file.path(folder, paste0("Gain_modelcomparison_", i, ".csv")))
    loss_compare[[i]] = read.csv(file = file.path(folder, paste0("Loss_modelcomparison_", i, ".csv")))
    gain_posterior[[i]] = read.csv(file = file.path(folder, paste0("Gain_modelposteriors_", i, ".csv")))
    loss_posterior[[i]] = read.csv(file = file.path(folder, paste0("Loss_modelposteriors_", i, ".csv")))
    gain_compare[[i]]$sim = i
    loss_compare[[i]]$sim = i
    gain_posterior[[i]]$sim = i
    loss_posterior[[i]]$sim = i
  }
  gc = do.call("rbind", gain_compare)
  lc = do.call("rbind", loss_compare)
  gp = do.call("rbind", gain_posterior)
  lp = do.call("rbind", loss_posterior)
  
  gc$condition = "Gain"
  lc$condition = "Loss"
  gp$condition = "Gain"
  lp$condition = "Loss"
  compare = rbind(gc, lc)
  posteriors = rbind(gp, lp)
  
  compare$likelihood_fn = factor(
    compare$likelihood_fn,
    levels=c("aDDM_likelihood","AddDDM_likelihood","RaDDM_likelihood"),
    labels=c("aDDM","AddDDM","RaDDM")
  )
  posteriors$likelihood_fn = factor(
    posteriors$likelihood_fn,
    levels=c("aDDM_likelihood","AddDDM_likelihood","RaDDM_likelihood"),
    labels=c("aDDM","AddDDM","RaDDM")
  )
  
  return(list(compare = compare, posteriors = posteriors))
}

aDDM_results = getRecoveryData(aDDM_folder)
AddDDM_results = getRecoveryData(AddDDM_folder)
RaDDM_results = getRecoveryData(RaDDM_folder)


######################################################
# Model Recovery
######################################################

## Clean model recovery data

# Binary for if the fitting process matchese the data generating process
aDDM_results$compare$sameprocess = factor(aDDM_results$compare$likelihood_fn=="aDDM", levels=c(T,F))
AddDDM_results$compare$sameprocess = factor(AddDDM_results$compare$likelihood_fn=="AddDDM", levels=c(T,F))
RaDDM_results$compare$sameprocess = factor(RaDDM_results$compare$likelihood_fn=="RaDDM", levels=c(T,F))

aDDM_results$compare$generating = "aDDM"
AddDDM_results$compare$generating = "AddDDM"
RaDDM_results$compare$generating = "RaDDM"

data_compare = do.call("rbind", list(aDDM_results$compare, AddDDM_results$compare, RaDDM_results$compare))
data_compare$generating = factor(
  data_compare$generating, 
  levels=c("aDDM","AddDDM","RaDDM"),
  labels=c("aDDM Simulations","AddDDM Simulations","RaDDM Simulations")
)

## Plot model recovery
plt = ggplot(data_compare, aes(x=likelihood_fn, y=posterior_sum)) +
    myPlot + 
    
    geom_hline(yintercept=.33, color="lightgrey") +
    #geom_violin(aes(fill=condition, alpha=sameprocess), color=NA) +
    geom_boxplot(aes(fill=condition, alpha=sameprocess), width=.4) +
    geom_dotplot(binaxis="y", stackdir="center", dotsize=1, fill="white") +
    
    labs(
      y = "Posterior Model Probability",
      x = "Model",
      fill = "Condition"
    ) +
    scale_y_continuous(breaks=c(0, .33, .67, 1)) +
    scale_alpha_manual(values = c(.85, .25), guide = "none") +
    facet_grid(rows=vars(condition), cols=vars(generating)) +
    theme(
      strip.text.x = element_text(size = 20),
      strip.background = element_blank(),
      strip.text.y = element_blank(),
      panel.spacing = unit(1, "lines"),
      legend.position = c(.225,.36)
    )
plot(plt)
ggsave(file.path(figdir, "ModelRecovery.pdf"), plot=plt, width = 12, height = 5)


######################################################
# Parameter Recovery
######################################################

## Clean and renomalize posteriors

aDDM_post = aDDM_results$posteriors[aDDM_results$posteriors$likelihood_fn=="aDDM",]
AddDDM_post = AddDDM_results$posteriors[AddDDM_results$posteriors$likelihood_fn=="AddDDM",]
RaDDM_post = RaDDM_results$posteriors[RaDDM_results$posteriors$likelihood_fn=="RaDDM",]

# Correct posteriors by renormalizing them within a specific model.
correctPosteriors = function(data) {
  for (i in 1:simCount) {
    data = data %>%
      group_by(condition, sim) %>%
      mutate(
        corr_posterior = posterior/sum(posterior)
      )
  }
  return(data)
}

aDDM_post = correctPosteriors(aDDM_post)
AddDDM_post = correctPosteriors(AddDDM_post)
RaDDM_post = correctPosteriors(RaDDM_post)

## Get Marginal Posteriors for each generatingProcess-condition-simulation-parameter (of interest)

# Calculate marginal posterior for a specific variable within a condition-simulation.
calculateMarginal = function(data) {
  output = data %>%
    group_by(likelihood_fn, condition, sim, variable, value) %>%
    summarize(
      value = first(value),
      posterior = sum(corr_posterior)
    )
  return(output)
}

d_pdata = data.frame()
sigma_pdata = data.frame()
theta_pdata = data.frame()
eta_pdata = data.frame()
bias_pdata = data.frame()
ref_pdata = data.frame()
#decay_pdata = data.frame()
for (post in list(aDDM_post, AddDDM_post, RaDDM_post)) {
  d_p = post %>% mutate(variable="d", value=d) %>% calculateMarginal()
  sigma_p = post %>% mutate(variable="sigma", value=sigma) %>% calculateMarginal()
  theta_p = post %>% mutate(variable="theta", value=theta) %>% calculateMarginal()
  eta_p = post %>% mutate(variable="eta", value=eta) %>% calculateMarginal()
  bias_p = post %>% mutate(variable="bias", value=bias) %>% calculateMarginal()
  ref_p = post %>% mutate(variable="reference", value=reference) %>% calculateMarginal()
  #decay_p = post %>% mutate(variable="decay", value=decay) %>% calculateMarginal()
  d_pdata = rbind(d_pdata, d_p)
  sigma_pdata = rbind(sigma_pdata, sigma_p)
  theta_pdata = rbind(theta_pdata, theta_p)
  eta_pdata = rbind(eta_pdata, eta_p)
  bias_pdata = rbind(bias_pdata, bias_p)
  ref_pdata = rbind(ref_pdata, ref_p)
  #decay_pdata = rbind(decay_pdata, decay_p)
}

pdata = do.call("rbind", list(d_pdata, sigma_pdata, theta_pdata, eta_pdata, bias_pdata, ref_pdata))#, decay_pdata))
pdata$variable = factor(
  pdata$variable,
  levels = c("d","sigma","theta","eta","bias","decay", "reference"),
  labels = c("d","sigma","theta","eta","bias","decay", "reference")
)
pdata$value = factor(pdata$value)

## Get true parameters for each generatingProcess-condition-simulation

pdata$truth = NA
for (row in 1:nrow(pdata)) {
  
  genProc = pdata$likelihood_fn[row]
  condition = pdata$condition[row]
  simulation = pdata$sim[row]
  variable = pdata$variable[row]
  if (genProc=="aDDM") {folder=aDDM_folder; tInd=1} 
  else if (genProc=="AddDDM") {folder=AddDDM_folder; tInd=1} 
  else if (genProc=="RaDDM") {folder=RaDDM_folder; tInd=0} 
  else {print("Generating Process is f**ked.")}
  
  x = read.table(file.path(folder, paste0(condition, "_model_", simulation, ".txt")))
  d = parse_number(x$V10)
  sigma = parse_number(x$V7)
  if (tInd==1) {theta = parse_number(x$V22); eta = parse_number(x$V25); reference = 0} 
  else if (tInd==0) {theta = parse_number(x$V25); eta = parse_number(x$V28); reference = parse_number(x$V16)}
  bias = parse_number(x$V13)
  decay = parse_number(x$V19)
  
  if (variable == "d") {pdata$truth[row]=d}
  else if (variable == "sigma") {pdata$truth[row]=sigma}
  else if (variable == "theta") {pdata$truth[row]=theta}
  else if (variable == "eta") {pdata$truth[row]=eta}
  else if (variable == "bias") {pdata$truth[row]=bias}
  else if (variable == "reference") {pdata$truth[row]=reference}
  #else if (variable == "decay") {pdata$truth[row]=decay}
}
pdata$truth = factor(pdata$truth)

## Plot marginal posteriors

for (likelihood_fn in c("aDDM", "AddDDM", "RaDDM")){
  for (sim in 1:simCount) {
    
    if (likelihood_fn %in% c("aDDM", "RaDDM")) {
      pd = pdata[pdata$sim==sim & pdata$likelihood_fn==likelihood_fn & pdata$variable!="eta",]  
    }
    else if (likelihood_fn %in% c("AddDDM")) {
      pd = pdata[pdata$sim==sim & pdata$likelihood_fn==likelihood_fn & pdata$variable!="theta",]  
    }
    
    plt = ggplot(pd, aes(x=value, y=posterior)) +
      myPlot +
      geom_hline(yintercept=.5, color="lightgrey") +
      
      geom_bar(aes(fill=condition), stat="identity", alpha=.7) +
      geom_vline(aes(xintercept=truth, group=condition), linewidth=3.5, color="black", linetype="dashed") +
      
      labs(
        y = "Posterior Probability" #\\sigma
      ) +
      facet_grid(rows=vars(condition), cols=vars(variable), scales="free", space="free") +
      scale_y_continuous(breaks=c(0, .5, 1), expand=c(0,0)) +
      theme(
        axis.title.x=element_blank(),
        strip.text.x = element_text(size = 20),
        strip.background = element_blank(),
        strip.text.y = element_blank(),
        panel.spacing = unit(1, "lines")
      )
    
    fn = paste0("Sim", sim, "_MarginalPosteriors.pdf")
    ggsave(file.path(datadir, likelihood_fn, fn), plot=plt, width = 20.5, height = 5.25)
  }
}