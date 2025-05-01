################ Data bridging #####################




### Setup
library(here)
library(r4ss)
library(dplyr)
library(renv)
library(future.apply)

# Load bridging functions
source(here("R", "functions", "bridging_functions.r"))
source(here("R", "functions", "combine_hnl_discards.r"))
source(here("R", "functions", "retune_reweight_ss3.R"))

#Directories
main_dir <- here("models","data_bridging","finalised_data_bridging")
dir.create(main_dir)

####### Data load
#-------------------------- catches
catch_2025 <- read.csv(here("data_derived","catches","2025_catches.csv"))
#--------------------------  indices
#NWFSC
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
  

#Juveile survey
juvsurv <- read.csv(here("data_provided", "RREAS", "widow_indices.csv"))|>
  rename(year = YEAR,
         obs = est,
         se_log = logse)|>
  mutate(
    month = rep(7),
    index = rep(6)
  )|>
  select(year,month,index,obs,se_log)

indices_2025 <- rbind(nwfsc,juvsurv)

# -------------------------- discards

# Prefer data from 2025 assessment if available for a given year
discard_amounts <- read.csv(here("data_derived","discards","discards_2025.csv")) |> 
  arrange(fleet, year, source) |> 
  group_by(year, fleet) |> 
  slice_tail() |> 
  arrange(fleet, year) |> 
  select(-source) |> 
  as.data.frame()

#--------------------------  Length comp data
##  Pacfin length comps
pacfin_lcomps <- read.csv(here("data_derived","PacFIN_compdata_2025","widow_pacfin_lencomp_2025.csv"))|>
  filter(!(sex == 0 & fleet ==5)) #drop unsexed hnl comps
# WCGBTS  comps
nwfsc_lcomps <- read.csv(here("data_derived","NWFSCCombo","NWFSCCombo_length_comps_data.csv"))|>
  mutate(year = year, 
         month = rep(8.8), 
         fleet = rep(8))

#discard lcomps - think wcgop
discard_lcomps <- read.csv(here("data_derived", "discards", "discard_length_comps_April_no-midwater.csv")) |>
  #rename(part = part,input_n = Nsamp)|>
  select(-X) #drop weird rownumber column from excel
  

lcomp_2025 <- rbind(pacfin_lcomps,nwfsc_lcomps) #combine into one source

# --------------------------  Age comp data
#pacfin
pacfin_acomps <- read.csv(here("data_derived","PacFIN_compdata_2025","widow_pacfin_agecomp_2025.csv"))|>
  filter(!(sex == 0 & fleet ==5)) #drop unsexed hnl comps

#WCGBTS CAL
nwfsc_acomps <- read.csv(here("data_derived","NWFSCCombo","NWFSCCombo_conditional_age-at-length.csv"))|>
  mutate(year = year, 
         month = rep(8.8), 
         fleet = rep(8))


acomp_2025 <- rbind(pacfin_acomps,nwfsc_acomps)


### -------------------------- Model adjustments 
# Adjustmnets made below are programmed into the function update_ss3_dat() in function/bridging_functions
# They include
# - Extendding the main rec-dev period end year
# - Extending the forecasts years in the forecast file
# - Sdding time varying selectivity for hake seelx pars 1,2,3 (adding paramters, blocks etc)
# - Moving the data weighting into the var adjustmnet section (lambdas are then used to re-tune the model weights,
#                                                              this is to prevent doible counting fish used for marginal age comps) 
# - Extending the end year of the model
# 
# - Updating file names e.g. '2019widow.ctl' --> '2025widow.ctl'
  
##### 2019 model run with new version of SS3
model_2019 <- here("models","data_bridging","bridge_1_ss3_ver_ctl_files","widow_2019_ss_v3_30_23_new_ctl")
ctl <- SS_read(model_2019)$ctl
ss3_exe <- set_ss3_exe(model_2019, version = "v3.30.23")
r4ss::run(dir = model_2019, exe = ss3_exe, extras = "-nohess", skipfinished = FALSE)

#Apply the adjustments to the model which include: updating names, extending forecasts, extending rec-devs, 
#adding time varyin selex, extending data end year


base_model_dir <- here(main_dir,"base_model")

#Apply adjustments
update_ss3_dat(
  new_dir = base_model_dir,
  base_dir = model_2019,
  run_after_write = F,
  assessment_yr = 2025
)

#run the base to check it works
r4ss::run(dir = base_model_dir, exe = ss3_exe, extras = "-nohess", skipfinished = FALSE)



#################################
### Startign to add data ######
#################################
# 1. - catch
# 2. - dicards
# 3. - indices
# 4. - length comps
# 5. - age comps
#################################



