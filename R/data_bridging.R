###############################################################################
################ Widow r.fish 2025 assesment ##################################
################# Data bridging analysis ########################################
############## Author: Mico Kinneen/ ##########################################


### Setup 
library(here)
library(r4ss)
library(dplyr)
library(renv)
library(future.apply)


wd <- here::here() #set directory


# Bridge 1 - Compare 2019 assessment, 2019 assessment with new ctl, 2019 assessment with new ctl
bridge_1_dir <- here(wd,"models","data_bridging","bridge_1_ss3_ver_ctl_files")
dir.create(bridge_1_dir,recursive = TRUE)


#####   Model 1 - 2019 assessment with ss3 version 3.30.16 and old ctl file ####
widow_2019_ss_v3_30_13 <- here(bridge_1_dir,"widow_2019_ss_v3_30_13")
base_45 <- r4ss::SS_read(here(wd, 'models', '2019 base model', 'Base_45'))
r4ss::SS_write(base_45,dir = widow_2019_ss_v3_30_13)



#archive version of ss3 v 3.30.13 available at  https://tinyurl.com/39anp69v
file.copy(here("mk_scrtach","old_ss3_vers","ss3_v3_30_13.exe"),to = widow_2019_ss_v3_30_13)#copy over executable

#run the model
r4ss::run(dir = widow_2019_ss_v3_30_13,exe = "ss3_v3_30_13.exe",extras = "-nohess")


#####   Model 2 - 2019 assessment with new ctl and  version v3_30_23 #####  
widow_2019_ss_v3_30_23_new_ctl <- here(bridge_1_dir,"widow_2019_ss_v3_30_23_new_ctl")
base_45_new <- r4ss::SS_read(here(wd, 'models', '2019 base model', 'Base_45_new'))#Copy over the inouts
r4ss::SS_write(base_45_new,dir = widow_2019_ss_v3_30_23_new_ctl,overwrite = TRUE)


#Get the current ss3 version from github and stro in model folder
ss3_exe <- set_ss3_exe(dir = widow_2019_ss_v3_30_23_new_ctl,version = "v3.30.23")

#run the model
r4ss::run(dir = widow_2019_ss_v3_30_23_new_ctl,exe = ss3_exe,extras = "-nohess")




#### Compare SSB plots 
bridge_1_plots <- here(bridge_1_dir,"plots")#create a plot dir
dir.create(bridge_1_plots)

bridge_1_reps <- SSgetoutput(dirvec = c(widow_2019_ss_v3_30_13,widow_2019_ss_v3_30_23_new_ctl)) #get report files
bridge_1_sum <- SSsummarize(biglist = bridge_1_reps) #summarise reports

SSplotComparisons( #plot comparrisons
  bridge_1_sum,
  print = TRUE,
  plotdir = bridge_1_plots,
  legendlabels = c("2019 v3.30.13", "2019 v3.30.23 (new ctl)"),
  indexPlotEach = TRUE,
  filenameprefix = "sens_base_adj_"
)


#----------------------------------------------------------------
# Bridge 2 - Updating catch and 
#----------------------------------------------------------------
  
  
bridge_2_dir <- here(wd,"models","data_bridging","bridge_2_catch_and_discard_updates")

base_dir <- here(wd, 'models', '2019 base model', 'Base_45_new') #the base input model


#------------------------- Catch & discard ------------------------------------------------
# Model 1 - Update catch (end year = 2018)  
# Model 2 - Extend catch (end year = 2024)
# Model 3 - Update discards (observed discard + comps) (end year = 2018)  
# Model 4 - Extend discards (observed discard + comps) (end year = 2024)

### Model 1 - Update the historical catch ---------------------------------------------------------------

#Create the directory
update_hist_catch_dir <- here(bridge_2_dir,"updated_historical_catches")
update_hist_catch <- SS_read(base_dir) #read the base data file

catch <- read.csv(here("data_derived","catches","2025_catches.csv")) #read in catches

#Add the data to the model and run
update_ss3_dat(new_dir = update_hist_catch_dir,
               base_dir = base_dir,
               new_dat = catch,
               datlist_name = "catch",
               assessment_yr = 2019,
               run_after_write = TRUE,
               ss_exe_loc = ss3_exe,
               skipfinished = FALSE,
               extras = "-nohess")



