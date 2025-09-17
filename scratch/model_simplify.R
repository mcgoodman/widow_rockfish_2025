# read base model input files
base_inputs <- r4ss::SS_read(
  here::here(
    "models",
    "2025 base model"
  )
)
# read base model output
base_output <- r4ss::SS_output(
  here::here(
    "models",
    "2025 base model"
  ),
  printstats = FALSE,
  verbose = FALSE
)

inputs <- base_inputs

# set directory for new model
inputs$dir <- here::here(
  "models",
  "supplemental_requests",
  "simplify_step1_add_discards_to_landings"
)

inputs$dat$fleetnames
# [1] "BottomTrawl"   "MidwaterTrawl" "Hake"          "Net"           "HnL"           "JuvSurvey"     "Triennial"     "WCGBTS"        "ForeignAtSea"

# simplify catch data by combining fixed gear fleets (H&L and Net) with BottomTrawl
inputs$dat$catch <- inputs$dat$catch |>
  dplyr::mutate(
    fleet = dplyr::case_when(
      fleet %in% 4:5 ~ 1, # fleets 4 and 5 are Net and H&L, combine with fleet 1 (BottomTrawl)
      fleet %in% 3 & year %in% 1966:1968 ~ 1, # move foreign catch in 1966-67 from hake fleet to bottom trawl fleet
      TRUE ~ fleet
    )
  ) |>
  dplyr::group_by(year, fleet) |> # group by year and new fleet
  dplyr::summarize(catch = sum(catch)) |> # sum catch within year and new fleet
  dplyr::ungroup() |>
  dplyr::mutate(seas = 1, catch_se = 0.1) |> # add back columns needed in catch data
  dplyr::arrange(fleet, year) |>
  dplyr::select(year, seas, fleet, catch, catch_se) |> # reorder columns
  as.data.frame()

# confirm that dataframes (without discards) are identical
# after moving around some of the catch
# for fleets 2-3 (MidwaterTrawl and Hake) except for years 1966-1968
all.equal(
  base_inputs$dat$catch |>
    dplyr::filter(!year %in% 1966:1968, fleet %in% 2:3) |>
    dplyr::pull(catch),
  inputs$dat$catch |>
    dplyr::filter(!year %in% 1966:1968, fleet %in% 2:3) |>
    dplyr::pull(catch)
)
# [1] TRUE

# confirm that total catch is the same across all fleets
sum(base_inputs$dat$catch$catch) - sum(inputs$dat$catch$catch)
# [1] 0

# read table of discard rates from 2015 assessment report (Table 17)
discard_rates <- read.csv(
  "data_provided/2015_assessment/discard_rates_from_2015_report_Table_17.csv",
  check.names = FALSE
)
discard_rate_BT_pikitch <- discard_rates |>
  dplyr::filter(Fleet == "Bottom Trawl", Year %in% 1985:1987) |>
  dplyr::pull("Rate (d/[d+r])") |>
  mean()

discard_rate_BT_EDCP <- discard_rates |>
  dplyr::filter(Fleet == "Bottom Trawl", Year %in% 1995:1999) |>
  dplyr::pull("Rate (d/[d+r])") |>
  mean()

discard_rate_MD_pikitch <- discard_rates |>
  dplyr::filter(Fleet == "Midwater Trawl", Year %in% 1985:1987) |>
  dplyr::pull("Rate (d/[d+r])") |>
  mean()

discard_rate_MD_EDCP <- discard_rates |>
  dplyr::filter(Fleet == "Midwater Trawl", Year %in% 1995:1999) |>
  dplyr::pull("Rate (d/[d+r])") |>
  mean()

discard_rate_BT_pikitch
discard_rate_BT_EDCP
discard_rate_MD_pikitch
discard_rate_MD_EDCP

# which years for blocks on each fleet?
ret_blocks_BT <- inputs$ctl$size_selex_parms[
  grepl(
    pattern = "SizeSel_PRet.*_BottomTrawl.*",
    rownames(inputs$ctl$size_selex_parms)
  ),
  "Block"
] |>
  unique()
