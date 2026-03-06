### This file contains code to address supplemental requests for the January 2026 SSC review
### see file scratch/model_supplemental_requests.R for requests associated with the October 2025 review

library(r4ss)

table_labels <- c(
    "NatM",
    #"Eggs_scalar_Fem",
    #"Eggs_exp_len_Fem",
    "SmryBio_unfished",
    "SSB_Virgin",
    "SSB_2025",
    "Bratio_2025",
    "SPRratio_2024",
    "OFLCatch_2027",
    "ForeCatch_2027",
    "Dead_Catch_MSY",
    "Dead_Catch_SPR"
)

# Request 1: Revise the October 2025 model to use the length-fecundity relationship that is specific to Sebastes entomelas (Table 6; Dick et al. 2017, however for parameter values in SS3 units, please see github reference in SSC italic notes). [Request 15 from supplemental panel report]

# model set up by Vlada with edits to input files

model_oct25 <- SS_output(
    "models/Oct2025 base model",
    printstats = FALSE,
    verbose = FALSE
)
# species-specific fecundity model
model_fec2 <- SS_output(
    "models/supplemental_requests/SSC January 2026 review/Request_1/widow_new_base_model_with_plots_2025-09-30_Widow_fecundity",
    printstats = FALSE,
    verbose = FALSE
)

summary_r1 <- SSsummarize(list(model_oct25, model_fec2))
source("R/table_sens.R")


table_r1 <- SStableComparisons(
    summary_r1,
    modelnames = c(
        "October 2025 model",
        "January 2026 model (widow rockfish fecundity)"
    ),
    likenames = NULL,
    names = table_labels # defined at the top of this script
)

# format as HTML to paste into Google Doc
# https://docs.google.com/spreadsheets/d/1NnSHuIMHI_Q3qotlHda2tfeOCw9UPM4DEURgoC2uxVc/edit?gid=0#gid=0
# parentheses around commands should return the table when run and open in a viewer
(table_r1b <- table_r1 |>
    table_convert_vals() |>
    table_clean_labels() |>
    gt::gt())


### fecundity calculations below are obsolete, replaced by values from github provided by EJ

# # The calculation for output in billions of eggs
# expA <- 3.165e-07
# B <- 4.545
# (Ainput <- (expA * 10^B) / 1e6)
# # [1] 1.11013e-08

# dir.oct <- here::here(
#     "models",
#     "supplemental_requests",
#     "1.05_refine_biasramp_and_tuning"
# )
# oct_inputs <- r4ss::SS_read(dir.oct, ss_new = TRUE)

# # modify inputs
# fecundity_inputs <- oct_inputs

# # update parameters
# fecundity_inputs$ctl$MG_parms["Eggs_alpha_Fem_GP_1", "INIT"] <- Ainput
# fecundity_inputs$ctl$MG_parms["Eggs_beta_Fem_GP_1", "INIT"] <- B

# fecundity_inputs$dir <- here::here(
#     "models",
#     "supplemental_requests",
#     "fecundity_species_specific_params"
# )
# # write files
# r4ss::SS_write(
#     fecundity_inputs,
#     dir = fecundity_inputs$dir,
#     overwrite = TRUE,
#     verbose = FALSE
# )
# # run the model
# r4ss::run(fecundity_inputs$dir, extras = "-nohess", skipfinished = FALSE)
# # get output
# fecundity_output <- r4ss::SS_output(
#     fecundity_inputs$dir,
#     printstats = FALSE,
#     verbose = FALSE
# )
# oct_output <- r4ss::SS_output(dir.oct)

# fec_summary2 <- r4ss::SSsummarize(list(oct_output, fecundity_output))
# tab <- r4ss::SStableComparisons(
#     fec_summary2,
#     likenames = NULL,
#     names = c(
#         "NatM",
#         "R0",
#         "SSB_Virgin",
#         "SSB_2025",
#         "Bratio_2025",
#         "OFLCatch_2027",
#         "ForeCatch_2027",
#         "Dead_Catch_SPR"
#     )
# )
# r4ss::SSplotComparisons(
#     fec_summary2,
#     legendlabels = c(
#         "October 2025 base model",
#         "Species-specific fecundity parameters"
#     ),
#     endyrvec = 2036
# )

# Request 3 additional bridging
# models set up by Vlada with edits to input files