#Compare
compare_ss3_mods(
  dirs = c(base_dir, update_hist_catch_dir),
  plot_dir = here(update_hist_catch_dir, "compare_plots"),
  plot_names = c("base_45", "update_hist_catch")
)

##check the plots 
compare_ss3_mods(
  dirs = c(base_dir, update_hist_catch_dir),
  plot_dir = here(extend_catch_dir, "compare_plots"),
  plot_names = c("base_45", "update hist. catch"),
  subplots = c(1, 3)
)



### Model 2 - Extend catch ---------------------------------------------------------------
extend_catch_dir <- here(bridge_2_dir,"extend_catch")


#Update the model and run it
update_ss3_dat(new_dir = extend_catch_dir,
               base_dir = update_hist_catch_dir,
               new_dat = catch,
               datlist_name = "catch",
               assessment_yr = 2025,
               run_after_write = TRUE,
               ss_exe_loc = ss3_exe,
               skipfinished = FALSE,extras = "-nohess")



##check the plots 
compare_ss3_mods(
  dirs = c(base_dir, update_hist_catch_dir, extend_catch_dir),
  plot_dir = here(extend_catch_dir, "compare_plots"),
  plot_names = c("base_45", "update_hist_catch", "+extend_catch"),
  subplots = c(1, 3)
)



### Model 3 - Update discards ---------------------------------------------------------------
update_discard_dir <- here(bridge_2_dir,"update_discards")

#read in the data and edit as required
discards <- read.csv(here(wd,"data_derived","discards","discards_2025_opt2_new_wcgop.csv"))|>
  select(yr,month,fleet,obs,stderr)|>
  arrange(fleet,yr)|>
  rename(year = yr)|> #rename year
  mutate(year = if_else(obs <= 0, abs(year) * -1, year)) #model cant fit a 0, so set year negative in this instance**

disc_l_comps <- read.csv(here(wd,"data_derived","discards","discard_length_comps.csv"))|>
  select(!X)#discard row id


#** This occurs for fleet 5 (HnL) in 2021

#update lencomp data with new discard partition data
lencomp <- SS_read(extend_catch_dir)$dat$lencomp #get the base model lencomps
lencomp <- lencomp |> #update discard comps (partition = 1)
  filter(!(year >= 2005 & part %in% unique(disc_l_comps$part) & fleet %in% unique(disc_l_comps$fleet)))|>  #remove the old discards
  rbind(disc_l_comps)|> #add the new comps
  arrange(fleet)



#update and run
update_ss3_dat(new_dir = update_discard_dir,
               base_dir = extend_catch_dir, 
               new_dat = list(discards,lencomp),
               datlist_name = list("discard_data","lencomp"),
               assessment_yr = 2019,
               run_after_write = TRUE,
               ss_exe_loc = ss3_exe,
               skipfinished = FALSE,extras = "-nohess")

##check the plots 
compare_ss3_mods(dirs = c(base_dir,update_hist_catch_dir,update_discard_dir),
                 plot_dir = here(update_discard_dir,"compare_plots"),
                 plot_names = c("base 45","update hist. catch","+ update discards"),
                 subplots = c(1,3))


### Model 4 - Extend discards ---------------------------------------------------------------
extend_discard_dir <- here(bridge_2_dir,"extend_discards")

update_ss3_dat(new_dir = extend_discard_dir,
               base_dir = update_discard_dir, 
               new_dat = list(discards,lencomp),
               datlist_name = list("discard_data","lencomp"),
               assessment_yr = 2025,
               run_after_write = TRUE,
               ss_exe_loc = ss3_exe,
               skipfinished = FALSE,extras = "-nohess")


##check the plots 
compare_ss3_mods(dirs = c(base_dir,update_hist_catch_dir,extend_catch_dir,update_discard_dir,extend_discard_dir),
                 plot_dir = here(extend_discard_dir,"compare_plots"),
                 plot_names = c("base 45","update hist. catch","+ extend catch","+ update discards","+ extened discards"),
                 subplots = c(1,3))





