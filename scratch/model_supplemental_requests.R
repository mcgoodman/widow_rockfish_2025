# read base model projection with default HCR
base_inputs <- r4ss::SS_read(here::here("models/2025 base model"))
base_output <- r4ss::SS_output(
    here::here("models/2025 base model"),
    printstats = FALSE,
    verbose = FALSE
)

# copy of base model with control.ss_new written so use as starting values if needed
base_inputs2 <- base_inputs
base_inputs2$start$N_bootstraps <- 3
base_inputs2$dir <- here::here(
    "models",
    "supplemental_requests",
    "base_model_with_ss_new"
)
r4ss::SS_write(
    base_inputs2,
    dir = base_inputs2$dir,
    overwrite = TRUE,
    verbose = FALSE
)
r4ss::run(base_inputs2$dir, extras = "-nohess")

##############################################################################
## REQUEST: "Explore alternatives to the starting year for the recruitment
##           deviations bias adjustment ramp."
##############################################################################

# discussion at GFSC meeting was around the large recdevs in 1970 and 1971, and it makes sense that they have full bias adjustment

base_output$recruit |> dplyr::filter(Yr %in% 1967:1973)
#     Yr SpawnBio exp_recr with_regime bias_adjusted pred_recr        dev biasadjuster   era mature_bio mature_num    raw_dev
# 1 1967  67204.3  33903.5     33903.5       31904.8   36136.3  0.1245400     0.337567 Early    67204.3    59916.3  0.1245400
# 2 1968  65113.3  33772.9     33772.9       31485.7   34142.2  0.0810009     0.389580 Early    65113.3    58714.6  0.0810009
# 3 1969  64681.7  33745.0     33745.0       31166.6   29705.2 -0.0480252     0.441593 Early    64681.7    58881.8 -0.0480252
# 4 1970  65358.0  33788.6     33788.6       30916.0  117956.0  1.3390400     0.493607  Main    65358.0    59909.8  1.3390400
# 5 1971  66197.6  33841.5     33841.5       30675.9   97968.8  1.1611700     0.545620  Main    66197.6    60970.2  1.1611700
# 6 1972  67012.7  33891.9     33891.9       30435.2   13102.0 -0.8428370     0.597633  Main    67012.7    61728.6 -0.8428370
# 7 1973  68496.5  33980.7     33980.7       30230.7   11028.7 -1.0083600     0.649647  Main    68496.5    66276.6 -1.0083600

# create new object to modify
biasramp_inputs <- base_inputs

# extract current values as a named vector
unlist(biasramp_inputs$ctl[c(
    "last_early_yr_nobias_adj",
    "first_yr_fullbias_adj",
    "last_yr_fullbias_adj",
    "first_recent_yr_nobias_adj",
    "max_bias_adj"
)])


#   last_early_yr_nobias_adj      first_yr_fullbias_adj       last_yr_fullbias_adj first_recent_yr_nobias_adj               max_bias_adj
#                  1960.5100                  1977.0000                  2016.3300                  2024.8800                     0.8577

# modify the 2nd value from 1977
biasramp_inputs$ctl$first_yr_fullbias_adj <- 1970
# set directory for new model
biasramp_inputs$dir <- here::here(
    "models",
    "supplemental_requests",
    "biasramp1970"
)
# write files
r4ss::SS_write(
    biasramp_inputs,
    dir = biasramp_inputs$dir,
    overwrite = TRUE,
    verbose = FALSE
)
# run the model
r4ss::run(biasramp_inputs$dir, extras = "-nohess")
# get output
biasramp_output <- r4ss::SS_output(
    biasramp_inputs$dir,
    printstats = FALSE,
    verbose = FALSE
)

# plot the comparison of the two models
r4ss::SSplotComparisons(
    r4ss::SSsummarize(list(base_output, biasramp_output)),
    legendlabels = c(
        "August 2025 base model (full bias adjustment starts in 1977)",
        "Full recruitment bias adjustment starting in 1970"
    ),
    endyrvec = 2036,
    print = TRUE,
    plot = FALSE,
    plotdir = biasramp_inputs$dir,
    verbose = FALSE
)

