# update PEPtools package after change on 5 March 2026
# which added output of the sigma values used in the buffer calculations
remotes::install_github("pfmc-assessments/PEPtools")

require(PEPtools)
require(r4ss)
require(dplyr)
require(gt)
require(here)

# get output from the base model (initial example used to create table)
model <- r4ss::SS_output(here::here("models", "2025 base model"))

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
sigma_and_catch_table <- dplyr::left_join(sigma_table, catch_table, by = "year") # add catch to table

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
table |>
    gt::gt() |>
    gt::cols_width(
        gt::everything() ~ gt::px(80),
    )