#### mAKE COMAPRES FOR 2019 MODELS
compare_ss3_mods(dirs = c(widow_2019_ss_v3_30_23_new_ctl,
                          update_hist_catch_dir,
                          update_discard_dir),
                 plot_dir = here(bridge_2_dir,"compare_plots2019"),
                 plot_names = c("base 45",
                                " + update hist. catch",
                                " + update discards"),
                 subplots = c(1,3))








#### Make comapre for 2025 models
compare_ss3_mods(dirs = c(widow_2019_ss_v3_30_23_new_ctl,
                          extend_catch_dir,
                          extend_discard_dir),
                 plot_dir = here(bridge_2_dir,"compare_plots2025"),
                 plot_names = c("base 45",
                                " + extend catch",
                                " + extend discards"),
                 subplots = c(1,3))




#----------------------------------------------------------------
# Bridge 3 - Updating indices by fleet
#----------------------------------------------------------------

bridge_3_dir <- here(wd,"models","data_bridging","bridge_3_index_updates")

bridge_3_base_dir <- base_dir #use the previous bridge as the update



## Read in the index data and adjust the months
nwfsc <- read.csv(here("data_provided", "WCGBTS", "delta_lognormal", "index", "est_by_area.csv")) %>% filter(area == "Coastwide")
nwfsc_dat <- data.frame(year = nwfsc$year, 
                         month = rep(8.8), 
                         index = rep(8), 
                         obs = nwfsc$est, 
                           se_log = nwfsc$se)

nwfsc_lcomps <- read.csv(here(wd,"data_derived","NWFSCCombo","NWFSCCombo_length_comps_data.csv"))|>
  mutate(year = year, 
             month = rep(8.8), 
             fleet = rep(8))
             
nwfsc_acomps <- read.csv(here(wd,"data_derived","NWFSCCombo","NWFSCCombo_conditional_age-at-length.csv"))|>
  mutate(year = year, 
             month = rep(8.8), 
             fleet = rep(8))

# survey 2 update
juvsurv <- read.csv(here("data_provided", "RREAS", "widow_indices.csv"))
juvsurv_dat <- data.frame(year = juvsurv$YEAR, 
                          month = rep(7), 
                          index = rep(6),
                          obs = juvsurv$est, 
                          se_log = juvsurv$logse)






####### Model 1 - Update NWFSC survey + comps ####### 

update_nwfsc_dir <- here::here(bridge_3_dir,"update_nwfsc")

## Add the nwfsc index
update_nwfsc_index <- r4ss::SS_read(bridge_3_base_dir)$dat$CPUE|>
  mutate(year = if_else(index == 8,abs(year) * -1, year))|> #remove old comps
  rbind(nwfsc_dat)|>
  arrange(index)

## Add the nwfsc comps to the length comps
update_nwfsc_lcomps <- r4ss::SS_read(bridge_3_base_dir)$dat$lencomp|>
  rename(partition = part,input_n = Nsamp)|>
  mutate(year = if_else(fleet == 8,abs(year) * -1, year))|> #remove old comps
  rbind(nwfsc_lcomps)|> #add new comps
  arrange(fleet)


#add nwfsc a comps to the age comps
## Add the nwfsc comps to the length comps
update_nwfsc_acomps <- r4ss::SS_read(bridge_3_base_dir)$dat$agecomp|>
  rename(partition = part,input_n = Nsamp)|>
  mutate(year = if_else(fleet == 8,abs(year) * -1, year))|> #remove old comps
  rbind(nwfsc_acomps)|> #add new comps
  arrange(fleet)


## Create and run model
update_ss3_dat(new_dir = update_nwfsc_dir,
               base_dir = update_hist_catch_dir, 
               new_dat = list(update_nwfsc_index,update_nwfsc_lcomps,update_nwfsc_acomps),
               datlist_name = list("CPUE","lencomp","agecomp"),
               assessment_yr = 2019,
               run_after_write = TRUE,
               ss_exe_loc = ss3_exe,
               skipfinished = FALSE,
               extras = "-nohess")

#Plots
compare_ss3_mods(dirs = c(base_dir,update_hist_catch_dir,update_nwfsc_dir),
                 plot_dir = here(update_nwfsc_dir,"compare_plots"),
                 plot_names = c("base 45","+ update hist. catch","+ update NWFSC"),
                 subplots = c(1,3))



