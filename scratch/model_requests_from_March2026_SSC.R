# update PEPtools package after change on 5 March 2026
# which added output of the sigma values used in the buffer calculations
if (FALSE) {
    remotes::install_github("pfmc-assessments/PEPtools")
}

require(PEPtools)
require(r4ss)
require(dplyr)
require(gt)
require(here)

prob_table <- function(model, format = TRUE) {
    # create table of sigma values for each year, using PEPtools get_buffer function
    years <- 2025:2036
    sigma_table <- PEPtools::get_buffer(
        years = years,
        sigma = 0.5,
        pstar = 0.45
    )

    # table with catch data from the model output
    catch_table <- r4ss::SS_decision_table_stuff(model) |>
        dplyr::rename(year = yr) |>
        dplyr::select(year, catch, dep)

    # combine sigma table and catch table into one table
    sigma_and_catch_table <- dplyr::left_join(
        sigma_table,
        catch_table,
        by = "year"
    ) # add catch to table

    # add columns to table for fraction unfished and probability of being below 25%
    # using model output of Bratio and assuming a lognormal distribution
    table <- sigma_and_catch_table |>
        dplyr::select(-hash, -buffer, -dep) |> # remove unnecessary columns
        dplyr::mutate(
            frac_unfished = model$derived_quants |>
                dplyr::filter(Label %in% paste0("Bratio_", years)) |>
                dplyr::pull(Value) |>
                round(3),
            # probability of being below 40%
            prob_below_B40 = plnorm(
                q = 0.40,
                meanlog = log(frac_unfished),
                sdlog = sigma
            ) |>
                round(3),
            # probability of being below 25%
            prob_below_B25 = plnorm(
                q = 0.25,
                meanlog = log(frac_unfished),
                sdlog = sigma
            ) |>
                round(3)
        ) |>
        # reorder columns
        dplyr::select(
            year,
            catch,
            frac_unfished,
            sigma,
            prob_below_B40,
            prob_below_B25
        ) |>
        # use prettier column names
        dplyr::rename(
            Year = year,
            Catch = catch,
            `Fraction Unfished` = frac_unfished,
            Sigma = sigma,
            `Prob. < B40%` = prob_below_B40,
            `Prob. < B25%` = prob_below_B25
        )

    # format table as HTML using the gt package
    # (could paste into Excel instead)
    if (format) {
        table |>
            gt::gt() |>
            gt::cols_width(
                gt::everything() ~ gt::px(80),
            )
    } else {
        return(table)
    }
}

# get output from the base model (initial example used to create table)
alt1_base <- r4ss::SS_output(here::here("models", "2025 base model"))
alt1_low <- r4ss::SS_output(
    here::here("data_derived/decision_table/45_low"),
    printstats = FALSE,
    verbose = FALSE
)

#mydir <- "G:/My Drive/SS/widow/widow2025/supplemental_review/SSC January 2026 review/March 2026 Widow Alternatives"
mydir <- "models/extra_projections/March 2026 Widow Alternatives"
model_names <- c(
    "Alt_1",
    "Alt_1_45_low",
    "Alt_2a",
    "Alt_2a_45_low",
    "Alt_2b",
    "Alt_2b_45_low",
    "Alt_3_v2",
    "Alt_3_45_low_v2"
)
clean_names <- model_names |>
    gsub(pattern = "_45_low", replacement = " (low)") |>
    gsub(pattern = "_v2", replacement = "") |>
    gsub(pattern = "_", replacement = " ")

models <- r4ss::SSgetoutput(
    dirvec = file.path(mydir, model_names),
    modelnames = clean_names,
    SpawnOutputLabel = "Spawning output (billions of eggs)"
)

models[["Alt 1"]] |> prob_table()
models[["Alt 1 (low)"]] |> prob_table()
models[["Alt 2a"]] |> prob_table()
models[["Alt 2a (low)"]] |> prob_table()
models[["Alt 2b"]] |> prob_table()
models[["Alt 2b (low)"]] |> prob_table()
models[["Alt 3"]] |> prob_table()
models[["Alt 3 (low)"]] |> prob_table()

# read additional models with default HCR for 2029-2036
mydir <- "models/extra_projections/March 2026 Widow Alternatives"
model_names2 <- c(
    "Alt_1_time_varying_catch",
    "Alt_2a_time_varying_catch",
    "Alt_2b_time_varying_catch",
    "Alt_3_time_varying_catch"
)
clean_names2 <- model_names2 |>
    gsub(pattern = "_", replacement = " ")

models2 <- r4ss::SSgetoutput(
    dirvec = file.path(mydir, model_names2),
    modelnames = clean_names2,
    SpawnOutputLabel = "Spawning output (billions of eggs)"
)

tab2 <- r4ss::SStableComparisons(
    r4ss::SSsummarize(models2),
    likenames = NULL,
    names = paste0("ForeCatch_", 2025:2036)
) |>
    dplyr::mutate(
        Label = as.integer(gsub("ForeCatch_", "", Label))
    ) |>
    dplyr::rename(Year = Label) |>
    round()
tab2 |> gt::gt()

