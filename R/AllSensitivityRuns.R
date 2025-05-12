
# Install r4ss
# devtools::install_github("https://github.com/r4ss/r4ss.git")

library("tidyverse")
library("r4ss")
library("here")
library("parallel")

files <- list.files(here("R", "functions"), full.names = TRUE)
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
  ss3_exe <- ss3_exe[which(vapply(ss3_exe, \(x) file.exists(file.path(dir, paste0(x, ".exe"))), 
                                  logical(1)))]
  return(ss3_exe)
  
}

# Name of model direct
model_directory <- 'models'
dir.create(here("models", "sensitivities"))

# Create executable
ss3_exe <- set_ss3_exe("models", version = "v3.30.23")

# Save executable location
exe_loc <- here(model_directory, ss3_exe)

# Base model name
base_model_name <- '2025 base model'

# ------------------------------------------------------------------------------
# 2025 Base Model (only if not already run!)
# ------------------------------------------------------------------------------

# Read in the base file
run_base_model <- here(model_directory, base_model_name)

# run model
r4ss::run(
  dir = run_base_model, # make sure to edit the directory
  exe = exe_loc,
  show_in_console = TRUE,
  skipfinished = skip_finished
)

# Get r4ss output
replist <- SS_output( # make the output files
  dir = run_base_model,
  verbose = TRUE,
  printstats = TRUE,
  covar = TRUE
)

# ------------------------------------------------------------------------------
# If 2025 Base Model is run
# ------------------------------------------------------------------------------

# Read base model if made
base_model <- SS_read(file.path(model_directory, base_model_name), 
                      ss_new = FALSE)

# Where Outputs are stored
base_out <- SS_output(file.path(model_directory, base_model_name))

# ------------------------------------------------------------------------------
# Write sensitivities 
# ------------------------------------------------------------------------------

## Weighting composition data with Francis Method ------------------------------

### step 1: Create outputs by copying input files 

r4ss::copy_SS_inputs(dir.old = file.path(model_directory, base_model_name), 
                       dir.new = file.path(model_directory, "sensitivities", "Francis"))

#### copy over the Report file 
file.copy(from = file.path(model_directory, base_model_name,
                           c('Report.sso', 'CompReport.sso', 
                             'warning.sso')), 
          to = file.path(model_directory, "sensitivities", 
                         "Francis", c('Report.sso', 'CompReport.sso',
                                      'warning.sso')),
          overwrite = TRUE)

### step 2: Run function tune_comps

#### Run Francis data weighting, and tune original model method in 1 go. 
#### Note that the original model must have been previously run with Stock 
#### Synthesis, so that a report file is available.
tune_comps(
  dir = file.path(model_directory, "sensitivities", "Francis"),
  option = "Francis",
  exe = exe_loc,
  extras = "-nohess",
  verbose = FALSE,
  niters_tuning = 3, 
)

## Fixing steepness at 2019 selectivity values ---------------------------------

### Step 1: Copy base model

fix_steep_A <- base_model

### Step 2: Apply sensitivity changes
fix_steep_A$ctl$SR_parms["SR_BH_steep", ]$INIT <- 0.4 # fixed value
fix_steep_A$ctl$SR_parms["SR_BH_steep", ]$PHASE <- -1*fix_steep_A$ctl$SR_parms["SR_BH_steep", ]$PHASE # negative phase = no estimations

### Step 3: Save sensitivity as new model

SS_write(fix_steep_A, file.path("models", "sensitivities", "FixedSteep2019_A"),
         overwrite = TRUE)

### Step 1: Copy base model

fix_steep_B <- base_model

### Step 2: Apply sensitivity changes
fix_steep_B$ctl$SR_parms["SR_BH_steep", ]$INIT <- 0.6 # fixed value
fix_steep_B$ctl$SR_parms["SR_BH_steep", ]$PHASE <- -1*fix_steep_B$ctl$SR_parms["SR_BH_steep", ]$PHASE # negative phase = no estimations

### Step 3: Save sensitivity as new model

SS_write(fix_steep_B, file.path("models", "sensitivities", "FixedSteep2019_B"),
         overwrite = TRUE)

### Step 1: Copy base model

fix_steep_C <- base_model

