# Run jitters for 2025 base model

# Set up -----------------------------------------------------------------------

if (!exists("rerun_base")) rerun_base <- FALSE
if (!exists("parallel")) parallel <- TRUE

# Load packages
library(tidyverse)
library(r4ss)
library(here)

# Source functions
source(here("R", "functions", "bridging_functions.R"))

# Set directories
# Jitter base model unless sourcing script has overridden
# Overidden by model_bridging.R so that jittering can be used on non-base model
if (!exists("base_dir")) base_dir <- here("models", "2025 base model")
jitter_dir <- here("models", "jitters")  # directory to house jitters

# Copy base model into jitter folder
copy_SS_inputs(dir.old = base_dir, dir.new = jitter_dir, overwrite = TRUE) 

# Set number of jitters and jitter fraction
if (!exists("njitters")) njitters <- 100  # number of jitters to run
jitter_frac <- 0.1  # common value to use according to r4ss documentation (https://rdrr.io/github/r4ss/r4ss/man/jitter.html), investigate more?

# Set exe
ss3_exe <- here(base_dir, set_ss3_exe(base_dir, version = "v3.30.23.1"))

if (parallel) {
  library(future)
  future::plan(future::multisession(workers = parallelly::availableCores(omit = 2)))
}

# Run base model ---------------------------------------------------------------

r4ss::run(
  dir = base_dir,
  exe = ss3_exe,
  skipfinished = !rerun_base,
  show_in_console = TRUE,
  verbose = TRUE,
  extras = "-nohess"
)

base <- SS_output(base_dir)

# Run jitters ------------------------------------------------------------------

dir.create(here("models", "jitters", "plots"))

# Using r4ss, having issues installing nwfscDiag - make this parallel! check future::plan()
# could use init_values_src - lets you decide whether to jitter from the par file, might be worth using if convergence issues
jitter_loglike <- r4ss::jitter(
  dir = jitter_dir,
  Njitter = njitters,
  printlikes = TRUE,
  jitter_fraction = jitter_frac,  
  exe = ss3_exe,
  verbose = TRUE,
  extras = "-nohess",
  skipfinished = FALSE,
  show_in_console = FALSE
)

saveRDS(jitter_loglike, here("models/jitters", "jitter_loglike.RDS"))

# Set back to sequential processing
if (parallel) future::plan(future::sequential)

# Compare likelihoods ----------------------------------------------------------

like_df <- data.frame(run = seq_len(njitters), nll = jitter_loglike, max_grad = NA)

# Loop over report files, extract gradients
rep_files <- paste0("Report", seq_len(njitters), ".sso")
for (i in seq_along(rep_files)) {
  replines <- readLines(here(jitter_dir, rep_files[i]), n = 15)
  conv_line <- replines[grepl("Convergence_Level", replines)]
  like_df$max_grad[i] <- as.numeric(
    gsub(" is_final_gradient", "", gsub("Convergence_Level: ", "", conv_line, fixed = TRUE), fixed = TRUE)
  )
}

base_nll <- base$likelihoods_used["TOTAL", "values"]

write.csv(like_df, here(jitter_dir, "jitter_loglike.csv"), row.names = FALSE)

dir.create(here("figures", "diagnostics"))

# Plot
like_df |> 
  ggplot(aes(x = run, y = nll)) +
  geom_point() +
  geom_hline(yintercept = base_nll) +  # horizontal line at base ll
  labs(x = "run", y = "negative log-likelihood") +
  theme_bw() +
  theme(axis.text.x = element_blank())

ggsave(here("figures/diagnostics", "jitter_comparison.png"), width = 6, height = 5, units = "in")

# Zoomed likelihood
like_df |> 
  mutate(gradient = c("< 0.01", "> 0.01")[1 + (max_grad > 0.01)]) |> 
  filter(nll <= quantile(nll, 0.9)) |> 
  ggplot(aes(x = run, y = nll, color = gradient)) +
  geom_point() +
  geom_hline(yintercept = base_nll) +  # horizontal line at base ll
  labs(x = "run", y = "negative log-likelihood") +
  theme_bw() +
  theme(axis.text.x = element_blank())

ggsave(here("figures/diagnostics", "jitter_comparison_zoomed.png"), width = 6, height = 5, units = "in")

# Compare parameters and outputs for lower LL-----------------------------------

# Find lowest likelihood model(s) among converged models
min_run <- like_df |> 
  filter(max_grad < 0.01) |> 
  filter(nll == min(nll))  # 6 runs that hit this minimum

# Read in and summarize model output for those minimum likelihood runs
min_mods <- SSgetoutput(
  dirvec = jitter_dir,
  keyvec = min_run$run,
  getcovar = FALSE
)

min_sum <- SSsummarize(min_mods, verbose = TRUE)

# Make comparison plots for the models that had the lowest likelihood
dir.create(plot_dir <- here(jitter_dir, "plots", "min_mods_comp_plots"), recursive = TRUE)

SSplotComparisons(min_sum, print = TRUE, plotdir = plot_dir, subplots = 1:20)

##### Compare one of the lowest likelihood models (since they all looked the same) to the base
base_min <- list(minLL = min_mods[[1]], base = base)
base_min_sum <- SSsummarize(base_min)

dir.create(base_min_plot_dir <- here(jitter_dir, "plots", "base_min_comp"), recursive = TRUE)

# Make comparison plots
SSplotComparisons(
  base_min_sum,
  print = TRUE,
  plotdir = base_min_plot_dir, 
  legendlabels = names(base_min)
)

# Look into parameter differences ----------------------------------------------
# Look at parameters of lowest LL runs
jitter_run_pars <- min_sum[["pars"]]
write.csv(jitter_run_pars, file = here(jitter_dir, "minLL_run_parameter_estimates.csv"), row.names = FALSE)

# Looks at parameters from base run compared to one of the lowest LL run
base_min_pars <- base_min_sum[["pars"]]
write.csv(base_min_pars, file = here(jitter_dir, "base_vs_minLL_parameter_estimates.csv"), row.names = FALSE)

# Investigate differences between min LL parms and base
base_min_pars_comp <- base_min_pars %>% mutate(perc_diff = (minLL - base) / base)

# Which have are more than 10% different?
perc_diff_cutoff <- 0.1
diff_pars <- base_min_pars_comp %>% filter(perc_diff >= perc_diff_cutoff | perc_diff <= -perc_diff_cutoff)
write.csv(diff_pars, file = here(jitter_dir, "base_vs_minLL_most_different_parameter_estimates.csv"), row.names = FALSE)

##### Save the par file from a converged run with the lowest NLL
n_min_run <- min_run$run[which.min(min_run$max_grad)]
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
minLLruns <- sum(like_df$nll == base_nll)

minLLruns_2 <- sum(like_df$nll <= base_nll + 2)  # what about within 2 likelihood units?

# Save to summarize
jitter_summary <- list(
  base_like = base_nll,
  min_jitter_like = min(like_df$nll[like_df$max_grad < 0.01]),
  njitters_at_base = minLLruns,
  njitters_within_2 = minLLruns_2, 
  n_converged_001 = sum(like_df$max_grad < 0.01)
)

saveRDS(jitter_summary, here("models/jitters", "jitter_summary.RDS"))



