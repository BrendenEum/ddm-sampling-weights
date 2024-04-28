# BRMS settings
.cc = 3
.iter = 6000
brm <- function(...)
  brms::brm(
    ...,
    iter = .iter,
    warmup = floor(.iter/2),
    chains = .cc,
    cores = .cc,
    seed = 4,
    silent = 1,
    file_refit = "on_change")