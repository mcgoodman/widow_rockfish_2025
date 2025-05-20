
# Setup ---------------------------------------------------

library("here")
library("rstudioapi")

#' rstudioapi wrapper to run a job and wait until it finishes
#' @param path Path for R script to run
#' @param wait If TRUE, suspend the host R session until job finishes
#' @param ... Additional arguments to `rstudioapi::jobRunScript`
run_job <- function(path, wait = TRUE, ...) {
  
  job_id <- rstudioapi::jobRunScript(path, ...); Sys.sleep(10)
  
  while(wait & rstudioapi::jobGetState(job_id) == "running") Sys.sleep(1)
  
  if (rstudioapi::jobGetState(job_id) == "failed") stop("job failed")
  
}

# Data Processing -----------------------------------------

## Blank for now


# Data & Model bridging (sequential) ----------------------

run_job(
  here("R", "data_bridging.R"),
  name = "data bridging", 
  workingDir = here()
)

run_job(
  here("R", "model_bridging.R"), 
  name = "model bridging",
  workingDir = here()
)

# Diagnostics (can be parallel) ---------------------------

run_job(
  here("R", "jitters.R"), 
  name = "jittering", 
  workingDir = here()
)

run_job(
  here("R", "AllSensitivityRuns.R"), 
  name = "senitivity runs", 
  workingdir = here(), 
  wait = FALSE
)

run_job(
  here("R", "Model_diagnostics.R"), 
  name = "model diagnostics", 
  workingDir = here()
)

# Summaries (can be parallel) -----------------------------

run_job(
  here("R", "decision_table.R"), 
  name = "decision table",
  workingDir = here()
)

run_job(
  here("R", "report_tables.R"),
  name = "report tables", 
  workingdir = here()
)

run_job(
  here("R", "report_figures_paneled.R"),
  name = "paneled report figures", 
  workingdir = here()
)


# Render report -------------------------------------------