r4ss::SStableComparisons(
    r4ss::SSsummarize(list(base_output, biasramp_output)),
    names = c("NatM", "SSB_2025", "Bratio_2025", "ForeCatch_2027")
) |>
    dplyr::mutate(ratio = model2 / model1, diff_from_base = model2 - model1)
#                    Label      model1      model2     ratio diff_from_base
# 1             TOTAL_like 1.90165e+04 1.90152e+04 0.9999316      -1.300000
# 2            Survey_like 8.04479e+00 8.02787e+00 0.9978968      -0.016920
# 3       Length_comp_like 8.29491e+02 8.29533e+02 1.0000506       0.042000
# 4          Age_comp_like 1.36719e+03 1.36733e+03 1.0001024       0.140000
# 5       Parm_priors_like 9.03229e-01 9.22699e-01 1.0215560       0.019470
# 6  NatM_uniform_Fem_GP_1 1.22306e-01 1.22610e-01 1.0024856       0.000304
# 7  NatM_uniform_Mal_GP_1 1.34775e-01 1.35090e-01 1.0023372       0.000315
# 8   SSB_2025_thousand_mt 4.69340e+01 4.79590e+01 1.0218392       1.025000
# 9            Bratio_2025 5.49186e-01 5.53958e-01 1.0086892       0.004772
# 10        ForeCatch_2027 4.23801e+03 4.37062e+03 1.0312906     132.610000

# small differences: 1.3 units improved likelihood, 2% increase in SSB_2025_thousand_mt, 3% increase in 2027 ACL

##############################################################################
## REQUEST: Provide a sensitivity in which size-dependent fecundity is
## accounted for in the assessment (based on the fecundity parameters from
## Dick et al. 2017, see
## https://github.com/EJDick-NOAA/Rockfish-Fecundity/blob/main/README.md for
## converted parameters)
##############################################################################

# Table 6 of Dick et al. 2017 shows that for the unobserved Sebastes, the exp(A) and B parameters
# are 6.538e-06 and 4.043 which can convert from length in mm to eggs.
# Formulas to convert those values into SS3 inputs where length is in cm are shown in
# https://pfmc-assessments.github.io/pfmc_assessment_handbook/02-model-choices.html#fecundity.

# The calculation for output in billions of eggs
expA <- 6.538e-06
B <- 4.043
(Ainput <- (expA * 10^B) / 1e6)
# [1] 7.218466e-08

# modify inputs
fecundity_inputs <- base_inputs

# change fecundity_at_length option:(1)eggs=Wt*(a+b*Wt);(2)eggs=a*L^b;(3)eggs=a*Wt^b; (4)eggs=a+b*L; (5)eggs=a+b*W
fecundity_inputs$ctl$fecundity_option <- 2
# update parameters
fecundity_inputs$ctl$MG_parms["Eggs_alpha_Fem_GP_1", "INIT"] <- 7.218466e-08
fecundity_inputs$ctl$MG_parms["Eggs_beta_Fem_GP_1", "INIT"] <- 4.043

fecundity_inputs$dir <- here::here(
    "models",
    "supplemental_requests",
    "fecundity"
)
# write files
r4ss::SS_write(
    fecundity_inputs,
    dir = fecundity_inputs$dir,
    overwrite = TRUE,
    verbose = FALSE
)
# run the model
r4ss::run(fecundity_inputs$dir, extras = "-nohess", skipfinished = FALSE)
# get output
fecundity_output <- r4ss::SS_output(
    fecundity_inputs$dir,
    printstats = FALSE,
    verbose = FALSE
)

# plot the comparison of the two models
r4ss::SSplotComparisons(
    r4ss::SSsummarize(list(base_output, fecundity_output)),
    legendlabels = c(
        "August 2025 base model (spawning biomass based on body weight)",
        "Add fecundity relationship from rockfish meta-analysis (Dick et al. 2017)"
    ),
    endyrvec = 2036,
    print = TRUE,
    plot = FALSE,
    plotdir = fecundity_inputs$dir,
    verbose = FALSE
)

