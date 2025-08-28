
## Model diagnostics: likelihood profiles and retrospectives
## Authors: Raquel Ruiz Diaz, Maurice Goodman

library("nwfscDiag")
library("here")
library("r4ss")
library("parallel")

if (!exists("skip_finished")) skip_finished <- FALSE

source(here("R", "functions", "bridging_functions.R"))

# Directories
base_dir <- here("models", "2025 base model")
dir.create(diag_dir <- here("models", "diagnostics"))

# Rerun base model ----------------------------------------

# Duplicate to diagnostics directory
dir.create(base_diag_dir <- here(diag_dir, basename(base_dir)))

# Turn on ss_new files - required for likelihood profiles
model <- r4ss::SS_read(base_dir)
model$start$N_bootstraps <- 1
r4ss::SS_write(inputlist = model, dir = base_diag_dir, overwrite = TRUE)

ss3_exe <- here(base_diag_dir, set_ss3_exe(base_diag_dir, version = "v3.30.23.1"))

r4ss::run(base_diag_dir, exe = ss3_exe, extras = "-nohess", skipfinished = skip_finished)

# Likelihood profiles -------------------------------------

# Define a df which holds all profile parameter settings
profile_df <- data.frame(
  parameters   = c("NatM_uniform_Fem_GP_1",
                   "NatM_uniform_Mal_GP_1",
                   "SR_BH_steep",
                   "SR_LN(R0)"),
  low          = c(0.08, 0.08, 0.25, 9.8),
  high         = c(0.2, 0.2, 0.9, 11.4),
  step_size    = c(0.011, 0.011, 0.055, 0.2),
  param_space  = c("real", "real", "real", "real"),
  parlinenum   = c(5, 29, 51, 49),
  stringsAsFactors = FALSE
)

## Set up parallel
cl <- parallel::makeCluster(nrow(profile_df))
parallel::clusterEvalQ(cl, { library(nwfscDiag) }) # export diags package to cluster
parallel::clusterExport(cl, varlist = c("profile_df", "diag_dir", "ss3_exe", "base_diag_dir")) # export the settings df

## Run each profile in parallel
parLapply(cl = cl, X = 1:nrow(profile_df), function(x){

  get = get_settings_profile( parameters =  profile_df[x,"parameters"],
                              low =  profile_df[x,"low"],
                              high = profile_df[x,"high"],
                              step_size = profile_df[x,"step_size"],
                              param_space = profile_df[x,"param_space"])
  
  #Set up the model settings
  model_settings = get_settings(settings = list(
    base_name = basename(base_diag_dir),
    run = "profile", 
    profile_details = get
  ))
  
  if(model_settings$exe != ss3_exe) model_settings$exe <- ss3_exe
  
  # Apply additional settings to aid convergence
  model_settings$usepar <- TRUE # Use previous run estimates as starting vals
  model_settings$init_values_src <- 1 # Read starting vals from parameter file
  model_settings$parlinenum <- profile_df[x,"parlinenum"] # This refers to the line number that steepness is on in the ss3.par file
  model_settings$overwrite <- TRUE
  
   run_diagnostics(mydir = diag_dir, model_settings = model_settings)
  # 
})

parallel::stopCluster(cl)

# Retrospectives ------------------------------------------

model_settings_retros <- get_settings(
  settings = list(
    base_name = basename(base_diag_dir),
    run = "retro",
    verbose = TRUE,
    retro_yrs = -1:-5
  )
)

if(model_settings_retros$exe != ss3_exe) model_settings_retros$exe <- ss3_exe

run_diagnostics(mydir = diag_dir, model_settings = model_settings_retros)
