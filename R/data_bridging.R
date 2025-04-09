###############################################################################
################ Widow r.fish 2025 assesment ##################################
################# Data bridging analysis ########################################
############## Author: Mico Kinneen/ ##########################################


### Setup 
library(here)
library(r4ss)
library(dplyr)
library(renv)



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
  
  
bridge_2_dir <- here(wd,"models","data_bridging","bridge_2_catch and discard updates")

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
               skipfinished = FALSE)



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
               skipfinished = FALSE)



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
  mutate(year = if_else(obs <= 0, year * -1, year)) #model cant fit a 0, so set year negative in this instance**

disc_l_comps <- read.csv(here(wd,"data_derived","discards","discard_length_comps.csv"))|>
  select(!X)#discard row id


#** This occurs for fleet 5 (HnL) in 2021

#update lencomp data with new discard partition data
lencomp <- SS_read(base_dir)$dat$lencomp #get the base model lencomps
lencomp <- lencomp |> #update discard comps (partition = 1)
  filter(part != 1)|> #drop old discard comps
  rbind(disc_l_comps)|> #add new comps
  arrange(fleet)



#update and run
update_ss3_dat(new_dir = update_discard_dir,
               base_dir = extend_catch_dir, 
               new_dat = list(discards,lencomp),
               datlist_name = list("discard_data","lencomp"),
               assessment_yr = 2019,
               run_after_write = TRUE,
               ss_exe_loc = ss3_exe,
               skipfinished = FALSE)

#Updating comps, so need to re tune
r4ss::SS_tune_comps()

##check the plots 
compare_ss3_mods(dirs = c(base_dir,update_hist_catch_dir,extend_catch_dir,update_discard_dir),
                 plot_dir = here(update_discard_dir,"compare_plots"),
                 plot_names = c("base 45","update hist. catch","+ extend catch","+ update discards"),
                 subplots = c(1,3))


### Model 4 - Extend discards ---------------------------------------------------------------
extend_discards_dir <- here(bridge_2_dir,"extend_discards")

update_ss3_dat(new_dir = extend_discards_dir,
               base_dir = update_discard_dir, 
               new_dat = list(discards,lencomp),
               datlist_name = list("discard_data","lencomp"),
               assessment_yr = 2025,
               run_after_write = TRUE,
               ss_exe_loc = ss3_exe,
               skipfinished = FALSE)


##check the plots 
compare_ss3_mods(dirs = c(base_dir,update_hist_catch_dir,extend_catch_dir,update_discard_dir,extened_discard_dir),
                 plot_dir = here(update_discard_dir,"compare_plots"),
                 plot_names = c("base 45","update hist. catch","+ extend catch","+ update discards","+ extened discards"),
                 subplots = c(1,3))



#----------------------------------------------------------------
# Bridge 3 - Updating indices by fleet
#----------------------------------------------------------------

bridge_3_dir <- here(wd,"models","data_bridging","bridge_3_index_updates")

base_dir <- extend_discards_dir #use the previous bridge as the update









