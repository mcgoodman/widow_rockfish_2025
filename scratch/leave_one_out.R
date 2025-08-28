library(here)
library(r4ss)
library(dplyr)

#' Conduct a leave-one-out analysis on a stock synthesis model, leaving out individual data sets
#' 
#' Does not work for discard composition data (partition = 2) at this time
#' Future improvement: either "all" fleets or manually enter fleet selections for each data type
#' 
#' Within each data type, models will run in parallel if you set your future accordingly.
#' 
#' @param inputlist List of model inputs to conduct LOO analysis on
#' @param dir Large directory where LOO model files are to be stored
#' @param index TRUE/FALSE whether to loop over index data
#' @param lengths TRUE/FALSE whether to loop over length data
#' @param ages TRUE/FALSE whether to loop over age data
#' @param ... Other arguments to be passed to `r4ss::run()`
#'
run_loo <- function(inputlist, dir, index = TRUE, lengths = TRUE, ages = TRUE, ...) {
  # Remove indices
  if(index & !is.null(inputlist$dat$CPUE)) {
  
    # Vector of fleet numbers that have CPUE data to loop over
    index_fleets <- filter(inputlist$dat$CPUE, year > 0, index > 0) |>
      pull(index) |> 
      unique()
    
    suppressWarnings(dir.create(file.path(dir, 'indices'))) # will warn if this directory exists
    
    furrr::future_walk(index_fleets, \(flt) {
      inputs_new <- inputlist
      # Make negative year to remove CPUE data
      inputs_new$dat$CPUE <- inputlist$dat$CPUE |>
        mutate(year = ifelse(index == flt & year > 0, year * -1, year))
      # Remove Q
      inputs_new$ctl$Q_options <- filter(inputlist$ctl$Q_options, fleet != flt)
      inputs_new$ctl$Q_parms <- inputlist$ctl$Q_parms[!grepl(pattern = paste0('(', flt, ')'), 
                                                             x = rownames(inputs_new$ctl$Q_parms)),]

      if(!is.null(inputlist$ctl$Q_parms_tv)) {
        inputs_new$ctl$Q_parms_tv <- inputlist$ctl$Q_parms_tv[!grepl(pattern = paste0('\\(', flt, '\\)'), 
                                                                     x = rownames(inputlist$ctl$Q_parms_tv)),]
        if(nrow(inputs_new$ctl$Q_parms_tv) == 0) inputs_new$ctl$Q_parms_tv <- NULL
        # Note this isn't checked for Q_options and Q_parms. If there is only one index this function might not work.
      }
      # Write new model files
      SS_write(inputs_new, file.path(dir, 'indices', inputlist$dat$fleetnames[flt]),
               overwrite = TRUE)
      # Run model
      run(dir = file.path(dir, 'indices', inputlist$dat$fleetnames[flt]), ...)
    })
  }
  # Remove length data
  if(lengths & !is.null(inputlist$dat$lencomp)) {
    
    # Vector of fleet numbers that have length data to loop over
    length_fleets <- filter(inputlist$dat$lencomp, year > 0, fleet > 0, part != 1) |>
      pull(fleet) |> 
      unique()
    
    suppressWarnings(dir.create(file.path(dir, 'lengths')))
    
    furrr::future_walk(length_fleets, \(flt) {
      # only remove length data if age data exists to inform selectivity
      if(nrow(filter(inputlist$dat$agecomp, fleet == flt, year > 0, part != 1)) > 0) { # in future could check for mirroring, too
        inputs_new <- inputlist
        inputs_new$dat$lencomp <- inputlist$dat$lencomp |>
          mutate(fleet = ifelse(fleet == flt, fleet * -1, fleet))
        
        SS_write(inputs_new, file.path(dir, 'lengths', inputlist$dat$fleetnames[flt]),
                 overwrite = TRUE)
        run(dir = file.path(dir, 'lengths', inputlist$dat$fleetnames[flt]), ...)
      }
    })
  }
  # Remove age data
  if(ages & !is.null(inputlist$dat$agecomp)) {
    
    # Vector of fleet numbers that have age data to loop over
    age_fleets <- filter(inputlist$dat$agecomp, year > 0, fleet > 0, part != 1) |>
      pull(fleet) |> 
      unique()
    
    suppressWarnings(dir.create(file.path(dir, 'ages')))
    
    furrr::future_walk(age_fleets, \(flt) {
      # only remove age data if length data exists to inform selectivity
      if(nrow(filter(inputlist$dat$lencomp, fleet == flt, year > 0, part != 1)) > 0) { # in future could check for mirroring, too
        inputs_new <- inputlist
        inputs_new$dat$agecomp <- inputlist$dat$agecomp |>
          mutate(fleet = ifelse(fleet == flt, fleet * -1, fleet))
        
        SS_write(inputs_new, file.path(dir, 'ages', inputlist$dat$fleetnames[flt]),
                 overwrite = TRUE)
        run(dir = file.path(dir, 'ages', inputlist$dat$fleetnames[flt]), ...)
      }
    })
  }
}