mods <- dir("models/supplemental_requests/SSC January 2026 review/Request_3")
mods <- mods[grep("Aug2025", mods)]
mod_names <- c(
    "August 2025 model",
    "No HKL comps",
    "HKL and Net catches to BT",
    "MDT discard to MDT landings",
    "BT discard to BT landings"
)
cbind(mod_names, mods)
#      mod_names                     mods
# [1,] "August 2025 model"           "Aug2025_base_model_cleaned_ss_new_remove_HnL_retention"
# [2,] "No HKL comps"                "Aug2025_base_model_cleaned_ss_new_remove_HnL_retention_No_HKL_lengths"
# [3,] "HKL and Net catches to BT"   "Aug2025_base_model_cleaned_ss_new_remove_HnL_retention_No_HKL_lengths_Net_HKL_to_BT"
# [4,] "MDT discard to MDT landings" "Aug2025_base_model_cleaned_ss_new_remove_HnL_retention_No_HKL_lengths_Net_HKL_to_BT_MDT_discard"
# [5,] "BT discard to BT landings"   "Aug2025_base_model_cleaned_ss_new_remove_HnL_retention_No_HKL_lengths_Net_HKL_to_BT_MDT_discard_BT_discard"

mod_list <- SSgetoutput(
    dirvec = file.path(
        "models/supplemental_requests/SSC January 2026 review/Request_3",
        mods
    )
)
summary_r3 <- SSsummarize(mod_list)
source("R/table_sens.R")

table_r3 <- SStableComparisons(
    summary_r3,
    modelnames = mod_names,
    likenames = NULL,
    names = table_labels # defined at the top of this script
)

# format as HTML to paste into Google Doc
# https://docs.google.com/spreadsheets/d/1NnSHuIMHI_Q3qotlHda2tfeOCw9UPM4DEURgoC2uxVc/edit?gid=0#gid=0
# parentheses around commands should return the table when run and open in a viewer
(table_r3b <- table_r3 |>
    table_convert_vals() |>
    table_clean_labels() |>
    gt::gt())


# Request 4 explorations of M
# models set up by Vlada with edits to input files

dir_names <- c(
    "widow_new_base_model_with_plots_2025-09-30",
    "widow_new_base_model_with_plots_2025-09-30_widow_fecundity",
    "widow_new_base_model_with_plots_2025-09-30_widow_fecundity_M_0_1"
)
mod_names <- c(
    "October 2025 model",
    "January 2026 model (widow rockfish fecundity)",
    "January 2026 model with M = 0.1"
)

mod_list <- SSgetoutput(
    dirvec = file.path(
        "models/supplemental_requests/SSC January 2026 review/Request_4",
        dir_names
    )
)
summary_r4a <- SSsummarize(mod_list)
source("R/table_sens.R")

table_r4a <- SStableComparisons(
    summary_r4a,
    modelnames = mod_names,
    likenames = NULL,
    names = table_labels # defined at the top of this script
)

# format as HTML to paste into Google Doc
# https://docs.google.com/spreadsheets/d/1NnSHuIMHI_Q3qotlHda2tfeOCw9UPM4DEURgoC2uxVc/edit?gid=0#gid=0
# parentheses around commands should return the table when run and open in a viewer
(table_r4a <- table_r4a |>
    table_convert_vals() |>
    table_clean_labels() |>
    gt::gt())


# Request 4 explorations of M
# models set up by Vlada with edits to input files

dir_names <- c(
    "widow_new_base_model_with_plots_2025-09-30_corrected_fecundity",
    # "widow_new_base_model_with_plots_2025-09-30_corrected_fecundity_Mprior_50",
    "widow_new_base_model_with_plots_2025-09-30_corrected_fecundity_Mprior_45",
    "widow_new_base_model_with_plots_2025-09-30_corrected_fecundity_Mprior_40"
)
mod_names <- c(
    "January 2026 model (widow rockfish fecundity)",
    # "January 2026 model with M based on age 50",
    "January 2026 model with M prior based on age 45",
    "January 2026 model with M prior based on age 40"
)

mod_list <- SSgetoutput(
    dirvec = file.path(
        "models/supplemental_requests/SSC January 2026 review/Request_4/Alternative max age assumption",
        dir_names
    )
)
summary_r4b <- SSsummarize(mod_list)
source("R/table_sens.R")

table_r4b <- SStableComparisons(
    summary_r4b,
    modelnames = mod_names,
    likenames = NULL,
    names = table_labels # defined at the top of this script
)

