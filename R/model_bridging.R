
library("tidyverse")
library("r4ss")
library("here")

source(here("R", "functions", "bridging_functions.R"))

skip_finished <- FALSE
launch_html <- TRUE

# Base model ----------------------------------------------

# This will be Mico's 2025 base model
basedir <- here("models", "data_bridging", "finalised_data_bridging", "data_bridged_model_weighted")

# Download SS3 exe and return name
base_exe <- set_ss3_exe(basedir)

# Run base model
r4ss::run(
  dir = basedir,
  exe = base_exe,
  #extras = "-nohess",
  show_in_console = TRUE,
  skipfinished = TRUE
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
  skipfinished = skip_finished
)

LW_replist <- SS_output(LWdir)

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

# Midwater trawl selectivity (parameters 1, 3, 4, 6), 
# and retention (parameter 3)

dir.create(blockdir <- here(bridgedir, "MDT_Ret_Block"))
r4ss::copy_SS_inputs(SRdir, blockdir, overwrite = TRUE)
blockexe <- set_ss3_exe(blockdir)

ctrl <- SS_readctl(paste0(blockdir, "/2025widow.ctl"), datlist = paste0(blockdir, "/2025widow.dat"))

# Add new block for midwater trawl retention
ctrl$Block_Design[[12]] <- c(ctrl$Block_Design[[7]], c(2011, 2016))

# Increment the number of block design
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

SS_writectl(ctrl, paste0(blockdir, "/2025widow.ctl"), overwrite = TRUE)

r4ss::run(
  dir = blockdir,
  exe = blockexe,
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
block_run$parameters |> filter(grepl("Midwater", Label) & grepl("Ret", Label)) |> View()

# Compare -------------------------------------------------

#Comparison plots produced by r4ss
dirs <- c(
  "data bridging" = basedir,
  "+ Hamel & Cope 2022 M Prior" = Mdir,
  "+ Updated length-weight pars" = LWdir,
  "+ Updated bias-adjustment ramp" = SRdir,
  "+ Midwater retention block, 2011-2016" = blockdir
)

models <- SSgetoutput(dirvec = dirs, getcovar = TRUE)
models_ss <- SSsummarize(models)

labels <- c(
  "Year", "Spawning biomass (t)", "Relative spawning biomass", "Age-0 recruits (1,000s)",
  "Recruitment deviations", "Index", "Log index", "1 - SPR", "Density","Management target", 
  "Minimum stock size threshold", "Spawning output", "Harvest rate"
)

dir.create(plot_dir <- here("models", "comparison_plots", "model_bridging"), recursive = TRUE)

SSplotComparisons(
  models_ss,
  print = TRUE,
  plotdir = plot_dir,
  labels = labels,
  densitynames = c("SSB_2025", "SSB_Virgin"),
  legendlabels = names(dirs),
  indexPlotEach = TRUE,
  filenameprefix = "model_bridging_", 
  legendloc = "bottomleft"
)

# Correlations among shared parameters
parcor <- cor(models_ss$pars[,paste0("replist", 1:5)], use = "pairwise.complete.obs")
parcor[upper.tri(parcor) ] <- NA; diag(parcor) <- NA
colnames(parcor) <- rownames(parcor) <- names(dirs)
View(round(parcor, 4))

# Likelihood by fleet
models_ss$likelihoods_by_fleet |> 
  pivot_longer(ALL:ForeignAtSea, names_to = "fleet", values_to = "likelihood") |> 
  mutate(model = factor(names(dirs)[model], levels = names(dirs))) |>  
  ggplot(aes( likelihood, Label, color = model)) + 
  facet_wrap(~fleet, scales = "free_x") + 
  geom_jitter(height = 0.5, width = 0) + 
  theme(legend.position = "top")

ggsave(here(plot_dir, "likelihoods_all.png"), height = 6, width = 9, units = "in", scale = 1.4)

# Likelihood-ratio test of 2011-2016 retention block
pchisq(2 * (models_ss$likelihoods$replist4[1] - models_ss$likelihoods$replist5[1]), df = 4, lower.tail = FALSE)

# Fits to discards, log-scale 
SR_run <- SS_output(SRdir, covar=TRUE)
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

# Copy selected model to new base directory ---------------

# Use base model without new midwater trawl block
dir.create(Base2025 <- here("models", "2025 base model"))
r4ss::copy_SS_inputs(blockdir, Base2025, overwrite = TRUE)

