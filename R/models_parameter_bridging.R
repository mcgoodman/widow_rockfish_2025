
library("dplyr")
library("tidyr")
library("ggplot2")
library("r4ss")
library("here")
library("PEPtools")

source(here("R", "functions", "bridging_functions.R"))

if (!exists("skip_finished")) skip_finished <- FALSE
if (!exists("launch_html")) launch_html <- FALSE

# Base model, post data-bridging --------------------------

databridge_dir <- here("models", "data_bridging")
basedir <- here(databridge_dir, "data_bridged_model_weighted")

# Location for all model bridging runs
dir.create(bridgedir <- here("models", "model_bridging"))

# Download SS3 exe and return absolute path
ss3_exe <- file.path(basedir, set_ss3_exe(basedir, version = "v3.30.23.1"))

# Run base model
r4ss::run(
  dir = basedir,
  exe = ss3_exe,
  extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = skip_finished
)

if (!skip_finished) {
  SS_plots(
    SS_output(basedir), 
    dir = basedir, 
    printfolder = "plots", 
    html = launch_html
  )
} else if (launch_html) {
  SS_html(
    SS_output(basedir), 
    plotdir = here(basedir, "plots")
  )
}

# Mortality -----------------------------------------------

# Copy over model files from base model to modify
dir.create(Mdir <- here(bridgedir, "mortality"))
r4ss::copy_SS_inputs(basedir, Mdir, overwrite = TRUE)

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
  exe = ss3_exe,
  extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = skip_finished
)

if (!skip_finished) {
  SS_plots(
    SS_output(Mdir), 
    dir = Mdir, 
    printfolder = "plots", 
    html = launch_html
  )
} else if (launch_html) {
  SS_html(
    SS_output(Mdir), 
    plotdir = here(Mdir, "plots")
  )
}

# Length / weight parameters ------------------------------

dir.create(LWdir <- here(bridgedir, "length_weight"))
r4ss::copy_SS_inputs(Mdir, LWdir, overwrite = TRUE)

lw_pars <- read.csv(here("data_derived", "length_weight", "weight_length_estimates.csv"))

ctrl <- SS_readctl(paste0(LWdir, "/2025widow.ctl"), datlist = paste0(LWdir, "/2025widow.dat"))

ctrl$MG_parms["Wtlen_1_Fem_GP_1", ]$INIT <- lw_pars$A[lw_pars$Source == "All" & lw_pars$sex == "female"]
ctrl$MG_parms["Wtlen_2_Fem_GP_1", ]$INIT <- lw_pars$B[lw_pars$Source == "All" & lw_pars$sex == "female"]
ctrl$MG_parms["Wtlen_1_Mal_GP_1", ]$INIT <- lw_pars$A[lw_pars$Source == "All" & lw_pars$sex == "male"]
ctrl$MG_parms["Wtlen_2_Mal_GP_1", ]$INIT <- lw_pars$B[lw_pars$Source == "All" & lw_pars$sex == "male"]

SS_writectl(ctrl, paste0(LWdir, "/2025widow.ctl"), overwrite = TRUE)

# Need to run with hessian to estimate bias-adjustment ramp
r4ss::run(
  dir = LWdir,
  exe = ss3_exe,
  show_in_console = TRUE,
  skipfinished = skip_finished
)

LW_replist <- SS_output(LWdir, covar = TRUE)

if (!skip_finished) {
  SS_plots(
    LW_replist, 
    dir = LWdir, 
    printfolder = "plots", 
    html = launch_html
  )
} else if (launch_html) {
  SS_html(
    SS_output(LWdir), 
    plotdir = here(LWdir, "plots")
  )
}

# Recruitment bias ramp -----------------------------------

dir.create(SRdir <- here(bridgedir, "SR_bias_adj"))
r4ss::copy_SS_inputs(LWdir, SRdir, overwrite = TRUE)

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
  exe = ss3_exe,
  extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = skip_finished
)

if (!skip_finished) {
  SS_plots(
    SS_output(SRdir, covar=TRUE), 
    dir = SRdir, #basedir, 
    printfolder = "plots", 
    html = launch_html
  )
} else if (launch_html) {
  SS_html(
    SS_output(SRdir), 
    plotdir = here(SRdir, "plots")
  )
}

# Midwater, Hke, Hnl time blocks --------------------------

