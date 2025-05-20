
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
  report = TRUE # Buld report
)

#' rstudioapi wrapper to run a job and wait until it finishes
#' @param path Path for R script to run
#' @param workingDir Working directory in which to run the job
#' @param wait If TRUE, suspend the host R session until job finishes
#' @param ... Additional arguments to `rstudioapi::jobRunScript`
run_job <- function(path, workingDir = here(), wait = TRUE, ...) {
  
  job_id <- rstudioapi::jobRunScript(path, workingDir = workingDir, ...); Sys.sleep(10)
  
  while(wait & rstudioapi::jobGetState(job_id) == "running") Sys.sleep(1)
  
  if (rstudioapi::jobGetState(job_id) == "failed") stop("job failed")
  
}

# Data Processing -----------------------------------------

# Not all data scripts are here - several need testing

if (jobs$data) {
  
  run_job(
    here("R", "catches.R"), 
    name = "process landings"
  )
  
  run_job(
    here("R", "commercial_comps_clean_expand.R"),
    name = "commerical comps"
  )
  
}

# Data & Model bridging -----------------------------------

if (jobs$models) {
  
  run_job(
    here("R", "data_bridging.R"),
    name = "data bridging"
  )
  
  run_job(
    here("R", "model_bridging.R"), 
    name = "model bridging"
  )
  
}

# Diagnostics ---------------------------------------------

if (jobs$diagnostics) {
  
  run_job(
    here("R", "bridging_plots.R"), 
    name = "model bridging plots"
  )
  
  run_job(
    here("R", "jitters.R"), 
    name = "jittering"
  )
  
  run_job(
    here("R", "AllSensitivityRuns.R"), 
    name = "senitivity runs",
    wait = FALSE
  )
  
  run_job(
    here("R", "Model_diagnostics.R"), 
    name = "model diagnostics"
  )
  
}

# Summary plots and tables --------------------------------

if (jobs$report_plots) {
  
  run_job(
    here("R", "decision_table.R"), 
    name = "decision table"
  )
  
  run_job(
    here("R", "report_tables.R"),
    name = "report tables"
  )
  
  run_job(
    here("R", "report_figures_paneled.R"),
    name = "paneled report figures"
  )
  
}

# Render report -------------------------------------------

if (jobs$report) {
  
  quarto::quarto_render(here("report", "SAR_PFMC_skeleton.qmd"))
  
}