r4ss::SStableComparisons(
    r4ss::SSsummarize(list(base_output, fecundity_output)),
    names = c(
        "NatM",
        "SSB_2025",
        "Bratio_2025",
        "ForeCatch_2027",
        "SPR_MSY",
        "Dead_Catch_SPR"
    )
) |>
    dplyr::mutate(ratio = model2 / model1, diff_from_base = model2 - model1)

#                    Label      model1      model2     ratio diff_from_base
# 1             TOTAL_like 1.90165e+04 1.90166e+04 1.0000053    1.00000e-01
# 2            Survey_like 8.04479e+00 8.03791e+00 0.9991448   -6.88000e-03
# 3       Length_comp_like 8.29491e+02 8.29360e+02 0.9998421   -1.31000e-01
# 4          Age_comp_like 1.36719e+03 1.36741e+03 1.0001609    2.20000e-01
# 5       Parm_priors_like 9.03229e-01 9.09853e-01 1.0073337    6.62400e-03
# 6  NatM_uniform_Fem_GP_1 1.22306e-01 1.22565e-01 1.0021176    2.59000e-04
# 7  NatM_uniform_Mal_GP_1 1.34775e-01 1.35018e-01 1.0018030    2.43000e-04
# 8               SSB_2025 4.69339e+04 1.14437e+04 0.2438259   -3.54902e+04
# 9            Bratio_2025 5.49186e-01 5.31681e-01 0.9681256   -1.75050e-02
# 10        ForeCatch_2027 4.23801e+03 3.84454e+03 0.9071569   -3.93470e+02
# 11        Dead_Catch_SPR 5.82212e+03 5.60984e+03 0.9635391   -2.12280e+02

##############################################################################
## REQUEST: Provide a sensitivity analysis in which the pelagic juvenile survey
## index (age 0 abundance) is retuned and the total CV does not exceed sigma-R
##############################################################################

# look at mean SE (on a log scale, similar to CV) for the pelagic juvenile survey
base_output$cpue |>
    dplyr::filter(Fleet_name == "JuvSurvey") |>
    dplyr::select(SE, SE_input) |>
    apply(2, mean)
#        SE  SE_input
# 1.7527717 0.5025901

# confirm that difference is due to estimated extra_SE parameter
base_output$parameters["Q_extraSD_JuvSurvey(6)", "Value"]
# [1] 1.25018

base_output$sigma_R_in
# [1] 0.6

# copy input files
inputs <- base_inputs

# fixing the extra_SE at 0.1 will create a total SE which is similar to 0.6
inputs$ctl$Q_parms["Q_extraSD_JuvSurvey(6)", "INIT"] <- 0.1
inputs$ctl$Q_parms["Q_extraSD_JuvSurvey(6)", "PHASE"] <- -1 # fix value
inputs$ctl$Q_parms["Q_extraSD_JuvSurvey(6)", ]
#                        LO HI INIT PRIOR PR_SD PR_type PHASE env_var&link dev_link dev_minyr dev_maxyr dev_PH Block Block_Fxn
# Q_extraSD_JuvSurvey(6)  0  2  0.1     0    99       0    -1            0        0         0         0      0     0         0

# set directory for new model
inputs$dir <- here::here(
    "models",
    "supplemental_requests",
    "pelagic_juvenile_survey_CV"
)

# write files
r4ss::SS_write(
    inputs,
    dir = inputs$dir,
    overwrite = TRUE,
    verbose = FALSE
)

# run the model (took a few tries, so need to not skip run even if Report.sso is present)
r4ss::run(inputs$dir, extras = "-nohess", skipfinished = FALSE)

# get output
output <- r4ss::SS_output(
    # inputs$dir,
    here::here("models", "supplemental_requests", "pelagic_juvenile_survey_CV"),
    printstats = FALSE,
    verbose = FALSE
)

