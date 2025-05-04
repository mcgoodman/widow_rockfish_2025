library(here)
library(r4ss)
library(dplyr)
model_directory <- 'model_runs'
base_model_name <- '5.09_no_extra_se'
exe_loc <- here('model_runs/ss3.exe')
base_model <- SS_read(file.path(model_directory, base_model_name), ss_new = TRUE)
base_out <- SS_output(file.path(model_directory, base_model_name))

# Write sensitivities -----------------------------------------------------

## M-I weighting -----------------------------------------------------------

copy_SS_inputs(dir.old = file.path(model_directory, base_model_name), 
               dir.new = file.path(model_directory, 'sensitivities', 'M_I_weighting'))
file.copy(from = file.path(model_directory, base_model_name,
                           c('Report.sso', 'CompReport.sso', 'warning.sso')), 
          to = file.path(model_directory, 'sensitivities', 'M_I_weighting', 
                         c('Report.sso', 'CompReport.sso', 'warning.sso')), 
          overwrite = TRUE)
tune_comps(option = 'MI', niters_tuning = 3, 
           dir = file.path(model_directory, 'sensitivities', 'M_I_weighting'),
           exe = exe_loc, extras = '-nohess')


## SMURFS ------------------------------------------------------------------

sensi_mod <- base_model

sensi_mod$dat$CPUE <- sensi_mod$dat$CPUE |>
  filter(index != 7)

sensi_mod$ctl$Q_options <- sensi_mod$ctl$Q_options[-grep('SMURF', rownames(sensi_mod$ctl$Q_options)),]
sensi_mod$ctl$Q_parms <- sensi_mod$ctl$Q_parms[-grep('SMURF', rownames(sensi_mod$ctl$Q_parms)),]

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'no_SMURF'), overwrite = TRUE)

# out <- SSgetoutput(dirvec = c(file.path(model_directory, base_model_name),
#                               file.path(model_directory, 'sensitivities', 'SMURF')))
# SSsummarize(out) |>
#   SSplotComparisons(subplots = c(1,3), endyrvec = 2037, new = FALSE)


## ORBS --------------------------------------------------------------------

sensi_mod <- base_model

orbs <- read.csv('Data/raw_not_confidential/ORBS index/index_forSS.csv') |>
  mutate(index = 3) |>
  rename(se_log = logse) |>
  select(-fleet)

sensi_mod$dat$CPUEinfo['Recreational','units'] <- 0 # numbers

sensi_mod$dat$CPUE <- bind_rows(sensi_mod$dat$CPUE,
                                orbs)

sensi_mod$ctl$Q_options <- rbind(sensi_mod$ctl$Q_options,
                                 Recreational = c(3,1,0,1,0,0)) |>
  slice(5,1,2,3,4) # reorder
sensi_mod$ctl$Q_parms <- bind_rows(sensi_mod$ctl$Q_parms[1:2,], # copy H&L Q setup for SMURF
                                   sensi_mod$ctl$Q_parms)
rownames(sensi_mod$ctl$Q_parms) <- rownames(sensi_mod$ctl$Q_parms) |>
  stringr::str_replace('H&L_survey\\(4\\)\\.\\.\\.[1|2]', 'Recreational(3)') |> # fix row names
  stringr::str_remove('\\.\\.\\.[:digit:]')

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'ORBS'), overwrite = TRUE)

sensi_mod$ctl$Q_parms['Q_extraSD_Recreational(3)', 'PHASE'] <- 3
SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'ORBS_SE'), overwrite = TRUE)

# 
# out <- SSgetoutput(dirvec = c(file.path(model_directory, base_model_name),
#                               file.path(model_directory, 'sensitivities', 'ORBS')))
# SSsummarize(out) |>
#   SSplotComparisons(subplots = c(1,3), endyrvec = 2037, new = FALSE)
# SSplotIndices(out[[2]])
# 

## Oceanographic index -----------------------------------------------------

sensi_mod <- base_model

flt <- base_model$dat$Nfleets + 1