#--------------------  Extend catch -----------------------------------------
catch_dir <- here(main_dir,"add_catches") #dir

model_temp <- SS_read(base_model_dir) ##read base model
model_temp$dat$catch <- model_temp$dat$catch|>
  rbind(catch_2025|>
          filter(year >= 2019))## append data

###Check the data years
model_temp$dat$catch|>
  group_by(fleet)|>
  summarise(end_yr = max(year))


## write model
SS_write(model_temp,dir = catch_dir,overwrite = T) #write the model
file.copy(file.path(model_2019, ss3_exe), to = file.path(catch_dir, ss3_exe)) #copy the executable
r4ss::run(dir = catch_dir, exe = ss3_exe, extras = "-nohess", skipfinished = FALSE) #run the model  
model_temp <- NULL#Wipe model to be safe


#--------------------  Extend discards -----------------------------------------

discard_dir <- here(main_dir,"add_discards") #dir

model_temp <- SS_read(catch_dir) ##read base model
model_temp$dat$discard_data  <- discard_amounts|>
  mutate(obs = if_else(obs == 0, 0.001,obs))

###Check the data years
model_temp$dat$discard_data|>
  group_by(fleet)|>
  summarise(end_yr = max(year))

#add the discard lcomps
model_temp$dat$lencomp <- model_temp$dat$lencomp|>
  filter(part != 1)|> #remove old discards
  rbind(discard_lcomps|> #add new discards
          filter(part  == 1)|>
          arrange(fleet))
        
model_temp$dat$lencomp|>
  filter(part == 1)|>
  select(fleet,year)|>
  count(fleet)

## write model
SS_write(model_temp,dir = discard_dir,overwrite = T) #write the model

##Apply model changes that i) remove the HnL discards fleet, ii) add hnl discrd amounts to catch and iii) drop hnl discard comps.
combine_hnl_discards(model_dir = discard_dir,hnl_fleet_id = 5)



file.copy(file.path(model_2019, ss3_exe), to = file.path(discard_dir, ss3_exe)) # copy the executable
r4ss::run(dir = discard_dir, exe = ss3_exe, extras = "-nohess", skipfinished = FALSE) #run the model  
model_temp <- NULL#Wipe model to be safe

#--------------------  Extend indices  -----------------------------------------

index_dir <- here(main_dir,"add_indices") #dir

model_temp <- SS_read(discard_dir) ##read base model (previous model run)
model_temp$dat$CPUE <- model_temp$dat$CPUE|>
  rbind(indices_2025|>
          filter(year >= 2019))## append data

###Check the data years
model_temp$dat$CPUE |>
  group_by(index)|>
  summarise(end_yr = max(year))


## write model
SS_write(model_temp,dir = index_dir,overwrite = T) #write the model
file.copy(file.path(model_2019, ss3_exe), to = file.path(index_dir, ss3_exe)) # copy the executable
r4ss::run(dir = index_dir, exe = ss3_exe, extras = "-nohess", skipfinished = FALSE) #run the model  
model_temp <- NULL#Wipe model to be safe

#--------------------  Extend length comps  -----------------------------------------
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
file.copy(file.path(model_2019, ss3_exe), to = file.path(lcomp_dir, ss3_exe)) # copy the executable
r4ss::run(dir = lcomp_dir, exe = ss3_exe, extras = "-nohess", skipfinished = FALSE) #run the model  
model_temp <- NULL#Wipe model to be safe


#--------------------  Extend Age comps  -----------------------------------------

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
file.copy(file.path(model_2019, ss3_exe), to = file.path(acomp_dir, ss3_exe)) # copy the executable
r4ss::run(dir = acomp_dir, exe = ss3_exe, extras = "-nohess", skipfinished = FALSE) #run the model  
model_temp <- NULL#Wipe model to be safe

SS_plots(SS_output(acomp_dir))

############ Model tuning ##############
# All data has been added, so do a couple of tuning runs, and apply the 0.5 multiplier
########################################

retune_reweight_ss3(base_model_dir = acomp_dir, 
                                output_dir = main_dir, 
                                n_tuning_runs = 2, 
                                tuning_method = "MI", 
                                keep_tuning_runs = TRUE,
                                lambda_weight = 0.5, 
                                marg_comp_fleets = c(1,2,3,4,5))


##Make a copy of the final model
final_dir <- here(main_dir,"data_bridged_model_weighted")
dir.create(final_dir)
copy_SS_inputs(here(main_dir,"add_acomps_reweighted"), final_dir, overwrite = TRUE)

