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

base_dir <- here('models', '2025 base model')
base_in <- SS_read(base_dir)
base_out <- SS_output(base_dir)
future::plan(future::multisession(workers = parallelly::availableCores(omit = 1)))
run_loo(base_in, 'models/loo', exe = here('models', 'ss3.exe'), extras = '-nohess', skipfinished = FALSE, verbose = FALSE)

loo_index <- SSgetoutput(dirvec = list.dirs('models/loo/indices')[-1], # first element is just models/loo/indices
                         modelnames = stringr::str_extract(string = list.dirs('models/loo/indices')[-1], 
                                                           pattern = '(?<=/indices/)[:alpha:]+')) |> 
  # regular expression: any number of letters preceded by /indices/
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

SStableComparisons(loo_index, 
                   names = c("Recr_Virgin", "R0", "NatM", "L_at_Amax", "VonBert_K", "SSB_Virg",
                             "SSB_2025", "Bratio_2025", "SPRratio_2024", "OFLCatch_2027"), 
                   likenames = NULL) |>
  knitr::kable(digits = 3)
  write.csv('models/loo/indices.csv', row.names = FALSE)
SStableComparisons(loo_ages, 
                   names =c("Recr_Virgin", "R0", "NatM", "L_at_Amax", "VonBert_K", "SSB_Virg",
                            "SSB_2025", "Bratio_2025", "SPRratio_2024", "OFLCatch_2027"), 
                   likenames = NULL)  |>
  write.csv('models/loo/ages.csv', row.names = FALSE)
SStableComparisons(loo_lengths, 
                   names =c("Recr_Virgin", "R0", "NatM", "L_at_Amax", "VonBert_K", "SSB_Virg",
                            "SSB_2025", "Bratio_2025", "SPRratio_2024", "OFLCatch_2027"), 
                   likenames = NULL) |>
  write.csv('models/loo/lengths.csv', row.names = FALSE)