## Model 2 - Extend NWFSC index

#Create dir
extend_nwfsc_dir <- here(bridge_3_dir,"extend_nwfsc")


update_ss3_dat(new_dir = extend_nwfsc_dir,
               base_dir = bridge_3_base_dir, 
               new_dat = list(update_nwfsc_index,update_nwfsc_lcomps,update_nwfsc_acomps),
               datlist_name = list("CPUE","lencomps","agecomps"),
               assessment_yr = 2025,
               run_after_write = TRUE,
               ss_exe_loc = ss3_exe,
               skipfinished = FALSE,
               extras = "-nohess")

#Plots
compare_ss3_mods(dirs = c(base_dir,extend_catch_dir,extend_nwfsc_dir),
                 plot_dir = here(extend_nwfsc_dir,"compare_plots"),
                 plot_names = c("base 45","+ extend catch","+ extend NWFSC"),
                 subplots = c(1,3))




#Plots
compare_ss3_mods(dirs = c(base_dir,extend_catch_dir,extend_nwfsc_dir),
                 plot_dir = here(extend_nwfsc_dir,"compare_plots_new_weigth"),
                 plot_names = c("base 45","+ extend catch","+ extend NWFSC"),
                 subplots = c(1,3))


### Model 3 - Update juvenile survey index

update_juvenile_index_dir <- here(bridge_3_dir,"update_juvenile_index")

#update the data
update_juv_index <- r4ss::SS_read(bridge_3_base_dir)$dat$CPUE|>
  mutate(year = if_else(index == 6,abs(year) * -1, year))|> #remove old comps
  rbind(juvsurv_dat)|>
  arrange(index)

update_ss3_dat(new_dir = update_juvenile_index_dir,
               base_dir = bridge_3_base_dir, 
               new_dat = list(update_juv_index),
               datlist_name = list("CPUE"),
               assessment_yr = 2019,
               run_after_write = TRUE,
               ss_exe_loc = ss3_exe,
               skipfinished = FALSE,
               extras = "-nohess")

compare_ss3_mods(dirs = c(base_dir,update_hist_catch_dir,update_nwfsc_dir,update_juvenile_index_dir),
                 plot_dir = here(update_juvenile_index_dir,"compare_plots"),
                 plot_names = c("base 45","+ extened catch","+ update NWFSC","+ extend juv"),
                 subplots = c(1,3))


### Model 4 - Extend juvenile survey index

extend_juvenile_index_dir <- here(bridge_3_dir,"extend_juvenile_index")



update_ss3_dat(new_dir = extend_juvenile_index_dir,
               base_dir = bridge_3_base_dir, 
               new_dat = list(update_juv_index),
               datlist_name = list("CPUE"),
               assessment_yr = 2025,
               run_after_write = TRUE,
               ss_exe_loc = ss3_exe,
               skipfinished = FALSE)

compare_ss3_mods(dirs = c(base_dir,extend_catch_dir,extend_nwfsc_dir,extend_juvenile_index_dir),
                 plot_dir = here(extend_juvenile_index_dir,"compare_plots"),
                 plot_names = c("base 45","+ extened catch","+ extend NWFSC","+ extend juv"),
                 subplots = c(1,3))

#### mAKE COMAPRES FOR 2019 MODELS
compare_ss3_mods(dirs = c(update_discard_dir,
                          update_nwfsc_dir,
                          update_juvenile_index_dir),
                 plot_dir = here(bridge_3_dir,"compare_plots2019"),
                 plot_names = c("Updated catch + discards",
                                " + WCGBTS",
                                " + Juv."),
                 subplots = c(1,3))








#### Make comapre for 2025 models
compare_ss3_mods(dirs = c(extend_discard_dir,
                          extend_nwfsc_dir,
                          extend_juvenile_index_dir),
                 plot_dir = here(bridge_3_dir,"compare_plots2025"),
                 plot_names = c("Extended catch + discards",
                                " + WCGBTS",
                                " + Juv."),
                 subplots = c(1,3))