### Step 2: Apply sensitivity changes
fix_steep_C$ctl$SR_parms["SR_BH_steep", ]$INIT <- 0.798 # fixed value
fix_steep_C$ctl$SR_parms["SR_BH_steep", ]$PHASE <- -1*fix_steep_C$ctl$SR_parms["SR_BH_steep", ]$PHASE # negative phase = no estimations

### Step 3: Save sensitivity as new model

SS_write(fix_steep_C, file.path("models", "sensitivities", "FixedSteep2019_C"),
         overwrite = TRUE)

## Fixing mortality at 2019 selectivity values ---------------------------------

### Step 1: Copy base model

fix_mort_A <- base_model

### Step 2: Apply sensitivity changes
fix_mort_A$ctl$MG_parms["NatM_p_1_Fem_GP_1", ]$INIT <- 0.1 # fixed value
fix_mort_A$ctl$MG_parms["NatM_p_1_Fem_GP_1", ]$PHASE <- -1*fix_mort_A$ctl$MG_parms["NatM_p_1_Fem_GP_1", ]$PHASE # negative phase = no estimations
fix_mort_A$ctl$MG_parms["NatM_p_1_Mal_GP_1", ]$INIT <- 0.1
fix_mort_A$ctl$MG_parms["NatM_p_1_Mal_GP_1", ]$PHASE <- -1*fix_mort_A$ctl$MG_parms["NatM_p_1_Mal_GP_1", ]$PHASE

### Step 3: Save sensitivity as new model

SS_write(fix_mort_A, file.path("models", "sensitivities", "FixedFMort2019_A"),
         overwrite = TRUE)

### Step 1: Copy base model

fix_mort_B <- base_model

### Step 2: Apply sensitivity changes
fix_mort_B$ctl$MG_parms["NatM_p_1_Fem_GP_1", ]$INIT <- 0.124 # fixed value
fix_mort_B$ctl$MG_parms["NatM_p_1_Fem_GP_1", ]$PHASE <- -1*fix_mort_B$ctl$MG_parms["NatM_p_1_Fem_GP_1", ]$PHASE # negative phase = no estimations
fix_mort_B$ctl$MG_parms["NatM_p_1_Mal_GP_1", ]$INIT <- 0.129
fix_mort_B$ctl$MG_parms["NatM_p_1_Mal_GP_1", ]$PHASE <- -1*fix_mort_B$ctl$MG_parms["NatM_p_1_Mal_GP_1", ]$PHASE

### Step 3: Save sensitivity as new model

SS_write(fix_mort_B, file.path("models", "sensitivities", "FixedFMort2019_B"),
         overwrite = TRUE)

## Forcing asymptotic selectivity on the midwater trawl fleet ------------------

### Step 1: Copy base model

asy_select_mwt <- base_model

### Step 2: Apply sensitivity changes
# set all base high, and no estimation
base_sel_list <- c("SizeSel_P_2_MidwaterTrawl(2)", "SizeSel_P_4_MidwaterTrawl(2)", "SizeSel_P_6_MidwaterTrawl(2)")
asy_select_mwt$ctl$size_selex_parms[row.names(asy_select_mwt$ctl$size_selex_parms) %in% base_sel_list,]$INIT <- rep(15)
asy_select_mwt$ctl$size_selex_parms[row.names(asy_select_mwt$ctl$size_selex_parms) %in% base_sel_list,]$PHASE <- -1*asy_select_mwt$ctl$size_selex_parms[row.names(asy_select_mwt$ctl$size_selex_parms) %in% base_sel_list,]$PHASE
# then deal w time varying
tm_vy_list <- c("SizeSel_P_4_MidwaterTrawl(2)_BLK7repl_1916",
                "SizeSel_P_4_MidwaterTrawl(2)_BLK7repl_1983",
                "SizeSel_P_4_MidwaterTrawl(2)_BLK7repl_2002",
                "SizeSel_P_6_MidwaterTrawl(2)_BLK7repl_1916",
                "SizeSel_P_6_MidwaterTrawl(2)_BLK7repl_1983",
                "SizeSel_P_6_MidwaterTrawl(2)_BLK7repl_2002")
asy_select_mwt$ctl$size_selex_parms_tv[row.names(asy_select_mwt$ctl$size_selex_parms_tv) %in% tm_vy_list,]$INIT <- rep(15)
asy_select_mwt$ctl$size_selex_parms_tv[row.names(asy_select_mwt$ctl$size_selex_parms_tv) %in% tm_vy_list,]$PHASE <- -1*asy_select_mwt$ctl$size_selex_parms_tv[row.names(asy_select_mwt$ctl$size_selex_parms_tv) %in% tm_vy_list,]$PHASE