ocean <- read.csv('Data/raw_not_confidential/OceanographicIndex/OceanographicIndexV1.csv') |>
  mutate(month = 7, 
         index = ifelse(year >= 2015, flt, -flt) # include 10 years of index
  ) |>
  select(year, month, index, obs = fit, se_log = se.p)

# data file updates
sensi_mod$dat$Nfleets <- flt
sensi_mod$dat$fleetnames[flt] <- 'ocean'
sensi_mod$dat$fleetinfo[flt,] <- c(3,1,1,2,0,'ocean')
sensi_mod$dat$CPUEinfo[flt,] <- c(flt,36,-1,0)
sensi_mod$dat$len_info[flt,] <- sensi_mod$dat$len_info[flt-1,]
sensi_mod$dat$age_info[flt,] <- sensi_mod$dat$age_info[flt-1,]
sensi_mod$dat$fleetinfo1$SMURF <- sensi_mod$dat$fleetinfo1$WCGBTS
sensi_mod$dat$fleetinfo2$SMURF <- sensi_mod$dat$fleetinfo2$WCGBTS
sensi_mod$dat$CPUE <- bind_rows(sensi_mod$dat$CPUE,
                          ocean)

# control file updates
sensi_mod$ctl$size_selex_types[flt,] <- rep(0, 4)
sensi_mod$ctl$age_selex_types[flt,] <- sensi_mod$ctl$age_selex_types[flt-1,]
sensi_mod$ctl$Q_options <- rbind(sensi_mod$ctl$Q_options,
                           ocean = c(flt,1,0,0,0,0))
sensi_mod$ctl$Q_parms <- bind_rows(sensi_mod$ctl$Q_parms,
                             sensi_mod$ctl$Q_parms[1,])

sensi_mod$ctl$Q_parms[nrow(sensi_mod$ctl$Q_parms), c('INIT', 'PHASE')] <- c(1, -99)

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'oceanographic_index'), overwrite = TRUE)
# 
# out <- SSgetoutput(dirvec = c(file.path(model_directory, base_model_name),
#                               file.path(model_directory, 'sensitivities', 'oceanographic_index')))

# miraculously, it is not bad.
# 
# out <- SS_output(file.path(model_directory, 'sensitivities', 'hook_and_line'))
# SS_plots(out)

# surveys_only <- SS_read(file.path(model_directory, 'sensitivities', 'hook_and_line'), 
#                         ss_new = TRUE)
# 
# surveys_only$ctl$MG_parms$PHASE <- -99
# surveys_only$ctl$SR_parms$PHASE <- -99
# surveys_only$ctl$Q_parms$PHASE <- -99
# surveys_only$ctl$size_selex_parms$PHASE <- -99
# surveys_only$ctl$size_selex_parms_tv$PHASE <- -99
# surveys_only$ctl$lambdas <- surveys_only$ctl$lambdas |>
#   slice(-(1:2)) |>
#   bind_rows(
#     data.frame(
#       like_comp = rep(4, 6),
#       fleet = 1:6, phase = 1, value = 0, sizefreq_method = 0
#     ),
#     data.frame(
#       like_comp = rep(5, 5),
#       fleet = c(1,2,3,5,6), phase = 1, value = 0, sizefreq_method = 0
#     )
#     
#   )
# surveys_only$ctl$N_lambdas <- nrow(surveys_only$ctl$lambdas)
# surveys_only$ctl$recdev_phase <- 1
# 
# SS_write(surveys_only, file.path(model_directory, 'sensitivities', 'surveys_only'),
#          overwrite = TRUE)
# out_surveys <- SS_output(file.path(model_directory, 'sensitivities', 'surveys_only'))
# SS_plots(out_surveys)

## RREAS -------------------------------------------------------------------

sensi_mod <- base_model

flt <- base_model$dat$Nfleets + 1

rreas <- read.csv('Data/raw_not_confidential/RREAS/ytail_coastwide_indices.csv') |>
  mutate(index = flt, month = 7) |>
  rename(se_log = logse, year = YEAR, obs = est)