# plot the comparison of the two models
r4ss::SSplotComparisons(
    r4ss::SSsummarize(list(base_output, output)),
    legendlabels = c(
        "August 2025 base model (extra SE estimated at 1.25)",
        "Fix pelagic juvenile survey extra SE to 0.1 (mean total CV similar to sigmaR = 0.6)"
    ),
    endyrvec = 2036,
    print = TRUE,
    plot = FALSE,
    plotdir = inputs$dir,
    verbose = FALSE,
    indexPlotEach = TRUE
)

# plot index fits again without forecast years
r4ss::SSplotComparisons(
    r4ss::SSsummarize(list(base_output, output)),
    legendlabels = c(
        "August 2025 base model (extra SE estimated at 1.25)",
        "Fix pelagic juvenile survey extra SE to 0.1 (mean total CV similar to sigmaR = 0.6)"
    ),
    subplots = 13:14,
    endyrvec = 2025,
    print = TRUE,
    plot = FALSE,
    plotdir = inputs$dir,
    verbose = FALSE,
    indexPlotEach = TRUE
)

# ratios of index values
z <- output$cpue |>
    dplyr::filter(Fleet == 6) |>
    dplyr::select(Yr, Obs, Exp) |>
    dplyr::filter(Yr %in% 2013:2014)

# ratio of 2013 to 2014 observations
z$Obs[1] / z$Obs[2]
# [1] 5.100351

# ratio of 2013 obs to 2013 expected value
z$Obs[1] / z$Exp[1]
# [1] 26.8491

# plot absolute-scale index fits again without uncertainty
r4ss::SSplotComparisons(
    r4ss::SSsummarize(list(base_output, output)),
    legendlabels = c(
        "August 2025 base model (extra SE estimated at 1.25)",
        "Fix pelagic juvenile survey extra SE to 0.1 (mean total CV similar to sigmaR = 0.6)"
    ),
    subplots = 13,
    endyrvec = 2025,
    print = TRUE,
    plot = FALSE,
    plotdir = here::here(
        "models",
        "supplemental_requests",
        "pelagic_juvenile_survey_CV"
    ),
    verbose = FALSE,
    indexUncertainty = FALSE,
    legendloc = "left",
    filenameprefix = "no_index_uncertainty_"
)

r4ss::SStableComparisons(
    r4ss::SSsummarize(list(base_output, output)),
    names = c(
        "NatM",
        "SSB_2025",
        "Bratio_2025",
        "ForeCatch_2027",
        "SPR_MSY",
        "Dead_Catch_SPR"
    )
) |>
    dplyr::mutate(ratio = model2 / model1, diff_from_base = model2 - model1)

r4ss::SS_plots(output)

# # get timeseries of catch summed across fleets
# z <- output$timeseries |>
#     dplyr::select(Yr, dplyr::starts_with("dead(B)")) |>
#     tidyr::pivot_longer(
#         cols = dplyr::starts_with("dead(B)"),
#         names_to = "fleet",
#         values_to = "dead_bio"
#     ) |>
#     dplyr::group_by(Yr) |>
#     dplyr::summarize(total_dead_bio = sum(dead_bio))

# forecast catch
cbind(
    base = base_output$derived_quants |>
        dplyr::filter(grepl("ForeCatch_", Label)) |>
        dplyr::select(Value),
    juvsurvey = output$derived_quants |>
        dplyr::filter(grepl("ForeCatch_", Label)) |>
        dplyr::select(Value)
) |>
    setNames(c("base", "smaller_JuvSurveyCV")) |>
    dplyr::mutate(
        ratio = round(smaller_JuvSurveyCV / base, 2),
        diff = smaller_JuvSurveyCV - base
    )

