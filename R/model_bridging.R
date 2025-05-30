
library("dplyr")
library("tidyr")
library("ggplot2")
library("r4ss")
library("here")
library("renv")
library("future.apply")

source(here("R", "functions", "bridging_functions.R"))

skip_finished <- FALSE
launch_html <- FALSE

# Base model, post data-bridging --------------------------

databridge_dir <- here("models", "data_bridging", "finalised_data_bridging")
basedir <- here(databridge_dir, "data_bridged_model_weighted")

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

# Location for all model bridging runs
dir.create(bridgedir <- here("models", "model_bridging"))

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

ctrl <- SS_readctl(paste0(LWdir, "/2025widow.ctl"), datlist = paste0(LWdir, "/2025widow.dat"))

ctrl$MG_parms["Wtlen_1_Fem_GP_1", ]$INIT <- 1.59e-5
ctrl$MG_parms["Wtlen_2_Fem_GP_1", ]$INIT <- 2.99
ctrl$MG_parms["Wtlen_1_Mal_GP_1", ]$INIT <- 1.45e-5
ctrl$MG_parms["Wtlen_2_Mal_GP_1", ]$INIT <- 3.01

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

# Midwater trawl blocks -----------------------------------

dir.create(blockdir <- here(bridgedir, "MDT_Ret_Block"))
r4ss::copy_SS_inputs(SRdir, blockdir, overwrite = TRUE)

ctrl <- SS_readctl(here(blockdir, "/2025widow.ctl"), datlist = here(blockdir, "/2025widow.dat"))

# Add new block for midwater trawl retention
ctrl$Block_Design[[12]] <- c(ctrl$Block_Design[[7]], c(2011, 2016))

# Increment the number of block designs
ctrl$N_Block_Designs <- ctrl$N_Block_Designs + 1

# Number of blocks in new block group
ctrl$blocks_per_pattern <- c(ctrl$blocks_per_pattern, "blocks_per_pattern_12" = as.numeric(ctrl$blocks_per_pattern[7] + 1))

# Reassign block for retention asymptote
ctrl$size_selex_parms["SizeSel_PRet_3_MidwaterTrawl(2)", "Block"] <- 12
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
source(here("R", "jitters.R"))

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

##Read in the newly formatted forecast file, edit and overwrite
fcst <- r4ss::SS_readforecast(here("scratch","newly_formatted_2025_foc.ss"))

#Set P*45 for projection table
fcst$Flimitfraction_m <- SS_read(here("data_derived","decision_table","45_base"))$fore$Flimitfraction_m

gmt_fcst <- read.csv(here("data_provided", "GMT_forecast_catch", "GMT_forecast_catch.csv"))
gmt_fcst <- gmt_fcst |> mutate(seas = 1) |> select(year, seas, fleet, catch_or_F = catch_mt)
fcst$ForeCatch <- gmt_fcst

SS_writeforecast(mylist = fcst, dir = Base2025, overwrite = TRUE)

#Run the model
r4ss::run(dir = here("models", "2025 base model"), exe = ss3_exe, skipfinished = FALSE)
r4ss::run(dir = here("models", "2025 base model"), exe = ss3_exe, skipfinished = FALSE, extras = "-hess_step")
r4ss::SS_plots(replist = r4ss::SS_output(here("models", "2025 base model")), dir = here::here("figures","2025 base model r4ss plots"))