sensi_mod$dat$Nfleets <- flt
sensi_mod$dat$fleetnames[flt] <- 'RREAS'
sensi_mod$dat$fleetinfo[flt,] <- c(3,1,1,2,0,'RREAS')
sensi_mod$dat$CPUEinfo[flt,] <- c(flt,33,0,0)
sensi_mod$dat$len_info[flt,] <- sensi_mod$dat$len_info[flt-1,]
sensi_mod$dat$age_info[flt,] <- sensi_mod$dat$age_info[flt-1,]
sensi_mod$dat$fleetinfo1$SMURF <- sensi_mod$dat$fleetinfo1$WCGBTS
sensi_mod$dat$fleetinfo2$SMURF <- sensi_mod$dat$fleetinfo2$WCGBTS
sensi_mod$dat$CPUE <- bind_rows(sensi_mod$dat$CPUE,
                                rreas)

# control file updates
sensi_mod$ctl$size_selex_types[flt,] <- rep(0, 4)
sensi_mod$ctl$age_selex_types[flt,] <- sensi_mod$ctl$age_selex_types[flt-1,]
sensi_mod$ctl$Q_options <- rbind(sensi_mod$ctl$Q_options,
                                 RREAS = c(flt,1,0,0,0,0))
sensi_mod$ctl$Q_parms <- bind_rows(sensi_mod$ctl$Q_parms,
                                   sensi_mod$ctl$Q_parms[1,])

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'RREAS'),
         overwrite = TRUE)

## remove indices ----------------------------------------------------

sensi_mod <- base_model

sensi_mod$dat$CPUE$year <- -1*sensi_mod$dat$CPUE$year
sensi_mod$ctl$Q_options <- sensi_mod$ctl$Q_parms <- NULL

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'no_indices'),
         overwrite = TRUE)


## upweight wcbts ----------------------------------------------------------

sensi_mod <- base_model

sensi_mod$dat$CPUE <- sensi_mod$dat$CPUE |>
  mutate(se_log = ifelse(index == 6, 0.05, se_log))

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'upweight_wcgbts'),
         overwrite = TRUE)

## observer index ----------------------------------------------------------

sensi_mod <- base_model

sensi_mod$dat$CPUEinfo
sensi_mod$dat$CPUE <- bind_rows(sensi_mod$dat$CPUE,
                                read.csv('data/processed/observer_index.csv'))

sensi_mod$ctl$Q_options <- rbind(sensi_mod$ctl$Q_options,
                                 Commercial = c(1,1,0,0,0,1)) |> # float Q, was not being well estimated (possibly bad start value)
  slice(5,1,2,3,4) # reorder
sensi_mod$ctl$Q_parms <- bind_rows(sensi_mod$ctl$Q_parms[1,], # copy H&L Q setup for observer index
                                   sensi_mod$ctl$Q_parms)
sensi_mod$ctl$Q_parms[1, 'PHASE'] <- -99

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'observer_index'),
         overwrite = TRUE)
# out <- SS_output(file.path(model_directory, 'sensitivities', 'observer_index'))
# SSplotIndices(out, fleets = 1)

## no fishery lengths ------------------------------------------------------

sensi_mod <- base_model
sensi_mod$ctl$lambdas <- sensi_mod$ctl$lambdas |>
  bind_rows(data.frame(
    like_comp = 4, fleet = 1:3, phase = 1, value = 0, sizefreq_method = 0
  ))
sensi_mod$ctl$N_lambdas <- nrow(sensi_mod$ctl$lambdas)

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'no_fishery_len'),
         overwrite = TRUE)

## non-linear WCGBTS catchability -------------------------------------------------

sensi_mod <- base_model
sensi_mod$ctl$Q_options['WCGBTS', 'link'] <- 3
# Triennial estimate of power parameters is pretty close to zero

power_row <- sensi_mod$ctl$Q_parms[1,] |>
  `rownames<-`('power_parameter')
power_row$INIT <- 0
power_row$PHASE <- 3