# format as HTML to paste into Google Doc
# https://docs.google.com/spreadsheets/d/1NnSHuIMHI_Q3qotlHda2tfeOCw9UPM4DEURgoC2uxVc/edit?gid=0#gid=0
# parentheses around commands should return the table when run and open in a viewer
(table_r4b <- table_r4b |>
    table_convert_vals() |>
    table_clean_labels() |>
    gt::gt())

#### Nov 2026 Council Request 3:
# The STAT include a Bayesian projection to evaluate the probability that the
# stock would remain above B40% in 2029, if such a method is feasible to
# achieve within existing workload capacity and model structure.

# MCMC diagnostics
dir.oct <- here::here(
    "models",
    "supplemental_requests",
    "1.05_refine_biasramp_and_tuning"
)
new_inputs <- oct_inputs <- r4ss::SS_read(dir.oct, ss_new = FALSE)

# modify recdev method from 1 to 2
new_inputs$ctl$do_recdev <- 2

new_inputs$dir <- here::here(
    "models",
    "supplemental_requests",
    "oct2025_plus_recdev_method2"
)
# write files
r4ss::SS_write(
    new_inputs,
    dir = new_inputs$dir,
    overwrite = TRUE,
    verbose = FALSE
)
# run the model
r4ss::run(new_inputs$dir, extras = "-nohess", skipfinished = FALSE)

# get output
new_output <- r4ss::SS_output(
    new_inputs$dir,
    printstats = FALSE,
    verbose = FALSE
)
oct_output <- r4ss::SS_output(dir.oct, printstats = FALSE, verbose = FALSE)

mod_summary <- r4ss::SSsummarize(list(oct_output, new_output))
tab <- r4ss::SStableComparisons(
    mod_summary,
    likenames = NULL,
    names = c(
        "NatM",
        "R0",
        "SSB_Virgin",
        "SSB_2025",
        "Bratio_2025",
        "OFLCatch_2027",
        "ForeCatch_2027",
        "Dead_Catch_SPR"
    )
)
# get executable required to be in the directory for MCMC diagnostics
r4ss::get_ss3_exe(new_inputs$dir)
nwfscDiag::run_mcmc_diagnostics(
    #dir_wd = 'models/supplemental_requests/oct2025_plus_recdev_method2'
    #dir_wd = "C:/ss/widow/Widow2025/widow-assessment-update/models/supplemental_requests/oct2025_plus_recdev_method2",
    dir_wd = "C:/ss/widow/Widow2025/widow_rockfish_2025/models/supplemental_requests/oct2025_plus_recdev_method2",
    chains = 3,
    hour = 15
)

model = "ss3"
extension = ".exe"
iter = 2000
chains = 2
hour = 1
thin = NULL
interactive = FALSE
verbose = FALSE

###

# alternative approach to getting probabilities from MLE output
# model was copied from
# models\supplemental_requests\SSC January 2026 review\Request_1\widow_new_base_model_with_plots_2025-09-30_Widow_fecundity
# and renamed. Starter file was modified to have Bratio represent value relative to B40%
#   1 # Depletion basis:  denom is: 0=skip; 1=X*SPBvirgin; 2=X*SPBmsy; 3=X*SPB_styr; 4=X*SPB_endyr; 5=X*dyn_Bzero;  values>=11 invoke N multiyr with 10s & 100s digit; append .1 to invoke log(ratio); e.g. 122.1 produces log(12 year trailing average of B/Bmsy)
#   0.4 # Fraction (X) for Depletion denominator (e.g. 0.4)
# as well as start from .par file

b40_model <- SS_output(
    "models/supplemental_requests/SSC January 2026 review/Council_Request_3/Bratio_40",
    printstats = FALSE,
    verbose = FALSE
)
# move targets
b40_model$btarg = 1.0
b40_model$minbthresh = 0.25 / 0.40

#par(mar = c(2, 2, 1, 1))
png(
    filename = "figures/supplemental_requests/Council_Request_3_B40_probability.png",
    width = 6,
    height = 4.5,
    units = "in",
    res = 300
)
SSplotComparisons(
    SSsummarize(list(b40_model)),
    densitynames = c("Bratio_2029"),
    subplots = 16,
    legend = FALSE,
    #add = TRUE,
    new = FALSE,
    par = list(mar = c(3.1, 3.1, 1, 1))
)
mtext(side = 1, line = 2, "Spawning output in 2029 relative to B40%")
mtext(side = 2, line = 1, "Density")
dev.off()

info <- b40_model$derived_quants["Bratio_2029", c("Value", "StdDev")]
(prob <- pnorm(
    q = 1.0,
    mean = info$Value,
    sd = info$StdDev,
    lower.tail = FALSE
) |>
    round(3))