### Step 3: Save sensitivity as new model

SS_write(asy_select_mwt, file.path("models", "sensitivities", "AsympSelMidwaterTrawl"),
         overwrite = TRUE)

## Fitting logistic curves for survey selectivities ----------------------------

### Step 1: Copy base model

log_select_survey <- base_model

### Step 2: Apply sensitivity changes
log_select_survey$ctl$size_selex_types["NWFSC",]$Pattern <- 1 # for logisitic
log_select_survey$ctl$age_selex_types["NWFSC",]$Pattern <- 12 # for logisitic
# size selectivity: replace with P_1 & P_2
# names to remove
rm_old_spline <- c("SizeSel_Spline_Code_NWFSC(8)", 
                   "SizeSel_Spline_GradLo_NWFSC(8)",
                   "SizeSel_Spline_GradLo_NWFSC(8)",
                   "SizeSel_Spline_GradHi_NWFSC(8)",
                   "SizeSel_Spline_Knot_1_NWFSC(8)",
                   "SizeSel_Spline_Knot_2_NWFSC(8)",
                   "SizeSel_Spline_Knot_3_NWFSC(8)",
                   "SizeSel_Spine_Val_1_NWFSC(8)",
                   "SizeSel_Spine_Val_2_NWFSC(8)",
                   "SizeSel_Spine_Val_3_NWFSC(8)")
log_select_survey$ctl$size_selex_parms <- log_select_survey$ctl$size_selex_parms[!(row.names(log_select_survey$ctl$size_selex_parms) %in% rm_old_spline), ]
# and insert the two new parameters, choosing inital values based on 2019 spline results
log_select_survey$ctl$size_selex_parms <- 
  log_select_survey$ctl$size_selex_parms |> 
  insert_row(
    new_row = "SizeSel_P_1_NWFSC(8)",
    ref_row = "SizeSel_Spine_Val_3_Triennial(7)"
  )
log_select_survey$ctl$size_selex_parms["SizeSel_P_1_NWFSC(8)", ] <- c(20, 50, 35, 35, 0.5, 0, 2, 0, 0, 0, 0, 0.5, 0, 0) 
log_select_survey$ctl$size_selex_parms <- 
  log_select_survey$ctl$size_selex_parms |> 
  insert_row(
    new_row = "SizeSel_P_2_NWFSC(8)",
    ref_row = "SizeSel_P_1_NWFSC(8)"
  )
log_select_survey$ctl$size_selex_parms["SizeSel_P_2_NWFSC(8)", ] <- c(5, 20, 15, 15, 0.5, 0, 2, 0, 0, 0, 0, 0.5, 0, 0) 

# hold age_selex_parms for now, they are P_1, P_2.... though add estimation of them, i.e., change phase to positive number
log_select_survey$ctl$age_selex_parms["AgeSel_P_1_NWFSC(8)", ]$PHASE <- 2
log_select_survey$ctl$age_selex_parms["AgeSel_P_2_NWFSC(8)", ]$PHASE <- 2

### Step 3: Save sensitivity as new model

SS_write(log_select_survey, file.path("models", "sensitivities", "LogisCurvSurvSel"),
         overwrite = TRUE)

## Excluding triennial survey ----------------------------

### Step 1: Copy base model

no_tri_survey <- base_model

### Step 2: Apply sensitivity changes
# fix selectivity for tri survey--needed??
# q opts list
q_opts_list <- c("LnQ_base_Triennial(7)","Q_extraSD_Triennial(7)")
no_tri_survey$ctl$Q_parms[row.names(no_tri_survey$ctl$Q_parms) %in% q_opts_list,]$PHASE <- -1*no_tri_survey$ctl$Q_parms[row.names(no_tri_survey$ctl$Q_parms) %in% q_opts_list,]$PHASE

