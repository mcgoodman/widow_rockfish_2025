
# Data bridging
# Author: Mico Kineen

### Setup
library("here")
library("r4ss")
library("dplyr")

if (!exists("skip_finished")) skip_finished <- FALSE

# Load bridging functions
source(here("R", "functions", "bridging_functions.r"))
source(here("R", "functions", "combine_hnl_discards.r"))
source(here("R", "functions", "retune_reweight_ss3.R"))

#Directories
main_dir <- here("models", "data_bridging")
dir.create(main_dir)

# Read in data --------------------------------------------

## Data from 2019 for old discard stuff #
dat_2019 <- r4ss::SS_read(here("models","2019 base model","Base_45_new"))

## Catches ------------------------------------------------

catch_2025 <- read.csv(here("data_derived","catches","2025_catches.csv"))

## Indices ------------------------------------------------

## WCGBTS
nwfsc <- read.csv(here("data_provided", "WCGBTS", "delta_lognormal", "index", "est_by_area.csv"))|>
  filter(area == "Coastwide")|>
  select(year,est,se)|>
  rename(obs = est,
         se_log = se)|>
  mutate(
    month = rep(8.8),
    index = rep(8)
  )|>
  select(year,month,index,obs,se_log)
  
## Juvenile survey 
juvsurv <- read.csv(here("data_provided", "RREAS", "widow_indices.csv"))|>
  rename(year = YEAR,
         obs = est,
         se_log = logse)|>
  mutate(
    month = rep(7),
    index = rep(6)
  )|>
  select(year,month,index,obs,se_log) |> 
  # Remove years with incomplete sampling
  filter(!(year %in% c(2001:2003, 2010, 2012)))

indices_2025 <- rbind(nwfsc,juvsurv)

## Discards -----------------------------------------------

# Prefer data from 2025 assessment if available for a given year
discard_amounts <- read.csv(here("data_derived","discards","discards_2025.csv")) |> 
  arrange(fleet, year)

## Length composition -------------------------------------

## Pacfin length comps
pacfin_lcomps <- read.csv(here("data_derived","PacFIN_compdata_2025","widow_pacfin_lencomp_2025.csv"))|>
  filter(!(sex == 0 & fleet ==5)) #drop unsexed hnl comps

## WCGBTS comps
nwfsc_lcomps <- read.csv(here("data_derived","NWFSCCombo","NWFSCCombo_length_comps_data.csv"))|>
  mutate(year = year, 
         month = rep(8.8), 
         fleet = rep(8))

# Discard lcomps - think wcgop
discard_lcomps <- read.csv(here("data_derived", "discards", "discard_length_comps_April_no-midwater.csv"))
  #rename(part = part,input_n = Nsamp)
  
lcomp_2025 <- rbind(pacfin_lcomps,nwfsc_lcomps) #combine into one source

## Age composition ----------------------------------------

#pacfin
pacfin_acomps <- read.csv(here("data_derived","PacFIN_compdata_2025","widow_pacfin_agecomp_2025.csv"))|>
  filter(!(sex == 0 & fleet ==5)) #drop unsexed hnl comps

#WCGBTS CAL
nwfsc_acomps <- read.csv(here("data_derived","NWFSCCombo","NWFSCCombo_conditional_age-at-length.csv"))|>
  mutate(year = year, 
         month = rep(8.8), 
         fleet = rep(8))

acomp_2025 <- rbind(pacfin_acomps,nwfsc_acomps)

# Model adjustments ---------------------------------------

# Adjustments made below are programmed into the function update_ss3_dat() in function/bridging_functions
# They include
# - Extending the main rec-dev period end year
# - Extending the forecasts years in the forecast file
# - Adding time varying selectivity for hake selex pars 1,2,3 (adding parameters, blocks etc)
# - Moving the data weighting into the var adjustment section (lambdas are then used to re-tune the model weights,
#                                                              this is to prevent double counting fish used for marginal age comps) 
# - Extending the end year of the model
# 
# - Updating file names e.g. '2019widow.ctl' --> '2025widow.ctl'
  
