rm(list=ls())  # Clears environment
gc()  # Runs garbage collection

# Install r4ss
# devtools::install_github("https://github.com/r4ss/r4ss.git")

library("tidyverse")
library("r4ss")
library("here")

wd <- here()

files <- list.files(here(wd, "R", "functions"), full.names = TRUE)
lapply(files, source)

skip_finished <- FALSE
launch_html <- TRUE



#' Wrapper for r4ss::get_ss3_exe to check for, download, and return name of SS3 exe file
#' @param dir directory to install SS3 in
#' @param ... Other arguments to `r4ss::get_ss3_exe`
#'
#' @return Character string with name of downloaded SS3 exe (without extension)
set_ss3_exe <- function(dir, ...) {
  
  # Get and set filename for SS3 exe
  ss3_exe <- c("ss", "ss3")
  ss3_check <- vapply(ss3_exe, \(x) file.exists(file.path(dir, paste0(x, ".exe"))), logical(1))
  if (!any(ss3_check)) r4ss::get_ss3_exe(dir, ...)
  ss3_exe <- ss3_exe[which(vapply(ss3_exe, \(x) file.exists(file.path(dir, paste0(x, ".exe"))), logical(1)))]
  return(ss3_exe)
  
}

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