dir.create(blockdir <- here(bridgedir, "MDT_HKE_Ret_Block"))
r4ss::copy_SS_inputs(SRdir, blockdir, overwrite = TRUE)

ctrl <- SS_readctl(here(blockdir, "/2025widow.ctl"), datlist = here(blockdir, "/2025widow.dat"))

## New hake retention block -------------------------------

ctrl$Block_Design[[11]] <- c(1916, 2019)

# Increment the number of block designs
ctrl$N_Block_Designs <- ctrl$N_Block_Designs + 1

# Number of blocks in new block group
ctrl$blocks_per_pattern <- c(ctrl$blocks_per_pattern, "blocks_per_pattern_11" = 1)

#Adjust the blocks on hake selx pars 1,2,3
old_sel_pars <- ctrl$size_selex_parms[c("SizeSel_P_1_Hake(3)", "SizeSel_P_2_Hake(3)", "SizeSel_P_3_Hake(3)"),]
new_sel_pars <- old_sel_pars |> mutate(Block = 11, Block_Fxn = 2)

# Reassign block for hake selex
ctrl$size_selex_parms[c("SizeSel_P_1_Hake(3)","SizeSel_P_2_Hake(3)","SizeSel_P_3_Hake(3)"),] <- new_sel_pars
ctrl$size_selex_parms["SizeSel_PRet_3_MidwaterTrawl(2)", "PHASE"] <- 2

# Add rows to time-varying selectivity for relevant parameters
ctrl$size_selex_parms_tv <- rbind(ctrl$size_selex_parms_tv[1:24,], #up to midwater sel pars
                                 new_sel_pars[,1:7], # new hake sel pars
                                 ctrl$size_selex_parms_tv[25:29,]) #hnl onward sl pars

# Update row names in time-varying selectivity parameters block
hake_ret_rows <- grepl("_Hake(3)", rownames(ctrl$size_selex_parms_tv), fixed = TRUE)
rownames(ctrl$size_selex_parms_tv)[hake_ret_rows] <- paste0(rownames(ctrl$size_selex_parms_tv)[hake_ret_rows], "_BLK11repl_1916")

## New midwater trawl retention block ---------------------

ctrl$Block_Design[[12]] <- c(ctrl$Block_Design[[7]], c(2011, 2016))

# Increment the number of block designs
ctrl$N_Block_Designs <- ctrl$N_Block_Designs + 1

# Number of blocks in new block group
ctrl$blocks_per_pattern <- c(ctrl$blocks_per_pattern, "blocks_per_pattern_12" = as.numeric(ctrl$blocks_per_pattern[7] + 1))

# Reassign block for retention asymptote
ctrl$size_selex_parms["SizeSel_PRet_3_MidwaterTrawl(2)", "Block"] <- 12

# Turn on estimation of retention in the final time block
ctrl$size_selex_parms["SizeSel_PRet_3_MidwaterTrawl(2)", "PHASE"] <- 2

# Add rows to time-varying selectivity for relevant parameters
ctrl$size_selex_parms_tv <- 
  ctrl$size_selex_parms_tv |> 
  insert_row(
    new_row = "SizeSel_PRet_3_MidwaterTrawl(2)_BLK7repl_2011",
    ref_row = "SizeSel_PRet_3_MidwaterTrawl(2)_BLK7repl_2002"#,
    #INIT = 10, PHASE = -2 # Set at boundary -> Full retention 2011-2016
    # INIT = 4.59512, PHASE = -2 # Set at 0.99 retention (same as early and final years)
  )

# Update row names in time-varying selectivity parameters block
mdt_ret_rows <- grepl("SizeSel_PRet_3_MidwaterTrawl(2)_BLK7repl_", rownames(ctrl$size_selex_parms_tv), fixed = TRUE)
rownames(ctrl$size_selex_parms_tv)[mdt_ret_rows] <- gsub("BLK7", "BLK12", rownames(ctrl$size_selex_parms_tv)[mdt_ret_rows])

# Fix ascending with of Hook & Line Selectivity at lower bound
ctrl$size_selex_parms["SizeSel_P_3_HnL(5)", "INIT"] <- -5
ctrl$size_selex_parms["SizeSel_P_3_HnL(5)", "PHASE"] <- -2

