# adapted from petrale plot:
# https://github.com/pfmc-assessments/petrale/blob/main/Rscripts/fecundity_plot.R

# Function to add lines to fecundity plot
# @param model SS_output object from r4ss
# @param type Type of line to add: "weight", "fecundity", "numbers_initial", "numbers_year"
# @param year Year for numbers at length (only used if type = "numbers_year")
# @param scale_length Length bin to scale fecundity lines to match weight (default is 40cm). NULL will remove scaling.
# @param col Line color (default: 1)
# @param lwd Line width (default: 3)
# @param lty Line type (default: 1)
# @param ... Additional arguments passed to lines()
#
# Usage examples:
#   # Add weight-length relationship
#   add_fecundity_line(model, type = "weight", col = 2)
#
#   # Add fecundity lines (scaled to reference weight)
#   add_fecundity_line(model, type = "fecundity", col = 4)
#   add_fecundity_line(model2, type = "fecundity", col = 4, lty = 2)
#
#   # Add numbers at length for initial year
#   add_fecundity_line(model, type = "numbers_initial", col = 3)
#
#   # Add numbers at length for a specific year
#   add_fecundity_line(model, type = "numbers_year", year = 2025, col = 3, lty = 3)
add_fecundity_line <- function(
    model,
    type = c("weight", "fecundity", "numbers_initial", "numbers_year"),
    year = NULL,
    scale_length = 40,
    col = 1,
    lwd = 3,
    lty = 1,
    ...
) {
    type <- match.arg(type)

    # reference weight at
    if (type == "fecundity" & !is.null(scale_length)) {
        if (!scale_length %in% model$biology$Len_lo) {
            cli::cli_abort(
                "scale_length {scale_length} not found in model length bins (see $biology$Len_lo)."
            )
        }
        wt_ref <- model$biology$Wt_F[which(
            model$biology$Len_lo == scale_length
        )]
    }

    if (type == "weight") {
        # Weight-length relationship
        lines(
            model$biology$Len_lo,
            model$biology$Wt_F,
            col = col,
            lwd = lwd,
            lty = lty,
            ...
        )
    } else if (type == "fecundity") {
        # Fecundity scaled to match weight at 40 cm
        lines(
            model$biology$Len_lo,
            model$biology$Fec *
                wt_ref /
                model$biology$Fec[which(model$biology$Len_lo == scale_length)],
            col = col,
            lwd = lwd,
            lty = lty,
            ...
        )
    } else if (type == "numbers_initial" || type == "numbers_year") {
        # Calculate numbers at length for specified year
        if (type == "numbers_initial") {
            year <- model$startyr
        } else if (is.null(year)) {
            stop("year must be specified when type = 'numbers_year'")
        }

        # Get numbers at age
        natage <- model$natage |>
            dplyr::filter(Time == year & Sex == 1) |>
            dplyr::select(paste(0:(model$accuage))) |>
            as.numeric()

        # Length at age matrix
        len_at_age <- model$ALK[,, "Seas: 1 Sub_Seas: 1 Morph: 1"]
        # Reverse the matrix so rows are increasing with length rather than decreasing
        len_at_age <- len_at_age[nrow(len_at_age):1, ]

        # Maturity at age vector
        maturity_at_age <- model$endgrowth |>
            dplyr::filter(Sex == 1) |>
            dplyr::pull(Age_Mat) |>
            as.numeric()

        # Maturity at length from mature numbers at age
        mature_at_len <- len_at_age %*%
            (natage * maturity_at_age) |>
            as.numeric()

        # Add line (convert to millions)
        lines(
            model$biology$Len_lo,
            0.001 * mature_at_len,
            col = col,
            lwd = lwd,
            lty = lty,
            ...
        )
    }
}

