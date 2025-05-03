##################################################
### WIDOW ROCKFISH ASSESSMENT UPDATE
### MODEL DIAGNOSTICS: RETROS AND LIKELIHOODS
### using nwfscDiag
#################################################

## Load libraries
library(adnuts)
library(renv)
renv::init()
library(r4ss)
library(nwfscSurvey)

#install.packages("remotes")
#remotes::install_github("pfmc-assessments/nwfscDiag")
library(nwfscDiag)
library(here)

## Set Directory location
directory <- here::here("models")
base_model_name <- "2025_base_model"
exe_dir<- here::here("models/2025_base_model")

r4ss::get_ss3_exe(dir = here::here("models/model_bridging", "2025_base_model"))
exe_loc <- here::here(exe_dir, 'ss_osx.exe')

## Diagnostics
profiles <- list(
  list(
    name        = "SR_BH_steep",
    low         = 0.25,
    high        = 0.90,
    step_size   = 0.05,
    param_space = "real",
    parlinenum  = 57
  ),
  list(
    name        = "NatM_uniform_Fem_GP_1",
    low         = 0.08,
    high        = 0.20,
    step_size   = 0.01,
    param_space = "real",
    parlinenum  = 5
  ),
  list(
    name        = "SR_LN(R0)",
    low         = 9.5,
    high        = 11.5,
    step_size   = 0.25,
    param_space = "real",
    parlinenum  = 55
  )
)

# Single function to run everything
run_all_diagnostics <- function(retro_years = -1:-5, profiles_list = profiles) {
  # 1) retrospectives
  retro_settings <- get_settings(
    settings = list(
      base_name = base_model_name,
      exe       = exe_loc,
      run       = "retro",
      verbose   = TRUE,
      retro_yrs = retro_years
    )
  )
  run_diagnostics(mydir = directory, model_settings = retro_settings)
  
  # 2) likelihood profiles
  for (prof in profiles_list) {
    # build the grid
    grid <- get_settings_profile(
      parameters  = prof$name,
      low         = prof$low,
      high        = prof$high,
      step_size   = prof$step_size,
      param_space = prof$param_space
    )
    
    # get model settings for this profile
    prof_settings <- get_settings(
      mydir           = directory,
      settings = list(
        base_name       = base_model_name,
        run             = "profile",
        exe             = exe_loc,
        profile_details = grid
      )
    )
    prof_settings$usepar          <- TRUE
    prof_settings$init_values_src <- 1
    prof_settings$parlinenum      <- prof$parlinenum
    
    # run it
    run_diagnostics(mydir = directory, model_settings = prof_settings)
  }
  
  message("Retrospectives and profiles complete.")
}

# Call the function:
run_all_diagnostics()