# Better initial values from jittering runs
ctrl$size_selex_parms$INIT <- c(43.4649, -1.80857, 4.59681, 9, -9, 8, 3.65822, 0.94448, 4.59512, 
                                0, 36.9415, -9.42479, 2.86093, 3.93042, -9, -1.31066, -5, 1.2, 
                                5.76562, 0, 33.4628, -1.95041, 2.07216, 9, -9, 8, 42.6301, 2.50606, 
                                3.56247, 9, -9, 8, 23.5551, 2.4995, -5, 9, -9, 8, 15.202, 2.82473, 
                                7.42538, 0, 0, 0.11879, 0.03989, 24, 34, 48, -1.82288, -1, 0.449, 
                                0, 0.46803, -0.10048, 24, 34, 48, -2.23028, -1, -0.0919, 1, -1)

ctrl$size_selex_parms_tv$INIT <- c(38.9887, 3.43106, 27.2069, 27.4913, 0.96811, 1.83185, 1.71039, 
                                   0.76421, 0.10521, 38.6506, 38.0022, 37.3779, 3.36663, 3.07693, 
                                   2.79, 4.2676, 3.06196, -1.3839, -1.99095, -0.41643, 1.63249, 
                                   4.5912, 1.65703, 1.85385, 8.94664, 42.7146, 2.50182, 3.70709, 
                                   37.2372, 3.75028, -5, 1.2, 4.5912)

## Address warnings ---------------------------------------

# SS3 Warning: 
# Note 2 Suggestion: This model has just one settlement event. 
# Changing to recr_dist_method 4 and removing the recruitment distribution parameters
# at the end of the MG parms section (below growth parameters) will produce identical
# results and simplify the model.
ctrl$recr_dist_method <- 4
ctrl$MG_parms <- ctrl$MG_parms[!grepl("RecrDist", rownames(ctrl$MG_parms)),]

SS_writectl(ctrl, here(blockdir, "/2025widow.ctl"), overwrite = TRUE)

# Change length / age comp partition for fleets without estimated retention
# This is already handled by SS3, but is implemented here to get rid of warnings
dat <- SS_readdat(here(blockdir, "/2025widow.dat"))
dat$lencomp$part[dat$lencomp$fleet %in% c(3, 4, 5)] <- 0
dat$agecomp$part[dat$agecomp$fleet %in% c(3, 4, 5)] <- 0
SS_writedat(dat, here(blockdir, "/2025widow.dat"), overwrite = TRUE)

# Set non-zero forecast fishing mortalities
fcst <- SS_readforecast(here(blockdir, "forecast.ss"))
fcst$vals_fleet_relative_f[fcst$vals_fleet_relative_f == 0]  <- 1e-4
SS_writeforecast(fcst, dir = blockdir, file = "forecast.ss", overwrite = TRUE)

## Run with blocks ----------------------------------------

r4ss::run(
  dir = blockdir,
  exe = ss3_exe,
  #extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = skip_finished
)

if (!skip_finished) {
  SS_plots(
    SS_output(blockdir, covar = TRUE), 
    dir = blockdir, #basedir, 
    printfolder = "plots", 
    html = launch_html
  )
} else if (launch_html) {
  SS_html(
    SS_output(blockdir), 
    plotdir = here(blockdir, "plots")
  )
}

# View time-varying retention parameters
block_run <- SS_output(blockdir, covar = TRUE)

# Fits to discards, log-scale 
SR_run <- SS_output(SRdir, covar=TRUE)
dir.create(plot_dir <- here(blockdir, "plots"))
discards <- bind_rows(list(
  "+ Updated bias-adjustment ramp" = filter(SR_run$discard, Fleet_Name == "MidwaterTrawl"), 
  "+ Midwater block, 2011-2016" = filter(block_run$discard, Fleet_Name == "MidwaterTrawl")
), .id = "model")

discards |>  
  ggplot(aes(Yr)) + 
  geom_point(aes(y = log(Exp), color = model), position = position_dodge(width = 0.5)) + 
  geom_pointrange(aes(y = log(Obs), ymin = log(Obs) - Std_use, ymax = log(Obs) + Std_use, color = "observed"), size = 0.25) + 
  labs(x = "Year", y = "log(discards)", color = "source") + 
  guides(color = guide_legend(reverse = TRUE)) +
  scale_x_continuous(breaks = seq(1984, 2024, 4)) + 
  theme_bw() +
  theme(legend.position = "bottom", panel.grid.minor.x = element_blank()) + 
  scale_color_manual(values = c(r4ss::rich.colors.short(4)[c(2, 4)], "black"))

