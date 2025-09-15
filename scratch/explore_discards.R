# explore differences in discards from GEMM report and model inputs/outputs

require(ggplot2)
require(dplyr)

# pull new GEMM data from warehouse
if (FALSE) {
    # allow pull_gemm() to work on Ian's computer using stuff from the following:
    # https://github.com/pfmc-assessments/nwfscSurvey/issues/165
    # https://github.com/HenrikBengtsson/startup/blob/develop/R/is_radian.R
    if (nzchar(Sys.getenv("RADIAN_VERSION"))) {
        Sys.setlocale("LC_ALL", Sys.getenv("LANG"))
    }
    # run function to extract GEMM table
    gemm <- nwfscSurvey::pull_gemm(
        common_name = "Widow Rockfish",
        dir = "data_provided/wcgop"
    )
} else {
    # load previously extracted GEMM table (saved as variable "gemm")
    load("Data/Processed/gemm_Widow_Rockfish.rdata")
}

# summarize catch by sector across all years
gemm |>
    dplyr::group_by(sector) |>
    dplyr::summarize(
        catch = sum(total_landings_mt, na.rm = TRUE),
        discard = sum(total_discard_mt, na.rm = TRUE),
        dead_discard = sum(
            total_discard_with_mort_rates_applied_mt,
            na.rm = TRUE
        )
    ) |>
    dplyr::arrange(desc(catch)) |>
    print(n = 40)

# # A tibble: 31 × 4
#    sector                                 catch    discard dead_discard
#    <chr>                                  <dbl>      <dbl>        <dbl>
#  1 Midwater Rockfish EM            35841.        98.3         98.3
#  2 Midwater Rockfish               27019.        49.9         49.9
#  3 Midwater Hake                    4460.        36.1         36.1
#  4 Midwater Hake EM                 2136.         7.66         7.66
#  5 At-Sea Hake CP                   1112.       511.         511.
#  6 Shoreside Hake                    763.         0            0
#  7 CS - Bottom Trawl                 577.         3.76         3.76
#  8 At-Sea Hake MSCV                  438.       551.         551.
#  9 Tribal Shoreside                  372.         0            0
# 10 California Recreational           142.         0.675        0.504
# 11 Limited Entry Trawl                48.2       66.2         66.2
# 12 Oregon Recreational                46.9        0.777        0.577
# 13 CS EM - Bottom Trawl               41.8        0.0317       0.0317
# 14 Tribal At-Sea Hake                 34.4        0.997        0.997
# 15 OA Fixed Gear - Hook & Line        25.4        1.03         1.03
# 16 CS - Bottom and Midwater Trawl     14.4        0.0828       0.0828
# 17 Incidental                         10.1        0            0
# 18 LE Fixed Gear DTL - Hook & Line     6.57       0            0
# 19 Nearshore                           6.00       1.93         1.45
# 20 LE CA Halibut                       2.30       0            0
# 21 LE Sablefish - Hook & Line          1.39       1.32         1.32
# 22 CS - Hook & Line                    0.224      0.00590      0.00590
# 23 Pink Shrimp                         0.176      0.552        0.552
# 24 Directed P Halibut                  0.0758     0.0215       0.0215
# 25 OA Fixed Gear - Pot                 0.0740     0            0
# 26 Combined LE & OA CA Halibut         0.0372     0            0
# 27 LE Sablefish - Pot                  0.0340     0.00466      0.00466
# 28 LE Fixed Gear DTL - Pot             0.00726    0            0
# 29 CS - Pot                            0.00181    0.000688     0.000688
# 30 CS EM - Pot                         0.000907   0            0
# 31 Research                            0          0            0

# top sectors for dead discards
gemm |>
    dplyr::group_by(sector) |>
    dplyr::summarize(
        catch = sum(total_landings_mt, na.rm = TRUE),
        discard = sum(total_discard_mt, na.rm = TRUE),
        dead_discard = sum(
            total_discard_with_mort_rates_applied_mt,
            na.rm = TRUE
        )
    ) |>
    dplyr::arrange(desc(dead_discard)) |>
    print(n = 10)

# # A tibble: 31 × 4
#    sector                        catch discard dead_discard
#    <chr>                         <dbl>   <dbl>        <dbl>
#  1 At-Sea Hake MSCV             438.    551.         551.
#  2 At-Sea Hake CP              1112.    511.         511.
#  3 Midwater Rockfish EM       35841.     98.3         98.3
#  4 Limited Entry Trawl           48.2    66.2         66.2
#  5 Midwater Rockfish          27019.     49.9         49.9
#  6 Midwater Hake               4460.     36.1         36.1
#  7 Midwater Hake EM            2136.      7.66         7.66
#  8 CS - Bottom Trawl            577.      3.76         3.76
#  9 Nearshore                      6.00    1.93         1.45
# 10 LE Sablefish - Hook & Line     1.39    1.32         1.32

