
library("tidyverse")
library("r4ss")
library("here")

# Setup ---------------------------------------------------

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

#' Function to add new row to parameters by copying another row
#'
#' @param data Data frame (with row names)
#' @param new_row name of new row to add
#' @param ref_row name of reference row to copy values from
#' @param ... Values to override reference with (e.g. )
#'
#' @examples
#' 
#' mtcars |> 
#'   insert_row(
#'     new_row = "Mazda RX4 Wagu", 
#'     ref_row = "Maxda RX4 Wag",
#'     mpg = 100
#'   )
#' 
insert_row <- function(data, new_row, ref_row, ...) {
  
  rownames <- row.names(data)
  
  stopifnot(ref_row %in% rownames(data))
  stopifnot(length(new_row) == 1)
  stopifnot(length(ref_row) == 1)
  stopifnot(all(names(list(...)) %in% names(data)))
  
  ref_clone <- data[ref_row,]
  rownames(ref_clone) <- new_row
  ref_clone <- modifyList(ref_clone, list(...))
  
  do.call(
    "rbind", 
    list(
      data[1:which(rownames == ref_row),], 
      ref_clone, 
      data[(which(rownames == ref_row) + 1):nrow(data),]
    )
  )
  
}

# This will be Mico's 2025 base model
basedir <- here("models", "data_updates", "catch_index_comps_update")

# This will be a new model in the models/ subdir
testdir <- here("scratch", "model_bridging_test")

# Copy over model files from base model to modify
if (!dir.exists(testdir)) {
  
  dir.create(testdir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(basedir, testdir, overwrite = TRUE)
  
}

# Download SS3 exe and return name
base_exe <- set_ss3_exe(basedir)
test_exe <- set_ss3_exe(testdir)

# Read in control file to modify
ctrl <- SS_readctl(paste0(testdir, "/2025widow.ctl"), datlist = paste0(testdir, "/2025widow.dat"))

# Update blocks -------------------------------------------

## Block 1 ------------------------------------------------
## Bottom trawl retention asymptote

ctrl$Block_Design[[1]] <- c(ctrl$Block_Design[[1]], c(2011, 2016))

ctrl$blocks_per_pattern[1] <- ctrl$blocks_per_pattern[1] + 1

ctrl$size_selex_parms_tv <- 
  ctrl$size_selex_parms_tv |> 
  insert_row(
    new_row = "SizeSel_PRet_3_BottomTrawl(1)_BLK1repl_2010",
    ref_row = "SizeSel_PRet_3_BottomTrawl(1)_BLK1repl_1998",
    PRIOR = 0
  )

## Block 2: -----------------------------------------------
## Bottom trawl retention

# ctrl$Block_Design[[2]] <- c(ctrl$Block_Design[[2]], c(2011, 2016))

# ctrl$blocks_per_pattern[2] <- ctrl$blocks_per_pattern[2] + 1

# ADD: Time-varying parameters block

## Block 7 ------------------------------------------------
## Midwater trawl selectivity (parameters 1, 3, 4, 6), 
## and retention (parameter 3)

# ctrl$Block_Design[[7]] <- c(ctrl$Block_Design[[7]], c(2011, 2016))

# ctrl$blocks_per_pattern[7] <- ctrl$blocks_per_pattern[7] + 1

# ADD: Time-varying parameters block

# Stock-recruitment ---------------------------------------

# Update main recruitment deviations
ctrl$MainRdevYrLast <- 2024

# Bias adjustment
ctrl$last_yr_fullbias_adj <- 2024

# Should tune with SS_fitbiasramp
ctrl$first_recent_yr_nobias_adj <- 2021

# Mortality and Growth ------------------------------------

# Mortality SD following Hamel and Cope 2022
ctrl$MG_parms["NatM_p_1_Fem_GP_1", ]$PR_SD <- 0.31

# Growth
ctrl$MG_parms["Wtlen_1_Fem_GP_1", ]$INIT <- 1.59e-5
ctrl$MG_parms["Wtlen_2_Fem_GP_1", ]$INIT <- 2.99
ctrl$MG_parms["Wtlen_1_Mal_GP_1", ]$INIT <- 1.45e-5
ctrl$MG_parms["Wtlen_2_Mal_GP_1", ]$INIT <- 3.01

# Run -----------------------------------------------------

# Write out new control file
SS_writectl(ctrl, paste0(testdir, "/2025widow.ctl"), overwrite = TRUE)

# Run base model
r4ss::run(
  dir = basedir,
  exe = base_exe,
  extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = TRUE
)

SS_plots(
  SS_output(basedir), 
  dir = basedir, 
  printfolder = "R_Plots"
)

# Run test model
r4ss::run(
  dir = testdir,
  exe = test_exe,
  extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = TRUE
)

SS_plots(
  SS_output(testdir), 
  dir = basedir, 
  printfolder = "R_Plots"
)

# Compare -------------------------------------------------

#Comparison plots produced by r4ss
models <- SSgetoutput(dirvec = c(basedir, testdir), getcovar = TRUE)
models_ss <- SSsummarize(Models)
model_names <- c("data updates", "ctrl updates")

labels <- c(
  "Year", "Spawning biomass (t)", "Relative spawning biomass", "Age-0 recruits (1,000s)",
  "Recruitment deviations", "Index", "Log index", "1 - SPR", "Density","Management target", 
  "Minimum stock size threshold", "Spawning output", "Harvest rate"
)

dir.create(plot_dir <- here("scratch", "ctrl_updates_test"))

SSplotComparisons(
  models_ss,
  print = TRUE,
  plotdir = plot_dir,
  labels = labels,
  densitynames = c("SSB_2019","SSB_Virgin"),
  legendlabels = model_names,
  indexPlotEach = TRUE,
  filenameprefix = "sens_base_adj_"
)
