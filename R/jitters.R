# Run jitters for 2025 base model

# Set up -----------------------------------------------------------------------

parallel <- TRUE

# Load packages
library(tidyverse)
library(r4ss)
library(here)

# Source functions
source(here("R", "functions", "bridging_functions.R"))

# Set directories
base_dir <- here("models", "2025 base model")  # base model directory
jitter_dir <- here("models", "jitters")  # directory to house jitters

# Copy base model into jitter folder
copy_SS_inputs(dir.old = base_dir, dir.new = jitter_dir, overwrite = TRUE) 

# Set number of jitters and jitter fraction
njitters <- 100  # number of jitters to run
jitter_frac <- 0.1  # common value to use according to r4ss documentation (https://rdrr.io/github/r4ss/r4ss/man/jitter.html), investigate more?

# Set exe
base_exe <- "ss3"  # name of exe (set_ss3_exe doesn't work on my windows computer...)

if (parallel) {
  library(future)
  future::plan(future::multisession(workers = parallelly::availableCores(omit = 2)))
}

# Run base model ---------------------------------------------------------------

r4ss::run(
  dir = base_dir,
  exe = base_exe,
  skipfinished = FALSE,
  show_in_console = TRUE,
  verbose = TRUE,
  extras = "-nohess"
)

base <- SS_output(base_dir)

# Run jitters ------------------------------------------------------------------

# Using r4ss, having issues installing nwfscDiag - make this parallel! check future::plan()
# could use init_values_src - lets you decide whether to jitter from the par file, might be worth using if convergence issues
jitter_loglike <- r4ss::jitter(
  dir = jitter_dir,
  Njitter = njitters,
  printlikes = TRUE,
  jitter_fraction = jitter_frac,  
  exe = base_exe,
  verbose = TRUE,
  extras = "-nohess",
  skipfinished = FALSE,
  show_in_console = FALSE
)

saveRDS(jitter_loglike, here("models/jitters", "jitter_loglike.RDS"))
jitter_loglike <- readRDS(here("models/jitters", "jitter_loglike.RDS"))

# Set back to sequential processing
if (parallel) future::plan(future::sequential)

# Compare likelihoods ----------------------------------------------------------
like_df <- data.frame(run = seq(1:njitters), like = NA)  # data frame with run number and likelihood

base_like <- base$likelihoods_used$values[1]  # has to be a way to specifically call the row "TOTAL"....

like_df$like <- jitter_loglike

# Plot
ggplot(data = like_df, aes(x = run, y = like)) +
  geom_point() +
  geom_hline(yintercept = base_like) +  # horizontal line at base ll
  xlab("run") +
  theme_bw() +
  theme(axis.text.x = element_blank())

ggsave(here("figures/diagnostics", "jitter_comparison.png"), width = 6, height = 5, units = "in")

# Zoomed likelihood
ggplot(data = like_df %>% filter(like < 8000), aes(x = run, y = like)) +
  geom_point() +
  geom_hline(yintercept = base_like) +  # horizontal line at base ll
  xlab("run") +
  theme_bw() +
  theme(axis.text.x = element_blank())

ggsave(here("figures/diagnostics", "jitter_comparison_zoomed.png"), width = 6, height = 5, units = "in")


# See what likelihoods were below the base
run_summary <- data.frame(run = 1:njitters, loglike = jitter_loglike)
below_base <- run_summary %>%
  filter(loglike < base_like)
min(jitter_loglike)  # lowest loglikelihood of 7664.50 (others below are at 7664.52), base: 7664.96  (previous time: 7905.46 (base is 7912.2 for this run)


# Compare parameters and outputs for lower LL-----------------------------------
# Find lowest likelihood model(s)
min_run <- run_summary %>% filter(loglike == min(jitter_loglike))  # 6 runs that hit this minimum

# Read in and summarize model output for those minimum likelihood runs
min_mods <- SSgetoutput(
  dirvec = jitter_dir,
  keyvec = min_run$run,
  getcovar = FALSE
)

min_sum <- SSsummarize(min_mods, verbose = TRUE)

# Make comparison plots for the models that had the lowest likelihood
plot_dir <- here(jitter_dir, "plots", "min_mods_comp_plots")

SSplotComparisons(min_sum,
                  print = TRUE,
                  plotdir = plot_dir,
                  subplots = 1:20)


##### Compare one of the lowest likelihood models (since they all looked the same) to the base
base_min_sum <- SSsummarize(list(minLL = min_mods[[1]], base = base))

base_min_plot_dir <- here(jitter_dir, "plots", "base_min_comp")

# Make comparison plots
SSplotComparisons(base_min_sum,
                  print = TRUE,
                  plotdir = base_min_plot_dir)


# Look into parameter differences ----------------------------------------------
# Look at parameters of lowest LL runs
jitter_run_pars <- min_sum[["pars"]]
write.csv(jitter_run_pars, file = here(jitter_dir, "minLL_run_parameter_estimates.csv"), row.names = FALSE)

# Looks at parameters from base run compared to one of the lowest LL run
base_min_pars <- base_min_sum[["pars"]]
write.csv(base_min_pars, file = here(jitter_dir, "base_vs_minLL_parameter_estimates.csv"), row.names = FALSE)

# Investigate differences between min LL parms and base
base_min_pars_comp <- base_min_pars %>%
  mutate(perc_diff = (minLL-base)/base)

# Which have are more than 10% different?
perc_diff_cutoff <- 0.1
diff_pars <- base_min_pars_comp %>% filter(perc_diff >= perc_diff_cutoff | perc_diff <= -perc_diff_cutoff)
write.csv(diff_pars, file = here(jitter_dir, "base_vs_minLL_most_different_parameter_estimates.csv"), row.names = FALSE)

##### Save the par file from one of the lowest LL jitters to use for re-running the base
n_min_run <- which.min(jitter_loglike)
par_name <- paste("ss3.par_", n_min_run, ".sso", sep = "")

# Read in par file from best run
best_par <- SS_readpar_3.30(
  parfile = here(jitter_dir, par_name),
  datsource = here(jitter_dir, "2025widow.dat"),
  ctlsource = here(jitter_dir, "2025widow.ctl"),
  verbose = TRUE
)

# Save it as "ss3.par_best.sso"
SS_writepar_3.30(
  parlist = best_par,
  outfile = here(jitter_dir, "ss3.par_best.sso"),
  overwrite = TRUE,
  verbose = TRUE
)

# Find values for report -------------------------------------------------------
# Checked above that min of jitter_loglike is the same as the base like
# Find number of runs that reached the same minimum loglike (as the base)
minLLruns <- sum(jitter_loglike == min(jitter_loglike))

minLLruns_2 <- sum(jitter_loglike <= base_like + 2)  # what about within 2 likelihood units?

# Save to summarize
jitter_summary <- list(base_like = base_like,
                       min_jitter_like = min(jitter_loglike),
                       njitters_at_base = minLLruns,
                       njitters_within_2 = minLLruns_2)

saveRDS(jitter_summary, here("models/jitters", "jitter_summary.RDS"))