#                    base smaller_JuvSurveyCV ratio    diff
# ForeCatch_2025 10668.60            10668.60  1.00    0.00
# ForeCatch_2026  9823.60             9823.60  1.00    0.00
# ForeCatch_2027  4238.01             4338.00  1.02   99.99
# ForeCatch_2028  4348.84             5023.60  1.16  674.76
# ForeCatch_2029  4676.98             6212.09  1.33 1535.11
# ForeCatch_2030  5004.36             7111.66  1.42 2107.30
# ForeCatch_2031  5212.97             7365.23  1.41 2152.26
# ForeCatch_2032  5319.59             7194.11  1.35 1874.52
# ForeCatch_2033  5358.98             6869.72  1.28 1510.74
# ForeCatch_2034  5359.67             6539.74  1.22 1180.07
# ForeCatch_2035  5354.68             6274.44  1.17  919.76
# ForeCatch_2036  5347.47             6072.03  1.14  724.56

##############################################################################
## REQUEST: Reweight the compositional data using Francis methods
## (as was done in the sensitivity analysis for the draft document)
## and provide a profile across M with Francis weighting.
##############################################################################

# first explore removing lambdas
inputs <- base_inputs
# there are 10 lambdas set to 0.5
table(inputs$ctl$lambdas$value)
# 0.5   1
#  10   3
inputs$ctl$lambdas$value <- 1
inputs$dir <- here::here(
    "models",
    "supplemental_requests",
    "lambda1_MI"
)
# write files
r4ss::SS_write(
    inputs,
    dir = inputs$dir,
    overwrite = TRUE,
    verbose = FALSE
)

# run the model (took a few tries, so need to not skip run even if Report.sso is present)
r4ss::run(inputs$dir, extras = "-nohess", skipfinished = FALSE)

# apply Francis reweighting to the resulting model with lambdas = 1

### step 1: Create outputs by copying input files

dir_lambda1_Francis <- here::here(
    "models",
    "supplemental_requests",
    "lambda1_Francis"
)
dir.create(dir_lambda1_Francis)

#### copy over the input and output files (output needed for tune_comps)
cpy_files <- dir(inputs$dir)[grepl(
    "\\.ss$|\\.sso$|\\.dat$|\\.ctl$",
    dir(inputs$dir)
)]

file.copy(
    from = file.path(inputs$dir, cpy_files),
    to = file.path(dir_lambda1_Francis, cpy_files),
    overwrite = TRUE
)

### step 2: Run function tune_comps

#### Run Francis data weighting, and tune original model method in 1 go.
#### Note that the original model must have been previously run with Stock
#### Synthesis, so that a report file is available.
tune_comps(
    dir = dir_lambda1_Francis,
    option = "Francis",
    exe = exe_loc,
    extras = "-nohess",
    verbose = FALSE,
    niters_tuning = 3
)

output_lambda0.5_Francis <- SS_output(
    "models/supplemental_requests/lambda0.5_Francis",
    printstats = FALSE,
    verbose = FALSE
) # "models/supplemental_requests/lambda0.5_Francis"
output_lambda1_MI <- SS_output(inputs$dir, printstats = FALSE, verbose = FALSE) # "models/supplemental_requests/lambda1_MI"
output_lambda1_Francis <- SS_output(
    dir_lambda1_Francis,
    printstats = FALSE,
    verbose = FALSE
)
SSplotComparisons(
    SSsummarize(list(
        base_output,
        output_lambda0.5_Francis,
        output_lambda1_MI,
        output_lambda1_Francis
    )),
    legendlabels = c(
        "August 2025 base model (M-I, lambdas = 0.5)",
        "Francis weighting, lambdas = 0.5",
        "M-I weighting, lambdas = 1",
        "Francis weighting, lambdas = 1"
    ),
    endyrvec = 2036,
    print = TRUE,
    plot = FALSE,
    plotdir = inputs$dir,
    verbose = FALSE
)

