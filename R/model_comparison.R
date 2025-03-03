
library("tidyverse")
library("r4ss")
library("here")

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

# 2019 Base model -------------------------------------------------------------

## With old SS3 version and control file --------------------------------------

# directory for the base model
# run Base_45 from par file (i.e. archived model)
# Use old version of SS3 (not quite as old as 2019 assessment, which uses v3.30.12)
base_dir <- here(wd, 'models', '2019 base model', 'Base_45')
ss3_exe <- set_ss3_exe(base_dir, version = "v3.30.16")

# run model
# With estimation and hessian it takes ~12 minutes
r4ss::run(
  dir = base_dir,
  exe = ss3_exe,
  #extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = !rerun
)


# Get r4ss output
replist <- SS_output(
  dir = base_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# Plots the results (store in the 'R_Plots' sub-directory)
SS_plots(replist, dir = base_dir, printfolder = "R_Plots")


# 2019 base model, new SS3 version and control file ---------------------------

# now run Base_45 with the CTL file shared by Ian in Discussion #27, saved as 2019widow.ctl
base_ctl_dir <- here(wd, 'models', '2019 base model', 'Base_45_new')
ss3_exe <- set_ss3_exe(base_ctl_dir)

# set it up to run from the CTL file and to ignore par
starter_file <- file.path(base_ctl_dir, "starter.ss")
starter <- SS_readstarter(
  file = starter_file,
  verbose = TRUE
)

starter$init_values_src <- 0 # read initial files from ctl

# save starter
SS_writestarter(
  mylist =  starter ,
  dir =  base_ctl_dir, 
  overwrite = TRUE,
  verbose = TRUE
)

# run model
r4ss::run(
  dir = base_ctl_dir,
  exe = ss3_exe,
  show_in_console = TRUE,
  skipfinished = !rerun
)

# Get r4ss output
replist <- SS_output(
  dir = base_ctl_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# Plots the results (store in the 'R_Plots' sub-directory)
SS_plots(replist, dir = base_ctl_dir, printfolder = "R_Plots")

# 2019 base model, with shrimp trawls -----------------------------------------

## Create outputs by copying and modifying Base_45_new ------------------------

dir.create(base_shrimp_dir <- here(wd, "models", "2019 base model", "Base_45_add_shrimp"))

r4ss::copy_SS_inputs(base_ctl_dir, base_shrimp_dir)

# Data file created by R/catches.R
catch_w_shrimp <- read.csv(here("data_derived", "catches", "2019_catch_shrimp_added.csv"))

data_2019 <- SS_readdat(here(base_shrimp_dir, "2019widow.dat"))

data_2019$catch <- catch_w_shrimp

SS_writedat(data_2019, here(base_shrimp_dir, "2019widow.dat"), overwrite = TRUE)

## Run ------------------------------------------------------------------------

ss3_exe <- set_ss3_exe(base_shrimp_dir)

r4ss::run(
  dir = base_shrimp_dir,
  exe = ss3_exe,
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output(
  dir = base_shrimp_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

SS_plots(replist, dir = base_shrimp_dir, printfolder = "R_Plots")


# 2019 base model, with changes to 1979/80 CA trawls --------------------------

## Create outputs by copying and modifying Base_45_new ------------------------

dir.create(base_adj_dir <- here(wd, "models", "2019 base model", "Base_45_trawl_adj"))

r4ss::copy_SS_inputs(base_ctl_dir, base_adj_dir)

# Data file created by R/catches.R
catch_adj <- read.csv(here("data_derived", "catches", "2019_catch_adjusted.csv"))

data_2019$catch <- catch_adj

SS_writedat(data_2019, here(base_adj_dir, "2019widow.dat"), overwrite = TRUE)

## Run ------------------------------------------------------------------------

ss3_exe <- set_ss3_exe(base_adj_dir)

r4ss::run(
  dir = base_adj_dir,
  exe = ss3_exe,
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output(
  dir = base_adj_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

SS_plots(replist, dir = base_adj_dir, printfolder = "R_Plots")


# Catch update ----------------------------------------------------------------

## Create outputs by copying and modifying Base_45_new ------------------------

catch_update_dir <- here(wd, "models", "data_updates", "catch_update")

if (!dir.exists(catch_update_dir)) {
  
  dir.create(catch_update_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(base_ctl_dir, catch_update_dir)
  
  files_rename <- list.files(catch_update_dir)[grepl("2019", list.files(catch_update_dir))]
  
  lapply(files_rename, \(x) {
    file.rename(file.path(catch_update_dir, x), gsub("2019", "2025", file.path(catch_update_dir, x)))
  })
  
}

# Replace catch with updated catch data file created by R/catches.R
data_2025 <- SS_readdat(here(catch_update_dir, "2025widow.dat"))
data_2025$catch <- read.csv(here("data_derived", "catches", "2025_catches.csv"))
data_2025$endyr <- 2024
data_2025$Comments[1] <- "#C 2025 Widow Rockfish Update Assessment"
SS_writedat(data_2025, here(catch_update_dir, "2025widow.dat"), overwrite = TRUE)

# Update forecast.ss
fcast_2025 <- SS_readforecast(here(catch_update_dir, "forecast.ss"), verbose = FALSE)
fcast_2025$ForeCatch$year <- fcast_2025$ForeCatch$year + 6
fcast_2025$Flimitfraction_m$year <- fcast_2025$Flimitfraction_m$year + 6
SS_writeforecast(fcast_2025, catch_update_dir, overwrite = TRUE)

# Update control file
ctl <- readLines(here(catch_update_dir, "2025widow.ctl"))
ctl <- gsub("2019widow", "2025widow", ctl)
writeLines(ctl, here(catch_update_dir, "2025widow.ctl"))

# Update starter file
strt <- readLines(here(catch_update_dir, "starter.ss"))
strt <- gsub("2019widow", "2025widow", strt)
writeLines(strt, here(catch_update_dir, "starter.ss"))

## Run ------------------------------------------------------------------------

ss3_exe <- set_ss3_exe(catch_update_dir)

r4ss::run(
  dir = catch_update_dir,
  exe = ss3_exe,
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output(
  dir = catch_update_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

SS_plots(replist, dir = catch_update_dir, printfolder = "R_Plots")


# WCGBTS update ---------------------------------------------------------------

# TO-DO

# Model comparison plots ------------------------------------------------------

labels <- c(
  "Year", "Spawning biomass (t)", "Relative spawning biomass", "Age-0 recruits (1,000s)",
  "Recruitment deviations", "Index", "Log index", "1 - SPR", "Density","Management target", 
  "Minimum stock size threshold", "Spawning output", "Harvest rate"
)

## Compare 2019 base model runs -----------------------------------------------

# List directories
folders <- here(wd, 'models', '2019 base model', c("Base_45", "Base_45_new"))

#Comparison plots produced by r4ss
Models <- SSgetoutput(dirvec = folders, getcovar = TRUE)
Models_SS <- SSsummarize(Models)

dir.create(plot_dir <- here(wd, 'models', 'compare_plots', "base_ctl"), recursive = TRUE)

mod_names <- c('base', 'new ctl') #add model names as appropriate

#plot time series (SSB, Recruitment, Fishing mortality)
SSplotComparisons(
  Models_SS,
  print = TRUE,
  plotdir = plot_dir,
  labels = labels,
  densitynames = c("SSB_2019", "SSB_Virgin"),
  legendlabels = mod_names,
  indexPlotEach = TRUE,
  filenameprefix = "sens_base_"
)

## Compare 2019 base model runs to those with pre-2019 data tweaks ------------

# List directories
folders <- here(wd, 'models', '2019 base model', c("Base_45", "Base_45_new", "Base_45_add_shrimp", "Base_45_trawl_adj"))

#Comparison plots produced by r4ss
Models <- SSgetoutput(dirvec = folders, getcovar = TRUE)
Models_SS <- SSsummarize(Models)

dir.create(plot_dir <- here(wd, 'models', 'compare_plots', "base_catch_adj"), recursive = TRUE)

mod_names <- c('base', 'new ctl', "+ shrimp trawls", "+ mid/bot trawl adj.") #add model names as appropriate

#plot time series (SSB, Recruitment, Fishing mortality)
SSplotComparisons(
  Models_SS,
  print = TRUE,
  plotdir = plot_dir,
  labels = labels,
  densitynames = c("SSB_2019","SSB_Virgin"),
  legendlabels = mod_names,
  indexPlotEach = TRUE,
  filenameprefix = "sens_base_adj_"
)

## Compare 2019 base model runs to those with updated catch / WCGBTS data -----

# List directories
folders <- here(wd, 'models', '2019 base model', "Base_45_trawl_adj") # TO-DO: change reference data to reflect trawl adj.
folders <- c(folders, here(wd, 'models', "data_updates", "catch_update")) # TO-DO: add WCGBTS update

#Comparison plots produced by r4ss
Models <- SSgetoutput(dirvec = folders, getcovar = TRUE)
Models_SS <- SSsummarize(Models)

dir.create(plot_dir <- here(wd, 'models', 'compare_plots', "data_update"), recursive = TRUE)

mod_names <- c("base + mid/bot trawl adj.", "catch update") #add model names as appropriate

#plot time series (SSB, Recruitment, Fishing mortality)
SSplotComparisons(
  Models_SS,
  print = TRUE,
  plotdir = plot_dir,
  labels = labels,
  densitynames = c("SSB_2019", "SSB_Virgin"),
  legendlabels = mod_names,
  indexPlotEach = TRUE,
  filenameprefix = "sens_data_update"
)
