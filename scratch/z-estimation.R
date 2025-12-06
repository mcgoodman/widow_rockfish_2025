# code below adapted from Jason Cope's work on Rougheye/Blackspotted Rockfish
# https://github.com/shcaba/REBS-2025/blob/main/docs/Pre_assessment/plots/LH_plots.R

library("dplyr")
library("pacfintools")
library("here")

### get age data
# pacfin data cleaning copied from R\data_commerical_comps.R

# Author: Mico Kineen

library("dplyr")
library("pacfintools")
library("here")

# Setup ---------------------------------------------------

## Read data ----------------------------------------------

## PacFin data for widow 2025
load(here("data_provided", "PacFIN", "PacFIN.WDOW.bds.25.Mar.2025.RData")) #BDS
load(here("data_provided", "PacFIN", "PacFIN.WDOW.CompFT.25.Mar.2025.RData")) #Catch

## Settings -----------------------------------------------

### Filtering variables -----------------------------------

# Variables are based on the filters used in the 2015 assessment, (2019 unavilable)
# docmented in the widoww code archive and can be found in the script "CommComps.R
common_name <- "WIDOW ROCKFISH" # Species common name based on NWFSC survey data
species_code <- "WDOW" # PacFIN species code
used_gears <- c("TWL", "NET", "MSC", "POT", "HKL")
good_lengths <- c("F", "T", "U")
good_methods <- c("R")
good_samples <- c("C", "M", "NA")
good_states <- c("WA", "OR", "CA")
good_age_method <- c("BB", "B", "U", "NA")

### Get fish ticket numbers of shoreside hake samples (used to split ss hake from midwater fleet)
shore_hke_dahl_codes <- c("03", "17")
shore_hke_ftid <- catch.pacfin |>
    filter(DAHL_GROUNDFISH_CODE %in% shore_hke_dahl_codes) |>
    pull(FTID)

# Bins for biological data
length_bins <- seq(8, 56, by = 2) #widow_2019_data$lbin_vector
age_bins <- seq(0, 40, by = 1) #widow_2019_data$agebin_vector

### Survey weight-length ----------------------------------

weight_length_estimates <- nwfscSurvey::estimate_weight_length(
    bds_survey <- nwfscSurvey::pull_bio(
        common_name = "widow rockfish",
        survey = "NWFSC.Combo"
    ),
    verbose = FALSE
)

weight_length_estimates <- nwfscSurvey::estimate_weight_length(
    data = bds_survey,
    verbose = TRUE
)
### Gear groups -------------------------------------------

#List of gear groupings as per Hicks 2015 , appended fleets are commented
gear_mapping_2024 <- list(
    ShrimpTrawl = c("SST", "SHT", "PWT", "DST"),
    BottomTrawl = c("RLT", "GFT", "GFS", "GFL", "FTS", "FFT", "BTT"), #added BTT
    MidwaterTrawl = c("OTW", "MDT", "MPT", "TWL"), #added TWL
    MiscTrawl = c("PRT", "DNT", "BMT"),
    Pot = c("BTR", "CLP", "CPT", "FPT", "OPT", "PRW"),
    HnL = c("JIG", "LGL", "OHL", "POL", "TRL", "VHL", "HKL"),
    Net = c("DPN", "DGN", "GLN", "ONT", "SEN", "STN"),
    Other = c("DVG", "USP")
)

### Create gear groups based on PACFIN gear code, and associate with an agency sample number.

# The reason for doing this is that PACFIN_GEAR_CODE is dropped during cleaning, as fleets
# are aggregated to PACFIN_GEAR_GROUP level. This combines all midwater and bottom trawl fleets into
# 'TWL' grouping, which makes splitting them more difficult

