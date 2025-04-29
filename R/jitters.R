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
jitter_dir <- here("models", "jitters")  # directory to house jitters, in case base model updates again

# Copy base model into jitter folder
copy_SS_inputs(dir_old = base_dir, dir_new = jitter_dir) 

# Set number of jitters and jitter fraction
njitters <- 3  # number of jitters to run
jitter_frac <- 0.1  # common value to use according to r4ss documentation, investigate more?

# Set exe
base_exe <- "ss3"  # name of exe (set_ss3_exe doesn't work on my windows computer...)


# Run base model ---------------------------------------------------------------
r4ss::run(
  dir = base_model_dir,
  exe = base_exe,
  skipfinished = FALSE,
  show_in_console = TRUE,
  verbose = TRUE,
  extras = "-nohess"
)

base <- SS_output(base_model_dir)


# Run jitters ------------------------------------------------------------------
# using r4ss, having issues installing nwfscDiag - make this parallel! check future::plan()
jitter_loglike <- jitter(
  dir = jitter_dir,
  Njitter = njitters,
  printlikes = TRUE,
  jitter_fraction = 0.1,  # this is the value suggested in r4ss documentation (https://rdrr.io/github/r4ss/r4ss/man/jitter.html), should look into more
  exe = base_exe,
  verbose = TRUE,
  extras = "-nohess"
)


# Compare likelihoods ----------------------------------------------------------
like_df <- data.frame(run = c("base", seq(1:njitters)), like = NA)  # data frame with run number and likelihood

# Put in base
like_df$like[1] <- base$likelihoods_used$values[1]  # has to be a way to specifically call the row "TOTAL"....
like_df$like[2:(njitters+1)] <- jitter_loglike

# Plot
ggplot(data = like_df, aes(x = run, y = like)) +
  geom_point() +
  geom_hline(yintercept = base$likelihoods_used$values[1]) +  # horizontal line at base ll
  xlab("log likelihood") +
  theme_bw()

ggsave(here("figures/diagnostics", "jitter_comparison.png"), width = 6, height = 5, units = "in")