#----------------------------------------------------------------
# Bridge 4 - Updating lencomps by fleet
#----------------------------------------------------------------
bridge_4_dir <- here(wd,"models","data_bridging","bridge_4_lcomp_updates")

### Model 1 --- Updating lencomps by fleet
widow_dat_replace_2005_2018_lencomp <- read.csv(file = file.path("data_derived","PacFIN_compdata_2025","widow_dat_replace_2005_2018_lencomp.csv"))


#Directories
base_dir <- extend_juvenile_index_dir
base_45 <- r4ss::SS_read(dir = base_dir)


add_L_dir <- here(bridge_4_dir,"comm_lencomps")
dir.create(add_L_dir,recursive = TRUE)


data_types <- c("lencomp")
fleets <- sort(unique(widow_dat_replace_2005_2018_lencomp$fleet))  # Ensure sorted order for lencomp build-up

for (data_type in data_types) {
  
  current_base_dir <- base_dir  # Start with original base_dir
  
  
  for (i in seq_along(fleets)) {
    fleet_num <- c(as.numeric(fleets[1:i]))
    fleet_name <- paste0("commercial_", data_type, "_fleet_", paste(fleet_num, collapse = "_"))

    
    # Choose parent directory
    parent_dir <- if (data_type == "lencomp") add_L_dir else add_A_dir
    
    # Construct fleet directory and create if needed
    update_fleet_dir <- here::here(parent_dir, fleet_name)
    if (!dir.exists(update_fleet_dir)) {
      dir.create(update_fleet_dir, recursive = TRUE)
    }
    
    # Subset and update data
    if (data_type == "lencomp") {
      subset_data <- widow_dat_replace_2005_2018_lencomp %>% 
        filter(fleet %in% fleet_num & year >= 2005)
      
      updated_data <- base_45$dat$lencomp %>%
        rename(partition = part, input_n = Nsamp) %>%
        filter(!(fleet %in% fleet_num & year >= 2005))|>
       # mutate(year = if_else(fleet %in% as.character(fleet_num), abs(year) * -1, year)) %>%
        rbind(subset_data) %>%
        arrange(fleet)
      
    } else if (data_type == "agecomp") {
      subset_data <- widow_dat_replace_2005_2018_agecomp %>%
        filter(fleet %in% fleet_num & year >= 2005)
      
      updated_data <- base_45$dat$agecomp %>%
        rename(partition = part, input_n = Nsamp) %>%
        mutate(year = if_else(fleet %in% as.character(fleet_num), abs(year) * -1, year)) %>%
        rbind(subset_data) %>%
        arrange(fleet)
    }
    
    # Run model
    update_ss3_dat(
      new_dir = update_fleet_dir,
      base_dir = current_base_dir,
      new_dat = list(updated_data),
      datlist_name = list(data_type),
      assessment_yr = 2019,
      run_after_write = FALSE,
      ss_exe_loc = ss3_exe,
      skipfinished = FALSE,
      extras = "-nohess"
    )
    
    message("Finished: ", data_type, " — ", fleet_name)
    
    current_base_dir <- update_fleet_dir
  }
}


##### Run model sin paralell
# Set up parallel backend
plan(multisession, workers = length(mods))

# Define the wrapper function to run SS3 and then post-process
run_and_post <- function(dir) {
  r4ss::run(
    dir = dir,
    exe = "ss3",
    show_in_console = TRUE,
    extras = "-nohess"
    # ... other arguments if needed
  )
  #Now update the weight snad re-run th emdoel in a new dir
  update_model_weights(model_dir = dir,new_weight_dir = paste0(dir,"_re_wght"))
}

# Run them in parallel
results <- future_lapply(mods, run_and_post)


## Now do the plots

compare_ss3_mods(
  dirs = c(base_dir,mods[c(2:6,11)]),
  plot_dir = here(add_L_dir,"plots") ,
  plot_names = c(
    "Base_45",
    "+ BT",
    "+ MWT",
    "+ HKE",
    "+ NET",
    "+ HnL", 
    "+ re-weighted"
  ),
  subplots = c(1,3)
)




### Model 2 --- Extending lencomps by fleet
widow_dat_2025_lencomp <- read.csv(file = file.path("data_derived","PacFIN_compdata_2025","widow_pacfin_lencomp_2025.csv"))