# selex parameters
base_sel_list <- c("SizeSel_Spline_Code_Triennial(7)", "SizeSel_Spline_GradLo_Triennial(7)", "SizeSel_Spline_GradHi_Triennial(7)", "SizeSel_Spline_Knot_1_Triennial(7)", "SizeSel_Spline_Knot_2_Triennial(7)", "SizeSel_Spline_Knot_3_Triennial(7)", "SizeSel_Spine_Val_1_Triennial(7)", "SizeSel_Spine_Val_2_Triennial(7)", "SizeSel_Spine_Val_3_Triennial(7)")
no_tri_survey$ctl$size_selex_parms[row.names(no_tri_survey$ctl$size_selex_parms) %in% base_sel_list,]$PHASE <- -1*no_tri_survey$ctl$size_selex_parms[row.names(no_tri_survey$ctl$size_selex_parms) %in% base_sel_list,]$PHASE

# then deal w time varying
tm_vy_list <- c("LnQ_base_Triennial(7)_BLK9add_1995")
no_tri_survey$ctl$size_selex_parms_tv[row.names(no_tri_survey$ctl$size_selex_parms_tv) %in% tm_vy_list,]$PHASE <- -1*no_tri_survey$ctl$size_selex_parms_tv[row.names(no_tri_survey$ctl$size_selex_parms_tv) %in% tm_vy_list,]$PHASE

no_tri_survey$dat$CPUE$index <- ifelse(no_tri_survey$dat$CPUE$index==7, -1*no_tri_survey$dat$CPUE$index, no_tri_survey$dat$CPUE$index)
no_tri_survey$dat$lencomp$fleet <- ifelse(no_tri_survey$dat$lencomp$fleet==7, -1*no_tri_survey$dat$lencomp$fleet, no_tri_survey$dat$lencomp$fleet)
no_tri_survey$dat$agecomp$fleet <- ifelse(no_tri_survey$dat$agecomp$fleet==7, -1*no_tri_survey$dat$agecomp$fleet, no_tri_survey$dat$agecomp$fleet)

### Step 3: Save sensitivity as new model

SS_write(no_tri_survey, file.path("models", "sensitivities", "NoTriSurvey"),
         overwrite = TRUE)

## WA catch reconstruction -----------------------------

# Step 1: Copy base model
wa_reconstruction <- base_model

### Step 2: Apply sensitivity changes

### Read in catch using new WA historical reconstruction
catch_wa_new <- read.csv(here("data_derived", "catches", "2025_catch_wa_reconstruction.csv"))
catch_wa_new <- catch_wa_new[catch_wa_new$year != -999,]

### Add back in Hook & Line discards (added during data bridging)
### Done by simply differencing catches from base model and those written out from R/catches.R
catch_noHnLdisc <- SS_readdat(here("models", "data_bridging", "finalised_data_bridging", "add_catches", "2025widow.dat"))$catch
catch_noHnLdisc <- catch_noHnLdisc |> rename(catch_noHnL = catch) |> select(-catch_se)

catch_diff <- base_model$dat$catch |> left_join(catch_noHnLdisc, by = c("year", "seas", "fleet")) |> 
  mutate(diff = catch - catch_noHnL) |> select(year, fleet, diff)

catch_wa_new <- catch_wa_new |> left_join(catch_diff, by = c("year", "fleet"))  |> 
  mutate(catch = catch + diff) |> select(-diff)
wa_reconstruction$dat$catch <- catch_wa_new

### Step 3: Save sensitivity as new model
SS_write(wa_reconstruction, file.path("models", "sensitivities", "NewWACatch"),
         overwrite = TRUE)

## Inclusion vs. exclusion of shrimp trawl catches -----------------------------

# Step 1: Copy base model
shrimp_trawl <- base_model

### Step 2: Apply sensitivity changes

### Read in catch with shrimp trawls added in
catch_w_shrimp <- read.csv(here("data_derived", "catches", "2025_catch_shrimp_added.csv"))
catch_w_shrimp <- catch_w_shrimp[catch_w_shrimp$year != -999,]

### Add back in Hook & Line discards
catch_w_shrimp <- catch_w_shrimp |> left_join(catch_diff, by = c("year", "fleet"))  |> 
  mutate(catch = catch + diff) |> select(-diff)

shrimp_trawl$dat$catch <- catch_w_shrimp

### Step 3: Save sensitivity as new model
SS_write(shrimp_trawl, file.path("models", "sensitivities", "ShrmpNoShrmp"),
         overwrite = TRUE)

## Any issues noted in the STAR or SSC reports ----------------------------

### Step 1: Copy base model
# sensi_mod <- base_model

### Step 2: Apply sensitivity changes