table_sens <- function(file_csv,
                       #  caption = "Differences in negative log-likelihood, estimates of key parameters, and estimates of derived quantities between the base model and several alternative models (columns). See main text for details on each sensitivity analysis. Red values indicate negative log-likelihoods that were lower (fit better to that component) than the base model.",
                       #  caption_extra = "",
                       # label = "tbl-sens",
                       sens_group = NULL,
                       dir = file.path("..", "tables"),
                       format = "latex") {
  
  conditional_color <- function(x) {
    kableExtra::cell_spec(x,
                          color = ifelse(is.na(x) | x >= 0, "black", "red"),
                          format = format
    )
  }
  if (!is.data.frame(file_csv)) {
    file_csv <- utils::read.csv(file_csv, check.names = FALSE) 
  }
  data <- file_csv |>
    dplyr::filter(!grepl("VonBert", Label)) |> # remove VonBert K to fit on page
    dplyr::filter(!grepl("Forecast", Label)) |> # remove VonBert K to fit on page
    dplyr::rename_with(~ gsub(" & ", "-", .x)) |>
    table_convert_vals() |>
    table_convert_offsets() |>
    dplyr::filter(!grepl("NatM_break_2_Mal", Label)) |>
    table_clean_labels()
  
  tt <- kableExtra::kbl(
    data |>
      dplyr::mutate_if(is.numeric, round, 3) |>
      dplyr::mutate_if(is.numeric, conditional_color),
    booktabs = TRUE, longtable = TRUE,
    format = format, escape = FALSE,
    digits = 3 # ,
    # caption = caption,
    # label = label
  ) |> 
    kableExtra::kable_styling(font_size = 9)
  
  # decrease column width for tables with lots of columns
  if (NCOL(data) <= 7) {
    tt <- tt |>
      kableExtra::column_spec(3:NCOL(data), width = "5em")
  }
  if (NCOL(data) > 7) {
    tt <- tt |>
      kableExtra::column_spec(3:NCOL(data), width = "4em")
  }
  
  # add subsection to improve readability
  # needs to be customized for the quantities chosen
  switch1 <- grep("Recruitment unfished", data[, 1])[1] # age X+ summary biomass is first derived quantity
  switch2 <- grep("+ bio", data[, 1])[1] # age X+ summary biomass is first derived quantity
  tt <- tt |>
    kableExtra::pack_rows("Diff. in likelihood from base model", 1, switch1 - 1) |>
    kableExtra::pack_rows("Estimates of key parameters", switch1, switch2 - 1) |>
    kableExtra::pack_rows("Estimates of derived quantities", switch2, NROW(data))
  return(tt)
}

base_dir <- here('models', '2025 base model')
base_in <- SS_read(base_dir)
base_out <- SS_output(base_dir)
future::plan(future::multisession(workers = parallelly::availableCores(omit = 1)))
run_loo(base_in, 'models/loo', exe = here('models', 'ss3.exe'), extras = '-nohess', skipfinished = FALSE, verbose = FALSE)

loo_index <- SSgetoutput(dirvec = list.dirs('models/loo/indices')[-1]) |> # first element is just models/loo/indices
  `names<-`(stringr::str_extract(string = list.dirs('models/loo/indices')[-1], 
                                 pattern = '(?<=/indices/)[:alpha:]+')) |> # any number of letters preceded by /indices/
  c(list(Base = base_out)) |> 
  SSsummarize() 

loo_lengths <- SSgetoutput(dirvec = list.dirs('models/loo/lengths')[-1]) |> 
  `names<-`(stringr::str_extract(string = list.dirs('models/loo/lengths')[-1], 
                                 pattern = '(?<=/lengths/)[:alpha:]+')) |> 
  c(list(Base = base_out)) |> 
  SSsummarize() 

loo_ages <- SSgetoutput(dirvec = list.dirs('models/loo/ages')[-1]) |> 
  `names<-`(stringr::str_extract(string = list.dirs('models/loo/ages')[-1], 
                                 pattern = '(?<=/ages/)[:alpha:]+')) |> 
  c(list(Base = base_out)) |> 
  SSsummarize() 

list(indices = SStableComparisons(loo_index, 
                                  modelnames = head(names(loo_index$parphases), -1),
                                  names = c("Recr_Virgin", "R0", "NatM", "L_at_Amax", "VonBert_K", "SSB_Virg",
                                            "SSB_2025", "Bratio_2025", "SPRratio_2024", "OFLCatch_2027")),
     ages = SStableComparisons(loo_ages, 
                               modelnames = head(names(loo_ages$parphases), -1),
                               names =c("Recr_Virgin", "R0", "NatM", "L_at_Amax", "VonBert_K", "SSB_Virg",
                                        "SSB_2025", "Bratio_2025", "SPRratio_2024", "OFLCatch_2027")),
     lengths = SStableComparisons(loo_lengths, 
                                  modelnames = head(names(loo_lengths$parphases), -1),
                                  names =c("Recr_Virgin", "R0", "NatM", "L_at_Amax", "VonBert_K", "SSB_Virg",
                                           "SSB_2025", "Bratio_2025", "SPRratio_2024", "OFLCatch_2027"))) |>
  saveRDS('models/loo/loo_res.rds')
