library("r4ss")
library("here")
library("parallel")
library("ggplot2")
library("dplyr")

plotdir <- here("figures", "bridging")

base_Aug2025 <- here("models", "Aug2025 base model")

dir_NewWACatch <- here("models", "Aug2025_NewWACatch")

# Supplemental bridging plots -------------------------------------

## SSB, SPR, etc. -----------------------------------------

models <- c(
    "Aug 2025 model" = base_Aug2025,
    "Aug 2025 + New WA catch" = here("models", "Aug2025_NewWACatch"),
    "Simplify fleets + include discards with landings" = here(
        "models",
        "supplemental_requests",
        "1.01_add_discards_to_landings"
    ),
    "Update data weighting (McAllister-Ianelli, lambda = 0.5)" = here(
        "models",
        "supplemental_requests",
        "1.02_retune_lambda0.5_MI"
    ),
    "Change data weighting (Francis, lambda = 1)" = here(
        "models",
        "supplemental_requests",
        "1.03_retune_lambda1_Francis"
    ),
    "Add fecundity relationship" = here(
        "models",
        "supplemental_requests",
        "1.04_add_fecundity"
    ),
    "Refine recruitment bias adjustment, re-weight" = here(
        "models",
        "supplemental_requests",
        "1.05_refine_biasramp_and_tuning"
    )
)

combined_models_list <- SSgetoutput(dirvec = models, modelnames = names(models))
model_summary <- SSsummarize(combined_models_list)

SSplotComparisons(
    model_summary,
    plotdir = plotdir,
    legendlabels = names(models),
    filenameprefix = "bridging2_",
    legendloc = c(0.05, 0.4),
    subplots = c(1:2, 11:12, 18),
    plot = FALSE,
    png = TRUE
)

SSplotComparisons(
    model_summary,
    plotdir = plotdir,
    legendlabels = names(models),
    filenameprefix = "bridging2_",
    legendloc = c(0.01, 0.75),
    subplots = 3,
    plot = FALSE,
    png = TRUE
)

SSplotComparisons(
    model_summary,
    plotdir = plotdir,
    legendlabels = names(models),
    filenameprefix = "bridging2_",
    legendloc = c(0.05, 1),
    subplots = 9:10,
    plot = FALSE,
    png = TRUE
)

r4ss::plot_twopanel_comparison(
    combined_models_list,
    subplot1 = 18,
    subplot2 = 3,
    legendloc = "bottomleft",
    legendlabels = names(models),
    dir = plotdir
)

r4ss::plot_twopanel_comparison(
    combined_models_list,
    subplot1 = 9,
    subplot2 = 11,
    legendloc = "topleft",
    legendlabels = names(models),
    dir = plotdir
)

# Tables

## Bridging table -----------------------------------------
tab <- SStableComparisons(
    model_summary,
    likenames = NULL,
    names = c(
        "Recr_Virgin",
        "R0",
        "NatM",
        "SmryBio_unfished",
        "SSB_Virg",
        "SSB_2025",
        "Bratio_2025",
        "SPRratio_2024",
        "Dead_Catch_SPR",
        "OFLCatch_2027",
        "ForeCatch_2027"
    )
)

write.csv(
    tab,
    file = here("report", "tables", "bridging2_table.csv"),
    row.names = FALSE
)

# read input files to get lambdas
inputs_Aug2025_base <- SS_read(models["Aug 2025 model"])
inputs_new_base <- SS_read(models[
    "Refine recruitment bias adjustment, re-weight"
])

# function to add lambda values to r4ss table
table_compweight_with_lambda <- function(outputs, inputs) {
    tab1 <- r4ss::table_compweight(outputs, save = FALSE)

    # parse the rownames in the table above to get length or age and fleet as additional columns
    lambda_table <- data.frame(
        rowname = rownames(inputs$ctl$lambdas),
        inputs$ctl$lambdas
    ) |>
        tidyr::separate(
            col = rowname,
            into = c("Type", "Fleet", "extra"),
            sep = "_",
            extra = "merge",
            fill = "right"
        ) |>
        dplyr::select(Type, Fleet, value) |>
        dplyr::rename(Lambda = value) |>
        dplyr::mutate(Type = ifelse(Type == "length", "Length", "Age")) |>
        # not at all general, but in this case only the WCGBTS age data is CAAL
        dplyr::mutate(
            Type = ifelse(Fleet == "WCGBTS" & Type == "Age", "CAAL", Type)
        )

    # merge the lambda table with the tab1$table to add a lambda column
    tab1$table |>
        left_join(lambda_table, by = c("Type", "Fleet")) |>
        dplyr::rename(Weight = Francis) |>
        dplyr::mutate(`Weight x lambda` = round(Weight * Lambda, 3)) |>
        dplyr::mutate(
            `Sum N adj. x lambda` = round(`Sum N adj.` * Lambda, 1)
        ) |>
        dplyr::select(
            Type,
            Fleet,
            Weight,
            Lambda,
            `Weight x lambda`,
            everything()
        )
}

write.csv(
    table_compweight_with_lambda(
        combined_models_list[[which(names(models) == "Aug 2025 model")]],
        inputs_Aug2025_base
    ),
    file = here("report", "tables", "compweight_Aug2025_base.csv"),
    row.names = FALSE
)
write.csv(
    table_compweight_with_lambda(
        combined_models_list[[which(
            names(models) == "Refine recruitment bias adjustment, re-weight"
        )]],
        inputs_new_base
    ),
    file = here("report", "tables", "compweight_new_base.csv"),
    row.names = FALSE
)