# second round with request 3 using constant catch model:
dir_old <- here::here(
    "models/supplemental_requests/SSC January 2026 review/Council_Request_2",
    "widow_new_base_model_with_plots_2025-09-30_widow_fecundity_ramp_Owen_constant_buffer"
)
dir_new <- here::here(
    "models/supplemental_requests/SSC January 2026 review/Council_Request_3/Bratio_40_constant_catch"
)

r4ss::copy_SS_inputs(
    dir_old,
    dir_new,
    copy_par = TRUE,
    copy_exe = TRUE,
    overwrite = TRUE
)
inputs <- r4ss::SS_read(
    dir_new,
    ss_new = FALSE
)

# change depletion basis to 40%
inputs$start$depl_denom_frac <- 0.4
inputs$start$init_values_src <- 1 # read in from .par file
inputs$start$run_display_detail <- 0 # less info in console

r4ss::SS_write(
    inputs,
    dir = dir_new,
    overwrite = TRUE,
    verbose = FALSE
)
r4ss::run(
    dir_new,
    skipfinished = FALSE,
    show_in_console = TRUE,
    extras = "-phase 10" # start in final phase
)

# read output
b40_model_v2 <- r4ss::SS_output(
    dir_new,
    printstats = FALSE,
    verbose = FALSE
)
# move targets to change lines on plot
b40_model_v2$btarg = 1.0
b40_model_v2$minbthresh = 0.25 / 0.40

info <- b40_model_v2$derived_quants["Bratio_2029", c("Value", "StdDev")]
(prob <- pnorm(
    q = 1.0,
    mean = info$Value,
    sd = info$StdDev,
    lower.tail = FALSE
) |>
    round(3))

png(
    filename = "figures/supplemental_requests/Council_Request_3_B40_probability_v2.png",
    width = 7,
    height = 5,
    units = "in",
    res = 300
)
SSplotComparisons(
    SSsummarize(list(b40_model, b40_model_v2)),
    densitynames = c("Bratio_2029"),
    subplots = 16,
    #legend = FALSE,
    #add = TRUE,
    legendlabels = c(
        "default forecast",
        "constant catch at\nSPR target equilibrium"
    ),
    legendloc = "topleft",
    new = FALSE,
    par = list(mar = c(3.1, 3.1, 1, 1))
)
mtext(side = 1, line = 2, "Spawning output in 2029 relative to B40%")
mtext(side = 2, line = 1, "Density")
dev.off()


#####################################################################
# sensitivity table
dir_sens <- "models/supplemental_requests/SSC January 2026 review/Sensitivity runs"
dir_mods <- dir(dir_sens) |> grep(pattern = "widow", value = TRUE)
# [1] "widow_new_base_model_with_plots_2025-09-30_corrected_fecundity_Mprior_45"
# [2] "widow_new_base_model_with_plots_2025-09-30_corrected_fecundity_Mprior_50"
# [3] "widow_new_base_model_with_plots_2025-09-30_widow_fecundity"
# [4] "widow_new_base_model_with_plots_2025-09-30_widow_fecundity_2015_M"
# [5] "widow_new_base_model_with_plots_2025-09-30_widow_fecundity_2019_M"
# [6] "widow_new_base_model_with_plots_2025-09-30_widow_fecundity_M_0_1"
# [7] "widow_new_base_model_with_plots_2025-09-30_widow_fecundity_plus_rec"
# [8] "widow_new_base_model_with_plots_2025-09-30_widow_fecundity_WCGBTS_selex24"
# [9] "widow_new_base_model_with_plots_2025-09-30_widow_fecundity_WCGBTS_selex24_asymp"

dir_mods <- dir_mods[c(3, 6, 5, 4, 2, 1, 9, 8, 7)]
mod_names <- c(
    "January 2026 base model",
    "M=0.1 (the median of a prior)",
    "M fixed at 2019 model estimates",
    "M fixed at 2015 model estimates",
    "M prior based on max age 50",
    "M prior based on max age 45",
    "WCGBTS selectivity double-normal, asymptotic",
    "WCGBTS selectivity double-normal, allowed to be dome",
    "Recreational catches added"
)