ggsave(here(plot_dir, "discard_fits.png"), height = 3, width = 6, units = "in")

# Rerun from new MLE, post jittering ----------------------

# Settings for jittering - use fewer runs, 
# and set block run as base model
base_dir <- blockdir
njitters <- 50
source(here("R", "diagnostics_jitters.R"))

# Copy files to directory
dir.create(mle_dir <- here(bridgedir, "jittered_mle"))
r4ss::copy_SS_inputs(blockdir, mle_dir, overwrite = TRUE)

# Copy par file from best jitter run
file.copy(here("models", "jitters", "ss3.par_best.sso"), here(mle_dir, "ss.par"), overwrite = TRUE)

# Change starter file to use par file for initial values
mle_start <- SS_readstarter(here(mle_dir, "starter.ss"))
mle_start$init_values_src <- 1
mle_start$N_bootstraps <- 1
SS_writestarter(mle_start, dir = mle_dir, file = "starter.ss", overwrite = TRUE)

# Run without estimation to produce new control file
r4ss::run(
  dir = mle_dir,
  exe = ss3_exe,
  extras = "-nohess -stopph 0",
  show_in_console = TRUE,
  skipfinished = skip_finished
)

# Replace control file
file.copy(here(mle_dir, "control.ss_new"), here(mle_dir, "2025widow.ctl"), overwrite = TRUE)

# Change starter file back to using control file for initial values
mle_start <- SS_readstarter(here(mle_dir, "starter.ss"))
mle_start$init_values_src <- 0
mle_start$N_bootstraps <- 0
SS_writestarter(mle_start, dir = mle_dir, file = "starter.ss", overwrite = TRUE)

# Run
r4ss::run(
  dir = mle_dir,
  exe = ss3_exe,
  show_in_console = TRUE,
  skipfinished = skip_finished
)

if (!skip_finished) {
  SS_plots(
    SS_output(blockdir, covar = TRUE), 
    dir = blockdir, #basedir, 
    printfolder = "plots", 
    html = launch_html
  )
} else if (launch_html) {
  SS_html(
    SS_output(blockdir), 
    plotdir = here(blockdir, "plots")
  )
}

# Set new base model, add fcst catches, run ---------------

# Use base model with block on midwater trawl retention
dir.create(Base2025 <- here("models", "2025 base model"))
r4ss::copy_SS_inputs(mle_dir, Base2025, overwrite = TRUE)

## Forecast file changes ----------------------------------

##Read in the newly formatted forecast file, edit and overwrite
fcst <- r4ss::SS_readforecast(here("data_provided", "SS3_inputs", "forecast_reformatted_2025.ss"))

## Set the rebuilder years to 0 -> West coast rebuilder is off, so this hsouldnt make a difference
fcst$Ydecl  <- 0
fcst$Yinit  <- 0
#Set P*45 for projection table
fcst$Flimitfraction_m <- PEPtools::get_buffer(2025:2036, sigma = 0.5, pstar = 0.45)

gmt_fcst <- read.csv(here("data_provided", "GMT_forecast_catch", "GMT_forecast_catch.csv"))
gmt_fcst <- gmt_fcst |> mutate(seas = 1) |> select(year, seas, fleet, catch_or_F = catch_mt)
fcst$ForeCatch <- gmt_fcst

SS_writeforecast(mylist = fcst, dir = Base2025, overwrite = TRUE)

## Clean up data file -------------------------------------

dat <- r4ss::SS_readdat(here(Base2025, "2025widow.dat"))

dat$CPUE <- dat$CPUE[dat$CPUE$year > 0,]
dat$lencomp <- arrange(dat$lencomp[dat$lencomp$year > 0,], fleet, year)
dat$agecomp <- arrange(dat$agecomp[dat$agecomp$year > 0,], fleet, year)

r4ss::SS_writedat(dat, here(Base2025, "2025widow.dat"), overwrite = TRUE)

## Run using Hessian information --------------------------

## Run with Hessian around MLE to improve final gradient
r4ss::run(dir = here("models", "2025 base model"), exe = ss3_exe, skipfinished = FALSE)
r4ss::run(dir = here("models", "2025 base model"), exe = ss3_exe, skipfinished = FALSE, extras = "-hess_step")
r4ss::SS_plots(replist = r4ss::SS_output(here("models", "2025 base model")), dir = here::here("figures","2025 base model r4ss plots"))
