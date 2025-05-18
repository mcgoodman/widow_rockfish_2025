#' Plot time-varying selectivity or selectivity
#'
#' Adapted from Petrale 2023
#' https://github.com/pfmc-assessments/petrale/blob/main/R/plot_petrale_selex.R
#' which was based on Lingcod 2021
#' https://github.com/pfmc-assessments/lingcod/blob/main/R/plot_selex.R
#' 
#' @param mod A model object created by `r4ss::SS_output()`
#' @param fleet a single fleet number
#' @param Factor a factor from mod$sizeselex$Factor
#' @param sex sex 1 for females, 2 for males
#' @export
#' @author Ian G. Taylor
plot_sel_ret <- function(mod,
                         fleet = 1,
                         Factor = "Lsel",
                         sex = 1, 
                         legendloc = "topleft") {
  years <- mod$startyr:mod$endyr

  # run selectivity function to get table of info on time blocks etc.
  # NOTE: this writes a png file to sel01_multiple_fleets_length1.png
  #       within the model directory
  infotable <- r4ss::SSplotSelex(mod,
    fleets = fleet,
    sexes = sex,
    sizefactors = Factor,
    years = years,
    subplots = 1,
    plot = FALSE,
    print = TRUE,
    plotdir = mod$inputs$dir
  )$infotable
  # remove extra file (would need to sort out the relative path stuff)
  file.remove(file.path(mod$inputs$dir, "sel01_multiple_fleets_length1.png"))

  # how many lines are in the plot
  nlines <- nrow(infotable)
  # update vector of colors
  infotable$col <- r4ss::rich.colors.short(max(6, nlines), alpha = 0.7) %>%
    rev() %>%
    tail(nlines)
  infotable$pch <- NA
  infotable$lty <- nrow(infotable):1
  infotable$lwd <- 3
  infotable$longname <- infotable$Yr_range
  # run plot function again, passing in the modified infotable
  r4ss::SSplotSelex(mod,
    fleets = fleet,
    # fleetnames = ,
    sexes = sex,
    sizefactors = Factor,
    labels = c(
      "Length (cm)",
      "Age (yr)",
      "Year",
      ifelse(Factor == "Lsel", "Selectivity", "Retention"),
      "Retention",
      "Discard mortality"
    ),
    legendloc = legendloc,
    years = years,
    subplots = 1,
    plot = TRUE,
    print = FALSE,
    infotable = infotable,
    mainTitle = TRUE,
    mar = c(2, 2, 2, 1), 
    res = 500
  )
}