sensi_mod$ctl$Q_parms <- bind_rows(
  sensi_mod$ctl$Q_parms[1:5,],
  power_row,
  sensi_mod$ctl$Q_parms[6:8,]
)

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'nonlinear_q'),
         overwrite = TRUE)


## Add unsexed commercial lengths ------------------------------------------

sensi_mod <- base_model

unsexed_lengths <- read.csv('data/processed/pacfin_lcomps.csv') |>
  `names<-`(names(sensi_mod$dat$lencomp)) |>
  filter(sex == 0)
sensi_mod$dat$lencomp <- bind_rows(sensi_mod$dat$lencomp,
                                   unsexed_lengths)

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'unsexed_lengths'),
         overwrite = TRUE)


## sex-specific selectivity ------------------------------------------------

sensi_mod <- base_model

sensi_mod$ctl$size_selex_parms[grepl('Off_(1|2|5)', rownames(sensi_mod$ctl$size_selex_parms)) &
                                 !grepl('Rec|H&L', rownames(sensi_mod$ctl$size_selex_parms)), 
                               'PHASE'] <- 6

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'sex_selex'), 
         overwrite = TRUE)


## No sex specific selectivity ---------------------------------------------

sensi_mod <- base_model

sensi_mod$ctl$size_selex_parms[grepl('Off', rownames(sensi_mod$ctl$size_selex_parms)), 'PHASE'] <- -99

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'no_sex_selex'), 
         overwrite = TRUE)

8
## Breakpoint M --------------------------------------------------------------

sensi_mod <- base_model

sensi_mod$ctl$natM_type <- 1
sensi_mod$ctl$N_natM <- sensi_mod$ctl$N_natMparms <- 2
sensi_mod$ctl$M_ageBreakPoints <- 9:10 # age at 50% maturity is 10

nat_m_ind <- grep('NatM', rownames(sensi_mod$ctl$MG_parms))

mg_table <- SS_read(file.path(model_directory, '4.07_breakpoint_m'))$ctl$MG_parms
mg_table['CV_old_Fem_GP_1', 'LO'] <- -0.99
sensi_mod$ctl$MG_parms <- mg_table

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'breakpoint_m'),
         overwrite = TRUE)  


## Single M ----------------------------------------------------------------

sensi_mod <- base_model

sensi_mod$ctl$MG_parms['NatM_p_1_Mal_GP_1', c('INIT', 'PHASE')] <- c(0, -99)

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'single_m'),
         overwrite = TRUE)  


## Time varying W-L --------------------------------------------------------

source('Rscripts/add_time_varying_WL.R')

sensi_mod <- add_tv_wl(base_model)

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'tv_wl'))

## F method --base_model# F method ----------------------------------------------------------------

sensi_mod <- base_model

sensi_mod$ctl$F_Method <- 3
sensi_mod$ctl$F_iter <- 4

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'hybrid_f'))

# Run stuff ---------------------------------------------------------------

sensi_dirs <- list.files(file.path(model_directory, 'sensitivities'))

tuning_mods <- grep('weighting', sensi_mods)

future::plan(future::multisession(workers = parallelly::availableCores(omit = 1)))

# furrr::future_map(sensi_dirs[-tuning_mods], \(x) 
#                   run(file.path(model_directory, 'sensitivities', x), 
#                       exe = exe_loc, extras = '-nohess', skipfinished = FALSE)
# )

furrr::future_map(c('nonlinear_q', 'oceanographic_index'), \(x) 
                  run(file.path(model_directory, 'sensitivities', x), 
                      exe = exe_loc, extras = '-nohess', skipfinished = FALSE)
)

future::plan(future::sequential)


# Plot stuff --------------------------------------------------------------


## function ----------------------------------------------------------------