gear_groups_2024 <- bds.pacfin %>%
    dplyr::mutate(
        gear_group = case_when(
            PACFIN_GEAR_CODE %in%
                gear_mapping_2024[["ShrimpTrawl"]] ~ "ShrimpTrawl",
            PACFIN_GEAR_CODE %in%
                gear_mapping_2024[["BottomTrawl"]] ~ "BottomTrawl",
            PACFIN_GEAR_CODE %in%
                gear_mapping_2024[["MidwaterTrawl"]] &
                !FTID %in% shore_hke_ftid ~ "MidwaterTrawl",
            PACFIN_GEAR_CODE %in%
                gear_mapping_2024[["MidwaterTrawl"]] &
                FTID %in% shore_hke_ftid ~ "Hake",
            PACFIN_GEAR_CODE %in% gear_mapping_2024[["Pot"]] ~ "Pot",
            PACFIN_GEAR_CODE %in% gear_mapping_2024[["HnL"]] ~ "HnL",
            PACFIN_GEAR_CODE %in% gear_mapping_2024[["Net"]] ~ "Net",
            PACFIN_GEAR_CODE %in%
                gear_mapping_2024[["MiscTrawl"]] ~ "MiscTrawl",
            PACFIN_GEAR_CODE %in% gear_mapping_2024[["Other"]] ~ "Other"
        )
    ) |>
    distinct(AGENCY_SAMPLE_NUMBER, gear_group, SAMPLE_YEAR)

## Clean data ---------------------------------------------

bds_cleaned <- cleanPacFIN(
    Pdata = bds.pacfin, #|> filter(SAMPLE_YEAR >= 2005), #Only do post 2005 data
    keep_gears = used_gears,
    CLEAN = TRUE,
    keep_age_method = good_age_method,
    keep_sample_type = good_samples,
    keep_sample_method = good_methods,
    keep_length_type = good_lengths,
    keep_states = good_states,
    spp = "widow rockfish"
) |>
    left_join(gear_groups_2024, by = "AGENCY_SAMPLE_NUMBER") |> ##a ppend the gear_groups
    dplyr::mutate(
        stratification = paste(state, gear_group, sep = ".") # Stratification is a combination of gear and state (matches catch data formatting)
    ) |>
    dplyr::filter(!PACFIN_GEAR_NAME %in% c("XXX", "OTH-KNOWN", "DNSH SEINE")) #drop gears in NA and Misc catgories (not used in assessment)

ages <- bds_cleaned |>
    dplyr::filter(!is.na(Age)) |>
    dplyr::select(Age, SEX, year) |>
    dplyr::rename(Sex = SEX, Year = year) |>
    dplyr::mutate(source = "PacFIN") |>
    as_tibble()
# add WCGBTS ages
survey_ages <- bds_survey |>
    dplyr::filter(!is.na(Age)) |>
    dplyr::select(Age, Sex, Year) |>
    dplyr::mutate(source = "WCGBTS")

ages <- rbind(ages, survey_ages)


table(ages$Sex)
#     F     M     U
# 77678 69083   285
ages <- ages |> dplyr::filter(Sex != "U")

# histograms of the age data grouped by source and sex
ages |>
    dplyr::filter(Age > 30, Age <= 60) |>
    dplyr::mutate(Sex = dplyr::recode(Sex, F = "Female", M = "Male")) |>
    ggplot2::ggplot(ggplot2::aes(x = Age)) +
    ggplot2::geom_histogram(binwidth = 1) +
    ggplot2::facet_wrap(~ source + Sex, scales = "free_y") +
    ggplot2::labs(
        title = "Ages 30+ by Source and Sex",
        x = "Age",
        y = "Count"
    )
ggsave(
    filename = here(
        "figures",
        "supplemental_requests",
        "age_frequencies_30plus.png"
    ),
    width = 6.5,
    height = 4
)

# histograms of the age data grouped by source and sex
ages |>
    dplyr::filter(Age <= 60) |>
    dplyr::mutate(Sex = dplyr::recode(Sex, F = "Female", M = "Male")) |>
    ggplot2::ggplot(ggplot2::aes(x = Age)) +
    ggplot2::geom_histogram(binwidth = 1) +
    ggplot2::facet_wrap(~ source + Sex, scales = "free_y") +
    ggplot2::labs(
        title = "Ages by Source and Sex",
        x = "Age",
        y = "Count"
    )
ggsave(
    filename = here("figures", "supplemental_requests", "age_frequencies.png"),
    width = 6.5,
    height = 4
)


range(ages$Age)
# [1]  1 80
hist(ages$Age, breaks = 0:80)

