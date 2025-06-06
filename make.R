
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
    here("R", "length_weight.R"), # Runs
    name = "length-weight parameters"
  )
  
  run_job(
    here("R", "ASHOP_composition.R"), # Runs
    name = "process ASHOP comps"
  )
  
  run_job(
    here("R", "commercial_comps_clean_expand.R"), # Runs
    name = "expand commercial comps"
  )
  
  run_job(
    here("R", "catches.R"), # Runs
    name = "process landings"
  )
  
  run_job(
    here("R", "WCGOP_discard_data_preparation.R"), # Runs
    name = "process WCGOP discards"
  )
  
  run_job(
    here("R", "NWFSCCombo_age_length_comps.R"), # Runs
    name = "process WCGBTS comps"
  )
  
}

# Data & Model bridging -----------------------------------

if (jobs$models) {
  
  run_job(
    here("R", "data_bridging.R"), # Runs
    name = "data bridging"
  )
  
  run_job(
    here("R", "model_bridging.R"), # Runs
    name = "model bridging"
  )
  
}

# Diagnostics ---------------------------------------------

if (jobs$diagnostics) {
  
  run_job(
    here("R", "bridging_plots.R"), # Runs
    name = "model bridging plots"
  )
  
  run_job(
    here("R", "jitters.R"), # Runs
    name = "jittering"
  )
  
  run_job(
    here("R", "AllSensitivityRuns.R"), # Runs
    name = "sensitivity runs",
    wait = FALSE
  )
  
  run_job(
    here("R", "Model_diagnostics.R"), # Runs
    name = "model diagnostics"
  )
  
}

# Summary plots and tables --------------------------------

if (jobs$report_plots) {
  
  run_job(
    here("R", "decision_table.R"), # Runs
    name = "decision table"
  )
  
  run_job(
    here("R", "report_tables.R"), # Runs
    name = "report tables"
  )
  
  run_job(
    here("R", "report_figures_paneled.R"), # Runs
    name = "paneled report figures"
  )
  
  run_job(
    here("R", "age_length_comp_plots.R"), # Runs
    name = "age / length composition plots"
  )

}

# Render report -------------------------------------------

if (jobs$report) {
  
  quarto::quarto_render(
    here::here("report", "SAR_PFMC_skeleton.qmd"), 
    as_job = TRUE
  )
  
}