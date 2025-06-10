
# Dependencies --------------------------------------------

if (!require("remotes")) {
  install.packages("remotes")
  library("remotes")
}

# R packages and associated repositories
pkgs <- list(
  CRAN = c(
    "tidyverse", "parallel", "future", "parallelly","future.apply", "here", "readxl", 
    "magick", "data.table", "ggpubr", "cowplot", "flextable", "testthat"
  ), 
  GitHub = c(
    "r4ss" = "r4ss/r4ss",
    "pacfintools" = "pfmc-assessments/pacfintools",
    "nwfscSurvey" = "pfmc-assessments/nwfscSurvey",
    "nwfscDiag" = "pfmc-assessments/nwfscDiag",
    "PEPtools" = "pfmc-assessments/PEPtools"
  )
)

# Install packages from CRAN
pkgs_cran_new <- pkgs$CRAN[!(pkgs$CRAN %in% installed.packages()[,"Package"])]
if(length(pkgs_cran_new)) install.packages(pkgs_cran_new)

# Install packages from GitHub
pkgs_gh_new <- pkgs$GitHub[!(names(pkgs$GitHub) %in% installed.packages()[,"Package"])]
if(length(pkgs_gh_new)) sapply(pkgs_gh_new, remotes::install_github)

# Setup ---------------------------------------------------

library("here")
library("rstudioapi")
library("quarto")

# Toggles for running script types
jobs <- list(
  data = FALSE, # Process data
  models = TRUE, # Run bridging models
  diagnostics = TRUE, # Run diagnostics (jitters, sensitivities)
  report_plots = TRUE, # Build report plots and tables
  report = TRUE # Build report
)

# Toggles for in-script settings
rerun_base = FALSE # Rerun base model in diagnostic scripts
launch_html = FALSE # Launch html exploration from SS_plots
parallel = TRUE # Run jitters in parallel (multiple scripts can be parallelized via jobs)
skip_finished = FALSE # skip finished runs within scripts

#' rstudioapi wrapper to run a job and wait until it finishes
#' @param path Path for R script to run
#' @param workingDir Working directory in which to run the job
#' @param importEnv Whether to import the global environment (required for global settings)
#' @param wait If TRUE, suspend the host R session until job finishes
#' @param ... Additional arguments to `rstudioapi::jobRunScript`
run_job <- function(path, workingDir = here(), importEnv = TRUE, wait = TRUE, ...) {
  
  job_id <- rstudioapi::jobRunScript(path, workingDir = workingDir, ...); Sys.sleep(10)
  
  while(wait & rstudioapi::jobGetState(job_id) == "running") Sys.sleep(1)
  
  if (rstudioapi::jobGetState(job_id) == "failed") stop("job failed")
  
}

# Data Processing -----------------------------------------

# Several data scripts are missing from this section

if (jobs$data) {
  
  run_job(
    here("R", "data_length_weight.R"),
    name = "length-weight parameters"
  )
  
  run_job(
    here("R", "data_ASHOP_composition.R"),
    name = "process ASHOP comps"
  )
  
  run_job(
    here("R", "data_commercial_comps.R"),
    name = "expand commercial comps"
  )
  
  run_job(
    here("R", "data_landings.R"),
    name = "process landings"
  )
  
  run_job(
    here("R", "data_WCGOP_discards.R"),
    name = "process WCGOP discards"
  )
  
  run_job(
    here("R", "data_discard_lengths.R"),
    name = "process discard length comps"
  )
  
  run_job(
    here("R", "data_WCGBTS_comps.R"),
    name = "process WCGBTS comps"
  )
  
}

# Data & Model bridging -----------------------------------

if (jobs$models) {
  
  run_job(
    here("R", "models_data_bridging.R"),
    name = "model data bridging"
  )
  
  run_job(
    here("R", "models_parameter_bridging.R"),
    name = "model parameter bridging"
  )
  
}

# Diagnostics ---------------------------------------------

if (jobs$diagnostics) {
  
  run_job(
    here("R", "diagonstics_jitters.R"),
    name = "jittering"
  )
  
  run_job(
    here("R", "diagnostics_sensitivities.R"),
    name = "sensitivity runs",
    wait = FALSE
  )
  
  run_job(
    here("R", "diagnostics_profiles_retros.R"),
    name = "likelihood profiles and retrospectives"
  )
  
}

# Summary plots and tables --------------------------------

if (jobs$report_plots) {
  
  run_job(
    here("R", "plots_bridging.R"),
    name = "model bridging plots"
  )
  
  run_job(
    here("R", "plots_report_figures_paneled.R"),
    name = "paneled report figures"
  )
  
  run_job(
    here("R", "plots_age_length.R"),
    name = "age / length composition plots"
  )
  
  run_job(
    here("R", "tables_decision.R"),
    name = "decision table"
  )
  
  run_job(
    here("R", "tables_report.R"),
    name = "report tables"
  )

}

# Render report -------------------------------------------

if (jobs$report) {
  
  quarto::quarto_render(
    here::here("report", "SAR_PFMC_skeleton.qmd"), 
    as_job = TRUE
  )
  
}