#Directories
base_dir <- extend_juvenile_index_dir
base_catch_disc_ind <- r4ss::SS_read(dir = base_dir)


add_L_dir <- here(bridge_4_dir,"comm_lencomps_extend")
dir.create(add_L_dir,recursive = TRUE)


data_types <- c("lencomp")
fleets <- sort(unique(widow_dat_2025_lencomp$fleet))  # Ensure sorted order for lencomp build-up

for (data_type in data_types) {
  
  current_base_dir <- base_dir  # Start with original base_dir
  
  
  for (i in seq_along(fleets)) {
    fleet_num <- c(as.numeric(fleets[1:i]))
    fleet_name <- paste0("commercial_", data_type, "_fleet_", paste(fleet_num, collapse = "_"))
    
    
    # Choose parent directory
    parent_dir <- if (data_type == "lencomp") add_L_dir else add_A_dir
    
    # Construct fleet directory and create if needed
    update_fleet_dir <- here::here(parent_dir, fleet_name)
    if (!dir.exists(update_fleet_dir)) {
      dir.create(update_fleet_dir, recursive = TRUE)
    }
    
    # Subset and update data
    if (data_type == "lencomp") {
      subset_data <- widow_dat_2025_lencomp %>% 
        filter(fleet %in% fleet_num & year >= 2018)
      
      updated_data <- base_catch_disc_ind$dat$lencomp %>%
        rename(partition = part, input_n = Nsamp) %>%
        filter(!(fleet %in% fleet_num & year >= 2018))|>
        # mutate(year = if_else(fleet %in% as.character(fleet_num), abs(year) * -1, year)) %>%
        rbind(subset_data) %>%
        arrange(fleet)
      
    } else if (data_type == "agecomp") {
      subset_data <- widow_dat_2005_lencomp %>%
        filter(fleet %in% fleet_num & year >= 2018)
      
      updated_data <- base_catch_disc_ind$dat$agecomp %>%
        rename(partition = part, input_n = Nsamp) %>%
        mutate(year = if_else(fleet %in% as.character(fleet_num), abs(year) * -1, year)) %>%
        rbind(subset_data) %>%
        arrange(fleet)
    }
    
    # Run model
    update_ss3_dat(
      new_dir = update_fleet_dir,
      base_dir = current_base_dir,
      new_dat = list(updated_data),
      datlist_name = list(data_type),
      assessment_yr = 2025,
      run_after_write = FALSE,
      ss_exe_loc = ss3_exe,
      skipfinished = FALSE,
      extras = "-nohess"
    )
    
    message("Finished: ", data_type, " — ", fleet_name)
    
    #current_base_dir <- update_fleet_dir
  }
}


##### Run model sin paralell
mods <- list.dirs(add_L_dir)[-1] #list of the models


# Set up parallel backend
plan(multisession, workers = length(mods))

# Define the wrapper function to run SS3 and then post-process
run_and_post <- function(dir) {
  r4ss::run(
    dir = dir,
    exe = "ss3",
    show_in_console = TRUE,
    extras = "-nohess"
    # ... other arguments if needed
  )
  #Now update the weight snad re-run th emdoel in a new dir
  update_model_weights(model_dir = dir,new_weight_dir = paste0(dir,"_re_wght"))
}

# Run them in parallel
results <- future_lapply(mods, run_and_post)


## Now do the plots

compare_ss3_mods(
  dirs = c(base_dir,mods[c(2:6,11)]),
  plot_dir = here(add_L_dir,"plots") ,
  plot_names = c(
    "Catch_index_discards",
    "+ extend BT lcomp.",
    "+ extend MWT lcomp.",
    "+ extend HKE lcomp.",
    "+ extend NET lcomp.",
    "+ extend HnL lcomp.", 
    "+ re-weighted"
  ),
  subplots = c(1,3)
)


##### Bridge 5 - Age comps
bridge_5_dir <- here(wd,"models","data_bridging","bridge_5_acomp_updates")

widow_dat_replace_2005_2018_agecomp<- read.csv(file = file.path("data_derived","PacFIN_compdata_2025","widow_dat_replace_2005_2018_agecomp.csv"))