if (!exists("model") | !exists("base_2025")) {
    old_fecundity <- r4ss::SS_output(
        "models/supplemental_requests/1.05_refine_biasramp_and_tuning",
        verbose = FALSE,
        printstats = FALSE
    )
    base_2025 <- r4ss::SS_output(
        "models/2025 base model",
        verbose = FALSE,
        printstats = FALSE
    )
}

first_plot <- function() {
    # Add weight-length relationship
    add_fecundity_line(base_2025, type = "weight", col = 2)

    # Add fecundity lines (scaled to match weight at scale_length cm)
    add_fecundity_line(
        old_fecundity,
        type = "fecundity",
        col = 4,
        lty = 1
    )
    add_fecundity_line(
        base_2025,
        type = "fecundity",
        col = 4,
        lty = 2
    )

    # Add numbers at length for initial year and end year
    add_fecundity_line(
        base_2025,
        type = "numbers_initial",
        col = 3,
        lty = 1
    )
    add_fecundity_line(
        base_2025,
        type = "numbers_year",
        year = base_2025$endyr + 1,
        col = 3,
        lty = 3
    )
}

# make first plot
png(
    "figures/supplemental_requests/fecundity.png",
    width = 6.5,
    height = 5,
    res = 300,
    pointsize = 10,
    units = 'in'
)
par(mar = c(5, 4, 1, 1))
plot(
    0,
    type = 'n',
    xlim = c(0, 60),
    ylim = c(0, 6),
    yaxs = 'i',
    xaxs = 'i',
    xlab = "Length (cm)",
    ylab = "Weight (kg) or numbers (millions)"
)

# run wrapper function created above to add lines
first_plot()

legend(
    x = 0,
    y = 6,
    col = c(2, 4, 4),
    legend = c(
        "Weight (kg)",
        "Fecundity for unobserved rockfish (scaled to match weight at 40 cm)",
        "Fecundity for widow rockfish (scaled to match weight at 40 cm)"
    ),
    lwd = 3,
    lty = c(1, 1, 2),
    bty = 'n'
)
text(
    x = 0,
    y = 4.5,
    pos = 4,
    "Estimated numbers (millions) of \nmature females by length bin:"
)
legend(
    x = 0,
    y = 4.3,
    col = c(3, 3),
    legend = c(
        glue::glue("at the start of {base_2025$startyr}"),
        glue::glue("at the start of {base_2025$endyr + 1}")
    ),
    lwd = 3,
    lty = c(1, 3),
    bty = 'n'
)
dev.off()

# Optional validation: confirm that numbers at length from numbers at age matches
# numbers at length directly
if (FALSE) {
    natlen_init <- base_2025$natlen |>
        dplyr::filter(Time == base_2025$startyr & Sex == 1) |>
        dplyr::select(paste(base_2025$lbinspop)) |>
        as.numeric()
    natage_init <- base_2025$natage |>
        dplyr::filter(Time == base_2025$startyr & Sex == 1) |>
        dplyr::select(paste(0:(base_2025$accuage))) |>
        as.numeric()
    len_at_age <- base_2025$ALK[,, "Seas: 1 Sub_Seas: 1 Morph: 1"]
    len_at_age <- len_at_age[nrow(len_at_age):1, ]
    natlen_init2 <- len_at_age %*% natage_init |> as.numeric()
    range(natlen_init / natlen_init2)
    # [1] 0.9999952 1.0000070

    x = base_2025$endgrowth |>
        dplyr::filter(Sex == 1) |>
        dplyr::pull("Mat*Fecund") |>
        as.numeric()

    # numbers at age are in thousands
    # fecundity units are in?
    # product is in millions
    sum(x * natage_init)
    # [1] 21079.16

    base_2025$derived_quants["SSB_1916", "Value"]
    # [1] 21079.2

    # calculate mean length weighting by mature numbers at length
    natage_init <- base_2025$natage |>
        dplyr::filter(Time == base_2025$startyr & Sex == 1) |>
        dplyr::select(paste(0:(base_2025$accuage))) |>
        as.numeric()
    natage_end <- base_2025$natage |>
        dplyr::filter(Time == base_2025$endyr + 1 & Sex == 1) |>
        dplyr::select(paste(0:(base_2025$accuage))) |>
        as.numeric()
    len_at_age <- base_2025$ALK[,, "Seas: 1 Sub_Seas: 1 Morph: 1"]
    len_at_age <- len_at_age[nrow(len_at_age):1, ]
    maturity_at_age <- base_2025$endgrowth |>
        dplyr::filter(Sex == 1) |>
        dplyr::pull(Age_Mat) |>
        as.numeric()
    mature_at_len_init <- len_at_age %*%
        (natage_init * maturity_at_age) |>
        as.numeric()
    mature_at_len_end <- len_at_age %*%
        (natage_end * maturity_at_age) |>
        as.numeric()
    mean_length_mature_init <- sum(
        base_2025$biology$Len_lo * mature_at_len_init
    ) /
        sum(mature_at_len_init)
    mean_length_mature_end <- sum(
        base_2025$biology$Len_lo * mature_at_len_end
    ) /
        sum(mature_at_len_end)
    print(glue::glue(
        "Mean length of mature females at start: {round(mean_length_mature_init, 2)} cm"
    ))
    print(glue::glue(
        "Mean length of mature females at end: {round(mean_length_mature_end, 2)} cm"
    ))
}