ret_blocks_BT <- ret_blocks_BT[ret_blocks_BT > 0] # remove 0 (no block)
inputs$ctl$Block_Design[ret_blocks_BT]
# [[1]]
# [1] 1982 1989 1990 2010

# [[2]]
# [1] 1982 1989 1990 1997 1998 2010
ret_blocks_MD <- inputs$ctl$size_selex_parms[
  grepl(
    pattern = "SizeSel_PRet.*_MidwaterTrawl.*",
    rownames(inputs$ctl$size_selex_parms)
  ),
  "Block"
] |>
  unique()
ret_blocks_MD <- ret_blocks_MD[ret_blocks_MD > 0] # remove 0 (no block)
inputs$ctl$Block_Design[ret_blocks_MD]
# [[1]]
# [1] 1916 1982 1983 2001 2002 2010 2011 2016

# add gemm_discards for 2002-2021
# as calculated in /scratch/explore_discards.R
gemm_discards <- readRDS("data_derived/discards/gemm_discards_by_fleet.rds")
# # A tibble: 6 x 3
# # Groups:   year [6]
#    year fleet       catch
#   <int> <chr>       <dbl>
# 1  2002 BottomTrawl  2.48
# 2  2003 BottomTrawl  1.24
# 3  2004 BottomTrawl  5.26
# 4  2005 BottomTrawl  3.99
# 5  2006 BottomTrawl  1.02
# 6  2007 BottomTrawl  9.46

table(gemm_discards$fleet)
# BottomTrawl MidwaterTrawl
#          22            12

# convert gemm discards to same fleet numbering as model
gemm_discards <- gemm_discards |>
  dplyr::mutate(
    fleet = dplyr::case_when(
      fleet == "BottomTrawl" ~ 1,
      fleet == "MidwaterTrawl" ~ 2
    )
  ) |>
  # adding missing columns to gemm_discards and order correctly
  dplyr::mutate(seas = 1, catch_se = 0.1) |>
  dplyr::select(year, seas, fleet, catch, catch_se)

# add 2024 discard amounts which are the average of the past 3 years for each fleet
gemm_discards_2024 <- gemm_discards |>
  dplyr::filter(year %in% 2021:2023) |>
  dplyr::group_by(fleet) |>
  dplyr::summarize(
    year = 2024,
    seas = 1,
    catch = mean(catch),
    catch_se = mean(catch_se)
  ) |>
  dplyr::select(year, seas, fleet, catch, catch_se)
gemm_discards <- rbind(gemm_discards, gemm_discards_2024)

# add gemm_discards to landings (covers period 2002 to 2023)
catch_with_gemm <- rbind(
  inputs$dat$catch,
  gemm_discards
) |>
  dplyr::group_by(year, seas, fleet) |>
  dplyr::summarize(catch = sum(catch), catch_se = mean(catch_se)) |>
  dplyr::ungroup() |>
  dplyr::arrange(fleet, year) |>
  as.data.frame()

# apply discard rates to catch data to cover the period 1982 to 2001
catch_with_discards <- catch_with_gemm |>
  dplyr::mutate(
    discard_rate = dplyr::case_when(
      fleet == 1 & year %in% 1982:1989 ~ discard_rate_BT_pikitch,
      fleet == 1 & year %in% 1990:2001 ~ discard_rate_BT_EDCP,
      fleet == 2 & year %in% 1982:1989 ~ discard_rate_MD_pikitch,
      fleet == 2 & year %in% 1990:2001 ~ discard_rate_MD_EDCP,
      TRUE ~ 0
    ),
    discard = catch * discard_rate / (1 - discard_rate),
    total_catch = catch + discard
  ) |>
  dplyr::select(year, seas, fleet, catch = total_catch, catch_se)