make_detailed_sensitivites <- function(biglist, mods, 
                                       outdir, grp_name) {
  
  shortlist <- big_sensitivity_output[c('base', mods$dir)] |>
    r4ss::SSsummarize() 
  
  r4ss::SSplotComparisons(shortlist,
                          subplots = c(2,4, 18), 
                          print = TRUE,  
                          plot = FALSE,
                          plotdir = outdir, 
                          filenameprefix = grp_name,
                          legendlabels = c('Base', mods$pretty), 
                          endyrvec = 2036)
  
  SStableComparisons(shortlist, 
                     modelnames = c('Base', mods$pretty),
                     names =c("Recr_Virgin", "R0", "NatM", "L_at_Amax", "VonBert_K", "SmryBio_unfished", "SSB_Virg",
                              "SSB_2025", "Bratio_2025", "SPRratio_2024", "LnQ_base_WCGBTS"),
                     likenames = c(
                              "TOTAL", "Survey", "Length_comp", "Age_comp",
                              "Discard", "Mean_body_wt", "Recruitment", "priors"
                            )
                          ) |>
    # dplyr::filter(!(Label %in% c('NatM_break_1_Fem_GP_1',
    #                              'NatM_break_1_Mal_GP_1', 'NatM_break_2_Mal_GP_1')),
    #               Label != 'NatM_uniform_Mal_GP_1' | any(grep('break', Label)),
    #               Label != 'SR_BH_steep' | any(grep('break', Label))) |>
    # dplyr::mutate(dplyr::across(-Label, ~ sapply(., format, digits = 3, scientific = FALSE) |>
    #                               stringr::str_replace('NA', ''))) |>
    `names<-`(c('Label', 'Base', mods$pretty)) |>
    write.csv(file.path(outdir, paste0(grp_name, '_table.csv')), 
              row.names = FALSE, )
  
}



## grouped plots -----------------------------------------------------------

modeling <- data.frame(dir = c('breakpoint_m', 
                               'no_sex_selex',
                               'sex_selex',
                               'single_m',
                               'tv_wl',
                               'hybrid_f',
                               'nonlinear_q'),
                       pretty = c('Breakpoint M',
                                  'No sex selectivity',
                                  'Sex selectivity all fleets',
                                  'Single M',
                                  'Time-vary weight-length',
                                  'Hybrid F method',
                                  'Nonlinear WCGBTS Q')
)

indices <- data.frame(dir = c('no_indices',
                              'no_smurf',
                              'observer_index',
                              'oceanographic_index',
                              'ORBS',
                              'ORBS_SE',
                              'RREAS',
                              'upweight_wcgbts'),
                      pretty = c('No indices',
                                 '- SMURF index',
                                 '+ WCGOP index',
                                 '+ Oceanographic index',
                                 '+ ORBS index',
                                 '+ ORBS w/added SE',
                                 '+ RREAS index',
                                 'Decrease WCGBTS CV')
)


comp_data <- data.frame(dir = c('M_I_weighting',
                                'no_fishery_len',
                                'unsexed_lengths'),
                        pretty = c('McAllister & Ianelli',
                                   '- Fishery lengths',
                                   '+ Unsexed commercial lengths')
)

sens_names <- bind_rows(modeling,
                        indices,
                        comp_data)

big_sensitivity_output <- SSgetoutput(dirvec = file.path(model_directory,
                                                         c(base_model_name,
                                                           glue::glue("sensitivities/{subdir}", 
                                                                      subdir = sens_names$dir)))) |>
  `names<-`(c('base', sens_names$dir))



# test to make sure they all read correctly:
which(sapply(big_sensitivity_output, length) < 180) # all lengths should be >180

sens_names_ls <- list(modeling = modeling,
                      indices = indices,
                      comp_data = comp_data)

outdir <- 'report/figures/sensitivities'

purrr::imap(sens_names_ls, \(sens_df, grp_name) 
            make_detailed_sensitivites(biglist = big_sensitivity_output, 
                                       mods = sens_df, 
                                       outdir = outdir, 
                                       grp_name = grp_name))



## big plot ----------------------------------------------------------------

current.year <- 2025
CI <- 0.95

sensitivity_output <- SSsummarize(big_sensitivity_output) 

