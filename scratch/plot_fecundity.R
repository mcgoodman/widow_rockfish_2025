# adapted from petrale plot:
# https://github.com/pfmc-assessments/petrale/blob/main/Rscripts/fecundity_plot.R#L4

if (!exists("model") | !exists("model2")) {
    model <- r4ss::SS_output(
        "models/supplemental_requests/1.05_refine_biasramp_and_tuning",
        verbose = FALSE,
        printstats = FALSE
    )
    model2 <- r4ss::SS_output(
        "models/2025 base model",
        verbose = FALSE,
        printstats = FALSE
    )
}
#plot_fecundity <- function(model) {
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
lines(
    model$biology$Len_lo,
    model$biology$Wt_F,
    col = 2,
    lwd = 3,
)
wt_ref <- model$biology$Wt_F[which(model$biology$Len_lo == 40)]

# weight in the 40cm bin
lines(
    model$biology$Len_lo,
    model$biology$Fec *
        wt_ref /
        model$biology$Fec[which(model$biology$Len_lo == 40)],
    col = 4,
    lwd = 3
)
lines(
    model2$biology$Len_lo,
    model2$biology$Fec *
        wt_ref /
        model2$biology$Fec[which(model2$biology$Len_lo == 40)],
    col = 4,
    lwd = 3,
    lty = 2
)
# initial and final numbers at length and age
natlen_init <- model$natlen |>
    dplyr::filter(Time == model$startyr & Sex == 1) |>
    dplyr::select(paste(model$lbinspop)) |>
    as.numeric()
natage_init <- model$natage |>
    dplyr::filter(Time == model$startyr & Sex == 1) |>
    dplyr::select(paste(0:(model$accuage))) |>
    as.numeric()
natlen_end <- model$natlen |>
    dplyr::filter(Time == model$endyr + 1 & Sex == 1) |>
    dplyr::select(paste(model$lbinspop))
natage_end <- model$natage |>
    dplyr::filter(Time == model$endyr + 1 & Sex == 1) |>
    dplyr::select(paste(0:(model$accuage))) |>
    as.numeric()

# length at age matrix
len_at_age <- model$ALK[,, "Seas: 1 Sub_Seas: 1 Morph: 1"]
# reverse the matrix so rows are increasing with length rather than decreasing
len_at_age <- len_at_age[nrow(len_at_age):1, ]

# confirm that numbers at length from numbers at age matches
# numbers at length directly
natlen_init2 <- len_at_age %*% natage_init |> as.numeric()
# confirm match
range(natlen_init / natlen_init2)
# [1] 0.9999952 1.0000070

# maturity at age vector
maturity_at_age <- model$endgrowth |>
    dplyr::filter(Sex == 1) |>
    dplyr::pull(Age_Mat) |>
    as.numeric()

# maturity at length from mature numbers at age
mature_at_len_init <- len_at_age %*%
    (natage_init * maturity_at_age) |>
    as.numeric()
mature_at_len_end <- len_at_age %*%
    (natage_end * maturity_at_age) |>
    as.numeric()

# add lines
lines(
    model$biology$Len_lo,
    0.001 * mature_at_len_init,
    col = 3,
    lwd = 3
)
lines(
    model$biology$Len_lo,
    0.001 * mature_at_len_end,
    col = 3,
    lwd = 3,
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
    "Estimated numbers (millions) of \nmature females by length bin:"
)
legend(
    x = 0,
    y = 4.3,
    col = c(3, 3),
    legend = c(
        glue::glue("at the start of {model$startyr}"),
        glue::glue("at the start of {model$endyr + 1}")
    ),
    lwd = 3,
    lty = c(1, 3),
    bty = 'n'
)
dev.off()

x = model$endgrowth |>
    dplyr::filter(Sex == 1) |>
    dplyr::pull("Mat*Fecund") |>
    as.numeric()

# numbers at age are in thousands
# fecundity units are in?

# product is in millions
sum(x * natage_init)
# [1] 20220.36

model$derived_quants["SSB_1916", "Value"]
# [1] 20220.4

# calculate mean length weighting by mature numbers at length
mean_length_mature_init <- sum(model$biology$Len_lo * mature_at_len_init) /
    sum(mature_at_len_init)
mean_length_mature_end <- sum(model$biology$Len_lo * mature_at_len_end) /
    sum(mature_at_len_end)
print(glue::glue(
    "Mean length of mature females at start: {round(mean_length_mature_init, 2)} cm"
))
print(glue::glue(
    "Mean length of mature females at end: {round(mean_length_mature_end, 2)} cm"
))