r4ss::SStableComparisons(
    r4ss::SSsummarize(list(
        base_output,
        output_lambda0.5_Francis,
        output_lambda1_MI,
        output_lambda1_Francis
    )),
    names = c(
        "NatM",
        "SSB_2025",
        "Bratio_2025",
        "ForeCatch_2027",
        "SPR_MSY",
        "Dead_Catch_SPR"
    )
)
#                    Label      model1      model2      model3      model4
# 1             TOTAL_like 1.90165e+04 1.77943e+04 2.01024e+04 1.35946e+04
# 2            Survey_like 8.04479e+00 8.47381e+00 8.50489e+00 1.22647e+01
# 3       Length_comp_like 8.29491e+02 2.31808e+02 1.31914e+03 4.78772e+02
# 4          Age_comp_like 1.36719e+03 7.53171e+02 1.95653e+03 1.18477e+03
# 5       Parm_priors_like 9.03229e-01 1.39297e+00 1.05306e+00 1.82207e-01
# 6  NatM_uniform_Fem_GP_1 1.22306e-01 1.33219e-01 1.26805e-01 1.02317e-01
# 7  NatM_uniform_Mal_GP_1 1.34775e-01 1.46405e-01 1.39766e-01 1.13523e-01
# 8   SSB_2025_thousand_mt 4.69340e+01 5.49820e+01 4.21830e+01 4.17910e+01
# 9            Bratio_2025 5.49186e-01 5.91803e-01 5.49754e-01 4.74469e-01
# 10        ForeCatch_2027 4.23801e+03 6.24214e+03 3.94436e+03 2.84247e+03
# 11               SPR_MSY 3.36819e-01 3.34478e-01 3.36581e-01 3.40962e-01
# 12        Dead_Catch_SPR 5.82212e+03 6.99630e+03 5.46901e+03 5.12887e+03

##############################################################################
## REQUEST: Explore some means to remove, combine or down-weight the H&L and
##          other fixed gear compositional data.
##############################################################################

# get inputs from ss_new files which will use MLE starting values from control.ss_new
base_inputs_start_values <- r4ss::SS_read(
    here::here(
        "models",
        "supplemental_requests",
        "base_model_with_ss_new"
    ),
    ss_new = TRUE
)
inputs <- base_inputs_start_values

# set directory for new model
inputs$dir <- here::here(
    "models",
    "supplemental_requests",
    # "mirror_fixed_gear_selex"
    # "mirror_fixed_gear_selex_midwater_fixed_at_MLE"
    "mirror_fixed_gear_selex_rephase"
)

# figure out which fleets are H&L and Net
inputs$dat$fleetnames
# [1] "BottomTrawl"   "MidwaterTrawl" "Hake"          "Net"           "HnL"           "JuvSurvey"     "Triennial"     "WCGBTS"        "ForeignAtSea"

inputs$ctl$size_selex_types
#               Pattern Discard Male Special
# BottomTrawl        24       1    0       0
# MidwaterTrawl      24       1    0       0
# Hake               24       0    0       0
# Net                24       0    0       0
# HnL                24       1    0       0
# JuvSurvey           0       0    0       0
# Triennial          27       0    0       3
# WCGBTS             27       0    0       3
# ForeignAtSea        5       0    0       3

# change fleets 4 and 5 to mirror selectivity of BottomTrawl
inputs$ctl$size_selex_types$Pattern[4:5] <- 15 # mirror with no parameters required
inputs$ctl$size_selex_types$Discard[4:5] <- 0 # turn off retention stuff
inputs$ctl$size_selex_types$Special[4:5] <- 1 # mirror fleet 1 (BottomTrawl)

# check changed values
inputs$ctl$size_selex_types
#               Pattern Discard Male Special
# BottomTrawl        24       1    0       0
# MidwaterTrawl      24       1    0       0
# Hake               24       0    0       0
# Net                15       0    0       1
# HnL                15       0    0       1
# JuvSurvey           0       0    0       0
# Triennial          27       0    0       3
# WCGBTS             27       0    0       3
# ForeignAtSea        5       0    0       3