#Directories
base_dir <- here("models","data_bridging","bridge_4_lcomp_updates","comm_lencomps","commercial_lencomp_fleet_1_2_3_4_5_re_wght") 
base_45 <- r4ss::SS_read(dir = base_dir)

add_A_dir <- here(bridge_5_dir,"comm_agecomps")
dir.create(add_A_dir,recursive = TRUE)


data_types <- c("agecomp")
fleets <- sort(unique(widow_dat_replace_2005_2018_agecomp$fleet))  # Ensure sorted order for lencomp build-up
fleets <- fleets[fleets >= 1]
for (data_type in data_types) {
  
  current_base_dir <- base_dir  # Start with original base_dir
  
  
  for (i in seq_along(fleets)) {
    fleet_num <- c(as.numeric(fleets[1:i]))
    fleet_name <- paste0("commercial_", data_type, "_fleet_", paste(fleet_num, collapse = "_"))
    
    
    # Choose parent directory
    parent_dir <- if (data_type == "lencomp") add_L_dir else add_A_dir
    
    # Construct fleet directory and create if needed
    update_fleet_dir <- here::here(parent_dir, fleet_name)
    if (!dir.exists(update_fleet_dir)) {
      dir.create(update_fleet_dir, recursive = TRUE)
    }
    
    # Subset and update data
    if (data_type == "lencomp") {
      subset_data <- widow_dat_replace_2005_2018_lencomp %>% 
        filter(fleet %in% fleet_num & year >= 2005)
      
      updated_data <- base_45$dat$lencomp %>%
        rename(partition = part, input_n = Nsamp) %>%
        filter(!(fleet %in% fleet_num & year >= 2005))|>
        # mutate(year = if_else(fleet %in% as.character(fleet_num), abs(year) * -1, year)) %>%
        rbind(subset_data) %>%
        arrange(fleet)
      
    } else if (data_type == "agecomp") {
      subset_data <- widow_dat_replace_2005_2018_agecomp %>%
        filter(fleet %in% fleet_num & year >= 2005)
      
      updated_data <- base_45$dat$agecomp %>%
        rename(partition = part, input_n = Nsamp) %>%
        filter(!(fleet %in% fleet_num & year >= 2005))|>
        # mutate(year = if_else(fleet %in% as.character(fleet_num), abs(year) * -1, year)) %>%
        rbind(subset_data) %>%
        arrange(fleet)
    }
    
    # Run model
    update_ss3_dat(
      new_dir = update_fleet_dir,
      base_dir = current_base_dir,
      new_dat = list(updated_data),
      datlist_name = list(data_type),
      assessment_yr = 2019,
      run_after_write = FALSE,
      ss_exe_loc = ss3_exe,
      skipfinished = FALSE,
      extras = "-nohess"
    )
    
    message("Finished: ", data_type, " — ", fleet_name)
    
    current_base_dir <- update_fleet_dir
  }
}


##### Run model sin paralell
# Set up parallel backend
mods <- list.dirs(add_A_dir)[-1] #list of the models

plan(multisession, workers = length(mods))

# Define the wrapper function to run SS3 and then post-process
run_and_post <- function(dir) {
  r4ss::run(
    dir = dir,
    exe = "ss3",
    show_in_console = TRUE,
    extras = "-nohess"
    # ... other arguments if needed
  )
  #Now update the weight snad re-run th emdoel in a new dir
  #update_model_weights(model_dir = dir,new_weight_dir = paste0(dir,"_re_wght"))
}


                     # Run them in parallel
results <- future_lapply(mods, run_and_post)

update_model_weights(model_dir = mods[],new_weight_dir = paste0(dir,"_re_wght"))
                     


## Now do the plots

compare_ss3_mods(
  dirs = c(base_dir,mods[c(2:6,11)]),
  plot_dir = here(add_L_dir,"plots") ,
  plot_names = c(
    "Base_45",
    "+ BT agecomp.",
    "+ MWT agecomp.",
    "+ HKE agecomp.",
    "+ NET agecomp.",
    "+ HnL agecomp.", 
    "+ re-weighted  agecomp."
  ),
  subplots = c(1,3)
)









