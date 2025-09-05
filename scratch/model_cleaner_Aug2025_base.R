# read input files for 2025 base model
base_inputs <- r4ss::SS_read(here::here("models/2025 base model"))
# new set of inputs
base_inputs2 <- base_inputs
# change N_bootstraps from 0 to 3 so that ss_new files are produced
base_inputs2$start$N_bootstraps <- 3
# write new input files to new directory and run model
base_inputs2$dir <- here::here(
    "models",
    "supplemental_requests",
    "Aug2025_base_model_cleaned"
)
r4ss::SS_write(
    base_inputs2,
    dir = base_inputs2$dir,
    overwrite = TRUE,
    verbose = FALSE
)
r4ss::run(base_inputs2$dir, extras = "-nohess")

# now copy ss_new files to use as new input files
r4ss::copy_SS_inputs(
    dir.old = base_inputs2$dir,
    dir.new = here::here(
        "models",
        "supplemental_requests",
        "Aug2025_base_model_cleaned_ss_new"
    ),
    copy_par = TRUE,
    use_ss_new = TRUE,
    overwrite = TRUE
)

# remove HnL retention parameters from fleet 5 (discard data not used)
base_inputs3 <- r4ss::SS_read(
    here::here(
        "models",
        "supplemental_requests",
        "Aug2025_base_model_cleaned_ss_new"
    )
)
# turn off the use of retention for fleet 5 (HnL)
base_inputs3$ctl$size_selex_types["HnL", "Discard"] <- 0

# remove all retention parameters for fleet 5 (HnL)
base_inputs3$ctl$size_selex_parms <- base_inputs3$ctl$size_selex_parms |>
    dplyr::filter(
        !grepl(
            "SizeSel_PRet.*\\(5\\)",
            rownames(base_inputs3$ctl$size_selex_parms)
        )
    )
# remove the time-varying size selectivity parameters for fleets 5 (HnL)
base_inputs3$ctl$size_selex_parms_tv <- base_inputs3$ctl$size_selex_parms_tv |>
    dplyr::filter(
        !grepl(
            "SizeSel_PRet.*\\(5\\)",
            rownames(base_inputs3$ctl$size_selex_parms_tv)
        )
    )

# -99  -9  -4  -3  -2   1   2   3   4   5
#  14   2   8   5   2   4  13   5   4   1

# increase phase of all size selectivity parameters by 3 unless it is fixed (<0)
base_inputs3$ctl$size_selex_parms <- base_inputs3$ctl$size_selex_parms |>
    dplyr::mutate(PHASE = ifelse(PHASE < 0, PHASE, PHASE + 3))
base_inputs3$ctl$size_selex_parms$PHASE |> table()

# -99  -9  -4  -3  -2   4   5   6   7   8
#  14   2   8   5   2   4  13   5   4   1

# write new input files to new directory and run model
base_inputs3$dir <- here::here(
    "models",
    "supplemental_requests",
    "Aug2025_base_model_cleaned_ss_new_remove_HnL_retention"
)
r4ss::SS_write(
    base_inputs3,
    dir = base_inputs3$dir,
    overwrite = TRUE,
    verbose = FALSE
)
r4ss::run(base_inputs3$dir)

output_clean <- r4ss::SS_output(
    here::here(
        "models",
        "supplemental_requests",
        "Aug2025_base_model_cleaned_ss_new_remove_HnL_retention"
    ),
    printstats = FALSE,
    verbose = FALSE
)

# compare to base model
# total likelihoods are identical to reported digits
# unfished SSB is 0.99996 times that of base model
output_base <- r4ss::SS_output(here::here("models/2025 base model"),
    printstats = FALSE,
    verbose = FALSE
)

SStableComparisons(SSsummarize(list(base_output, output_clean)))

#                     Label      model1      model2
# 1              TOTAL_like 1.90165e+04 1.90165e+04
# 2             Survey_like 8.04479e+00 8.04465e+00
# 3        Length_comp_like 8.29491e+02 8.29491e+02
# 4           Age_comp_like 1.36719e+03 1.36720e+03
# 5        Parm_priors_like 9.03229e-01 9.03344e-01
# 6    Recr_Virgin_millions 3.47990e+01 3.47995e+01
# 7               SR_LN(R0) 1.04573e+01 1.04574e+01
# 8             SR_BH_steep 7.20000e-01 7.20000e-01
# 9   NatM_uniform_Fem_GP_1 1.22306e-01 1.22309e-01
# 10  NatM_uniform_Mal_GP_1 1.34775e-01 1.34778e-01
# 11     L_at_Amax_Fem_GP_1 4.94918e+01 4.94918e+01
# 12     L_at_Amax_Mal_GP_1 4.36083e+01 4.36083e+01
# 13     VonBert_K_Fem_GP_1 1.81125e-01 1.81125e-01
# 14     VonBert_K_Mal_GP_1 2.45195e-01 2.45195e-01
# 15 SSB_Virgin_thousand_mt 8.54610e+01 8.54580e+01
# 16            Bratio_2025 5.49186e-01 5.49185e-01
# 17          SPRratio_2024 1.17546e+00 1.17546e+00
