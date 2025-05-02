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
r4ss::run(
  dir = finBasedir, # make sure to edit the directory
  exe = ss3_exe,
  extras = "-nohess", # no hess for now
  show_in_console = TRUE,
  skipfinished = !rerun
)


# Get r4ss output
replist <- SS_output( # make the output files
  dir = finBasedir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# Plots the results (store in the 'R_Plots' sub-directory)
SS_plots(replist, dir = finBasedir, printfolder = "R_Plots")

### Sensitivty run 1: Weighting composition data with Francis Method --------------------------

# step 1: Create outputs by copying and modifying base model ------------------------

Francis_sens_dir <- here(wd, "models", "sensitivites", "Francis")

if (!dir.exists(Francis_sens_dir)) {
  
  dir.create(Francis_sens_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(finBasedir, Francis_sens_dir)
  
}

# copy over the Report file
file.copy(
  from = file.path(finBasedir, "Report.sso"),
  to = file.path(Francis_sens_dir, "Report.sso")
)

# copy comp report file
file.copy(
  from = file.path(finBasedir, "CompReport.sso"),
  to = file.path(Francis_sens_dir, "CompReport.sso")
)

# step 2: Run function tune_comps ------------------------

# Just get the Francis and MI tables, without running the model. Note that the
# model in Francis_sens_dir needs to already have been run with Stock Synthesis, so
# that a report file is available.
weight_table <- tune_comps(
  dir = Francis_sens_dir,
  option = "Francis",
  verbose = FALSE
)

# step 3: Run recommended tuning iterations ------------------------

# step 3.1: Update BottomTrawlAgeComps------------------------------

BottomTrawlAgeComp_dir <- here(wd, "models", "sensitivites", "BottomTrawlAgeComp")

if (!dir.exists(BottomTrawlAgeComp_dir)) {
  
  dir.create(BottomTrawlAgeComp_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(finBasedir, BottomTrawlAgeComp_dir)
  
}


ctrl <- SS_readctl(paste0(BottomTrawlAgeComp_dir, "/2025widow.ctl"), datlist = paste0(BottomTrawlAgeComp_dir, "/2025widow.dat"))

# Update the value for Data_type = 4 and Fleet = 1 (fixed value)
ctrl$Variance_adjustment_list[ctrl$Variance_adjustment_list$Data_type == 5 & ctrl$Variance_adjustment_list$Fleet == 1, "value"] <- 0.206741

SS_writectl(ctrl, here(BottomTrawlAgeComp_dir, "2025widow.ctl"), overwrite = T)

ss3_exe <- set_ss3_exe(BottomTrawlAgeComp_dir) # make executable

r4ss::run( # run the model
  dir = BottomTrawlAgeComp_dir, # make sure to edit the directory
  exe = ss3_exe,
  extras = "-nohess", # no hess for now
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output( # make the output files
  dir = BottomTrawlAgeComp_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# can look at plots here, but can skip for now, bc will have as comparison plots (below)
## SS_plots(replist, dir = BottomTrawlAgeComp_dir, printfolder = "R_Plots")


# step 3.2: Update MidwaterTrawlAgeComp------------------------------

MidwaterTrawlAgeComp_dir <- here(wd, "models", "sensitivites", "MidwaterTrawlAgeComp")

if (!dir.exists(MidwaterTrawlAgeComp_dir)) {
  
  dir.create(MidwaterTrawlAgeComp_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(BottomTrawlAgeComp_dir, MidwaterTrawlAgeComp_dir)
  
}


ctrl <- SS_readctl(paste0(MidwaterTrawlAgeComp_dir, "/2025widow.ctl"), datlist = paste0(MidwaterTrawlAgeComp_dir, "/2025widow.dat"))

# Update the value for Data_type = 4 and Fleet = 2 (fixed value)
ctrl$Variance_adjustment_list[ctrl$Variance_adjustment_list$Data_type == 5 & ctrl$Variance_adjustment_list$Fleet == 2, "value"] <- 0.131374

SS_writectl(ctrl, here(MidwaterTrawlAgeComp_dir, "2025widow.ctl"), overwrite = T)

ss3_exe <- set_ss3_exe(MidwaterTrawlAgeComp_dir) # make executable

r4ss::run( # run the model
  dir =MidwaterTrawlAgeComp_dir, # make sure to edit the directory
  exe = ss3_exe,
  extras = "-nohess", # no hess for now
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output( # make the output files
  dir = MidwaterTrawlAgeComp_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# can look at plots here, but can skip for now, bc will have as comparison plots (below)
## SS_plots(replist, dir = MidwaterTrawlAgeComp_dir, printfolder = "R_Plots")

# step 3.3: Update HakeAgeComp------------------------------

HakeAgeComp_dir <- here(wd, "models", "sensitivites", "HakeAgeComp")

if (!dir.exists(HakeAgeComp_dir)) {
  
  dir.create(HakeAgeComp_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(MidwaterTrawlAgeComp_dir, HakeAgeComp_dir)
  
}


ctrl <- SS_readctl(paste0(HakeAgeComp_dir, "/2025widow.ctl"), datlist = paste0(HakeAgeComp_dir, "/2025widow.dat"))

# Update the value for Data_type = 4 and Fleet = 3 (fixed value)
ctrl$Variance_adjustment_list[ctrl$Variance_adjustment_list$Data_type == 5 & ctrl$Variance_adjustment_list$Fleet == 3, "value"] <- 0.180223

SS_writectl(ctrl, here(HakeAgeComp_dir, "2025widow.ctl"), overwrite = T)

ss3_exe <- set_ss3_exe(HakeAgeComp_dir) # make executable

r4ss::run( # run the model
  dir = HakeAgeComp_dir, # make sure to edit the directory
  exe = ss3_exe,
  extras = "-nohess", # no hess for now
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output( # make the output files
  dir = HakeAgeComp_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# can look at plots here, but can skip for now, bc will have as comparison plots (below)
## SS_plots(replist, dir = HakeAgeComp_dir, printfolder = "R_Plots")

# step 3.4: Update NetAgeComp------------------------------

NetAgeComp_dir <- here(wd, "models", "sensitivites", "NetAgeComp")

if (!dir.exists(NetAgeComp_dir)) {
  
  dir.create(NetAgeComp_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(HakeAgeComp_dir, NetAgeComp_dir)
  
}


ctrl <- SS_readctl(paste0(NetAgeComp_dir, "/2025widow.ctl"), datlist = paste0(NetAgeComp_dir, "/2025widow.dat"))

# Update the value for Data_type = 4 and Fleet = 4 (fixed value)
ctrl$Variance_adjustment_list[ctrl$Variance_adjustment_list$Data_type == 5 & ctrl$Variance_adjustment_list$Fleet == 4, "value"] <- 0.179957

SS_writectl(ctrl, here(NetAgeComp_dir, "2025widow.ctl"), overwrite = T)

ss3_exe <- set_ss3_exe(NetAgeComp_dir) # make executable

r4ss::run( # run the model
  dir = NetAgeComp_dir, # make sure to edit the directory
  exe = ss3_exe,
  extras = "-nohess", # no hess for now
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output( # make the output files
  dir = NetAgeComp_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# can look at plots here, but can skip for now, bc will have as comparison plots (below)
## SS_plots(replist, dir = NetAgeComp_dir, printfolder = "R_Plots")

# step 3.5: Update HnLAgeComp------------------------------

HnLAgeComp_dir <- here(wd, "models", "sensitivites", "HnLAgeComp")

if (!dir.exists(HnLAgeComp_dir)) {
  
  dir.create(HnLAgeComp_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(NetAgeComp_dir, HnLAgeComp_dir)
  
}


ctrl <- SS_readctl(paste0(HnLAgeComp_dir, "/2025widow.ctl"), datlist = paste0(HnLAgeComp_dir, "/2025widow.dat"))

# Update the value for Data_type = 4 and Fleet = 4 (fixed value)
ctrl$Variance_adjustment_list[ctrl$Variance_adjustment_list$Data_type == 5 & ctrl$Variance_adjustment_list$Fleet == 5, "value"] <- 0.517972

SS_writectl(ctrl, here(HnLAgeComp_dir, "2025widow.ctl"), overwrite = T)

ss3_exe <- set_ss3_exe(HnLAgeComp_dir) # make executable

r4ss::run( # run the model
  dir = HnLAgeComp_dir, # make sure to edit the directory
  exe = ss3_exe,
  extras = "-nohess", # no hess for now
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output( # make the output files
  dir = HnLAgeComp_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# can look at plots here, but can skip for now, bc will have as comparison plots (below)
## SS_plots(replist, dir = HnLAgeComp_dir, printfolder = "R_Plots")

# step 3.6: Update NWFSC ------------------------------

NWFSCAgeComp_dir <- here(wd, "models", "sensitivites", "NWFSCAgeComp")

if (!dir.exists(NWFSCAgeComp_dir)) {
  
  dir.create(NWFSCAgeComp_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(HnLAgeComp_dir, NWFSCAgeComp_dir)
  
}


ctrl <- SS_readctl(paste0(NWFSCAgeComp_dir, "/2025widow.ctl"), datlist = paste0(NWFSCAgeComp_dir, "/2025widow.dat"))

# Update the value for Data_type = 4 and Fleet = 4 (fixed value)
ctrl$Variance_adjustment_list[ctrl$Variance_adjustment_list$Data_type == 4 & ctrl$Variance_adjustment_list$Fleet == 8, "value"] <- 0.092450

SS_writectl(ctrl, here(NWFSCAgeComp_dir, "2025widow.ctl"), overwrite = T)

ss3_exe <- set_ss3_exe(NWFSCAgeComp_dir) # make executable

r4ss::run( # run the model
  dir = NWFSCAgeComp_dir, # make sure to edit the directory
  exe = ss3_exe,
  extras = "-nohess", # no hess for now
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output( # make the output files
  dir = NWFSCAgeComp_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# can look at plots here, but can skip for now, bc will have as comparison plots (below)
## SS_plots(replist, dir = NWFSC_dir, printfolder = "R_Plots")

### Comparison plots --------------------------

# list directories
folders <- here(wd, 'models', c("2025 base model", "sensitivites/BottomTrawlAgeComp", 
                                "sensitivites/MidwaterTrawlAgeComp", "sensitivites/HakeAgeComp", 
                                "sensitivites/NetAgeComp", "sensitivites/HnLAgeComp", 
                                "sensitivites/NWFSCAgeComp"))

# r4ss plots!
Models <- SSgetoutput(dirvec = folders, getcovar = TRUE)
Models_SS <- SSsummarize(Models)

dir.create(plot_dir <- here(wd, 'figures', 'sensitivity_comp_plots', "AgeComps_Francis"), recursive = TRUE)

mod_names <- c("base", "OTB_ageCompsFR", "OTM_ageCompsFR", "HKE_ageCompsFR","Net_ageCompsFR", "HnL_ageCompsFR", "NWFSC_ageCompsFR") # add model names as appropriate

# Use default plot labels
SSplotComparisons(
  Models_SS,
  print = TRUE,
  plotdir = plot_dir,
  densitynames = c("SSB_2019","SSB_Virgin"),
  legendlabels = mod_names,
  indexPlotEach = TRUE,
  filenameprefix = "sens_Francis_"
)