# ratio of catch with discards to dead catch in base model
sum(catch_with_discards$catch) / sum(base_output$catch$dead_bio)
# [1] 1.004989

# ratio of total catch to retained catch in base model by year
base_output$catch |>
  dplyr::rename(year = Yr) |>
  dplyr::group_by(year) |>
  dplyr::summarize(dead_bio = sum(dead_bio), ret_bio = sum(ret_bio)) |>
  dplyr::mutate(ratio = dead_bio / ret_bio) |>
  dplyr::filter(year > 1950) |>
  dplyr::select(year, ratio) |>
  plot()

# calculate ratio of total catch to landings (retained) from new catch table
yearly_ratio1 <- catch_with_discards |>
  dplyr::group_by(year) |>
  dplyr::summarize(catch = sum(catch)) |>
  dplyr::left_join(
    base_output$catch |>
      dplyr::rename(year = Yr) |>
      dplyr::group_by(year) |>
      # dplyr::summarize(dead_bio = sum(dead_bio)),
      dplyr::summarize(ret_bio = sum(ret_bio)),
    by = "year"
  ) |>
  dplyr::mutate(ratio = catch / ret_bio)

# plot ratio of catch with discards to retained catch over time
yearly_ratio1 |>
  dplyr::select(year, ratio) |>
  lines()


# calculate ratio for each year using the new table including discards
yearly_ratio2 <- catch_with_discards |>
  dplyr::group_by(year) |>
  dplyr::summarize(catch = sum(catch)) |>
  dplyr::left_join(
    base_output$catch |>
      dplyr::rename(year = Yr) |>
      dplyr::group_by(year) |>
      dplyr::summarize(dead_bio = sum(dead_bio)),
    by = "year"
  ) |>
  dplyr::mutate(ratio = catch / dead_bio)

yearly_ratio2 |>
  dplyr::select(year, ratio) |>
  dplyr::filter(year > 1950) |>
  plot()

# replace catch time series in inputs with catch including discards
inputs$dat$catch <- catch_with_discards

# remove fleets 4 and 5 from comp data
inputs$dat$agecomp <- inputs$dat$agecomp |>
  dplyr::filter(!fleet %in% 4:5)
inputs$dat$lencomp <- inputs$dat$lencomp |>
  dplyr::filter(!fleet %in% 4:5)

# remove discard comps from all fleets
inputs$dat$agecomp$part |> table()
#   0   2
# 560  92
inputs$dat$lencomp$part |> table()
#   0   1   2
# 121  26  98
inputs$dat$lencomp <- inputs$dat$lencomp |>
  dplyr::filter(part != 1) # remove discard comps (partition 1)

# assign all remaining comps to partition 0 (total catch) instead of 2 (retained)
inputs$dat$lencomp <- inputs$dat$lencomp |>
  dplyr::mutate(part = 0)
inputs$dat$agecomp <- inputs$dat$agecomp |>
  dplyr::mutate(part = 0)

# remove all discard data
inputs$dat$N_discard_fleets <- 0
inputs$dat$discard_fleet_info <- NULL
inputs$dat$discard_data <- NULL

# simplify the control file
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
inputs$ctl$size_selex_types$Pattern[c(4:5, 9)] <- 0 # no parameters required
inputs$ctl$size_selex_types$Discard <- 0 # turn off retention for all fleets

# check changed values
inputs$ctl$size_selex_types
#               Pattern Discard Male Special
# BottomTrawl        24       0    0       0
# MidwaterTrawl      24       0    0       0
# Hake               24       0    0       0
# Net                 0       0    0       0
# HnL                 0       0    0       0
# JuvSurvey           0       0    0       0
# Triennial          27       0    0       3
# WCGBTS             27       0    0       3
# ForeignAtSea        5       0    0       3