##### 2019 model run with new version of SS3
model_2019 <- here("models", "2019 base model", "Base_45_new")
ctl <- SS_read(model_2019)$ctl
ss3_exe <- file.path(model_2019, set_ss3_exe(model_2019, version = "v3.30.23"))
r4ss::run(dir = model_2019, exe = ss3_exe, extras = "-nohess", skipfinished = skip_finished)

#Apply the adjustments to the model which include: updating names, extending forecasts, extending rec-devs, 
#adding time varying selex, extending data end year

base_model_dir <- here(main_dir,"base_model")

#Apply adjustments
update_ss3_dat(
  new_dir = base_model_dir,
  base_dir = model_2019,
  run_after_write = F,
  assessment_yr = 2025
)

#run the base to check it works
r4ss::run(dir = base_model_dir, exe = ss3_exe, extras = "-nohess", skipfinished = skip_finished)

# Extend catch --------------------------------------------

catch_dir <- here(main_dir,"add_catches") #dir

model_temp <- SS_read(base_model_dir)

# Overwrite catch file - catch_2025 includes historic
# catches and adjustments to 1979/1980 catch reconstruction
model_temp$dat$catch <- catch_2025

###Check the data years
catch_endyr <- model_temp$dat$catch |> group_by(fleet) |> 
  summarise(end_yr = max(year)) |> pull(end_yr) 

stopifnot("Catch does not run through 2024" = all(catch_endyr == 2024))

## write model
SS_write(model_temp,dir = catch_dir,overwrite = T) #write the model
r4ss::run(dir = catch_dir, exe = ss3_exe, extras = "-nohess", skipfinished = skip_finished) #run the model  
model_temp <- NULL#Wipe model to be safe

# Extend discard amounts MDT, BT, HnL as in 2019 ----------

discard_amnt_dir <- here(main_dir,"add_discard_amounts_bt_mwt_2025_hnl_2019") #dir

## Combine dicards for HnL from 2019 wit new discards
hnl_disc_2019 <- r4ss::SS_read(model_2019)$dat$discard_data|>
  filter(fleet == 5)

disc_bt_mwt_2025_hnl_2019 <- discard_amounts|>
  filter(fleet != 5)|> # Remove the 2025 hnl discards
  rbind(hnl_disc_2019)|> # add the 2019 hnl discards
  arrange(fleet)

model_temp <- SS_read(catch_dir) ##read base model
model_temp$dat$discard_data  <- disc_bt_mwt_2025_hnl_2019

###Check the data years
model_temp$dat$discard_data|>
  group_by(fleet)|>
  summarise(end_yr = max(year))

## write model
SS_write(model_temp,dir = discard_amnt_dir,overwrite = T) #write the model

##Apply model changes that i) remove the HnL discards fleet, ii) add hnl discrd amounts to catch and iii) drop hnl discard comps.
#combine_hnl_discards(model_dir = discard_amnt_dir,hnl_fleet_id = 5,drop_comps = FALSE)

r4ss::run(dir = discard_amnt_dir, exe = ss3_exe, extras = "-nohess", skipfinished = skip_finished) #run the model  
model_temp <- discard_amnt_dir <- NULL#Wipe model to be safe

# Extend discard amounts MDT, BT, HnL  --------------------

discard_amnt_dir <- here(main_dir,"add_discard_amounts_bt_mwt_hnl_2023_old_comps") #dir

model_temp <- SS_read(catch_dir) ##read base model
model_temp$dat$discard_data  <- discard_amounts

###Check the data years
model_temp$dat$discard_data|>
  group_by(fleet)|>
  summarise(end_yr = max(year))

## write model
SS_write(model_temp,dir = discard_amnt_dir,overwrite = T) #write the model

##Apply model changes that i) remove the HnL discards fleet, ii) add hnl discrd amounts to catch and iii) drop hnl discard comps.
#combine_hnl_discards(model_dir = discard_amnt_dir,hnl_fleet_id = 5,drop_comps = FALSE)