# confirm that the order is correct
data.frame(
    name = mod_names,
    dir = stringr::str_extract(dir_mods, "(?<=09-30_).+")
)
#                                                   name                                  dir
# 1                              January 2026 base model                      widow_fecundity
# 2                        M=0.1 (the median of a prior)                widow_fecundity_M_0_1
# 3                      M fixed at 2019 model estimates               widow_fecundity_2019_M
# 4                      M fixed at 2015 model estimates               widow_fecundity_2015_M
# 5                          M prior based on max age 50        corrected_fecundity_Mprior_50
# 6                          M prior based on max age 45        corrected_fecundity_Mprior_45
# 7         WCGBTS selectivity double-normal, asymptotic widow_fecundity_WCGBTS_selex24_asymp
# 8 WCGBTS selectivity double-normal, allowed to be dome       widow_fecundity_WCGBTS_selex24
# 9                           Recreational catches added             widow_fecundity_plus_rec

mod_list <- SSgetoutput(
    dirvec = file.path(
        dir_sens,
        dir_mods
    ),
    modelnames = mod_names,
    SpawnOutputLabel = "Spawning output (billions of eggs)"
)

table_labels <- c(
    "NatM",
    #"Eggs_scalar_Fem",
    #"Eggs_exp_len_Fem",
    "SmryBio_unfished",
    "SSB_Virgin",
    "SSB_2025",
    "Bratio_2025",
    "SPRratio_2024",
    "OFLCatch_2027",
    "ForeCatch_2027",
    "Dead_Catch_MSY",
    "Dead_Catch_SPR"
)


summary_sens1 <- SSsummarize(mod_list)
tab_sens1 <- SStableComparisons(
    summary_sens1,
    #likenames = NULL,
    names = table_labels # defined at the top of this script
)
write.csv(
    tab_sens1,
    file = "report/tables/sensitivity_table.csv",
    row.names = FALSE
)

## SSC Request 6
# Request 6: Calculate the expected age/size structure on which the 2027 OFL (i.e. as seen by the fishery) would be based, as well as under the assumption of an equilibrium situation (i.e. with recruitment off of the S-R curve) at the MSY-proxy SPR rate (e.g. by projecting the model forward at the SPR target harvest rate until it reaches equilibrium) and compare with the estimates of age/size structure at the start of 2027, with the aim of understanding why the 2027 OFL is substantially lower than would be expected for a population in equilibriumation.
# Rationale: The 2027 OFL is 1,000t less than the equilibrium catch corresponding to the MSY proxy SPR. This may be related to lower than expected recent recruitments but that cannot be confirmed from the information provided.

dir6 <- here::here(
    "models",
    "supplemental_requests",
    "SSC January 2026 review",
    "meeting_request_6_equilibrium_projection"
)
# copy base model to new directory
r4ss::copy_SS_inputs(
    dir.old = "models/2025 base model",
    dir.new = dir6,
    copy_par = TRUE,
    overwrite = TRUE
)
# change starter to use .par file (triggers read of .par in current version of SS_read used below)
start <- r4ss::SS_readstarter(file.path(dir6, "starter.ss"))
start$init_values_src <- 1 # read in from .par file
start$run_display_detail <- 0 # less info in console
r4ss::SS_writestarter(
    start,
    dir = dir6,
    overwrite = TRUE,
    verbose = FALSE
)

# read base model input files
inputs <- r4ss::SS_read(dir6)
inputs$fore$Flimitfraction <- 1 # turn off year-specific buffers
inputs$fore$Nforecastyrs <- 100 # extend forecast period to reach equilibrium
inputs$par$recdev_forecast <- rbind(
    inputs$par$recdev_forecast,
    data.frame(year = 2037:2124, recdev = 0)
)

r4ss::SS_write(
    inputs,
    dir = inputs$dir,
    overwrite = TRUE,
    verbose = FALSE
)
r4ss::run(
    dir = dir6,
    skipfinished = FALSE,
    show_in_console = TRUE,
    extras = "-phase 10 -nohess" # start in final phase
)
output6 <- r4ss::SS_output(
    dir6,
    printstats = FALSE,
    verbose = FALSE
)
# confirm that the SSB has stabilized
output6$timeseries |> filter(Yr > 2050) |> pull(SpawnBio) |> range()
# [1] 9400.12 9418.69

output6$timeseries |> filter(Yr > 2120) |> pull(SpawnBio) |> range()
# [1] 9418.69 9418.69

# get selectivity at age
sel_f <- output6$ageselex |>
    filter(Factor == "Asel2", Fleet == 2 & Yr == 2024 & Sex == 1) |>
    select(-(1:7)) |>
    as.numeric() # convert to vector
