# Run jitters for 2025 base model

# Set up -----------------------------------------------------------------------
# Load packages
library(tidyverse)
library(r4ss)
#library(nwfscDiag)
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
# using r4ss, having issues installing nwfscDiag - make this parallel! check future::plan()
jitter_loglike <- jitter(
  dir = jitter_dir,
  Njitter = njitters,
  printlikes = TRUE,
  jitter_fraction = jitter_frac,  
  exe = base_exe,
  verbose = TRUE,
  extras = "-nohess",
  skipfinished = FALSE,
  show_in_console = TRUE
)
# could use init_values_src - lets you decide whether to jitter from the par file, might be worth using if convergence issues

saveRDS(jitter_loglike, here("models/jitters", "jitter_loglike.RDS"))


# Compare likelihoods ----------------------------------------------------------
like_df <- data.frame(run = seq(1:njitters), like = NA)  # data frame with run number and likelihood

base_like <- base$likelihoods_used$values[1]  # has to be a way to specifically call the row "TOTAL"....

like_df$like <- jitter_loglike

# Plot
ggplot(data = like_df, aes(x = run, y = like)) +
  geom_point() +
  geom_hline(yintercept = base_like) +  # horizontal line at base ll
  xlab("log likelihood") +
  theme_bw() +
  theme(axis.text.x = element_blank())

ggsave(here("figures/diagnostics", "jitter_comparison.png"), width = 6, height = 5, units = "in")


# See what likelihoods were below the base
run_summary <- data.frame(run = 1:njitters, loglike = jitter_loglike)
below_base <- run_summary %>%
  filter(loglike < base_like)
min(jitter_loglike)  # lowest loglikelihood of 7905.46 (base is 7912.2 for this run)

