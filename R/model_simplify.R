# ------------------------------------------------------------------------------
# Model simplification and data modification steps performed in this script:
#
# NOTE: this list is out of date
# 1. Combine fixed gear fleets (H&L and Net) with BottomTrawl in catch and forecast.
# 2. Move foreign catch in 1966-76 from Hake fleet to BottomTrawl.
# 3. Add discard estimates to landings for 1982-2024 using discard rates and external data.
# 4. Remove fleets 4 (Net), 5 (H&L) from composition data.
# 5. Remove all discard composition data and assign all remaining comps to partition 0 (total catch).
# 6. Remove all discard data structures from input (N_discard_fleets, discard_fleet_info, discard_data).
# 7. Simplify selectivity: set fleets 4, 5, and 9 to Pattern=0, Discard=0, and remove their selectivity parameters.
# 8. Remove all retention parameters and time-varying selectivity parameters for all fleets.
# 9. Remove variance adjustments and lambdas for removed fleets.
# 10. Increase starting value for R0 and adjust bounds to avoid estimation issues.
# 11. Aggregate fixed catches for fleets 4 and 5 in the forecast file.
# 12. Set final midwater selectivity change to 2017 instead of 2011
# 13. Update bias adjustment using estimated values but modified to have full bias adjustment starting in 1970.
# ------------------------------------------------------------------------------

which_steps <- 1:6
run_models <- TRUE # doesn't apply to tuning steps, only works for step 1, perhaps
copy_to_base_dir <- TRUE