##### Model 4 - Extened acomps
widow_dat_2025_agecomp <- read.csv(file = file.path("data_derived","PacFIN_compdata_2025","widow_pacfin_agecomp_2025.csv"))


#Directories
base_dir <- here("models","data_bridging","bridge_4_lcomp_updates","comm_lencomps","commercial_lencomp_fleet_1_2_3_4_5_re_wght") 
base_catch_disc_ind <- r4ss::SS_read(dir = base_dir)


add_A_dir <- here(bridge_5_dir,"comm_agecomps_extend")
dir.create(add_L_dir,recursive = TRUE)


data_types <- c("agecomp")
fleets <- sort(unique(widow_dat_2025_agecomp$fleet))  # Ensure sorted order for agecomp build-up

for (data_type in data_types) {
  
  current_base_dir <- base_dir  # Start with original base_dir
  
  
  for (i in seq_along(fleets)) {
    fleet_num <- c(as.numeric(fleets[1:i]))
    fleet_name <- paste0("commercial_", data_type, "_fleet_", paste(fleet_num, collapse = "_"))
    
    
    # Choose parent directory
    parent_dir <- if (data_type == "agecomp") add_L_dir else add_A_dir
    
    # Construct fleet directory and create if needed
    update_fleet_dir <- here::here(parent_dir, fleet_name)
    if (!dir.exists(update_fleet_dir)) {
      dir.create(update_fleet_dir, recursive = TRUE)
    }
    
    # Subset and update data
    if (data_type == "lencomp") {
      subset_data <- widow_dat_2025_lencomp %>% 
        filter(fleet %in% fleet_num & year >= 2018)
      
      updated_data <- base_catch_disc_ind$dat$lencomp %>%
        rename(partition = part, input_n = Nsamp) %>%
        filter(!(fleet %in% fleet_num & year >= 2018))|>
        # mutate(year = if_else(fleet %in% as.character(fleet_num), abs(year) * -1, year)) %>%
        rbind(subset_data) %>%
        arrange(fleet)
      
    } else if (data_type == "agecomp") {
      subset_data <- widow_dat_2005_agecomp %>%
        filter(fleet %in% fleet_num & year >= 2018)
      
      updated_data <- base_catch_disc_ind$dat$agecomp %>%
        rename(partition = part, input_n = Nsamp) %>%
        mutate(year = if_else(fleet %in% fleet_num, abs(year) * -1, year)) %>%
        rbind(subset_data) %>%
        arrange(fleet)
    }
    
    # Run model
    update_ss3_dat(
      new_dir = update_fleet_dir,
      base_dir = current_base_dir,
      new_dat = list(updated_data),
      datlist_name = list(data_type),
      assessment_yr = 2025,
      run_after_write = FALSE,
      ss_exe_loc = ss3_exe,
      skipfinished = FALSE,
      extras = "-nohess"
    )
    
    message("Finished: ", data_type, " — ", fleet_name)
    
    #current_base_dir <- update_fleet_dir
  }
}


##### Run model sin paralell
mods <- list.dirs(add_A_dir)[-1] #list of the models


# Set up parallel backend
plan(multisession, workers = length(mods))

# Define the wrapper function to run SS3 and then post-process
run_and_post <- function(dir) {
  r4ss::run(
    dir = dir,
    exe = "ss3",
    show_in_console = TRUE,
    extras = "-nohess"
    # ... other arguments if needed
  )
  #Now update the weight snad re-run th emdoel in a new dir
  update_model_weights(model_dir = dir,new_weight_dir = paste0(dir,"_re_wght"))
}

# Run them in parallel
results <- future_lapply(mods, run_and_post)


## Now do the plots

compare_ss3_mods(
  dirs = c(base_dir,mods[c(1:5)]),
  plot_dir = here(add_A_dir,"plots") ,
  plot_names = c(
    "Catch_index_discards",
    "+ extend BT acomp.",
    "+ extend MWT acomp.",
    "+ extend HKE acomp.",
    "+ extend NET acomp.",
    "+ extend HnL acomp.", 
    "+ re-weighted"
  ),
  subplots = c(1,3)
)





######### Bridge 5 ------ aDD EACH BRIDGE TOGETHER, THEN RE-WEIGHT AND RUN 