tab3 <- r4ss::SStableComparisons(
    r4ss::SSsummarize(models2),
    likenames = NULL,
    names = paste0("Bratio_", 2025:2036)
) |>
    dplyr::mutate(
        Label = as.integer(gsub("Bratio_", "", Label))
    ) |>
    dplyr::rename(Year = Label) |>
    round(3)
tab3 |> gt::gt()

# make a list of all the tables
tabs <- lapply(models, prob_table, format = FALSE)
# convert to a single dataframe
tabs_long <- dplyr::bind_rows(tabs, .id = "model") |>
    dplyr::mutate(model = factor(model, levels = clean_names))
# now convert from wide to long dataframe
tabs_long <- tidyr::pivot_longer(
    tabs_long,
    cols = c(
        "Catch",
        "Fraction Unfished",
        "Sigma",
        "Prob. < B40%",
        "Prob. < B25%"
    ),
    names_to = "metric",
    values_to = "value"
)

# Define color palette for models
# Assign base colors to models without "low"
base_names <- clean_names[!grepl("low", clean_names)]
low_names <- clean_names[grepl("low", clean_names)]
base_colors <- scales::hue_pal()(length(base_names))

model_colors <- rep(base_colors, each = 2) # repeat each color for the corresponding low model
names(model_colors) <- c(rbind(base_names, low_names)) # assign names to colors

# For each "low" model, assign a darker version of its base color
# Use colorspace::darken instead of scales::darken
if (!requireNamespace("colorspace", quietly = TRUE)) {
    install.packages("colorspace")
}
for (low_name in low_names) {
    # Find the corresponding base name (remove " (low)")
    base_name <- sub(" \\(low\\)", "", low_name)
    # Darken the base color for the corresponding low model
    model_colors[low_name] <- colorspace::darken(
        model_colors[base_name],
        amount = 0.4
    )
}

# plot catch by year for each model
library(ggplot2)
tabs_long |>
    dplyr::filter(!grepl("low", model) & metric == "Catch") |>
    ggplot() +
    geom_line(aes(x = Year, y = value, color = model), linewidth = 1.2) +
    scale_color_manual(values = model_colors) +
    labs(y = "Catch (mt)") +
    theme_minimal() +
    expand_limits(y = c(0, 12500)) +
    scale_y_continuous(breaks = seq(0, 12000, by = 2000)) +
    scale_x_continuous(breaks = unique(tabs_long$Year), minor_breaks = NULL) +
    geom_hline(yintercept = 0, linewidth = 0.5)
ggsave(
    filename = "catch_by_year.png",
    path = mydir,
    width = 6.5,
    height = 4,
    units = "in"
)

# plot expected fraction unfished by year for each model
tabs_long |>
    dplyr::filter(metric == "Fraction Unfished") |>
    ggplot() +
    geom_line(
        aes(
            x = Year,
            y = value,
            color = model
        ),
        linewidth = 1.2
    ) +
    scale_color_manual(values = model_colors) +
    labs(y = "Fraction of unfished spawning output") +
    theme_minimal() +
    expand_limits(y = c(0, 0.6)) +
    scale_y_continuous(breaks = seq(0, 1, by = 0.2)) +
    scale_x_continuous(breaks = unique(tabs_long$Year), minor_breaks = NULL) +
    geom_hline(yintercept = 0, linewidth = 0.5)
ggsave(
    filename = "fraction_unfished_by_year.png",
    path = mydir,
    width = 6.5,
    height = 4,
    units = "in"
)


# plot probability of being below B40% for each model
tabs_long |>
    dplyr::filter(metric == "Prob. < B40%") |>
    ggplot() +
    geom_line(
        aes(
            x = Year,
            y = value,
            color = model
        ),
        linewidth = 1.2
    ) +
    scale_color_manual(values = model_colors) +
    labs(y = "Probability of being below B40%") +
    theme_minimal() +
    expand_limits(y = c(0, 1.0)) +
    scale_y_continuous(breaks = seq(0, 1, by = 0.2)) +
    scale_x_continuous(breaks = unique(tabs_long$Year), minor_breaks = NULL) +
    geom_hline(yintercept = c(0, 1), linewidth = 0.5)
ggsave(
    filename = "prob_below_b40_by_year.png",
    path = mydir,
    width = 6.5,
    height = 4,
    units = "in"
)

# plot probability of being below B25% by year for each model
tabs_long |>
    dplyr::filter(metric == "Prob. < B25%") |>
    ggplot() +
    geom_line(
        aes(
            x = Year,
            y = value,
            color = model
        ),
        linewidth = 1.2
    ) +
    scale_color_manual(values = model_colors) +
    labs(y = "Probability of being below B25%") +
    theme_minimal() +
    expand_limits(y = c(0, 1.0)) +
    scale_y_continuous(breaks = seq(0, 1, by = 0.2)) +
    scale_x_continuous(breaks = unique(tabs_long$Year), minor_breaks = NULL) +
    geom_hline(yintercept = c(0, 1), linewidth = 0.5)
ggsave(
    filename = "prob_below_b25_by_year.png",
    path = mydir,
    width = 6.5,
    height = 4,
    units = "in"
)