r4ss::run(dir = discard_amnt_dir, exe = ss3_exe, extras = "-nohess", skipfinished = skip_finished) #run the model  
model_temp <- discard_amnt_dir <- NULL#Wipe model to be safe

# Extend discard amounts MDT, BT, HnL + comps  ------------

discard_amnt_dir <- here(main_dir,"add_discard_amounts_bt_mwt_hnl_2023_new_comps") #dir

model_temp <- SS_read(catch_dir) ##read base model
model_temp$dat$discard_data  <- discard_amounts
model_temp$dat$lencomp <- model_temp$dat$lencomp |>
  filter(part != 1) |> #remove old discards
  rbind(discard_lcomps|> #add new discards
          filter(part  == 1)|>
          filter(fleet != 3)|> #drop hake discards, minimal data an dmot modelled in the assessment
          arrange(fleet))

###Check the data years
model_temp$dat$discard_data|>
  group_by(fleet)|>
  summarise(end_yr = max(year))

model_temp$dat$lencomp|>
  filter(part == 1)|>
  group_by(fleet)|>
  summarise(end_yr = max(year))

## write model
SS_write(model_temp,dir = discard_amnt_dir,overwrite = T) #write the model

##Apply model changes that i) remove the HnL discards fleet, ii) add hnl discrd amounts to catch and iii) drop hnl discard comps.
#combine_hnl_discards(model_dir = discard_amnt_dir,hnl_fleet_id = 5,drop_comps = FALSE)

r4ss::run(dir = discard_amnt_dir, exe = ss3_exe, extras = "-nohess", skipfinished = skip_finished) #run the model  
model_temp <- discard_amnt_dir <- NULL#Wipe model to be safe

# Update BT, MWT, add hnl disc to landings ----------------

discard_amnt_dir <- here(main_dir,"add_discard_amounts_bt_mwt_combine_hnl_drop_hnl_lc") #dir

model_temp <- SS_read(catch_dir) ##read base model

# Exclude HnL from discard data
model_temp$dat$discard_data  <- discard_amounts |>
  filter(fleet %in% c(1,2))

HnL_discards <- discard_amounts |> filter(fleet == 5) |> select(-month, -stderr, disc = obs)

## Add the discard amounts to the catch for HnL
model_temp$dat$catch <- 
  model_temp$dat$catch |> 
  left_join(HnL_discards, by = c("year", "fleet")) |> 
  mutate(
    disc = ifelse(is.na(disc), 0, disc), 
    catch = catch + disc
  ) |> 
  select(-disc)

# #add the discard lcomps
model_temp$dat$lencomp <- model_temp$dat$lencomp |>
  filter(part != 1)|> #remove old discards
  rbind(discard_lcomps |> #add new discards
          filter(part  == 1) |>
          filter(fleet != 3) |> #drop hake discards, minimal data and not modeled in the assessment
          arrange(fleet)) |>
  mutate(year = if_else(part == 1 & fleet == 5,abs(year)*-1,year))

model_temp$dat$lencomp|>
  filter(part == 1)|>
  group_by(fleet)|>
  summarise(end_yr = max(year))

model_temp$dat$discard_data|>
  group_by(fleet)|>
  summarise(end_yr = max(year))

###Check the data years
model_temp$dat$discard_data|>
  group_by(fleet)|>
  summarise(end_yr = max(year))

## write model
SS_write(model_temp,dir = discard_amnt_dir,overwrite = T) #write the model

###Check the data years
SS_read(discard_amnt_dir)$dat$discard_data|>
  group_by(fleet)|>
  summarise(end_yr = max(year))

r4ss::run(dir = discard_amnt_dir, exe = ss3_exe, extras = "-nohess", skipfinished = skip_finished) #run the model  
model_temp  <- NULL#Wipe model to be safe

# Extend discard lencomps all  ----------------------------

discard_comp_dir <- here(main_dir,"add_discard_comps_bt_mwt_2023_hnl_removed") #dir

model_temp <- SS_read(discard_amnt_dir) ##read base model

