# update PEPtools package after change on 5 March 2026
# which added output of the sigma values used in the buffer calculations
remotes::install_github("pfmc-assessments/PEPtools")

# get output from the base model (initial example used to create table)
model <- r4ss::SS_output(here::here("models", "2025 base model"))

# create table of sigma values for each year, using PEPtools get_buffer function
years <- 2025:2036
sigma_table <- PEPtools::get_buffer(
    years = years,
    sigma = 0.5,
    pstar = 0.45
)

# add columns to table for fraction unfished and probability of being below 25%
# using model output of Bratio and assuming a lognormal distribution
table <- sigma_table |>
    dplyr::select(-hash, -buffer) |> # remove unnecessary columns
    dplyr::mutate(
        frac_unfished = model$derived_quants |>
            dplyr::filter(Label %in% paste0("Bratio_", years)) |>
            dplyr::pull(Value) |>
            round(3),
        prob_below_B25 = plnorm(
            q = 0.25,
            meanlog = log(frac_unfished),
            sdlog = sigma
        ) |>
            round(3)
    )
