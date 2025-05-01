rm(list=ls())  # Clears environment
gc()  # Runs garbage collection

# Install r4ss
# devtools::install_github("https://github.com/r4ss/r4ss.git")

library("tidyverse")
library("r4ss")
library("here")

source(here("R", "functions", "bridging_functions.R"))

wd <- here()

files <- list.files(here(wd, "R", "functions"), full.names = TRUE)
lapply(files, source)

skip_finished <- FALSE
launch_html <- TRUE

# Whether to re-run previously fitted models
rerun <- FALSE

# -------------------------------------------------------------
# 2025 Base Model
# -------------------------------------------------------------

## With new SS3 version ---------------------------------------

## Read in the base file
finBasedir <- here("models","2025 base model")

ss3_exe <- set_ss3_exe(finBasedir, version = "v3.30.23")

# run model
# With estimation and hessian it takes ~12 minutes
r4ss::run(
  dir = finBasedir,
  exe = ss3_exe,
  #extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = !rerun
)


# Get r4ss output
replist <- SS_output(
  dir = finBasedir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# Plots the results (store in the 'R_Plots' sub-directory)
SS_plots(replist, dir = finBasedir, printfolder = "R_Plots")

# -------------------------------------------------------------