library("r4ss")
library("here")
library("parallel")
library("ggplot2")
library("dplyr")

plotdir <- here("figures", "bridging")

base_Aug2025 <- here("models", "Aug2025 base model")

dir_NewWACatch <- here("models", "Aug2025_NewWACatch")

# Main bridging plots -------------------------------------

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