# remove all rows of the size selectivity parameters for fleets 4 and 5
# (those where the rowname matches the pattern "SizeSel_P_1_Net(4)", "SizeSel_P_2_Net(4)",..."SizeSel_P_1_HnL(5)", etc.)
inputs$ctl$size_selex_parms <- inputs$ctl$size_selex_parms |>
    dplyr::filter(
        !grepl("SizeSel_.*\\([4-5]\\)", rownames(inputs$ctl$size_selex_parms))
    )
# remove the time-varying size selectivity parameters for fleets 4 and 5 (had only been fleet 5)
inputs$ctl$size_selex_parms_tv <- inputs$ctl$size_selex_parms_tv |>
    dplyr::filter(
        !grepl(
            "SizeSel_.*\\([4-5]\\)",
            rownames(inputs$ctl$size_selex_parms_tv)
        )
    )


# remove length and age data for fleets 4 and 5
inputs$dat$lencomp <- inputs$dat$lencomp |>
    dplyr::filter(!fleet %in% 4:5)
inputs$dat$agecomp <- inputs$dat$agecomp |>
    dplyr::filter(!fleet %in% 4:5)

# optionally fix the midwater trawl selectivity at MLE values
inputs$ctl$size_selex_parms[
    grepl("SizeSel_P_._MidwaterTrawl", rownames(inputs$ctl$size_selex_parms)),
    "PHASE"
] <- -1
inputs$ctl$size_selex_parms_tv[
    grepl(
        "SizeSel_P_._MidwaterTrawl",
        rownames(inputs$ctl$size_selex_parms_tv)
    ),
    "PHASE"
] <- -1

# fix the midwater trawl selectivity at MLE values (or estimate in a later phase)
inputs$ctl$size_selex_parms[
    grepl("SizeSel_P_._MidwaterTrawl", rownames(inputs$ctl$size_selex_parms)),
    "PHASE"
] <- 6
inputs$ctl$size_selex_parms_tv[
    grepl(
        "SizeSel_P_._MidwaterTrawl",
        rownames(inputs$ctl$size_selex_parms_tv)
    ),
    "PHASE"
] <- 6

# write files
r4ss::SS_write(
    inputs,
    dir = inputs$dir,
    overwrite = TRUE,
    verbose = FALSE
)

# run the model (took a few tries, so need to not skip run even if Report.sso is present)
r4ss::run(inputs$dir, extras = "-nohess", skipfinished = FALSE)

# get output
output1 <- r4ss::SS_output(
    # inputs$dir,
    here::here("models", "supplemental_requests", "mirror_fixed_gear_selex"),
    printstats = FALSE,
    verbose = FALSE
)
# get output from midwater selectivity fixed at MLE
output2 <- r4ss::SS_output(
    here::here("models", "supplemental_requests", "mirror_fixed_gear_selex_midwater_fixed_at_MLE"),
    printstats = FALSE,
    verbose = FALSE
)

# get output from midwater selectivity starting at MLE and estimated in a later phase
output3 <- r4ss::SS_output(
    here::here("models", "supplemental_requests", "mirror_fixed_gear_selex_rephase"),
    printstats = FALSE,
    verbose = FALSE
)

# plot the comparison of the two models
r4ss::SSplotComparisons(
    r4ss::SSsummarize(list(base_output, output)),
    legendlabels = c(
        "August 2025 base model",
        "Remove H&L and Net length and age data, mirror selectivity of BottomTrawl"
    ),
    endyrvec = 2036,
    print = TRUE,
    plot = FALSE,
    plotdir = inputs$dir,
    verbose = FALSE
)

r4ss::SStableComparisons(
    r4ss::SSsummarize(list(base_output, output1, output2)),
    names = c(
        "NatM",
        "SSB_2025",
        "Bratio_2025",
        "ForeCatch_2027",
        "SPR_MSY",
        "Dead_Catch_SPR"
    )
) |>
    dplyr::mutate(ratio = model2 / model1, diff_from_base = model2 - model1)

r4ss::SS_plots(output)

# 2025-08-21: results from mirrored selectivity model are implausibly low, need to check convergence
