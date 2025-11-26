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
    modelnames = c("October 2025 model", "Widow rockfish fecundity"),
    likenames = NULL,
    names = table_labels
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
    names = table_labels
)

# format as HTML to paste into Google Doc
# https://docs.google.com/spreadsheets/d/1NnSHuIMHI_Q3qotlHda2tfeOCw9UPM4DEURgoC2uxVc/edit?gid=0#gid=0
# parentheses around commands should return the table when run and open in a viewer
(table_r3b <- table_r3 |>
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