### Step 3: Save sensitivity as new model

# SS_write(sensi_mod, file.path("models", "sensitivities", "StarSscSens"),
#          overwrite = TRUE)

# Run all sensitivities -------------------------------------------------------

# List where sensitivity models are
model_list <- c(
  `Fixed natural mortality to 2015 prior` = "FixedFMort2019_A", 
  `Fixed natural mortality to 2011 prior` = "FixedFMort2019_B", 
  `Midwatertrawl asymptotic selectivity forced` = "AsympSelMidwaterTrawl", 
  `Logistic selectivity curves for surveys` = "LogisCurvSurvSel", 
  `Inclusing of shrimp trawl` = "ShrmpNoShrmp", 
  `New Washington catch reconstruction` = "NewWACatch",
  `Fixed steepness at 0.4` = "FixedSteep2019_A", 
  `Fixed steepness at 0.6` = "FixedSteep2019_B", 
  `Fixed steepness at 0.798 (2015 assessment)` = "FixedSteep2019_C", 
  `Exclusion of triennial survey` = "NoTriSurvey", 
  `Francis weighting` = "Francis"
)

model_paths <- setNames(here("models", "sensitivities", model_list), names(model_list))

# Plotting takes a long time, so do in parallel
cl <- parallel::makeCluster(length(model_list))

# Export required objects and packages
parallel::clusterEvalQ(cl, library(r4ss)) 
parallel::clusterExport(cl, c("set_ss3_exe", "exe_loc", "skip_finished"))

# Run all models
runs <- parallel::clusterApply(
  cl = cl, x = model_paths, \(x) r4ss::run(
    dir = x, exe = exe_loc, extras = "-nohess", skipfinished = skip_finished
  )
)

parallel::stopCluster(cl)

## Check all runs succeeded
run_checks <- vapply(runs, \(x) x == "ran model" | x == "contained Report.sso", logical(1))
if(!all(run_checks)) stop("1 or more runs failed")

#-------------------------------------------------------------------------------
# Only needed if updating indices in sensitivity runs
#-------------------------------------------------------------------------------

# furrr::future_map(sensi_dirs[-tuning_mods], \(x) 
#                   run(file.path("models", 'sensitivities ', x), 
#                       exe = exe_loc, extras = '-nohess', skipfinished = FALSE)
# )

# Indices sensitivities used in yelloweye rock fish assessment begin here-------

#furrr::future_map(c('nonlinear_q', 'oceanographic_index'), \(x) 
#                  run(file.path("models", 'sensitivities ', x), 
#                      exe = exe_loc, extras = '-nohess', skipfinished = FALSE)
#)
#
#future::plan(future::sequential)


# Plot stuff --------------------------------------------------------------

#-------------------------------------------------------------------------------
# Grouped plots
#-------------------------------------------------------------------------------

## If testing indices sensitivities --------------------------------------------

# indices <- c(
#   `No indices` = "no_indices", 
#   `- SMURF index` = "no_smurf", 
#   `+ WCGOP index` = "observer_index", 
#   `+ Oceanographic index` = "oceanographic_index", 
#   `+ ORBS index` = "ORBS", 
#   `+ ORBS w/added SE` = "ORBS_SE", 
#   `+ RREAS index` = "RREAS", 
#   `Decrease WCGBTS CV` = "upweight_wcgbts"
# )

# model_list <- c(model_list, indices)

## Put it all together ---------------------------------------------------------

# sens_paths <- c(base = here("GitHub", "widow-assessment-update", "models", "2025 base model"), model_paths) # missing RStudio
sens_paths <- c(base = here("models", "2025 base model"), model_paths)

big_sensitivity_output <- SSgetoutput(dirvec = sens_paths) |>
  setNames(c('2025 base model', names(model_list)))

## Test to make sure they all read correctly -----------------------------------

which(sapply(big_sensitivity_output, length) < 180) # all lengths should be >180

