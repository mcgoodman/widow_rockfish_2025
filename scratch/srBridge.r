
library("tidyverse")
library("r4ss")
library("here")

# Setup --------------------------------------------------

# This will be Mico's 2025 base model
basedir <- here("models", "data_bridging", "bridge_1_ss3_ver_ctl_files", "widow_2019_ss_v3_30_23_new_ctl") #"data_updates", "catch_index_comps_update")
# This will be a new model in the models/ subdir
#testdir <- here("scratch", "mPriorTest")#
testdir <- here("scratch", "newSRRTest")
#
model_names <- c("2019 Base New SS etc.", "New SRR Pars")

#
testCtlName = "/2019widow.ctl"
testDatName = "/2019widow.dat"

# Copy over model files from base model to modify
if (!dir.exists(testdir)) {
  dir.create(testdir, recursive = TRUE)
  r4ss::copy_SS_inputs(basedir, testdir, overwrite = TRUE)
}

#
#set_ss3_exe <- function(dir, ...) {
#  
#  # Get and set filename for SS3 exe
#  ss3_exe <- c("ss", "ss3")
#  ss3_check <- vapply(ss3_exe, \(x) file.exists(file.path(dir, paste0(x, ".exe"))), logical(1))
#  if (!any(ss3_check)) r4ss::get_ss3_exe(dir, ...)
#  ss3_exe <- ss3_exe[which(vapply(ss3_exe, \(x) file.exists(file.path(dir, paste0(x, ".exe"))), logical(1)))]
#  return(ss3_exe)
#  
#}
## Download SS3 exe and return name
#base_exe <- set_ss3_exe(basedir)
#test_exe <- set_ss3_exe(testdir)

#                                https://github.com/nmfs-ost/ss3-source-code/releases/download/v3.30.23.1/ss3_osx
set_ss_osx <- function(dir, url="https://github.com/nmfs-ost/ss3-source-code/releases/download/v3.30.23.1/ss3_osx", ...) {
  
  # Get and set filename for SS3 exe
  ss3_exe <- c("ss_osx")
  ss3_check <- vapply(ss3_exe, \(x) file.exists(file.path(dir, paste0(x, ".exe"))), logical(1))
  if (!any(ss3_check)) utils::download.file(url, destfile = file.path(dir, "ss3"), mode = "wb") #r4ss::get_ss3_exe(dir, ...)
  ss3_exe <- ss3_exe[which(vapply(ss3_exe, \(x) file.exists(file.path(dir, paste0(x, ".exe"))), logical(1)))]
  return("ss_osx")  
}
# Download SS3 exe and return name
base_exe <- set_ss_osx(basedir)
test_exe <- set_ss_osx(testdir)

## Read in control file to modify
#ctrl <- SS_readctl(paste0(testdir, "/2025widow.ctl"), datlist = paste0(testdir, "/2025widow.dat"))
# Read in control file to modify
ctrl <- SS_readctl(paste0(testdir, testCtlName), datlist = paste0(testdir, testDatName))



# Update blocks -------------------------------------------

# Block 1: Bottom trawl retention asymptote 
# ctrl$Block_Design[[1]] <- c(ctrl$Block_Design[[1]], c(2011, 2016))
# ctrl$blocks_per_pattern[1] <- ctrl$blocks_per_pattern[1] + 1

# Block 2: Bottom trawl retention
# ctrl$Block_Design[[2]] <- c(ctrl$Block_Design[[2]], c(2011, 2016))
# ctrl$blocks_per_pattern[2] <- ctrl$blocks_per_pattern[2] + 1

# Block 7: Midwater trawl selectivity (parameters 1, 3, 4, 6) and retention (parameter 3)
# ctrl$Block_Design[[7]] <- c(ctrl$Block_Design[[7]], c(2011, 2016))
# ctrl$blocks_per_pattern[7] <- ctrl$blocks_per_pattern[7] + 1

# Mortality and Growth ------------------------------------

## Mortality SD following Hamel and Cope 2022
##max age from 2015 is 54
#maxA = 54
##Hamel and Cope 2022 coefficient 
#a = 5.4
#logMean = log(a/maxA)
##ctrl$MG_parms["NatM_p_1_Fem_GP_1", ]$PRIOR = logMean
#ctrl$MG_parms["NatM_p_1_Fem_GP_1", ]$PR_SD <- 0.31
##ctrl$MG_parms["NatM_p_1_Mal_GP_1", ]$PRIOR = logMean
#ctrl$MG_parms["NatM_p_1_Mal_GP_1", ]$PR_SD <- 0.31

## Growth
#ctrl$MG_parms["Wtlen_1_Fem_GP_1", ]$INIT <- 1.59e-5
#ctrl$MG_parms["Wtlen_2_Fem_GP_1", ]$INIT <- 2.99
#ctrl$MG_parms["Wtlen_1_Mal_GP_1", ]$INIT <- 1.45e-5
#ctrl$MG_parms["Wtlen_2_Mal_GP_1", ]$INIT <- 3.01

# Run -----------------------------------------------------

# Run base model
r4ss::run(
  dir = basedir,
  exe = base_exe,
  #extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = TRUE
)
#
SS_plots(
  repList<-SS_output(basedir, covar=T), 
  dir = basedir, 
  printfolder = "R_Plots"
)

# Stock-recruitment ---------------------------------------

#
dir.create(plot_dir <- here(testdir, "bridgeComparePlots"))

#
png(paste0(plot_dir, "/biasRamp.png"))
biasRamp = SS_fitbiasramp(repList)
dev.off()

# Update main recruitment deviations

#_last_yr_fullbias_adj_in_MPD
ctrl$last_early_yr_nobias_adj = biasRamp$df[1,1]
ctrl$first_yr_fullbias_adj = biasRamp$df[2,1]
ctrl$last_yr_fullbias_adj = biasRamp$df[3,1]
ctrl$first_recent_yr_nobias_adj = biasRamp$df[4,1]
ctrl$max_bias_adj  = biasRamp$df[5,1]
#2014 # last year of main recr_devs; forecast devs start in following year
#ctrl$MainRdevYrLast = NOT SURE HOW TO UPDATE
###############################################

# Write out new control file
SS_writectl(ctrl, paste0(testdir, testCtlName), overwrite = TRUE)
# Run test model
r4ss::run(
  dir = testdir,
  exe = test_exe,
  extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = TRUE
)
#
SS_plots(
  SS_output(testdir, covar=TRUE), 
  dir = testdir, #basedir, 
  printfolder = "R_Plots", 
  plot=c(1:21, 23:26)
)
#Starting yield plots (group 22)
#Error in equil_yield[["SPRloop"]] : subscript out of bounds

# Compare -------------------------------------------------

#Comparison plots produced by r4ss
models <- SSgetoutput(dirvec = c(basedir, testdir), getcovar = TRUE)
models_ss <- SSsummarize(models)

##
#labels <- c(
#  "Year", "Spawning biomass (t)", "Relative spawning biomass", "Age-0 recruits (1,000s)",
#  "Recruitment deviations", "Index", "Log index", "1 - SPR", "Density","Management target", 
#  "Minimum stock size threshold", "Spawning output", "Harvest rate"
#)

#
SSplotComparisons(
  models_ss,
  print = TRUE,
  plotdir = plot_dir,
  #labels = labels,
  densitynames = c("SSB_2019","SSB_Virgin"),
  legendlabels = model_names,
  indexPlotEach = TRUE,
  filenameprefix = "sens_base_adj_"
)