# group by fleet
gemm2 <- gemm |>
    dplyr::mutate(
        fleet = dplyr::case_when(
            grepl("Hake", sector) ~ "Hake",
            grepl("Midwater Rockfish", sector) ~ "MidwaterTrawl",
            grepl("Trawl", sector) ~ "BottomTrawl",
            TRUE ~ "Other" # includes other small fleets
        )
    )

# confirm that other is tiny
gemm2 |>
    dplyr::group_by(fleet) |>
    dplyr::summarize(
        dead_discard = sum(
            total_discard_with_mort_rates_applied_mt,
            na.rm = TRUE
        )
    ) |>
    dplyr::arrange(desc(dead_discard))
# # A tibble: 4 × 2
#   fleet         dead_discard
#   <chr>                <dbl>
# 1 Hake               1107.
# 2 MidwaterTrawl       148.
# 3 BottomTrawl          70.1
# 4 Other                 5.46

# combine Other with BottomTrawl and
# filter out hake fleets because the shoreside hake has zero discards
# and at-sea hake is already accounted for in the model input catch
gemm2 <- gemm |>
    dplyr::mutate(
        fleet = dplyr::case_when(
            grepl("Hake", sector) ~ "Hake",
            grepl("Midwater Rockfish", sector) ~ "MidwaterTrawl",
            TRUE ~ "BottomTrawl" # includes other small fleets
        )
    ) |>
    dplyr::filter(fleet != "Hake")


# barplot of discards for all sectors
gemm2 |>
    group_by(sector, year) |>
    ggplot() +
    geom_col(aes(x = year, y = total_discard_mt, fill = sector))

# barplot of discards by fleets in the model
gemm2 |>
    group_by(fleet, year) |>
    ggplot() +
    geom_col(aes(x = year, y = total_discard_mt, fill = fleet))

# table by modeled fleet / year
gemm_discards <- gemm2 |>
    dplyr::group_by(year, fleet) |>
    dplyr::summarize(catch = sum(total_discard_with_mort_rates_applied_mt))
saveRDS(
    dead_discards,
    file = "data_derived/discards/gemm_discards_by_fleet.rds"
)


# model estimates of discards
base_outputs <- r4ss::SS_output(
    here::here(
        "models",
        "supplemental_requests",
        "Aug2025_base_model_cleaned_ss_new_remove_HnL_retention"
    ),
    printstats = FALSE,
    verbose = FALSE
)

model_discards <- base_outputs$catch |>
    dplyr::mutate(discard_bio = dead_bio - ret_bio) |>
    dplyr::filter(
        Fleet_Name %in% c("BottomTrawl", "MidwaterTrawl", "HnL")
    ) |>
    dplyr::mutate(
        fleet = dplyr::case_when(
            Fleet_Name %in% c("BottomTrawl", "HnL") ~ "BottomTrawl",
            Fleet_Name %in% c("MidwaterTrawl") ~ "MidwaterTrawl"
        ),
        year = Yr
    ) |>
    group_by(year, fleet) |>
    summarize(catch = sum(discard_bio, na.rm = TRUE))

# discard inputs to model
input_discards <- base_outputs$discard |>
    dplyr::mutate(catch = Obs) |>
    dplyr::mutate(
        fleet = dplyr::case_when(
            Fleet_Name %in% c("BottomTrawl", "HnL") ~ "BottomTrawl",
            Fleet_Name %in% c("MidwaterTrawl") ~ "MidwaterTrawl"
        ),
        year = Yr
    ) |>
    group_by(year, fleet) |>
    summarize(catch = sum(discard_bio, na.rm = TRUE))

model_discards$source <- "model estimate"
gemm_discards$source <- "GEMM report"
input_discards$source <- "model input"

# combine model and gemm discards
all_discards <- rbind(model_discards, gemm_discards, input_discards)

# plot comparison of discards from each source for the years 2002 onward

# Ensure all combinations of year, fleet, and source are present, filling missing catch with NA
all_discards_complete <- all_discards |>
    dplyr::filter(year >= 2002) |>
    dplyr::ungroup() |>
    tidyr::complete(year, fleet, source) |>
    dplyr::mutate(
        fleet = ifelse(fleet == "BottomTrawl", "BottomTrawl + others", fleet)
    )

ggplot(all_discards_complete) +
    geom_col(aes(x = year, y = catch, fill = source), position = "dodge", width = 0.7, na.rm = TRUE) +
    facet_wrap(~fleet, ncol = 1, scales = "fixed") +
    theme_minimal() +
    ylab("discards (t)")

ggsave(
    "figures/supplemental_requests/discard_comparison_by_source.png",
    width = 6, height = 6,
    bg = "white"
)
