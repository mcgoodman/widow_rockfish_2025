#######################################################################################################
# Here are the required packages that should be loaded with the nwfscDiag
# library(HandyCode)
# library(plyr)
# devtools::load_all("C:/Users/Chantel.Wetzel/Documents/GitHub/r4ss")
# devtools::load_all("C:/Users/Chantel.Wetzel/Documents/GitHub/nwfscDiag")

library(nwfscDiag)
library(here)
library(r4ss)
library(parallel)

source(here("R", "functions", "bridging_functions.R"))

#path to the base model
base_model <- here::here("models","2025 base model")

#######################################################################################################
# Define the working directory where the base model is and where all jitter, profile, and retrospective
# runs will be done:

mydir = here::here("models","diagnostics",paste0("diagnostics"))
base_model_name <- '2025 base model'

#Creae the dir, copy over the base model, then run it
if(!dir.exists(mydir)){
  
  dir.create(mydir)
  dir.create(here::here(mydir,base_model_name))
  
} 

model <- r4ss::SS_read(dir = base_model)
model$start$N_bootstraps <- 1 # TURN ON SS_NEW FILES
r4ss::SS_write(inputlist = model,dir = here(mydir,base_model_name),overwrite = T)
set_ss3_exe(dir = here(mydir,base_model_name))
r4ss::run(dir = here(mydir,"2025 base model"),exe = "ss3",extras = "-nohess",skipfinished = FALSE)

# The base model should be within a fold in the above directory.

#######################################################################################################
#------------------------------------------------------------------------------------------------------
# Likelihood profiles
#------------------------------------------------------------------------------------------------------

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
parallel::clusterEvalQ(cl, { library(nwfscDiag)}) #export diags package to cluster
parallel::clusterExport(cl,varlist = c("profile_df","mydir")) #export the settings df

## Run each profile in parallel
time_satrt <- Sys.time()
parLapply(cl = cl, X = 1:nrow(profile_df), function(x){
  
  get = get_settings_profile( parameters =  profile_df[x,"parameters"],
                              low =  profile_df[x,"low"],
                              high = profile_df[x,"high"],
                              step_size = profile_df[x,"step_size"],
                              param_space = profile_df[x,"param_space"])
  
  #Set up the model settings
  model_settings = get_settings(settings = list(base_name = "2025 base model",
                                                #run = c("jitter", "profile", "retro"),
                                                run = c("profile"),
                                                
                                                profile_details = get ))
  
  #Apply additinal settings to aid convergence
  model_settings$usepar <- TRUE #use previous run estimates as starting vals
  model_settings$init_values_src <- 1 #read starting vals from paramter file
  model_settings$parlinenum <- profile_df[x,"parlinenum"] #this refers to the line number that steepness is on in the ss3.par file
  model_settings$overwrite <- TRUE
  
  run_diagnostics(mydir = mydir, model_settings = model_settings)
  
  
  
})

parallel::stopCluster(cl)#stop the c;luster
time_end <- Sys.time()

#------------------------------------------------------------------------------------------------------
# Retrospectives
#------------------------------------------------------------------------------------------------------
model_settings_retros <- get_settings(
  settings = list(
    base_name = base_model_name,
    #exe= exe_loc,
    run = "retro",
    verbose = TRUE,
    retro_yrs = -1:-5)
)

run_diagnostics(mydir = mydir, model_settings = model_settings_retros)

#------------------------------------------------------------------------------------------------------
# Jitter
#------------------------------------------------------------------------------------------------------

