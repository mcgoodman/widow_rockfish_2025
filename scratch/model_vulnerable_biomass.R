# Script: Visualize vulnerable biomass, spawning output, and survey vulnerable biomass
# Purpose: Build a combined time series, add selectivity block markers, and plot
# Outputs: PNGs to figures/supplemental_requests and ggplot objects returned
# Notes: Requires r4ss outputs already read (or will read if missing)
## vulnerable biomass (based on comments from Andre)
library(dplyr)
library(tidyr)

# read input and output if not already in workspace
if (!exists("output")) {
    output <- r4ss::SS_output(
        'models/2025 base model',
        verbose = FALSE,
        printstats = FALSE
    )
    inputs <- r4ss::SS_read('models/2025 base model')
}
vb <- output$catch |>
    select(Fleet_Name, Yr, vuln_bio) |>
    rename(fleet = Fleet_Name, year = Yr, value = vuln_bio) |>
    arrange(fleet, year) |>
    mutate(type = "vuln_bio") |>
    filter(year >= output$startyr) # exclude unfished equilibrium with no vuln_bio output
head(vb)
#         fleet year  value
# 1 BottomTrawl 1916 131497
# 2 BottomTrawl 1917 131373
# 3 BottomTrawl 1918 131224
# 4 BottomTrawl 1919 131093
# 5 BottomTrawl 1920 130986
# 6 BottomTrawl 1921 130888

# Get values from timeseries table (age 4+ biomass and spawning biomass)
ts_values <- output$timeseries |>
    select(Yr, Bio_all, SpawnBio) |>
    pivot_longer(
        cols = c("Bio_all", "SpawnBio"),
        names_to = "fleet",
        values_to = "value"
    ) |>
    mutate(
        fleet = case_when(
            fleet == "Bio_all" ~ "Age 4+ biomass",
            fleet == "SpawnBio" ~ "Spawning output"
        )
    ) |>
    rename(year = Yr) |>
    arrange(fleet, year) |>
    select(fleet, year, value) |>
    mutate(type = "timeseries")

# get survey vulnerable biomass
survey_bio <- output$cpue |>
    filter(grepl("WCGBTS", Fleet_name)) |>
    rename(fleet = Fleet_name, year = Yr, value = Vuln_bio) |>
    select(fleet, year, value) |>
    mutate(type = "survey")

# combine info from different tables
vb <- rbind(
    vb,
    ts_values,
    survey_bio
)

# filter empty fleets for widow
vb <- vb |>
    filter(!grepl("ignore", fleet))


#' Compute vulnerable biomass for a fleet/year/sex
#'
#' @param model r4ss output list
#' @param fleet Fleet name or number
#' @param selyear Selectivity year to use (for time-varying selectivity)
#' @param year Year for numbers-at-length
#' @param sex Sex code (1 female, 2 male)
#' @return Vulnerable biomass in model units
get_vb <- function(
    model,
    fleet = 1,
    selyear = model$endyr,
    year = model$endyr,
    sex = 1
) {
    # convert fleet name to number if needed
    if (!is.numeric(fleet)) {
        fleet <- which(model$FleetNames == fleet)
    }
    # get selectivity at length for that fleet and selectivity year
    sel <- model$sizeselex |>
        filter(Factor == "Lsel", Fleet == fleet & Yr == selyear & Sex == sex) |>
        select(-Factor, -Fleet, -Yr, -Sex, -Label) |>
        as.numeric() # convert to vector

    # get numbers at length for that year and sex
    n_at_len <- model$natlen |>
        filter(Sex == sex, Yr == year, `Beg/Mid` == "M") |>
        select(-(1:12)) |>
        as.numeric() # convert to vector

    wt_at_len <- if (sex == 1) {
        model$biology$Wt_F
    } else {
        model$biology$Wt_M
    }
    sum(sel * n_at_len * wt_at_len)
}

# apply the get_vb function to get vulnerable biomass for the WCGBTS fleet
vb_wcgbts_2024 <- get_vb(
    model = output,
    fleet = "WCGBTS",
    selyear = 2024,
    year = 2024
)
get_vb(model = output, fleet = "WCGBTS", selyear = 2024, year = 2024, sex = 1) +
    get_vb(
        model = output,
        fleet = "WCGBTS",
        selyear = 2024,
        year = 2024,
        sex = 2
    )

# extended time series from last selectivity block onwards for fishing fleets
vb2 <- expand.grid(
    fleet = output$FleetNames[1:3],
    year = 2020:2036,
    value = NA,
    type = "projected"
)
for (irow in 1:nrow(vb2)) {
    vb2$value[irow] <- get_vb(
        model = output,
        fleet = vb2$fleet[irow],
        selyear = 2024,
        year = vb2$year[irow],
        sex = 1
    ) +
        get_vb(
            model = output,
            fleet = vb2$fleet[irow],
            selyear = 2024,
            year = vb2$year[irow],
            sex = 2
        )
}

#' Get selectivity block boundaries for a fleet
#'
#' @param fleet Fleet name
#' @return A list of block designs used for size selectivity
get_sel_blocks <- function(fleet = "MidwaterTrawl") {
    sel_block <- inputs$ctl$size_selex_parms[
        grepl(
            pattern = paste0("SizeSel_.*_", fleet),
            rownames(inputs$ctl$size_selex_parms)
        ),
        "Block"
    ] |>
        unique()
    sel_block <- sel_block[sel_block > 0] # remove 0 (no block)
    inputs$ctl$Block_Design[sel_block]
}
get_sel_blocks("MidwaterTrawl")
# [[1]]
# [1] 1916 1982 1983 2001 2002 2016

