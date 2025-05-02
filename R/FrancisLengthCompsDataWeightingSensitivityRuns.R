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
rerun <- TRUE

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

# step 3.1: Update BottomTrawlLenComps------------------------------

BottomTrawlLenComp_dir <- here(wd, "models", "sensitivites", "BottomTrawlLenComp")

if (!dir.exists(BottomTrawlLenComp_dir)) {
  
  dir.create(BottomTrawlLenComp_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(finBasedir, BottomTrawlLenComp_dir)
  
}


ctrl <- SS_readctl(paste0(BottomTrawlLenComp_dir, "/2025widow.ctl"), datlist = paste0(BottomTrawlLenComp_dir, "/2025widow.dat"))

# Update the value for Data_type = 4 and Fleet = 1 (fixed value)
ctrl$Variance_adjustment_list[ctrl$Variance_adjustment_list$Data_type == 4 & ctrl$Variance_adjustment_list$Fleet == 1, "value"] <- 0.050976

SS_writectl(ctrl, here(BottomTrawlLenComp_dir, "2025widow.ctl"), overwrite = T)

ss3_exe <- set_ss3_exe(BottomTrawlLenComp_dir) # make executable

r4ss::run( # run the model
  dir = BottomTrawlLenComp_dir, # make sure to edit the directory
  exe = ss3_exe,
  extras = "-nohess", # no hess for now
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output( # make the output files
  dir = BottomTrawlLenComp_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# can look at plots here, but can skip for now, bc will have as comparison plots (below)
## SS_plots(replist, dir = BottomTrawlLenComp_dir, printfolder = "R_Plots")


# step 3.2: Update MidwaterTrawlLenComp------------------------------

MidwaterTrawlLenComp_dir <- here(wd, "models", "sensitivites", "MidwaterTrawlLenComp")

if (!dir.exists(MidwaterTrawlLenComp_dir)) {
  
  dir.create(MidwaterTrawlLenComp_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(finBasedir, MidwaterTrawlLenComp_dir)
  
}


ctrl <- SS_readctl(paste0(MidwaterTrawlLenComp_dir, "/2025widow.ctl"), datlist = paste0(MidwaterTrawlLenComp_dir, "/2025widow.dat"))

# Update the value for Data_type = 4 and Fleet = 2 (fixed value)
ctrl$Variance_adjustment_list[ctrl$Variance_adjustment_list$Data_type == 4 & ctrl$Variance_adjustment_list$Fleet == 2, "value"] <- 0.043618

SS_writectl(ctrl, here(MidwaterTrawlLenComp_dir, "2025widow.ctl"), overwrite = T)

ss3_exe <- set_ss3_exe(MidwaterTrawlLenComp_dir) # make executable

r4ss::run( # run the model
  dir =MidwaterTrawlLenComp_dir, # make sure to edit the directory
  exe = ss3_exe,
  extras = "-nohess", # no hess for now
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output( # make the output files
  dir = MidwaterTrawlLenComp_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# can look at plots here, but can skip for now, bc will have as comparison plots (below)
## SS_plots(replist, dir = MidwaterTrawlLenComp_dir, printfolder = "R_Plots")

# step 3.3: Update HakeLenComp------------------------------

HakeLenComp_dir <- here(wd, "models", "sensitivites", "HakeLenComp")

if (!dir.exists(HakeLenComp_dir)) {
  
  dir.create(HakeLenComp_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(finBasedir, HakeLenComp_dir)
  
}


ctrl <- SS_readctl(paste0(HakeLenComp_dir, "/2025widow.ctl"), datlist = paste0(HakeLenComp_dir, "/2025widow.dat"))

# Update the value for Data_type = 4 and Fleet = 3 (fixed value)
ctrl$Variance_adjustment_list[ctrl$Variance_adjustment_list$Data_type == 4 & ctrl$Variance_adjustment_list$Fleet == 3, "value"] <- 0.027980

SS_writectl(ctrl, here(HakeLenComp_dir, "2025widow.ctl"), overwrite = T)

ss3_exe <- set_ss3_exe(HakeLenComp_dir) # make executable

r4ss::run( # run the model
  dir = HakeLenComp_dir, # make sure to edit the directory
  exe = ss3_exe,
  extras = "-nohess", # no hess for now
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output( # make the output files
  dir = HakeLenComp_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# can look at plots here, but can skip for now, bc will have as comparison plots (below)
## SS_plots(replist, dir = HakeLenComp_dir, printfolder = "R_Plots")

# step 3.4: Update NetLenComp------------------------------

NetLenComp_dir <- here(wd, "models", "sensitivites", "NetLenComp")

if (!dir.exists(NetLenComp_dir)) {
  
  dir.create(NetLenComp_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(finBasedir, NetLenComp_dir)
  
}


ctrl <- SS_readctl(paste0(NetLenComp_dir, "/2025widow.ctl"), datlist = paste0(NetLenComp_dir, "/2025widow.dat"))

# Update the value for Data_type = 4 and Fleet = 4 (fixed value)
ctrl$Variance_adjustment_list[ctrl$Variance_adjustment_list$Data_type == 4 & ctrl$Variance_adjustment_list$Fleet == 4, "value"] <- 0.115959

SS_writectl(ctrl, here(NetLenComp_dir, "2025widow.ctl"), overwrite = T)

ss3_exe <- set_ss3_exe(NetLenComp_dir) # make executable

r4ss::run( # run the model
  dir = NetLenComp_dir, # make sure to edit the directory
  exe = ss3_exe,
  extras = "-nohess", # no hess for now
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output( # make the output files
  dir = NetLenComp_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# can look at plots here, but can skip for now, bc will have as comparison plots (below)
## SS_plots(replist, dir = NetLenComp_dir, printfolder = "R_Plots")

# step 3.5: Update HnLLenComp------------------------------

HnLLenComp_dir <- here(wd, "models", "sensitivites", "HnLLenComp")

if (!dir.exists(HnLLenComp_dir)) {
  
  dir.create(HnLLenComp_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(finBasedir, HnLLenComp_dir)
  
}


ctrl <- SS_readctl(paste0(HnLLenComp_dir, "/2025widow.ctl"), datlist = paste0(HnLLenComp_dir, "/2025widow.dat"))

# Update the value for Data_type = 4 and Fleet = 4 (fixed value)
ctrl$Variance_adjustment_list[ctrl$Variance_adjustment_list$Data_type == 4 & ctrl$Variance_adjustment_list$Fleet == 5, "value"] <- 0.169713

SS_writectl(ctrl, here(HnLLenComp_dir, "2025widow.ctl"), overwrite = T)

ss3_exe <- set_ss3_exe(HnLLenComp_dir) # make executable

r4ss::run( # run the model
  dir = HnLLenComp_dir, # make sure to edit the directory
  exe = ss3_exe,
  extras = "-nohess", # no hess for now
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output( # make the output files
  dir = HnLLenComp_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# can look at plots here, but can skip for now, bc will have as comparison plots (below)
## SS_plots(replist, dir = HnLLenComp_dir, printfolder = "R_Plots")

# step 3.6: Update TriennialLenComp------------------------------

TriennialLenComp_dir <- here(wd, "models", "sensitivites", "TriennialLenComp")

if (!dir.exists(TriennialLenComp_dir)) {
  
  dir.create(TriennialLenComp_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(finBasedir, TriennialLenComp_dir)
  
}


ctrl <- SS_readctl(paste0(TriennialLenComp_dir, "/2025widow.ctl"), datlist = paste0(TriennialLenComp_dir, "/2025widow.dat"))

# Update the value for Data_type = 4 and Fleet = 4 (fixed value)
ctrl$Variance_adjustment_list[ctrl$Variance_adjustment_list$Data_type == 4 & ctrl$Variance_adjustment_list$Fleet == 7, "value"] <- 0.092531

SS_writectl(ctrl, here(TriennialLenComp_dir, "2025widow.ctl"), overwrite = T)

ss3_exe <- set_ss3_exe(TriennialLenComp_dir) # make executable

r4ss::run( # run the model
  dir = TriennialLenComp_dir, # make sure to edit the directory
  exe = ss3_exe,
  extras = "-nohess", # no hess for now
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output( # make the output files
  dir = TriennialLenComp_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# can look at plots here, but can skip for now, bc will have as comparison plots (below)
## SS_plots(replist, dir = Triennial_dir, printfolder = "R_Plots")

# step 3.7: Update NWFSCLenComp------------------------------

NWFSCLenComp_dir <- here(wd, "models", "sensitivites", "NWFSCLenComp")

if (!dir.exists(NWFSCLenComp_dir)) {
  
  dir.create(NWFSCLenComp_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(finBasedir, NWFSCLenComp_dir)
  
}


ctrl <- SS_readctl(paste0(NWFSCLenComp_dir, "/2025widow.ctl"), datlist = paste0(NWFSCLenComp_dir, "/2025widow.dat"))

# Update the value for Data_type = 4 and Fleet = 4 (fixed value)
ctrl$Variance_adjustment_list[ctrl$Variance_adjustment_list$Data_type == 4 & ctrl$Variance_adjustment_list$Fleet == 8, "value"] <- 0.101232
SS_writectl(ctrl, here(NWFSCLenComp_dir, "2025widow.ctl"), overwrite = T)

ss3_exe <- set_ss3_exe(NWFSCLenComp_dir) # make executable

r4ss::run( # run the model
  dir = NWFSCLenComp_dir, # make sure to edit the directory
  exe = ss3_exe,
  extras = "-nohess", # no hess for now
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output( # make the output files
  dir = NWFSCLenComp_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# can look at plots here, but can skip for now, bc will have as comparison plots (below)
## SS_plots(replist, dir = NWFSC_dir, printfolder = "R_Plots")

### Comparison plots --------------------------

# list directories
folders <- here(wd, 'models', c("2025 base model", "sensitivites/BottomTrawlLenComp", 
                                "sensitivites/MidwaterTrawlLenComp", "sensitivites/HakeLenComp", 
                                "sensitivites/NetLenComp", "sensitivites/HnLLenComp",
                                "sensitivites/TriennialLenComp", "sensitivites/NWFSCLenComp"))

# r4ss plots!
Models <- SSgetoutput(dirvec = folders, getcovar = TRUE)
Models_SS <- SSsummarize(Models)

dir.create(plot_dir <- here(wd, 'figures', 'sensitivity_comp_plots', "LenComps_Francis"), recursive = TRUE)

mod_names <- c("base", "OTB_lenCompsFR", "OTM_lenCompsFR", "HKE_lenCompsFR","Net_lenCompsFR", "HnL_lenCompsFR", "Triennial_lenCompsFR", "NWFSC_lenCompsFR") # add model names as appropriate

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