lapply(big_sensitivity_output, function(.)
  .$warnings[grep('gradient', .$warnings)]) # check gradients

dev.quants.SD <- c(
  sensitivity_output$quantsSD[sensitivity_output$quantsSD$Label == "SSB_Initial", 1],
  (sensitivity_output$quantsSD[sensitivity_output$quantsSD$Label == paste0("SSB_", current.year), 1]),
  sensitivity_output$quantsSD[sensitivity_output$quantsSD$Label == paste0("Bratio_", current.year), 1],
  sensitivity_output$quantsSD[sensitivity_output$quantsSD$Label == "Dead_Catch_SPR", 1],
  sensitivity_output$quantsSD[sensitivity_output$quantsSD$Label == "annF_SPR", 1]
)

dev.quants <- rbind(
  sensitivity_output$quants[sensitivity_output$quants$Label == "SSB_Initial", 
                            1:(dim(sensitivity_output$quants)[2] - 2)],
  sensitivity_output$quants[sensitivity_output$quants$Label == paste0("SSB_", current.year), 
                            1:(dim(sensitivity_output$quants)[2] - 2)],
  sensitivity_output$quants[sensitivity_output$quants$Label == paste0("Bratio_", current.year), 
                            1:(dim(sensitivity_output$quants)[2] - 2)],
  sensitivity_output$quants[sensitivity_output$quants$Label == "Dead_Catch_SPR", 
                            1:(dim(sensitivity_output$quants)[2] - 2)],
  sensitivity_output$quants[sensitivity_output$quants$Label == "annF_SPR", 
                            1:(dim(sensitivity_output$quants)[2] - 2)]
) |>
  cbind(baseSD = dev.quants.SD) |>
  dplyr::mutate(Metric = c("SB0", paste0("SSB_", current.year), paste0("Bratio_", current.year), "MSY_SPR", "F_SPR")) |>
  tidyr::pivot_longer(-c(base, Metric, baseSD), names_to = 'Model', values_to = 'Est') |>
  dplyr::mutate(relErr = (Est - base)/base,
                logRelErr = log(Est/base),
                mod_num = rep(1:nrow(sens_names), 5))

metric.labs <- c(
  SB0 = expression(SB[0]),
  SSB_2023 = as.expression(bquote("SB"[.(current.year)])),
  Bratio_2023 = bquote(frac(SB[.(current.year)], SB[0])),
  MSY_SPR = expression(Yield['SPR=0.50']),
  F_SPR = expression(F['SPR=0.50'])
)

CI.quants <- dev.quants |>
  dplyr::filter(Model == unique(dev.quants$Model)[1]) |>
  dplyr::select(base, baseSD, Metric) |>
  dplyr::mutate(CI = qnorm((1-CI)/2, 0, baseSD)/base)

ggplot(dev.quants, aes(x = relErr, y = mod_num, col = Metric, pch = Metric)) +
  geom_vline(xintercept = 0, linetype = 'dotted') +
  geom_point() +
  geom_segment(aes(x = CI, xend = abs(CI), col = Metric,
                   y = nrow(sens_names) + 1.5 + seq(-0.5, 0.5, length.out = length(metric.labs)),
                   yend = nrow(sens_names) + 1.5 + seq(-0.5, 0.5, length.out = length(metric.labs))), 
               data = CI.quants, linewidth = 2, show.legend = FALSE, lineend = 'round') +
  theme_bw() +
  scale_shape_manual(
    values = c(15:18, 12),
    # name = "",
    labels = metric.labs
  ) +
  # scale_color_discrete(labels = metric.labs) +
  scale_y_continuous(breaks = 1:nrow(sens_names), name = '', labels = sens_names$pretty, 
                     limits = c(1, nrow(sens_names) + 2), minor_breaks = NULL) +
  xlab("Relative change") +
  viridis::scale_color_viridis(discrete = TRUE, labels = metric.labs)
ggsave(file.path(outdir, 'sens_summary.png'),  dpi = 300,  
       width = 6, height = 7, units = "in")