z_estimation_plot <- function(
    ages,
    age.peak = 6,
    age.cut = 70,
    minyr = -Inf,
    maxyr = Inf,
    filename = NULL
) {
    # Recode Sex values
    ages <- ages |>
        dplyr::mutate(Sex = dplyr::recode(Sex, F = "Female", M = "Male"))

    #Filter by year if desired
    ninput <- nrow(ages)
    ages <- ages |>
        filter(Year >= minyr & Year <= maxyr)
    nfiltered <- nrow(ages)
    cli::cli_alert_info(
        "Retaining {nfiltered} of {ninput} ages"
    )

    age_comps_agg <- reshape2::melt(table(ages$Age, ages$Sex))
    colnames(age_comps_agg) <- c("Ages", "Sex", "Freq")
    age_comps_agg <- age_comps_agg[age_comps_agg$Freq > 0, ]
    age_comps_agg <- age_comps_agg[age_comps_agg$Sex != "U", ]
    age_comps_agg.df <- data.frame(
        age_comps_agg,
        Freq_ln = log(age_comps_agg$Freq)
    )
    age_comps_agg_peak <- age_comps_agg[
        age_comps_agg$Age > age.peak & age_comps_agg$Age <= age.cut,
    ]
    age_comps_agg_peak.df <- data.frame(
        age_comps_agg_peak,
        Freq_ln = log(age_comps_agg_peak$Freq)
    )

    #Report Z value
    age_comps_agg.df.F <- subset(age_comps_agg_peak.df, Sex == "Female")
    cc_lm.F <- lm(age_comps_agg.df.F$Freq_ln ~ age_comps_agg.df.F$Age)
    cc_lm.F$coefficients[2]

    age_comps_agg.df.M <- subset(age_comps_agg_peak.df, Sex == "Male")
    cc_lm.M <- lm(age_comps_agg.df.M$Freq_ln ~ age_comps_agg.df.M$Age)
    cc_lm.M$coefficients[2]

    #Make Z plot
    ggplot(age_comps_agg.df, aes(Ages, Freq_ln)) +
        geom_point() +
        ylab("Log frequency") +
        geom_point(
            data = age_comps_agg_peak.df,
            aes(Ages, Freq_ln),
            color = "red"
        ) +
        geom_smooth(method = "lm", data = age_comps_agg_peak.df) +
        facet_wrap(vars(Sex)) +
        geom_text(
            data = data.frame(
                Sex = c("Female", "Male"),
                Ages = c(
                    max(ages$Age, na.rm = TRUE),
                    max(ages$Age, na.rm = TRUE)
                ),
                Freq_ln = c(
                    max(age_comps_agg.df.F$Freq_ln, na.rm = TRUE),
                    max(age_comps_agg.df.M$Freq_ln, na.rm = TRUE)
                ),
                label = c(
                    paste0("Z = ", -round(cc_lm.F$coefficients[2], 3)),
                    paste0("Z = ", -round(cc_lm.M$coefficients[2], 3))
                )
            ),
            aes(x = Ages, y = Freq_ln, label = label),
            hjust = 1,
            vjust = 1,
            color = "black",
            size = 3,
            inherit.aes = FALSE
        )

    if (!is.null(filename)) {
        ggsave(
            filename = filename,
            width = 6.5,
            height = 3.5
        )
    }
}

ages |>
    z_estimation_plot(
        filename = here(
            "figures",
            "supplemental_requests",
            "z_estimation_all_years_all_ages.png"
        )
    )

ages |>
    dplyr::filter(source == "WCGBTS") |>
    z_estimation_plot(
        filename = here(
            "figures",
            "supplemental_requests",
            "z_estimation_2003-2024_WCGBTS.png"
        )
    )

ages |>
    dplyr::filter(source == "PacFIN") |>
    z_estimation_plot(
        minyr = 2003,
        filename = here(
            "figures",
            "supplemental_requests",
            "z_estimation_2003-2024_PacFIN.png"
        )
    )

ages |>
    dplyr::filter(source == "PacFIN") |>
    z_estimation_plot(
        maxyr = 1990,
        filename = here(
            "figures",
            "supplemental_requests",
            "z_estimation_1978-1990_PacFIN.png"
        )
    )


ages |>
    dplyr::filter(source == "PacFIN") |>
    z_estimation_plot(
        minyr = 1991,
        maxyr = 2000,
        filename = here(
            "figures",
            "supplemental_requests",
            "z_estimation_1991-2000_PacFIN.png"
        )
    )