# remove all rows of the size selectivity parameters for fleets 4 and 5 and 9
# (those where the rowname matches the pattern "SizeSel_P_1_Net(4)", "SizeSel_P_2_Net(4)",..."SizeSel_P_1_HnL(5)", etc.)
inputs$ctl$size_selex_parms <- inputs$ctl$size_selex_parms |>
  dplyr::filter(
    !grepl("SizeSel_.*\\([4-5,9]\\)", rownames(inputs$ctl$size_selex_parms))
  )
# remove the time-varying size selectivity parameters for fleets 4 and 5 (had only been present for fleet 5)
inputs$ctl$size_selex_parms_tv <- inputs$ctl$size_selex_parms_tv |>
  dplyr::filter(
    !grepl(
      "SizeSel_.*\\([4-5,9]\\)",
      rownames(inputs$ctl$size_selex_parms_tv)
    )
  )
# remove retention parameters (all fleets)
inputs$ctl$size_selex_parms <- inputs$ctl$size_selex_parms |>
  dplyr::filter(
    !grepl("SizeSel_PRet.*", rownames(inputs$ctl$size_selex_parms))
  )
inputs$ctl$size_selex_parms_tv <- inputs$ctl$size_selex_parms_tv |>
  dplyr::filter(
    !grepl("SizeSel_PRet.*", rownames(inputs$ctl$size_selex_parms_tv))
  )

# remove variance adjustments for removed data
inputs$ctl$Variance_adjustment_list <- inputs$ctl$Variance_adjustment_list |>
  dplyr::filter(
    !fleet %in% c(4, 5, 9) # remove fleets 4, 5, and 9
  )

# remove extraneous lambda (likelihood multipliers) for removed data
inputs$ctl$lambdas <- inputs$ctl$lambdas |>
  dplyr::filter(
    !fleet %in% c(4, 5, 9), # remove lambdas for fleets 4, 5, and 9
  )
inputs$ctl$N_lambdas <- nrow(inputs$ctl$lambdas)

# increase starting value for R0 (was causing crash penalty and warning at the start of estimation)
inputs$ctl$SR_parms["SR_LN(R0)", "INIT"] <- 11.5 # was 10.4573
inputs$ctl$SR_parms["SR_LN(R0)", "LO"] <- 6 # was 1
inputs$ctl$SR_parms["SR_LN(R0)", "HI"] <- 15 # was 20
# write ss_new files and expected values (but no bootstrap datasets)
inputs$start$N_bootstraps <- 2

# simplify forecast file by aggregating fixed catches for fleets 4 and 5
inputs$fore$ForeCatch <- inputs$fore$ForeCatch |>
  dplyr::mutate(
    fleet = dplyr::case_when(
      fleet %in% 4:5 ~ 1, # fleets 4 and 5 are Net and H&L, combine with fleet 1 (BottomTrawl)
      TRUE ~ fleet
    )
  ) |>
  dplyr::group_by(year, fleet) |> # group by new fleet
  dplyr::summarize(catch_or_F = sum(catch_or_F)) |> # sum catch within new fleet
  dplyr::ungroup() |>
  dplyr::mutate(seas = 1) |> # add back column needed in ForeCatch data
  dplyr::select(year, seas, fleet, catch_or_F) |> # reorder columns
  as.data.frame()
# confirm that total forecast catch matches original base model
inputs$fore$ForeCatch$catch_or_F |>
  sum() -
  base_inputs$fore$ForeCatch$catch_or_F |>
    sum()
# [1] 0

# write files
r4ss::SS_write(
  inputs,
  dir = inputs$dir,
  overwrite = TRUE,
  verbose = FALSE
)