dir.create(outdir <- here("figures", "sensitivities"))
# outdir <- here("GitHub", "widow-assessment-update", "figures", "sensitivities")

  shortlist <- r4ss::SSsummarize(big_sensitivity_output)

  r4ss::SSplotComparisons(shortlist,
                          subplots = c(2, 4, 11, 18), 
                          print = TRUE,  
                          plot = FALSE,
                          plotdir = outdir, 
                          filenameprefix = "sens_",
			  legendloc = "bottomleft", 
                          legendlabels = c('Base', names(model_list)), 
                          endyrvec = 2036)

  big_table <- SStableComparisons(
    shortlist, 
    modelnames = c('Base', names(model_list)),
    names =c("NatM_uniform_Fem_GP_1", "L_at_Amin_Fem_GP_1", "L_at_Amax_Fem_GP_1", "CV_young_Fem_GP_1", "CV_old_Fem_GP_1", "VonBert_K_Fem_GP_1", 
             "NatM_uniform_Mal_GP_1", "L_at_Amin_Mal_GP_1", "L_at_Amax_Mal_GP_1", "CV_young_Mal_GP_1", "CV_old_Mal_GP_1", "VonBert_K_Mal_GP_1", 
             "Recr_Virgin", "R0", "SmryBio_unfished", "SSB_Virg",
             "SSB_2025", "Bratio_2025", "SPRratio_2024"),
    digits = c(rep(3, 22), 1, rep(3, 4)), # not sure why this isn't cutting number of digits for smrybio_unfished
    likenames = c(
      "TOTAL", "Survey", "Length_comp", "Age_comp",
      "Discard", "Mean_body_wt", "Recruitment", "priors"
    )
  ) |> 
    setNames(c('Label', 'Base', names(model_list)))  # |>
    # write.csv(file.path(outdir, "sens_table.csv"), row.names = FALSE)

# rename labels to be informative
big_table$Label <- c("Total", "Survey", "Length", "Age", "Discards", "Recruitment", "Forecast recruitment", "Parameter priors",
		     "Natural mortality (female)", "Length at Amin (female)", "Length at Amax (female)", "CV young (female)", "CV old (female)", "vBL k (female)", 
		     "Natural mortality (male)", "Length at Amin (male)", "Length at Amax (male)", "CV young (male)", "CV old (male)", "vBL k (male)", 
		     "Virgin recruitment (thousands)", "ln(R0)", "SSB unfished (mt)", "SB0 (thousand mt)", "SSB 2025 (thousand mt)", "B ratio 2025", "SPR ratio 2025")


# add title rows
big_table <- rbind(c(Label = "LIKELIHOOD", Base= "Difference from base model", rep("", dim(big_table)[2]-2)), big_table[1:8,], 
		   c(Label = "PARAMETER", rep("", dim(big_table)[2]-1)), big_table[9:20, ], 
		   c(Label = "QUANTITY", rep("", dim(big_table)[2]-1)), big_table[21:27, ])

# get likelihoods to be difference between likelihood and base
for (b in 3:13) {
    big_table[2:9, b] <- round(as.numeric(big_table[2:9, b]) - as.numeric(big_table[2:9, 2]), 4)
}

big_table |> write.csv(file.path(outdir, "sens_table.csv"), row.names = FALSE)

# for (i in seq_along(model_list)) {
#   
#   shortlist <- r4ss::SSsummarize(big_sensitivity_output[c('base', names(model_list))])
#   
#   r4ss::SSplotComparisons(shortlist,
#                           subplots = c(2, 4, 18), 
#                           print = TRUE,  
#                           plot = FALSE,
#                           plotdir = outdir, 
#                           filenameprefix = tmp,
# 			  legendloc = "bottomleft",
#                           legendlabels = c('Base', names(model_list)), 
#                           endyrvec = 2036)
#   
#   SStableComparisons(
#     shortlist, 
#     modelnames = c('Base', names(model_list)[i]),
#     names =c("Recr_Virgin", "R0", "NatM", "L_at_Amax", "VonBert_K", "SmryBio_unfished", "SSB_Virg",
#              "SSB_2025", "Bratio_2025", "SPRratio_2024", "LnQ_base_WCGBTS"),
#     likenames = c(
#       "TOTAL", "Survey", "Length_comp", "Age_comp",
#       "Discard", "Mean_body_wt", "Recruitment", "priors"
#     )
#   ) |> 
#     setNames(c('Label', 'Base', names(model_list))) |>
#     write.csv(file.path(outdir, paste0(i, '_table.csv')), row.names = FALSE)
#   
# }

## Big plot --------------------------------------------------------------------

current.year <- 2025
CI <- 0.95

sensitivity_output <- SSsummarize(big_sensitivity_output) 

