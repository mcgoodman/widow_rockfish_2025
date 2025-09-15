# additional steps to remove fishery-dependent CPUE indices 
# (had a bigger impact than expected, so saving this for another day)
inputs2 <- inputs
# Remove fishery-dependent CPUE time series
inputs2$dat$CPUE <- inputs2$dat$CPUE |>
    dplyr::filter(!index %in% c(1, 3, 9)) # remove CPUE for bottom trawl, hake, and foreign fleets
# remove catchability stuff related to removed CPUE indices
inputs2$ctl$Q_options <- inputs2$ctl$Q_options |>
    dplyr::filter(!fleet %in% c(1, 3, 9))
inputs2$ctl$Q_parms <- inputs2$ctl$Q_parms |>
    dplyr::filter(
        !grepl("BottomTrawl|Hake|ForeignAtSea", rownames(inputs2$ctl$Q_parms))
    )
inputs2$ctl$Q_parms_tv <- inputs2$ctl$Q_parms_tv |>
    dplyr::filter(
        !grepl(
            "BottomTrawl|Hake|ForeignAtSea",
            rownames(inputs2$ctl$Q_parms_tv)
        )
    )

# write files
inputs2$dir <- here::here(
    "models",
    "supplemental_requests",
    "simplify_step2_remove_fishery_dependent_CPUE"
)
r4ss::SS_write(
    inputs2,
    dir = inputs2$dir,
    overwrite = TRUE,
    verbose = FALSE
)
# get output
output2 <- r4ss::SS_output(
    # inputs$dir,
    here::here(
        "models",
        "supplemental_requests",
        "simplify_step2_remove_fishery_dependent_CPUE"
    ),
    printstats = FALSE,
    verbose = FALSE
)