if (1 %in% which_steps) {
  cli::cli_alert_info(
    "Step 1: Simplify model by combining fleets and adding discards to landings"
  )

  # read model input files from model with WA catch reconstruction
  base_inputs <- r4ss::SS_read(
    here::here(
      "models",
      "sensitivities",
      "Aug2025_NewWACatch"
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
    "1.01_add_discards_to_landings"
  )

  inputs$dat$fleetnames
  # [1] "BottomTrawl"   "MidwaterTrawl" "Hake"          "Net"           "HnL"           "JuvSurvey"     "Triennial"     "WCGBTS"        "ForeignAtSea"

  # get ASHOP catch from the 1976-76 to keep in the hake fleet after removing foreign catch
  catch_ashop <- readxl::read_excel(here(
    "data_provided",
    "ASHOP",
    "A-SHOP_Widow_CatchData_removedConfidentialFields_1975-2024_012325.xlsx"
  ))
  catch_ashop_75_76 <- catch_ashop$EXPANDED_SumOfEXTRAPOLATED_2SECTOR_WEIGHT_KG[
    catch_ashop$YEAR %in% 1975:1976
  ] /
    1000
  # messy approach to calculating foreign catch
  fleet3_catch_66_76 <- inputs$dat$catch |>
    dplyr::filter(year %in% 1966:1976 & fleet == 3) |>
    dplyr::pull(catch)
  foreign_catch_66_76 <- fleet3_catch_66_76
  foreign_catch_66_76[which(
    1966:1976 %in% 1975:1976
  )] <- foreign_catch_66_76[which(1966:1976 %in% 1975:1976)] - catch_ashop_75_76

  # simplify catch data by combining fixed gear fleets (H&L and Net) with BottomTrawl
  inputs$dat$catch <- inputs$dat$catch |>
    dplyr::mutate(
      fleet = dplyr::case_when(
        fleet %in% 4:5 ~ 1, # fleets 4 and 5 are Net and H&L, combine with fleet 1 (BottomTrawl)
        #        fleet %in% 3 & year %in% 1966:1976 ~ 1, # move foreign catch in 1966-67 from hake fleet to bottom trawl fleet
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
  # add foreign catch in 1966-76 to BottomTrawl fleet
  inputs$dat$catch$catch[
    inputs$dat$catch$year %in% 1966:1976 & inputs$dat$catch$fleet == 1
  ] <-
    inputs$dat$catch$catch[
      inputs$dat$catch$year %in% 1966:1976 & inputs$dat$catch$fleet == 1
    ] +
    foreign_catch_66_76
  # subtract foreign catch in 1966-76 from Hake fleet
  inputs$dat$catch$catch[
    inputs$dat$catch$year %in% 1966:1976 & inputs$dat$catch$fleet == 3
  ] <-
    inputs$dat$catch$catch[
      inputs$dat$catch$year %in% 1966:1976 & inputs$dat$catch$fleet == 3
    ] -
    foreign_catch_66_76

  # confirm that total catch is the same across all fleets
  if (sum(base_inputs$dat$catch$catch) != sum(inputs$dat$catch$catch)) {
    cli::cli_alert_danger("Total catch has changed after combining fleets")
  } else {
    cli::cli_alert_success("Total catch is the same after combining fleets")
  }

  # move the actual hake catch back into the hake fleet for 1975-76
  inputs$dat$catch$catch[
    inputs$dat$catch$year %in% 1975:1976 & inputs$dat$catch$fleet == 1
  ] <-
    inputs$dat$catch$catch[
      inputs$dat$catch$year %in% 1975:1976 & inputs$dat$catch$fleet == 1
    ] -
    catch_ashop_75_76
  inputs$dat$catch$catch[
    inputs$dat$catch$year %in% 1975:1976 & inputs$dat$catch$fleet == 3
  ] <-
    inputs$dat$catch$catch[
      inputs$dat$catch$year %in% 1975:1976 & inputs$dat$catch$fleet == 3
    ] +
    catch_ashop_75_76

  # confirm that total catch is the same after moving ASHOP catch back into hake fleet
  if (sum(base_inputs$dat$catch$catch) != sum(inputs$dat$catch$catch)) {
    cli::cli_alert_danger("Total catch has changed after moving foreign catch")
  } else {
    cli::cli_alert_success("Total catch is the same after moving foreign catch")
  }

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

  table(catch_with_discards$catch == 0)
  # FALSE  TRUE
  #   213   114

  # remove rows with 0 catch
  catch_with_discards <- catch_with_discards |>
    dplyr::filter(catch > 0)

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

  # rename unused fleets
  inputs$dat$fleetnames[4:5] <- c("ignore1", "ignore2")
  inputs$dat$fleetinfo$fleetname[4:5] <- c("ignore1", "ignore2")

  ########## simplify the control file
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
  inputs$ctl$size_selex_types$Pattern[c(4:5)] <- 0 # no parameters required
  inputs$ctl$size_selex_types$Discard <- 0 # turn off retention for all fleets
  inputs$ctl$size_selex_types$Pattern[9] <- 15 # switch to mirror option 15 (all bins mirrored rather than requiring parameters for min and max bins)

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
  # fleet 9 still mirros fleet 3 (Hake) but using Pattern=15 so no parameters are needed
  inputs$ctl$size_selex_parms <- inputs$ctl$size_selex_parms |>
    dplyr::filter(
      !grepl("SizeSel_.*\\([4-5,9]\\)", rownames(inputs$ctl$size_selex_parms))
    )
  # remove the time-varying size selectivity parameters for fleets 4 and 5 (had only been present for fleet 5)
  inputs$ctl$size_selex_parms_tv <- inputs$ctl$size_selex_parms_tv |>
    dplyr::filter(
      !grepl(
        "SizeSel_.*\\([4-5]\\)",
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

  block_designs_used <- c(
    inputs$ctl$MG_parms$Block, # none used
    inputs$ctl$SR_parms$Block, # none used
    inputs$ctl$Q_parms$Block, #
    inputs$ctl$size_selex_parms$Block,
    inputs$ctl$age_selex_parms$Block
  ) |>
    unique() |>
    sort() |>
    setdiff(0)
  block_designs_used
  # [1]  4  7  9 10 11

  inputs$ctl$Q_parms |> dplyr::filter(Block != 0)
  #                        LO HI      INIT PRIOR PR_SD PR_type PHASE env_var&link dev_link dev_minyr dev_maxyr dev_PH Block Block_Fxn
  # LnQ_base_Hake(3)      -20  2 -11.11040     0    99       0     1            0        0         0         0      0    10         1
  # LnQ_base_Triennial(7)  -4  4  -2.04354     0    99       0     2            0        0         0         0      0     9         1

  inputs$ctl$size_selex_parms |> dplyr::filter(Block != 0)
  #                              LO HI     INIT PRIOR PR_SD PR_type PHASE env_var&link dev_link dev_minyr dev_maxyr dev_PH Block Block_Fxn
  # SizeSel_P_1_BottomTrawl(1)   10 59 43.47500  45.0  0.05       0     1            0        0         0         0    0.5     4         2
  # SizeSel_P_3_BottomTrawl(1)   -4 12  4.59780   3.0  0.05       0     2            0        0         0         0    0.5     4         2
  # SizeSel_P_1_MidwaterTrawl(2) 10 59 36.94380  45.0  0.05       0     1            0        0         0         0    0.5     7         2
  # SizeSel_P_3_MidwaterTrawl(2) -4 12  2.86134   3.0  0.05       0     2            0        0         0         0    0.5     7         2
  # SizeSel_P_4_MidwaterTrawl(2) -2 10  3.92888  10.0  0.05       0     4            0        0         0         0    0.5     7         2
  # SizeSel_P_6_MidwaterTrawl(2) -9  9 -1.30530   0.5  0.05       0     4            0        0         0         0    0.5     7         2
  # SizeSel_P_1_Hake(3)          10 59 33.47220  45.0  0.05       0     1            0        0         0         0    0.5    11         2
  # SizeSel_P_2_Hake(3)          -5 10 -2.01891   5.0  0.05       0     3            0        0         0         0    0.5    11         2
  # SizeSel_P_3_Hake(3)          -4 12  2.07545   3.0  0.05       0     2            0        0         0         0    0.5    11         2

  for (b in 1:inputs$ctl$N_Block_Designs) {
    if (!(b %in% block_designs_used)) {
      inputs$ctl$Block_Design[[b]] <- c(1916, 1916) # mark unused blocks
      inputs$ctl$blocks_per_pattern[b] <- 1
    }
  }
  # shift final year of midwater trawl block design to 2016
  inputs$ctl$Block_Design[[7]]
  # [1] 1916 1982 1983 2001 2002 2010
  inputs$ctl$Block_Design[[7]][6] <- 2016

  # increase starting value for R0 (was causing crash penalty and warning at the start of estimation)
  inputs$ctl$SR_parms["SR_LN(R0)", "INIT"] <- 11.5 # was 10.4573
  inputs$ctl$SR_parms["SR_LN(R0)", "LO"] <- 6 # was 1
  inputs$ctl$SR_parms["SR_LN(R0)", "HI"] <- 15 # was 20
  # write ss_new files and expected values (but no bootstrap datasets)
  inputs$start$N_bootstraps <- 2

  # change bias adjustment ramp to have full bias adjustment starting in 1970
  inputs$ctl$first_yr_fullbias_adj <- 1970

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

  # run the model
  if (run_models) {
    r4ss::run(inputs$dir, extras = "-nohess", skipfinished = FALSE)
  }
} # end of step 1

if (2 %in% which_steps) {
  cli::cli_alert_info(
    "Step 2: Retune model with status-quo weighting (M-I method and lambda=0.5)"
  )
  # copy all files from 1.01_add_discards_to_landings to new directory
  dir1.01 <- here::here(
    "models",
    "supplemental_requests",
    "1.01_add_discards_to_landings"
  )
  dir1.02 <- here::here(
    "models",
    "supplemental_requests",
    "1.02_retune_lambda0.5_MI"
  )
  dir.create(dir1.02)
  files_to_copy <- list.files(dir1.01, full.names = TRUE, recursive = TRUE)
  file.copy(
    from = files_to_copy,
    to = dir1.02,
    recursive = TRUE
  )

  # tune model with M-I method and lambda=0.5
  tuning_results1.02 <- tune_comps(
    dir = dir1.02,
    option = "MI",
    init_run = FALSE,
    extras = "-nohess",
    verbose = TRUE,
    niters_tuning = 1
  )
} # end of step 2

if (3 %in% which_steps) {
  cli::cli_alert_info(
    "Step 3: Retune simplified model with Francis method and lambda=1"
  )

  # get output
  output1.02 <- r4ss::SS_output(
    dir1.02,
    printstats = FALSE,
    verbose = FALSE
  )

  # step 3: remove 0.5 likelihood weights and retune with Francis method
  inputs1.03 <- SS_read(dir1.02)
  inputs1.03$dir <- here::here(
    "models",
    "supplemental_requests",
    "1.03_retune_lambda1_Francis"
  )
  # change all lambdas to 1
  inputs1.03$ctl$lambdas$value <- 1
  # write files
  r4ss::SS_write(
    inputs1.03,
    dir = inputs1.03$dir,
    overwrite = TRUE,
    verbose = FALSE
  )
  # retune
  tuning_results2 <- tune_comps(
    dir = inputs1.03$dir,
    option = "Francis",
    init_run = TRUE,
    extras = "-nohess",
    verbose = TRUE,
    niters_tuning = 2
  )

  output1.03 <- r4ss::SS_output(
    inputs1.03$dir,
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

  # get output
  output1.01 <- r4ss::SS_output(
    dir1.01,
    printstats = FALSE,
    verbose = FALSE
  )

  simpler_summary <- SSsummarize(list(
    base_output,
    output_restructured,
    output_restructured_lambda1_Francis,
    output1.01,
    output1.02,
    output1.03
  ))

  SSplotComparisons(
    simpler_summary,
    legendlabels = c(
      "2025 base model",
      "discards from model output",
      "discards from model output, lambda=1 Francis",
      "external discard values",
      "external discard values, lambda=0.5 M-I",
      "external discard values, lambda=1 Francis"
    ),
    filenameprefix = "compare_simplified_models_",
    plotdir = inputs1.03$dir,
    plot = FALSE,
    print = TRUE
  )

  SStableComparisons(
    simpler_summary,
    names = c("NatM", "SSB_2025", "Bratio_2025", "ForeCatch_2027")
  )
} # end of step 3

if (4 %in% which_steps) {
  cli::cli_alert_info(
    "Step 4: Add fecundity relationship"
  )
  # step4: add fecundity relationship, starting from initial values in previous step
  inputs1.04 <- SS_read(
    inputs1.03$dir,
    ss_new = TRUE
  )
  inputs1.04$dir <- here::here(
    "models",
    "supplemental_requests",
    "1.04_add_fecundity"
  )
  # add fecundity relationship
  # change fecundity_at_length option:(1)eggs=Wt*(a+b*Wt);(2)eggs=a*L^b;(3)eggs=a*Wt^b; (4)eggs=a+b*L; (5)eggs=a+b*W
  inputs1.04$ctl$fecundity_option <- 2
  # update parameters
  inputs1.04$ctl$MG_parms["Eggs_alpha_Fem_GP_1", "INIT"] <- 7.218466e-08
  inputs1.04$ctl$MG_parms["Eggs_beta_Fem_GP_1", "INIT"] <- 4.043
  inputs1.04$ctl$MG_parms["Eggs_beta_Fem_GP_1", "HI"] <- 5

  # increase starting value for R0 (was causing crash penalty and warning at the start of estimation)
  inputs1.04$ctl$SR_parms["SR_LN(R0)", "INIT"] <- 11.5

  # write files
  r4ss::SS_write(
    inputs1.04,
    dir = inputs1.04$dir,
    overwrite = TRUE,
    verbose = FALSE
  )

  # run the model
  if (run_models) {
    r4ss::run(
      inputs1.04$dir,
      # extras = "-nohess",
      skipfinished = FALSE
    )
  }

  output1.04 <- r4ss::SS_output(
    # inputs$dir,
    here::here(
      "models",
      "supplemental_requests",
      "1.04_add_fecundity"
    ),
    printstats = FALSE,
    verbose = FALSE
  )

  SSplotComparisons(
    SSsummarize(list(
      base_output,
      output1.01,
      output1.02,
      output1.03,
      output1.04
    )),
    subplot = 1:15
  )

  SStableComparisons(
    SSsummarize(list(
      base_output,
      output1.01,
      output1.02,
      output1.03,
      output1.04
    )),
    names = c("NatM", "SSB_2025", "Bratio_2025", "ForeCatch_2027")
  )
}

if (5 %in% which_steps) {
  cli::cli_alert_info(
    "Step 5: update bias adjustment ramp and use initial values from previous step"
  )
  # read in files
  inputs1.05 <- r4ss::SS_read(
    inputs1.04$dir,
    ss_new = TRUE
  )
  inputs1.05$dir <- here::here(
    "models",
    "supplemental_requests",
    "1.05_refine_biasramp_and_tuning"
  )

  # copy all files from 1.04_add_fecundity to new directory so that report is available
  files_to_copy <- list.files(
    inputs1.04$dir,
    full.names = TRUE,
    recursive = TRUE
  )
  file.copy(
    from = files_to_copy,
    to = inputs1.05$dir,
    recursive = TRUE
  )

  biasRamp = SS_fitbiasramp(output1.04, plot = FALSE)

  # Input bias ramp parameters

  inputs1.05$ctl$last_early_yr_nobias_adj = biasRamp$df[1, 1]
  inputs1.05$ctl$first_yr_fullbias_adj = 1970 # biasRamp$df[2, 1] estimate was 1975 which is after some well-informed big year classes
  inputs1.05$ctl$last_yr_fullbias_adj = biasRamp$df[3, 1]
  inputs1.05$ctl$first_recent_yr_nobias_adj = biasRamp$df[4, 1]
  inputs1.05$ctl$max_bias_adj = biasRamp$df[5, 1]

  # change R0 to starter initial value and estimate in phase 1 to avoid crash penalty at start of estimation
  inputs1.05$ctl$SR_parms["SR_LN(R0)", "INIT"] <- 11.5 # was ~10.5
  inputs1.05$ctl$SR_parms["SR_LN(R0)", "PHASE"] <- 1 # was 2

  # write files
  r4ss::SS_write(
    inputs1.05,
    dir = inputs1.05$dir,
    overwrite = TRUE,
    verbose = FALSE
  )

  # update tuning
  tuning_results1.05 <- tune_comps(
    dir = inputs1.05$dir,
    option = "Francis",
    init_run = TRUE,
    extras = "-nohess",
    verbose = TRUE,
    niters_tuning = 3
  )

  output1.05 <- r4ss::SS_output(
    here::here(
      "models",
      "supplemental_requests",
      "1.05_refine_biasramp_and_tuning"
    ),
    printstats = FALSE,
    verbose = FALSE
  )
  SS_plots(output1.05)

  SSplotComparisons(
    SSsummarize(list(
      base_output,
      output1.01,
      output1.02,
      output1.03,
      output1.04,
      output1.05
    )),
    subplot = 1:15
  )

  SStableComparisons(
    SSsummarize(list(
      base_output,
      output1.01,
      output1.02,
      output1.03,
      output1.04,
      output1.05
    )),
    names = c("NatM", "SSB_2025", "Bratio_2025", "ForeCatch_2027")
  )
}

if (6 %in% which_steps) {
  # step 6: projection with relative F average over last 5 years
  cli::cli_alert_info(
    "Step 6: Update fecundity parameters again to widow-specific values"
  )

  inputs1.06 <- SS_read(
    file.path(
      "models",
      "supplemental_requests",
      "1.05_refine_biasramp_and_tuning"
    ),
    ss_new = FALSE
  )
  inputs1.06$dir <- here::here(
    "models",
    "supplemental_requests",
    "1.06_widow_fecundity"
  )
  # add fecundity relationship
  # update parameters using values from from
  # https://github.com/EJDick-NOAA/Rockfish-Fecundity
  inputs1.06$ctl$MG_parms["Eggs_alpha_Fem_GP_1", "INIT"] <- 1.10961e-08 # / 1e3 # convert from billions to trillions
  inputs1.06$ctl$MG_parms["Eggs_beta_Fem_GP_1", "INIT"] <- 4.545
  inputs1.06$ctl$MG_parms["Eggs_beta_Fem_GP_1", "HI"] <- 5

  # write files
  r4ss::SS_write(
    inputs1.06,
    dir = inputs1.06$dir,
    overwrite = TRUE,
    verbose = FALSE
  )

  # run the model
  if (run_models) {
    r4ss::run(
      inputs1.06$dir,
      # extras = "-nohess",
      skipfinished = FALSE
    )
  }
}

# copy final simplified model to 2025 base model directory and re-run
if (copy_to_base_dir) {
  r4ss::copy_SS_inputs(
    dir.old = here::here(
      "models",
      "supplemental_requests",
      "1.06_widow_fecundity"
    ),
    dir.new = here::here(
      "models",
      "2025 base model"
    ),
    overwrite = TRUE
  )
  r4ss::run(
    here::here(
      "models",
      "2025 base model"
    ),
    skipfinished = FALSE
  )
}

# if (6 %in% which_steps) {
#   # step 6: projection with relative F average over last 5 years
#   cli::cli_alert_info(
#     "Step 6: Projection with relative F average over last 5 years"
#   )
#   dir1.06 <- here::here(
#     "models",
#     "supplemental_requests",
#     "1.06_projection_relativeF_last5"
#   )
#   r4ss::copy_SS_inputs(
#     dir.old = here::here(
#       "models",
#       "supplemental_requests",
#       "1.05_refine_biasramp_and_tuning"
#     ),
#     dir.new = dir1.06,
#     overwrite = TRUE,
#     copy_par = TRUE
#   )
#   inputs1.06 <- SS_read(dir1.06)
#   # set benchmark years for relative F to last 5 years of data (2020-2024)
#   #_Bmark_years: beg_bio, end_bio, beg_selex, end_selex, beg_relF, end_relF, beg_recr_dist, end_recr_dist, beg_SRparm, end_SRparm (enter actual year, or values of 0 or -integer to be rel. endyr)
#   inputs1.06$fore$Bmark_years[5:6] <- c(2020, 2024)

#   # set average forecast recruitment to the full timeseries
#   inputs1.06$fore$Fcast_years <- inputs1.06$fore$Fcast_years |>
#     dplyr::rows_update(
#       data.frame(
#         MG_type = 12,
#         method = 1,
#         # st_year = inputs1.06$ctl$inputs1.06$ctl$MainRdevYrFirst, # 1970
#         st_year = inputs1.06$ctl$recdev_early_start, # 1900
#         end_year = 0
#       ),
#       by = "MG_type" # replace row that matches MG_type=12 (recruitment)
#     )
#   # change starter to run from the .par file
#   inputs1.06$start$init_values_src <- 1

#   # write files
#   r4ss::SS_write(
#     inputs1.06,
#     dir = inputs1.06$dir,
#     overwrite = TRUE,
#     verbose = FALSE
#   )
#   # run the model without estimation starting in phase 10
#   if (run_models) {
#     r4ss::run(
#       inputs1.06$dir,
#       extras = "-nohess -phase 10",
#       skipfinished = FALSE
#     )
#   }
# }