lapply(big_sensitivity_output, function(.)
  .$warnings[grep('gradient', .$warnings)]) # check gradients

dev.quants.SD <- c(
  sensitivity_output$quantsSD[sensitivity_output$quantsSD$Label == "SSB_Initial", 1],
  (sensitivity_output$quantsSD[sensitivity_output$quantsSD$Label == paste0("SSB_", current.year), 1]),
  sensitivity_output$quantsSD[sensitivity_output$quantsSD$Label == paste0("Bratio_", current.year), 1],
  sensitivity_output$quantsSD[sensitivity_output$quantsSD$Label == "Dead_Catch_SPR", 1],
  sensitivity_output$quantsSD[sensitivity_output$quantsSD$Label == "annF_SPR", 1]
)

dev.quants <- rbind(
  sensitivity_output$quants[sensitivity_output$quants$Label == "SSB_Initial", 
                            1:(dim(sensitivity_output$quants)[2] - 2)],
  sensitivity_output$quants[sensitivity_output$quants$Label == paste0("SSB_", current.year), 
                            1:(dim(sensitivity_output$quants)[2] - 2)],
  sensitivity_output$quants[sensitivity_output$quants$Label == paste0("Bratio_", current.year), 
                            1:(dim(sensitivity_output$quants)[2] - 2)],
  sensitivity_output$quants[sensitivity_output$quants$Label == "Dead_Catch_SPR", 
                            1:(dim(sensitivity_output$quants)[2] - 2)],
  sensitivity_output$quants[sensitivity_output$quants$Label == "annF_SPR", 
                            1:(dim(sensitivity_output$quants)[2] - 2)]
) |>
  cbind(baseSD = dev.quants.SD) |>
  dplyr::mutate(Metric = c("SB0", paste0("SSB_", current.year), paste0("Bratio_", current.year), "MSY_SPR", "F_SPR")) |>
  tidyr::pivot_longer(-c(`2025 base model`, Metric, baseSD), names_to = 'Model', values_to = 'Est') |>
  dplyr::mutate(relErr = (Est - `2025 base model`)/`2025 base model`,
                logRelErr = log(Est/`2025 base model`),
                mod_num = match(Model, names(sens_paths)))

metric.labs <- c(
  Bratio_2023 = bquote(frac(SB[.(current.year)], SB[0])),
  F_SPR = expression(F['SPR=0.50']),
  MSY_SPR = expression(Yield['SPR=0.50']),
  SB0 = expression(SB[0]),
  SSB_2023 = as.expression(bquote("SB"[.(current.year)]))
)

CI.quants <- dev.quants |>
  dplyr::filter(Model == unique(dev.quants$Model)[1]) |>
  dplyr::select(`2025 base model`, baseSD, Metric) |>
  dplyr::mutate(CI = qnorm((1-CI)/2, 0, baseSD)/`2025 base model`)
CI.quants <- CI.quants %>% arrange(Metric)

dev.quants |> 
  ggplot(aes(x = relErr, y = mod_num, col = Metric, pch = Metric)) +
  geom_vline(xintercept = 0, linetype = 'dotted') +
  geom_point() +
  geom_segment(aes(x = CI, xend = abs(CI), col = Metric,
                   y = length(sens_paths) + 1.5 + seq(-0.5, 0.5, length.out = length(metric.labs)),
                   yend = length(sens_paths) + 1.5 + seq(-0.5, 0.5, length.out = length(metric.labs))), 
               data = CI.quants, linewidth = 2, show.legend = FALSE, lineend = 'round') +
  theme_bw() +
  scale_shape_manual(
    values = c(15:18, 12),
    # name = "",
    labels = NULL, # metric.labs
    guide = "none"
  ) +
  # scale_color_discrete(labels = metric.labs) +
  scale_y_continuous(breaks = seq_along(sens_paths), name = '', labels = names(sens_paths), 
                     limits = c(1, length(sens_paths) + 2), minor_breaks = NULL) +
  xlab("Relative change") +
  scale_color_manual(values = c("#005BFF", "#13F240", "#F6F900", "#FFBA00", "#FF592F"), labels = metric.labs)
#  viridis::scale_color_viridis(discrete = TRUE, labels = metric.labs, option = "turbo", begin = 0.1)

ggsave(file.path(outdir, 'sens_summary.png'),  dpi = 300,  
       width = 6, height = 7, units = "in")