if (FALSE) {
  # run the model
  # r4ss::run(inputs$dir, extras = "-nohess", skipfinished = FALSE)

  # get output
  output1 <- r4ss::SS_output(
    # inputs$dir,
    here::here(
      "models",
      "supplemental_requests",
      "simplify_step1_add_discards_to_landings"
    ),
    printstats = FALSE,
    verbose = FALSE
  )

  # step 2: remove 0.5 likelihood weights and retune with Francis method
  inputs_step2 <- inputs
  inputs_step2$dir <- here::here(
    "models",
    "supplemental_requests",
    "simplify_step2_lambda1_Francis"
  )
  inputs_step2$ctl$lambdas$value <- 1
  r4ss::SS_write(
    inputs_step2,
    dir = inputs_step2$dir,
    overwrite = TRUE,
    verbose = FALSE
  )
  tuning_results2 <- tune_comps(
    dir = inputs_step2$dir,
    option = "Francis",
    init_run = TRUE,
    extras = "-nohess",
    verbose = TRUE,
    niters_tuning = 2
  )

  output2 <- r4ss::SS_output(
    # inputs$dir,
    here::here(
      "models",
      "supplemental_requests",
      "simplify_step2_lambda1_Francis"
    ),
    printstats = FALSE,
    verbose = FALSE
  )

  # compare to similar simplified model developed by Vlada
  output_restructured <- SS_output(
    "models/supplemental_requests/Fleet structure exploration/New_base_POP_separate_nontrawl_blocks_tuned_mdt_BT_tuned_blocks_retuned_hess",
    printstats = FALSE,
    verbose = FALSE
  )
  output_restructured_lambda1_Francis <- SS_output(
    "models/supplemental_requests/restructured_lambda1_Francis",
    printstats = FALSE,
    verbose = FALSE
  )

  simpler_summary <- SSsummarize(list(
    base_output,
    output_restructured,
    output_restructured_lambda1_Francis,
    output1,
    output2
  ))
  SSplotComparisons(
    simpler_summary,
    legendlabels = c(
      "2025 base model",
      "discards from model output",
      "discards from model output, lambda=1 Francis",
      "external discard values",
      "external discard values, lambda=1 Francis"
    ),
    filenameprefix = "compare_simplified_models_",
    plotdir = here::here(
      "models",
      "supplemental_requests",
      "simplify_step2_lambda1_Francis"
    ),
    plot = FALSE,
    print = TRUE
  )

  SStableComparisons(
    simpler_summary,
    names = c("NatM", "SSB_2025", "Bratio_2025", "ForeCatch_2027")
  )

  # step3: add fecundity relationship, starting from initial values in previous step
  inputs3 <- SS_read(
    here::here(
      "models",
      "supplemental_requests",
      "simplify_step2_lambda1_Francis"
    ),
    ss_new = TRUE
  )
  inputs3$dir <- here::here(
    "models",
    "supplemental_requests",
    "simplify_step3_add_fecundity"
  )
  # add fecundity relationship
  # change fecundity_at_length option:(1)eggs=Wt*(a+b*Wt);(2)eggs=a*L^b;(3)eggs=a*Wt^b; (4)eggs=a+b*L; (5)eggs=a+b*W
  inputs3$ctl$fecundity_option <- 2
  # update parameters
  inputs3$ctl$MG_parms["Eggs_alpha_Fem_GP_1", "INIT"] <- 7.218466e-08
  inputs3$ctl$MG_parms["Eggs_beta_Fem_GP_1", "INIT"] <- 4.043

  # increase starting value for R0 (was causing crash penalty and warning at the start of estimation)
  inputs3$ctl$SR_parms["SR_LN(R0)", "INIT"] <- 11.5

  # write files
  r4ss::SS_write(
    inputs3,
    dir = inputs3$dir,
    overwrite = TRUE,
    verbose = FALSE
  )
  output3 <- r4ss::SS_output(
    # inputs$dir,
    here::here(
      "models",
      "supplemental_requests",
      "simplify_step3_add_fecundity"
    ),
    printstats = FALSE,
    verbose = FALSE
  )

  SSplotComparisons(
    SSsummarize(list(base_output, output2, output3)),
    subplot = 1:15
  )

  SStableComparisons(
    SSsummarize(list(base_output, output2, output3)),
    names = c("NatM", "SSB_2025", "Bratio_2025", "ForeCatch_2027")
  )

}