# #add the discard lcomps
model_temp$dat$lencomp <- model_temp$dat$lencomp|>
  filter(part != 1)|> #remove old discards
  rbind(discard_lcomps|> #add new discards
          filter(part  == 1)|>
          filter(fleet != 3)|> #drop hake discards, minimal data an dmot modelled in the assessment
          filter(fleet != 5)|> #drop the hnl lcomps from ythe new
          arrange(fleet))


model_temp$dat$lencomp|>
  filter(part == 1)|>
  group_by(fleet)|>
  summarise(end_yr = max(year))

## write model
SS_write(model_temp,dir = discard_comp_dir,overwrite = T) #write the model

r4ss::run(dir = discard_comp_dir, exe = ss3_exe, extras = "-nohess", skipfinished = skip_finished) #run the model  
model_temp <- NULL#Wipe model to be safe

# Extend indices ------------------------------------------

index_dir <- here(main_dir,"add_indices") #dir

model_temp <- SS_read(discard_comp_dir) ##read base model (previous model run)

model_temp$dat$CPUE <- model_temp$dat$CPUE|>
  filter(!index %in% c(6,8))|>
  rbind(indices_2025)|>
  arrange(index)

###Check the data years
model_temp$dat$CPUE |>
  group_by(index)|>
  summarise(end_yr = max(year))

## write model
SS_write(model_temp,dir = index_dir,overwrite = T) #write the model
r4ss::run(dir = index_dir, exe = ss3_exe, extras = "-nohess", skipfinished = skip_finished) #run the model  
model_temp <- NULL#Wipe model to be safe

# Extend length comps  ------------------------------------

lcomp_dir <- here(main_dir,"add_lcomps") #dir

model_temp <- SS_read(index_dir) ##read base model (previous model run)
model_temp$dat$lencomp <- model_temp$dat$lencomp|>
  rename(partition = part,input_n = Nsamp)|>
  rbind(lcomp_2025|>
          filter(year >= 2019 & year <= 2024))## append data

###Check the data years
model_temp$dat$lencomp |>
  group_by(fleet,partition)|>
  summarise(end_yr = max(year))

## write model
SS_write(model_temp,dir = lcomp_dir,overwrite = T) #write the model
r4ss::run(dir = lcomp_dir, exe = ss3_exe, extras = "-nohess", skipfinished = skip_finished) #run the model  
model_temp <- NULL#Wipe model to be safe

# Extend Age comps  ---------------------------------------

acomp_dir <- here(main_dir,"add_acomps") #dir

model_temp <- SS_read(lcomp_dir) ##read base model (previous model run)

model_temp$dat$agecomp <- model_temp$dat$agecomp|>
  rename(partition = part,input_n = Nsamp)|>
  rbind(acomp_2025|>
          filter(year >= 2019 & year <= 2024))## append data

###Check the data years
model_temp$dat$agecomp |>
  group_by(fleet,partition)|>
  summarise(end_yr = max(year))

## write model
SS_write(model_temp,dir = acomp_dir,overwrite = T) #write the model
r4ss::run(dir = acomp_dir, exe = ss3_exe, extras = "-nohess", skipfinished = skip_finished) #run the model  
model_temp <- NULL#Wipe model to be safe

SS_plots(SS_output(acomp_dir))

# Model tuning --------------------------------------------

# All data has been added, so do a couple of tuning runs, and apply the 0.5 multiplier

retune_reweight_ss3(base_model_dir = acomp_dir, 
                                output_dir = main_dir, 
                                n_tuning_runs = 2, 
                                tuning_method = "MI", 
                                keep_tuning_runs = TRUE,
                                lambda_weight = 0.5, 
                                ss3_exe = ss3_exe,
                                marg_comp_fleets = c(1,2,3,4,5))


##Make a copy of the final model
final_dir <- here(main_dir,"data_bridged_model_weighted")
dir.create(final_dir)
copy_SS_inputs(here(main_dir,"add_acomps_reweighted"), final_dir, overwrite = TRUE)

