################ Data bridging #####################




### Setup
library(here)
library(r4ss)
library(dplyr)
library(renv)
library(future.apply)

source(here("R","functions","bridging_functions.r")) #load bridging functions


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
discard_amounts <- read.csv(here("data_derived","discards","discards_2025.csv"))|>
  select(!source)




#--------------------------  Length comp data
##  Pacfin length comps
pacfin_lcomps <- read.csv(here("data_derived","PacFIN_compdata_2025","widow_pacfin_lencomp_2025.csv"))
# WCGBTS  comps
nwfsc_lcomps <- read.csv(here(wd,"data_derived","NWFSCCombo","NWFSCCombo_length_comps_data.csv"))|>
  mutate(year = year, 
         month = rep(8.8), 
         fleet = rep(8))

#discard lcomps - think wcgop
discard_lcomps <- read.csv(here("data_derived","discards","discard_length_comps_add-years-only.csv"))|>
  rename(partition = part,input_n = Nsamp)|>
  select(!X) #drop weird rownumber column from excel
  

lcomp_2025 <- rbind(pacfin_lcomps,nwfsc_lcomps,discard_lcomps) #combine into one source

# --------------------------  Age comp data
#pacfin
pacfin_acomps <- read.csv(here("data_derived","PacFIN_compdata_2025","widow_pacfin_agecomp_2025.csv"))

#WCGBTS CAL
nwfsc_acomps <- read.csv(here(wd,"data_derived","NWFSCCombo","NWFSCCombo_conditional_age-at-length.csv"))|>
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
r4ss::run(dir = base_model_dir,exe = "ss3",extras = "-nohess")



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
file.copy(file.path(model_2019,"ss3.exe"),to = file.path(catch_dir,"ss3.exe")) #copt the executable
r4ss::run(dir = catch_dir,exe = "ss3",extras = "-nohess") #run the model  
model_temp <- NULL#Wipe model to be safe


#--------------------  Extend discards -----------------------------------------

discard_dir <- here(main_dir,"add_discards") #dir

model_temp <- SS_read(catch_dir) ##read base model
model_temp$dat$discard_data <- model_temp$dat$discard_data|>
  rbind(discard_amounts|>
          filter(year >= 2019)|>
          mutate(year = if_else(fleet == 5 & year == 2021, year *-1, year)))## append data

###Check the data years
model_temp$dat$discard_data|>
  group_by(fleet)|>
  summarise(end_yr = max(year))


## write model
SS_write(model_temp,dir = discard_dir,overwrite = T) #write the model
file.copy(file.path(model_2019,"ss3.exe"),to = file.path(discard_dir,"ss3.exe")) #copt the executable
r4ss::run(dir = discard_dir,exe = "ss3",extras = "-nohess") #run the model  
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
file.copy(file.path(model_2019,"ss3.exe"),to = file.path(index_dir,"ss3.exe")) #copt the executable
r4ss::run(dir = index_dir,exe = "ss3",extras = "-nohess") #run the model  
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
file.copy(file.path(model_2019,"ss3.exe"),to = file.path(lcomp_dir,"ss3.exe")) #copt the executable
r4ss::run(dir = lcomp_dir,exe = "ss3",extras = "-nohess") #run the model  
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
# SS_write(model_temp,dir = %>% ,overwrite = T) #write the model
file.copy(file.path(model_2019,"ss3.exe"),to = file.path(acomp_dir,"ss3.exe")) #copt the executable
r4ss::run(dir = acomp_dir,exe = "ss3",extras = "-nohess") #run the model  
model_temp <- NULL#Wipe model to be safe





############ Model tuning ##############
# All data hasa been added, so do a ocuple of tuning runs, and apply the 0.5 multiplier
########################################


### Tuning run 1 
new_tunings <- tune_comps(replist = SS_output(acomp_dir),
                          dir = acomp_dir,option = "MI")
#read in the previous run
model_temp <- SS_read(dir = acomp_dir)
model_temp$ctl$Variance_adjustment_list$value <- new_tunings$New_Var_adj

#Write th emodel 
retune_dir <- here(main_dir,"retune_1")
SS_write(inputlist = model_temp,dir = retune_dir,overwrite = TRUE)
file.copy(here(replace_lambdas_with_var_adj_dir,"ss3.exe"),to = retune_dir)
r4ss::run(dir = retune_dir,exe = "ss3",extras = "-nohess")


### Tuning run 2
new_tunings <- tune_comps(replist = SS_output(retune_dir),
                          dir = retune_dir,option = "MI")
#read in the previous run
model_temp <- SS_read(dir = retune_dir)
model_temp$ctl$Variance_adjustment_list$value <- new_tunings$New_Var_adj
#Write themodel 
retune_dir_2 <- here(main_dir,"retune_2")
SS_write(inputlist = model_temp,dir = retune_dir_2,overwrite = T)
file.copy(here(retune_dir,"ss3.exe"),to = retune_dir_2)
r4ss::run(dir = retune_dir_2,exe = "ss3",extras = "-nohess", skipfinished = FALSE)



## Downweight data to to correct for double counted data
model_temp <- SS_read(dir = retune_dir_2)
model_temp$ctl$lambdas <- model_temp$ctl$lambdas|>
  mutate(value= ifelse(fleet %in% 1:5, value *0.5, value))

#Write the model 
reweight <- here(main_dir,"reweight")

SS_write(inputlist = model_temp,dir = reweight,overwrite = T)
file.copy(here(retune_dir,"ss3.exe"),to = reweight)
r4ss::run(dir = reweight,exe = "ss3",extras = "-nohess",skipfinished = F)





#### Summarise and compare models ########

models <- list.files(main_dir,full.names = T)
combined_models_replist <- list()
model_names <-
  c(
    "2019_model",
    "add_catches",
    "add_discards",
    "add_indices",
    "add_lcomps",
    "add_acomps",
    "retune_1",
    "retune_2",
    "reweight"
  )

## Loop through the models, putting together a combined replist and making plots at each go.
for(i in 1:length(models)){
  if(i == 1){
    combined_models_replist[[i]] <- SS_output(model_2019,covar = FALSE)
  } else {
  
  dir <- models[basename(models) == model_names[i]]
  combined_models_replist[[i]] <- SS_output(dir,covar = FALSE)
  #SS_plots(replist = combined_models_replist[[i]] ,dir = dir)
  }
}

names(combined_models_replist) <- model_names


##pLOT COMPARISONS
compare_ss3_mods(replist = combined_models_replist,
                 plot_dir = here(main_dir,"data_bridge_compare_plots"),
                 plot_names = model_names)


