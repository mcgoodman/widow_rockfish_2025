
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

# 2019 base model, with new WA catch reconstruction ---------------------------

## Create outputs by copying and modifying Base_45_new ------------------------

dir.create(base_wa_dir <- here(wd, "models", "2019 base model", "Base_45_wa_adj"))

r4ss::copy_SS_inputs(base_ctl_dir, base_wa_dir)

# Data file created by R/catches.R
catch_wa_adj <- read.csv(here("data_derived", "catches", "2019_catch_wa_reconstruction.csv"))

data_2019$catch <- catch_wa_adj

SS_writedat(data_2019, here(base_wa_dir, "2019widow.dat"), overwrite = TRUE)

## Run ------------------------------------------------------------------------

ss3_exe <- set_ss3_exe(base_wa_dir)

r4ss::run(
  dir = base_wa_dir,
  exe = ss3_exe,
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output(
  dir = base_wa_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

SS_plots(replist, dir = base_wa_dir, printfolder = "R_Plots")

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


# Update catches --------------------------------------------------------------

## Create outputs by copying and modifying Base_45_new ------------------------

catch_update_dir <- here(wd, "models", "data_updates", "update_catch")

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


# WCGBTS update: LN ---------------------------------------------------------------
## Create outputs by copying and modifying Base_45_new ------------------------

update_index_dir <- here(wd, "models", "data_updates", "index_update")

if (!dir.exists(update_index_dir)) {
  
  dir.create(update_index_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(base_ctl_dir, update_index_dir)
  
  files_rename <- list.files(update_index_dir)[grepl("2019", list.files(update_index_dir))]
  
  lapply(files_rename, \(x) {
    file.rename(file.path(update_index_dir, x), gsub("2019", "2025", file.path(update_index_dir, x)))
  })
  
}

# Update forecast.ss
fcast_2025 <- SS_readforecast(here(update_index_dir, "forecast.ss"), verbose = FALSE)
fcast_2025$ForeCatch$year <- fcast_2025$ForeCatch$year + 6
fcast_2025$Flimitfraction_m$year <- fcast_2025$Flimitfraction_m$year + 6
SS_writeforecast(fcast_2025, update_index_dir, overwrite = TRUE)

# Update control file
ctl <- readLines(here(update_index_dir, "2025widow.ctl"))
ctl <- gsub("2019widow", "2025widow", ctl)
writeLines(ctl, here(update_index_dir, "2025widow.ctl"))

# Update starter file
strt <- readLines(here(update_index_dir, "starter.ss"))
strt <- gsub("2019widow", "2025widow", strt)
writeLines(strt, here(update_index_dir, "starter.ss"))

# update data file
data_2025 <- SS_readdat(here(update_index_dir, "2025widow.dat"))
# end year update
if(data_2025$endyr != 2024){
  data_2025$endyr <- 2024
}
# survey 1 update
wcgbts <- read.csv(here("data_provided", "WCGBTS", "delta_lognormal", "index", "est_by_area.csv")) %>% filter(area == "Coastwide")
wcgbts_dat <- data.frame(year = wcgbts$year, 
                         month = rep(8.8), 
                         index = rep(8), 
                         obs = wcgbts$est, 
                         se_log = wcgbts$se)
# survey 2 update
juvsurv <- read.csv(here("data_provided", "RREAS", "widow_indices.csv"))
juvsurv_dat <- data.frame(year = juvsurv$YEAR, 
                          month = rep(7), 
                          index = rep(6),
                          obs = juvsurv$est, 
                          se_log = juvsurv$logse)
# for the index update, we want to keep the results from 1, 2, 3, 7, 9 and update 6 (juvsurv) and 8 (wcgbts)
index_old <- data_2025$CPUE %>% filter(index %in% c(1, 2, 3, 7, 9)) # keep the old index information
index_fin <- rbind(index_old, juvsurv_dat, wcgbts_dat)

data_2025$CPUE <- index_fin

SS_writedat(data_2025, here(update_index_dir, "2025widow.dat"), overwrite = TRUE)

## Run ------------------------------------------------------------------------

ss3_exe <- set_ss3_exe(update_index_dir)

r4ss::run(
  dir = update_index_dir,
  exe = ss3_exe,
  # extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output(
  dir = update_index_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

SS_plots(replist, dir = update_index_dir, printfolder = "R_Plots")

# WCGBTS update: GM ---------------------------------------------------------------
## Create outputs by copying and modifying Base_45_new ------------------------

update_index_dir_gamma <- here(wd, "models", "data_updates", "index_update_gamma")

if (!dir.exists(update_index_dir_gamma)) {
  
  dir.create(update_index_dir_gamma, recursive = TRUE)
  
  r4ss::copy_SS_inputs(base_ctl_dir, update_index_dir_gamma)
  
  files_rename <- list.files(update_index_dir_gamma)[grepl("2019", list.files(update_index_dir_gamma))]
  
  lapply(files_rename, \(x) {
    file.rename(file.path(update_index_dir_gamma, x), gsub("2019", "2025", file.path(update_index_dir_gamma, x)))
  })
  
}

# Update forecast.ss
fcast_2025 <- SS_readforecast(here(update_index_dir_gamma, "forecast.ss"), verbose = FALSE)
fcast_2025$ForeCatch$year <- fcast_2025$ForeCatch$year + 6
fcast_2025$Flimitfraction_m$year <- fcast_2025$Flimitfraction_m$year + 6
SS_writeforecast(fcast_2025, update_index_dir_gamma, overwrite = TRUE)

# Update control file
ctl <- readLines(here(update_index_dir_gamma, "2025widow.ctl"))
ctl <- gsub("2019widow", "2025widow", ctl)
writeLines(ctl, here(update_index_dir_gamma, "2025widow.ctl"))

# Update starter file
strt <- readLines(here(update_index_dir_gamma, "starter.ss"))
strt <- gsub("2019widow", "2025widow", strt)
writeLines(strt, here(update_index_dir_gamma, "starter.ss"))

# update data file
data_2025 <- SS_readdat(here(update_index_dir_gamma, "2025widow.dat"))
# end year update
if(data_2025$endyr != 2024){
  data_2025$endyr <- 2024
}
# survey 1 update
wcgbts <- read.csv(here("data_provided", "WCGBTS", "delta_gamma", "index", "est_by_area.csv")) %>% filter(area == "Coastwide")
wcgbts_dat <- data.frame(year = wcgbts$year, 
                         month = rep(8.8), 
                         index = rep(8), 
                         obs = wcgbts$est, 
                         se_log = wcgbts$se)
# survey 2 update
juvsurv <- read.csv(here("data_provided", "RREAS", "widow_indices.csv"))
juvsurv_dat <- data.frame(year = juvsurv$YEAR, 
                          month = rep(7), 
                          index = rep(6),
                          obs = juvsurv$est, 
                          se_log = juvsurv$logse)
# for the index update, we want to keep the results from 1, 2, 3, 7, 9 and update 6 (juvsurv) and 8 (wcgbts)
index_old <- data_2025$CPUE %>% filter(index %in% c(1, 2, 3, 7, 9)) # keep the old index information
index_fin <- rbind(index_old, juvsurv_dat, wcgbts_dat)

data_2025$CPUE <- index_fin

SS_writedat(data_2025, here(update_index_dir_gamma, "2025widow.dat"), overwrite = TRUE)

## Run ------------------------------------------------------------------------

ss3_exe <- set_ss3_exe(update_index_dir_gamma)

r4ss::run(
  dir = update_index_dir_gamma,
  exe = ss3_exe,
  # extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output(
  dir = update_index_dir_gamma,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

SS_plots(replist, dir = update_index_dir_gamma, printfolder = "R_Plots")

# WCGBTS + catch update ---------------------------------------------------------------
## Create outputs by copying and modifying index_update version -----------------------

update_all_dir <- here(wd, "models", "data_updates", "catch_index_update")

if (!dir.exists(update_all_dir)) {
  
  dir.create(update_all_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(update_index_dir, update_all_dir)
  
}

# update data file to also have catches
data_2025 <- SS_readdat(here(update_all_dir, "2025widow.dat"))
# end year update
if(data_2025$endyr != 2024){
  data_2025$endyr <- 2024
}
# Replace catch with updated catch data file created by R/catches.R
data_2025 <- SS_readdat(here(update_all_dir, "2025widow.dat"))
data_2025$catch <- read.csv(here("data_derived", "catches", "2025_catches.csv"))
data_2025$Comments[1] <- "#C 2025 Widow Rockfish Update Assessment"
SS_writedat(data_2025, here(update_all_dir, "2025widow.dat"), overwrite = TRUE)

## Run ------------------------------------------------------------------------

ss3_exe <- set_ss3_exe(update_all_dir)

r4ss::run(
  dir = update_all_dir,
  exe = ss3_exe,
  # extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = !rerun
)

replist <- SS_output(
  dir = update_all_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

SS_plots(replist, dir = update_all_dir, printfolder = "R_Plots")

# Model comparison plots ------------------------------------------------------

labels <- c(
  "Year", "Spawning biomass (t)", "Relative spawning biomass", "Age-0 recruits (1,000s)",
  "Recruitment deviations", "Index", "Log index", "1 - SPR", "Density","Management target", 
  "Minimum stock size threshold", "Spawning output", "Harvest rate"
)

## Compare 2019 base model runs to those with pre-2019 data tweaks ------------

# List directories
folders <- here(wd, 'models', '2019 base model', c("Base_45", "Base_45_new", "Base_45_add_shrimp", "Base_45_wa_adj", "Base_45_trawl_adj"))

#Comparison plots produced by r4ss
Models <- SSgetoutput(dirvec = folders, getcovar = TRUE)
Models_SS <- SSsummarize(Models)

dir.create(plot_dir <- here(wd, 'models', 'compare_plots', "base_catch_adj"), recursive = TRUE)

mod_names <- c('base', 'new ctl', "+ shrimp trawls", "+ WA reconstruction", "+ mid/bot trawl adj.") #add model names as appropriate

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

(par_cor <- cor(Models_SS$pars[,paste0("replist", 1:5)], use = "pairwise.complete.obs"))

## Compare 2019 base model runs to those with updated catch / WCGBTS data -----

# List directories
folders <- c(here(wd, 'models', '2019 base model', c("Base_45", "Base_45_new")), update_index_dir, update_index_dir_gamma)

#Comparison plots produced by r4ss
Models <- SSgetoutput(dirvec = folders, getcovar = TRUE)
Models_SS <- SSsummarize(Models)

dir.create(plot_dir <- here(wd, 'models', 'compare_plots', "compare_index_update"), recursive = TRUE)

mod_names <- c('base', 'new ctl', '+ ln index', '+ gm index') # Add model names as appropriate

# Plot time series (SSB, Recruitment, Fishing mortality)
SSplotComparisons(
  Models_SS,
  print = TRUE,
  plotdir = plot_dir,
  labels = labels,
  densitynames = c("SSB_2019", "SSB_Virgin"),
  legendlabels = mod_names,
  indexPlotEach = TRUE,
  filenameprefix = "comp_index_update_"
)

## Compare 2019 base model runs, catch update, index update, index/catch update -----

# List directories
folders <- c(here(wd, 'models', '2019 base model', c("Base_45", "Base_45_new")), catch_update_dir, update_index_dir, update_all_dir)

#Comparison plots produced by r4ss
Models <- SSgetoutput(dirvec = folders, getcovar = TRUE)
Models_SS <- SSsummarize(Models)

dir.create(plot_dir <- here(wd, 'models', 'compare_plots', "both_catch_index_update"), recursive = TRUE)

mod_names <- c('base', 'new ctl', "+ updated catch", "+ index update", "+ catch/index updates") #add model names as appropriate

#plot time series (SSB, Recruitment, Fishing mortality)
SSplotComparisons(
  Models_SS,
  print = TRUE,
  plotdir = plot_dir,
  labels = labels,
  densitynames = c("SSB_2019", "SSB_Virgin"),
  legendlabels = mod_names,
  indexPlotEach = TRUE,
  filenameprefix = "sens_catch_index_update_"
)