get_sel_blocks("BottomTrawl")
# [[1]]
# [1] 1916 2001

get_sel_blocks("Hake")
# [[1]]
# [1] 1916 2019

# create data frame of selectivity block midpoints for fishing fleets
blocks <- tibble::tribble(
    ~fleet          , ~year  , ~value , ~type   ,
    "MidwaterTrawl" , 1982.5 , NA     , "block" ,
    "MidwaterTrawl" , 2001.5 , NA     , "block" ,
    "MidwaterTrawl" , 2016.5 , NA     , "block" ,
    "BottomTrawl"   , 2001.5 , NA     , "block" ,
    "Hake"          , 2019.5 , NA     , "block"
)

# Fill NA values in blocks with mean of adjacent years (interpolated plotting anchor)
for (i in 1:nrow(blocks)) {
    fleet <- blocks$fleet[i]
    year <- blocks$year[i]
    adjacent_years <- c(floor(year), ceiling(year))
    values <- vb |>
        filter(fleet == !!fleet & year %in% adjacent_years) |>
        pull(value)
    if (length(values) == 2) {
        blocks$value[i] <- mean(values)
    }
}

# add blocks to main dataframe
vb <- rbind(
    vb,
    vb2,
    blocks
)

vb <- vb |>
    mutate(
        units = case_when(
            fleet == "Spawning output" ~ "billions of eggs",
            TRUE ~ "thousands of tons"
        )
    )


## make a ggplot time series plot of vulnerable biomass
# with separate lines for each fleet and selectivity block markers
library(ggplot2)
#' Plot vulnerable biomass, spawning output, and survey vulnerable biomass
#'
#' @param vb_data Data frame containing fleet, year, value, type, units
#' @param minyr Minimum year to show
#' @param maxyr Maximum year to show
#' @param rescale Logical: plot relative to 1916 (excludes WCGBTS)
#' @param dir Directory for output PNG (NULL to suppress saving)
#' @return A ggplot object
plot_vb <- function(
    vb_data = vb,
    minyr = 1916,
    maxyr = 2036,
    rescale = FALSE,
    dir = "figures/supplemental_requests"
) {
    # rescale if requested
    if (rescale) {
        vb_data <- vb_data |> filter(fleet != "WCGBTS") # no WCGBTS in 1916
        vb_data <- vb_data |>
            group_by(fleet) |>
            mutate(value = value / value[year == 1916]) |>
            ungroup()
    } else {
        # separate scaling for different units
        vb_data <- vb_data |>
            mutate(
                value = if_else(
                    units == "billions of eggs",
                    value / 1e3, # convert to thousands of billions
                    value / 1e3 # convert to thousands of tons
                )
            )
    }

    # calculate scaling factor for secondary axis
    # based on the ratio of max values for each unit type
    if (!rescale) {
        scaling_factor <- 10 # fixed ratio to align egg units on secondary axis

        # scale spawning output to match primary axis range
        vb_data <- vb_data |>
            mutate(
                value_scaled = if_else(
                    units == "billions of eggs",
                    value * scaling_factor,
                    value
                )
            )
    } else {
        vb_data <- vb_data |> mutate(value_scaled = value)
        scaling_factor <- 1
    }

    # reorder fleet factor for legend
    fleet_order <- c(
        "MidwaterTrawl",
        "BottomTrawl",
        "Hake",
        "WCGBTS",
        "Age 4+ biomass",
        "Spawning output"
    )
    vb_data <- vb_data |>
        mutate(fleet = factor(fleet, levels = fleet_order))

    # make plot
    p <- vb_data |>
        filter(year >= minyr & year <= maxyr) |> # filter out years before minyr
        ggplot(aes(x = year, y = value_scaled, color = fleet)) +
        annotate(
            "rect",
            xmin = 2025, # shade projection period
            xmax = maxyr + 0.5,
            ymin = -Inf,
            ymax = Inf,
            fill = "gray",
            alpha = 0.3
        ) +
        geom_line(
            data = ~ . |> filter(type != "block"),
            linewidth = 1.2,
            alpha = 0.7
        ) +
        geom_point(data = ~ . |> filter(type == "block"), size = 3) + # block midpoints
        labs(
            title = "Vulnerable biomass by fleet",
            subtitle = "(points indicate selectivity blocks for fishing fleets)",
            x = "Year",
            y = if (rescale) {
                "Vulnerable biomass (relative to unfished)"
            } else {
                "Vulnerable biomass (thousands of tons)"
            },
            color = ""
        ) +
        scale_x_continuous(breaks = seq(1920, 2035, by = 5), expand = 0) +
        scale_y_continuous(
            limits = c(0, NA),
            expand = expansion(mult = c(0, .1)),
            sec.axis = if (!rescale) {
                sec_axis(
                    ~ . / scaling_factor,
                    name = "Spawning output (trillions of eggs)"
                )
            } else {
                waiver()
            }
        ) +
        geom_hline(
            yintercept = if (rescale) c(0, 1.0) else 0,
            color = "black",
            linewidth = 0.5
        ) +
        theme_minimal() +
        theme(legend.position = "top")

    if (!is.null(dir)) {
        ggsave(
            plot = p,
            filename = file.path(
                dir,
                paste0(
                    "vulnerable_biomass_",
                    minyr,
                    "_",
                    ifelse(rescale, "relative", "absolute"),
                    ".png"
                )
            ),
            width = 7,
            height = 6,
            units = "in",
            dpi = 300
        )
    }
    return(p)
}

plot_vb(minyr = 1975)
plot_vb(rescale = TRUE, minyr = 1975)
