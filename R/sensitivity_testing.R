
library("tidyverse")
library("r4ss")
library("here")

### Basics: ID base model, directories, etc --------------------

wd <- here()

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

base_ctl_dir <- here(wd, "models", "2025 base model")

# note may need to run the base model as well for first run through
if (!dir.exists(base_ctl_dir)) {
  
  ss3_exe <- set_ss3_exe(base_ctl_dir) # make exectuable
  
  r4ss::run( # run the model
    dir = base_ctl_dir, # make sure to edit the directory
    exe = ss3_exe,
    extras = "-nohess", # no hess for now
    show_in_console = TRUE,
    skipfinished = !rerun
  )
  
  replist <- SS_output( # make the output files
    dir = base_ctl_dir,
    verbose = TRUE,
    printstats = TRUE,
    covar = TRUE
  )
}

### Sensitivty run 1: Fixed mortality --------------------------

# step 1: Create outputs by copying and modifying base model ------------------------

mort_sens_dir <- here(wd, "models", "sensitivites", "fixed_mortality_01")

if (!dir.exists(mort_sens_dir)) {
  
  dir.create(mort_sens_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(base_ctl_dir, mort_sens_dir)
  
}

# step 2: modify control file (or other relavent file changes, data/starter/control wise) ------------------------
# aiming to fix male and female natural mortality to 0.1
# 61: 0.01 0.3	0.144401 -2.3	0.31 3 5	0	0	0	0	0	0	0	#_NatM_p_1_Fem_GP_1
# 73: 0.01 0.3	0.154867 -2.3	0.31 3 5	0	0	0	0	0	0	0	#_NatM_p_1_Mal_GP_1 
ctrl <- SS_readctl(paste0(mort_sens_dir, "/2025widow.ctl"), datlist = paste0(mort_sens_dir, "/2025widow.dat"))
ctrl$MG_parms[row.names(ctrl$MG_parms) == "NatM_p_1_Fem_GP_1", ]$INIT <- 0.1 # fixed value
ctrl$MG_parms[row.names(ctrl$MG_parms) == "NatM_p_1_Fem_GP_1", ]$PHASE <- -1*ctrl$MG_parms[row.names(ctrl$MG_parms) == "NatM_p_1_Fem_GP_1", ]$PHASE # negative phase = no estimations
ctrl$MG_parms[row.names(ctrl$MG_parms) == "NatM_p_1_Mal_GP_1", ]$INIT <- 0.1
ctrl$MG_parms[row.names(ctrl$MG_parms) == "NatM_p_1_Mal_GP_1", ]$PHASE <- -1*ctrl$MG_parms[row.names(ctrl$MG_parms) == "NatM_p_1_Mal_GP_1", ]$PHASE
SS_writectl(ctrl, here(mort_sens_dir, "2025widow.ctl"), overwrite = T)

# step 3: run, without hess for now -----------------

ss3_exe <- set_ss3_exe(mort_sens_dir) # make exectuable

r4ss::run( # run the model
  dir = mort_sens_dir, # make sure to edit the directory
  exe = ss3_exe,
  extras = "-nohess", # no hess for now
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output( # make the output files
  dir = mort_sens_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# can look at plots here, but can skip for now, bc will have as comparision plots (below)
# SS_plots(replist, dir = mort_sens_dir, printfolder = "R_Plots")

### Sensitivty run 2: Fixed mortality, diff for M/F --------------------------
# step 1: Create outputs by copying and modifying base model ------------------------

mort_diff_sens_dir <- here(wd, "models", "sensitivites", "fixed_mortality_0124_0129")

if (!dir.exists(mort_diff_sens_dir)) {
  
  dir.create(mort_diff_sens_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(base_ctl_dir, mort_diff_sens_dir)
  
}

# step 2: modify control file (or other relavent file changes, data/starter/control wise) ------------------------
# aiming to fix natural mortality at 0.124 yr-1 for females and 0.129 yr-1 for males
# 61: 0.01 0.3	0.144401 -2.3	0.31 3 5	0	0	0	0	0	0	0	#_NatM_p_1_Fem_GP_1
# 73: 0.01 0.3	0.154867 -2.3	0.31 3 5	0	0	0	0	0	0	0	#_NatM_p_1_Mal_GP_1 
ctrl <- SS_readctl(paste0(mort_diff_sens_dir, "/2025widow.ctl"), datlist = paste0(mort_diff_sens_dir, "/2025widow.dat"))
ctrl$MG_parms[row.names(ctrl$MG_parms) == "NatM_p_1_Fem_GP_1", ]$INIT <- 0.124 # fixed value
ctrl$MG_parms[row.names(ctrl$MG_parms) == "NatM_p_1_Fem_GP_1", ]$PHASE <- -1*ctrl$MG_parms[row.names(ctrl$MG_parms) == "NatM_p_1_Fem_GP_1", ]$PHASE # negative phase = no estimations
ctrl$MG_parms[row.names(ctrl$MG_parms) == "NatM_p_1_Mal_GP_1", ]$INIT <- 0.129
ctrl$MG_parms[row.names(ctrl$MG_parms) == "NatM_p_1_Mal_GP_1", ]$PHASE <- -1*ctrl$MG_parms[row.names(ctrl$MG_parms) == "NatM_p_1_Mal_GP_1", ]$PHASE
SS_writectl(ctrl, here(mort_diff_sens_dir, "2025widow.ctl"), overwrite = T)

# step 3: run, without hess for now -----------------

ss3_exe <- set_ss3_exe(mort_diff_sens_dir) # make exectuable

r4ss::run( # run the model
  dir = mort_diff_sens_dir, # make sure to edit the directory
  exe = ss3_exe,
  extras = "-nohess", # no hess for now
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output( # make the output files
  dir = mort_diff_sens_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# can look at plots here, but can skip for now, bc will have as comparision plots (below)
# SS_plots(replist, dir = mort_sens_dir, printfolder = "R_Plots")

### Comparision plots --------------------------

labels <- c(
  "Year", "Spawning biomass (t)", "Relative spawning biomass", "Age-0 recruits (1,000s)",
  "Recruitment deviations", "Index", "Log index", "1 - SPR", "Density","Management target", 
  "Minimum stock size threshold", "Spawning output", "Harvest rate"
)

# list directories
folders <- here(wd, 'models', c("2025 base model", "sensitivites/fixed_mortality_01", "sensitivites/fixed_mortality_0124_0129"))

# r4ss plots!
Models <- SSgetoutput(dirvec = folders, getcovar = TRUE)
Models_SS <- SSsummarize(Models)

dir.create(plot_dir <- here(wd, 'figures', 'sensitivity_comp_plots', "fixed_mortality"), recursive = TRUE)

mod_names <- c('base', 'M & F 0.1', 'M 0.129, F 0.124') # add model names as appropriate

# plot time series (SSB, Recruitment, Fishing mortality)
SSplotComparisons(
  Models_SS,
  print = TRUE,
  plotdir = plot_dir,
  labels = labels,
  densitynames = c("SSB_2019","SSB_Virgin"),
  legendlabels = mod_names,
  indexPlotEach = TRUE,
  filenameprefix = "sens_fixed_mort_"
)