sel_m <- output6$ageselex |>
    filter(Factor == "Asel2", Fleet == 2 & Yr == 2024 & Sex == 2) |>
    select(-(1:7)) |>
    as.numeric() # convert to vector

# numbers at age in 2124
natage_2124_f <- output6$natage |>
    filter(Time == 2124.5 & Sex == 1) |> # middle of final year
    select(-(1:12)) |>
    as.numeric()
natage_2124_m <- output6$natage |>
    filter(Time == 2124.5 & Sex == 2) |> # middle of final year
    select(-(1:12)) |>
    as.numeric()

natage_2027_f <- output6$natage |>
    filter(Time == 2027.5 & Sex == 1) |> # middle of final year
    select(-(1:12)) |>
    as.numeric()
natage_2027_m <- output6$natage |>
    filter(Time == 2027.5 & Sex == 2) |> # middle of final year
    select(-(1:12)) |>
    as.numeric()

natage_2027 <- natage_2027_f + natage_2027_m
sel_natage_2027 <- sel_f * natage_2027_f + sel_m * natage_2027_m
natage_equil <- natage_2124_f + natage_2124_m
sel_natage_equil <- sel_f * natage_2124_f + sel_m * natage_2124_m

info6 <- rbind(
    tibble(
        age = 0:output6$accuage,
        value = natage_2027,
        type = "numbers",
        year = 2027
    ),
    tibble(
        age = 0:output6$accuage,
        value = natage_equil,
        type = "numbers",
        year = "equilibrium at SPR target"
    ),
    tibble(
        age = 0:output6$accuage,
        value = sel_natage_2027,
        type = "selected numbers",
        year = 2027
    ),
    tibble(
        age = 0:output6$accuage,
        value = sel_natage_equil,
        type = "selected numbers",
        year = "equilibrium at SPR target"
    )
)

# convert from thousands (default SS3 output) to millions
info6 <- info6 |>
    mutate(value = value / 1e3)

# make barplot showing values by age in 2027 vs equilibrium
info6 |>
    filter(type == "selected numbers") |>
    ggplot(aes(x = age, y = value, fill = as.factor(year))) +
    geom_bar(stat = "identity", position = "dodge") +
    facet_wrap(~type, scales = "free_y") +
    labs(
        x = "Age",
        y = "Numbers (millions)",
        fill = "Year"
    ) +
    theme_minimal() +
    theme(legend.position = "top")

ggsave(
    filename = "figures/supplemental_requests/SSC_Jan2026_Request6_age_structure_2027_vs_equilibrium.png",
    width = 6,
    height = 4.5,
    units = "in",
    dpi = 300
)

info6 |> dplyr::filter(age %in% 7:9 & type == "selected numbers")
# # A tibble: 6 x 4
#     age value type             year
#   <int> <dbl> <chr>            <chr>
# 1     7  5.00 selected numbers 2027
# 2     8  2.82 selected numbers 2027
# 3     9  2.16 selected numbers 2027
# 4     7  8.63 selected numbers equilibrium at SPR target
# 5     8  7.37 selected numbers equilibrium at SPR target
# 6     9  5.62 selected numbers equilibrium at SPR target

# fraction of selected numbers in 2027 relative to equilibrium at SPR target for ages 7 to 9
v1 <- info6 |>
    dplyr::filter(age %in% 7:9 & type == "selected numbers" & year == 2027) |>
    pull(value)
v2 <- info6 |>
    dplyr::filter(age %in% 7:9 & type == "selected numbers" & year != 2027) |>
    pull(value)
sum(v1) / sum(v2)
# [1] 0.461431

# extra selectivity plot showing just midwater vs WCGBTS as a function of age
r4ss::SSplotSelex(
    output,
    subplots = 2,
    fleets = c(2, 8),
    print = TRUE,
    plotdir = "figures/supplemental_requests",
    pheight = 4
)


# exploring retro -6 model to understand why 2013 cohort is estimated to be so much larger
retro6 <- r4ss::SS_output(
    "models/diagnostics/2025 base model_retro_6",
    printstats = FALSE,
    verbose = FALSE
)
r4ss::SS_plots(retro6)

retro6b <- r4ss::SS_output(
    "models/diagnostics/2025 base model_retro_6_no_JuvSurvey",
    printstats = FALSE,
    verbose = FALSE
)
r4ss::SS_plots(retro6b)

r4ss::SSplotComparisons(
    r4ss::SSsummarize(list(retro6, retro6b)),
    legendlabels = c("retro -6", "retro -6 no juv survey"),
    endyrvec = 2025
)
