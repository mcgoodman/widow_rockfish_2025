
library("tidyverse")
library("r4ss")
library("here")

source(here("R", "functions", "bridging_functions.R"))

# Base model ----------------------------------------------

# This will be Mico's 2025 base model
basedir <- here("models", "data_bridging", "finalised_data_bridging", "reweight_hnl_removed_reweighted")

# Download SS3 exe and return name
base_exe <- set_ss3_exe(basedir)

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
  printfolder = "plots"
)

# Mortality -----------------------------------------------

# Location for all model bridging runs
dir.create(bridgedir <- here("models", "model_bridging"))

# Copy over model files from base model to modify
dir.create(Mdir <- here(bridgedir, "mortality"))
r4ss::copy_SS_inputs(basedir, Mdir, overwrite = TRUE)
Mexe <- set_ss3_exe(Mdir)

# Read in control file to modify
ctrl <- SS_readctl(paste0(Mdir, "/2025widow.ctl"), datlist = paste0(Mdir, "/2025widow.dat"))

#max age from 2015 is 54
maxA = 54
#Hamel and Cope 2022 coefficient 
a = 5.4
logMean = log(a/maxA)

#ctrl$MG_parms["NatM_p_1_Fem_GP_1", ]$PRIOR = logMean
ctrl$MG_parms["NatM_p_1_Fem_GP_1", ]$PR_SD <- 0.31
#ctrl$MG_parms["NatM_p_1_Mal_GP_1", ]$PRIOR = logMean
ctrl$MG_parms["NatM_p_1_Mal_GP_1", ]$PR_SD <- 0.31

SS_writectl(ctrl, paste0(Mdir, "/2025widow.ctl"), overwrite = TRUE)

r4ss::run(
  dir = Mdir,
  exe = Mexe,
  #extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = TRUE
)

SS_plots(
  SS_output(Mdir), 
  dir = Mdir, 
  printfolder = "plots"
)

# Length / weight parameters ------------------------------

dir.create(LWdir <- here(bridgedir, "length_weight"))
r4ss::copy_SS_inputs(Mdir, LWdir, overwrite = TRUE)
LWexe <- set_ss3_exe(LWdir)

ctrl <- SS_readctl(paste0(LWdir, "/2025widow.ctl"), datlist = paste0(LWdir, "/2025widow.dat"))

ctrl$MG_parms["Wtlen_1_Fem_GP_1", ]$INIT <- 1.59e-5
ctrl$MG_parms["Wtlen_2_Fem_GP_1", ]$INIT <- 2.99
ctrl$MG_parms["Wtlen_1_Mal_GP_1", ]$INIT <- 1.45e-5
ctrl$MG_parms["Wtlen_2_Mal_GP_1", ]$INIT <- 3.01

SS_writectl(ctrl, paste0(LWdir, "/2025widow.ctl"), overwrite = TRUE)

r4ss::run(
  dir = LWdir,
  exe = LWexe,
  #extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = TRUE
)

LW_replist <- SS_output(LWdir)

SS_plots(
  LW_replist, 
  dir = LWdir, 
  printfolder = "plots"
)

# Recruitment bias ramp -----------------------------------

dir.create(SRdir <- here(bridgedir, "SR_bias_adj"))
r4ss::copy_SS_inputs(LWdir, SRdir, overwrite = TRUE)
SRexe <- set_ss3_exe(SRdir)

# Fit bias ramp
dir.create(plot_dir <- here(SRdir, "plots"))
png(paste0(plot_dir, "/biasRamp.png"))
biasRamp = SS_fitbiasramp(LW_replist)
dev.off()

ctrl <- SS_readctl(paste0(SRdir, "/2025widow.ctl"), datlist = paste0(SRdir, "/2025widow.dat"))

# Input bias ramp parameters
# Last year of main recruitment deviations changed in data bridging
ctrl$last_early_yr_nobias_adj = biasRamp$df[1,1]
ctrl$first_yr_fullbias_adj = biasRamp$df[2,1]
ctrl$last_yr_fullbias_adj = biasRamp$df[3,1]
ctrl$first_recent_yr_nobias_adj = biasRamp$df[4,1]
ctrl$max_bias_adj  = biasRamp$df[5,1]

SS_writectl(ctrl, paste0(SRdir, "/2025widow.ctl"), overwrite = TRUE)

r4ss::run(
  dir = SRdir,
  exe = SRexe,
  #extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = TRUE
)

SS_plots(
  SS_output(SRdir, covar=TRUE), 
  dir = SRdir, #basedir, 
  printfolder = "plots", 
  plot = c(1:21, 23:26)
)

# Midwater trawl blocks -----------------------------------

# Midwater trawl selectivity (parameters 1, 3, 4, 6), 
# and retention (parameter 3)

dir.create(Block7dir <- here(bridgedir, "Block7"))
r4ss::copy_SS_inputs(SRdir, Block7dir, overwrite = TRUE)
Block7exe <- set_ss3_exe(Block7dir)

ctrl <- SS_readctl(paste0(Block7dir, "/2025widow.ctl"), datlist = paste0(Block7dir, "/2025widow.dat"))

# Add time block to block group
ctrl$Block_Design[[7]] <- c(ctrl$Block_Design[[7]], c(2011, 2016))

# Note that there is an additional block in block group
ctrl$blocks_per_pattern[7] <- ctrl$blocks_per_pattern[7] + 1

# Add rows to time-varying selectivity for relevant parameters
ctrl$size_selex_parms_tv <- 
  ctrl$size_selex_parms_tv |> 
  insert_row(
    new_row = "SizeSel_P_1_MidwaterTrawl(2)_BLK7repl_2011",
    ref_row = "SizeSel_P_1_MidwaterTrawl(2)_BLK7repl_2002", 
    
  ) |> 
  insert_row(
    new_row = "SizeSel_P_3_MidwaterTrawl(2)_BLK7repl_2011",
    ref_row = "SizeSel_P_3_MidwaterTrawl(2)_BLK7repl_2002", 
    INIT = 2.94
  ) |> 
  insert_row(
    new_row = "SizeSel_P_4_MidwaterTrawl(2)_BLK7repl_2011",
    ref_row = "SizeSel_P_4_MidwaterTrawl(2)_BLK7repl_2002",
    INIT = 3.999
  ) |> 
  insert_row(
    new_row = "SizeSel_P_6_MidwaterTrawl(2)_BLK7repl_2011",
    ref_row = "SizeSel_P_6_MidwaterTrawl(2)_BLK7repl_2002", 
    INIT = -4.821
  ) |> 
  insert_row(
    new_row = "SizeSel_PRet_3_MidwaterTrawl(2)_BLK7repl_2011",
    ref_row = "SizeSel_PRet_3_MidwaterTrawl(2)_BLK7repl_2002",
    INIT = 8.808
  )

SS_writectl(ctrl, paste0(Block7dir, "/2025widow.ctl"), overwrite = TRUE)

r4ss::run(
  dir = Block7dir,
  exe = Block7exe,
  extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = TRUE
)

SS_plots(
  SS_output(Block7dir, covar = TRUE), 
  dir = Block7dir, #basedir, 
  printfolder = "plots", 
  plot = c(1:21, 23:26)
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