# second plot with 2019 assessment added for comparison
if (!exists("output_2019")) {
    output_2019 <- r4ss::SS_output(
        here::here("models", "2019 base model", "Base_45_new"),
        verbose = FALSE,
        printstats = FALSE
    )
}

png(
    "figures/supplemental_requests/fecundity_with_2019.png",
    width = 6.5,
    height = 5,
    res = 300,
    pointsize = 10,
    units = 'in'
)
par(mar = c(5, 4, 1, 1))
plot(
    0,
    type = 'n',
    xlim = c(0, 60),
    ylim = c(0, 6),
    yaxs = 'i',
    xaxs = 'i',
    xlab = "Length (cm)",
    ylab = "Weight (kg) or numbers (millions)"
)

# run wrapper function created above to add lines
first_plot()

# Add numbers at length for 2019 assessment (initial and 2025)
add_fecundity_line(
    output_2019,
    type = "numbers_initial",
    col = "orange3",
    lty = 1
)
add_fecundity_line(
    output_2019,
    type = "numbers_year",
    year = 2026,
    col = "orange3",
    lty = 3
)


legend(
    x = 0,
    y = 6,
    col = c(2, 4, 4),
    legend = c(
        "Weight (kg)",
        "Fecundity for unobserved rockfish (scaled to match weight at 40 cm)",
        "Fecundity for widow rockfish (scaled to match weight at 40 cm)"
    ),
    lwd = 3,
    lty = c(1, 1, 2),
    bty = 'n'
)
text(
    x = 0,
    y = 4.5,
    pos = 4,
    "Estimated numbers (millions) of \nmature females by length bin in Jan 2026 base model:"
)
legend(
    x = 0,
    y = 4.3,
    col = c(3, 3),
    legend = c(
        glue::glue("at the start of {old_fecundity$startyr}"),
        glue::glue("at the start of {old_fecundity$endyr + 1}")
    ),
    lwd = 3,
    lty = c(1, 3),
    bty = 'n'
)
text(
    x = 0,
    y = 2.5,
    pos = 4,
    "Projected numbers (millions) of \nmature females by length bin in 2019 model:"
    #col = "orange3"
)
legend(
    x = 0,
    y = 2.3,
    col = "orange3",
    legend = c(
        glue::glue("at the start of {old_fecundity$startyr}"),
        glue::glue("at the start of {old_fecundity$endyr + 1}")
    ),
    lwd = 3,
    lty = c(1, 3),
    bty = 'n'
)
dev.off()
