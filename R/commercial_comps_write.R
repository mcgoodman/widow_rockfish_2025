################################################################################
#### Script to append comp data to 2019 data file and test model ########
################################################################################


################################################################################
################# Widow 2025 assessment    ######################################
################# Mico Kinneen         #########################################
################# 03/19/2025 ##################################################
################################################################################


library(pacfintools)
library(r4ss)
library(dplyr)
library(here)

#### 1. Read in the data 
widow_dat_replace_2005_2018_lencomp <- read.csv(file = file.path("data_derived","PacFIN_compdata_2025","Widow_Comm_lcomps_2005_2025.csv"))
widow_dat_replace_2005_2018_agecomp <- read.csv(file = file.path("data_derived","PacFIN_compdata_2025","Widow_Comm_acomps_2005_2025.csv"))

#directory for the base model
base_model_dir <-  file.path("models","2019 base model","Base_45")





### 2. Filter the comp data to years 2018 - 2024 (Other data for QAQCQ)
widow_Comm_lcomps_2018_2024 <- widow_Comm_lcomps_2005_2025|>filter(year>= 2019)
widow_Comm_acomps_2018_2024 <- widow_Comm_acomps_2005_2025|>filter(year>= 2019)




### 2. Create a model with the correct setting in the forecast, data file
#Dont copy the par as we are re-running manually 

update_acomp_dir <- file.path("models", "data_updates", "update_acomp_data")

if (!dir.exists(update_acomp_dir)) {
  
  dir.create(update_acomp_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(base_model_dir, update_acomp_dir)
  
  files_rename <- list.files(update_acomp_dir)[grepl("2019", list.files(update_acomp_dir))]
  file.copy(file.path(base_model_dir,"ss3.exe"),file.path(update_acomp_dir,"ss3.exe"))
  lapply(files_rename, \(x) {
    file.rename(file.path(update_acomp_dir, x), gsub("2019", "2025", file.path(update_acomp_dir, x)))
  })
  
}



# Append acomp data for the model
data_2025 <- SS_readdat(here(update_acomp_dir, "2025widow.dat"))

#Append the acomp data
data_2025$agecomp <- data_2025$agecomp|>
  setNames(colnames(widow_Comm_acomps_2018_2024))|>
  rbind(widow_Comm_acomps_2018_2024)|>
  arrange(fleet,-sex) #keeps things orderely

data_2025$endyr <- 2024
data_2025$Comments[1] <- "#C 2025 Widow Rockfish Update Assessment"
SS_writedat(data_2025, here(update_acomp_dir, "2025widow.dat"), overwrite = TRUE)

# Update forecast.ss
fcast_2025 <- SS_readforecast(here(update_acomp_dir, "forecast.ss"), verbose = FALSE)
fcast_2025$ForeCatch$Year <- fcast_2025$ForeCatch$Year + 6
fcast_2025$Flimitfraction_m$Year <- fcast_2025$Flimitfraction_m$Year + 6
SS_writeforecast(fcast_2025, update_acomp_dir, overwrite = TRUE)

# Update control file
ctl <- readLines(here(update_acomp_dir, "2025widow.ctl"))
ctl <- gsub("2019widow", "2025widow", ctl)
writeLines(ctl, here(update_acomp_dir, "2025widow.ctl"))

# Update starter file
strt <- readLines(here(update_acomp_dir, "starter.ss"))
strt <- gsub("2019widow", "2025widow", strt)
strt <- gsub("1 # 0=use init values in control file; 1=use ss.par",
             "0 # 0=use init values in control file; 1=use ss.par",
             strt)

writeLines(strt, here(update_acomp_dir, "starter.ss"))


# Then open a terminal
rstudioapi::terminalCreate(workingDir = here(update_acomp_dir))





#### Updateing the lencomps

update_lcomp_dir <- file.path("models", "data_updates", "update_lcomp_data")

if (!dir.exists(update_lcomp_dir)) {
  
  dir.create(update_lcomp_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(base_model_dir, update_lcomp_dir)
  
  files_rename <- list.files(update_lcomp_dir)[grepl("2019", list.files(update_lcomp_dir))]
  file.copy(file.path(base_model_dir,"ss3.exe"),file.path(update_lcomp_dir,"ss3.exe"))
  lapply(files_rename, \(x) {
    file.rename(file.path(update_lcomp_dir, x), gsub("2019", "2025", file.path(update_lcomp_dir, x)))
  })
  
}



# Append acomp data for the model
data_2025 <- SS_readdat(here(update_lcomp_dir, "2025widow.dat"))

#Append the acomp data
data_2025$lencomp <- data_2025$lencomp|>
  setNames(colnames(widow_Comm_lcomps_2018_2024))|>
  rbind(widow_Comm_lcomps_2018_2024)|>
  arrange(fleet,-sex) #keeps things orderely

data_2025$endyr <- 2024
data_2025$Comments[1] <- "#C 2025 Widow Rockfish Update Assessment"
SS_writedat(data_2025, here(update_lcomp_dir, "2025widow.dat"), overwrite = TRUE)

# Update forecast.ss
fcast_2025 <- SS_readforecast(here(update_lcomp_dir, "forecast.ss"), verbose = FALSE)
fcast_2025$ForeCatch$Year <- fcast_2025$ForeCatch$Year + 6
fcast_2025$Flimitfraction_m$Year <- fcast_2025$Flimitfraction_m$Year + 6
SS_writeforecast(fcast_2025, update_lcomp_dir, overwrite = TRUE)

# Update control file
ctl <- readLines(here(update_lcomp_dir, "2025widow.ctl"))
ctl <- gsub("2019widow", "2025widow", ctl)
writeLines(ctl, here(update_lcomp_dir, "2025widow.ctl"))

# Update starter file
strt <- readLines(here(update_lcomp_dir, "starter.ss"))
strt <- gsub("2019widow", "2025widow", strt)
strt <- gsub("1 # 0=use init values in control file; 1=use ss.par",
             "0 # 0=use init values in control file; 1=use ss.par",
             strt)

writeLines(strt, here(update_lcomp_dir, "starter.ss"))



### Updating all comp data

update_all_comp_dir <- file.path("models", "data_updates", "update_all_comp_data")

if (!dir.exists(update_all_comp_dir)) {
  
  dir.create(update_all_comp_dir, recursive = TRUE)
  
  r4ss::copy_SS_inputs(base_model_dir, update_all_comp_dir)
  
  files_rename <- list.files(update_all_comp_dir)[grepl("2019", list.files(update_all_comp_dir))]
  file.copy(file.path(base_model_dir,"ss3.exe"),file.path(update_all_comp_dir,"ss3.exe"))
  lapply(files_rename, \(x) {
    file.rename(file.path(update_all_comp_dir, x), gsub("2019", "2025", file.path(update_all_comp_dir, x)))
  })
  
}



# Append acomp data for the model
data_2025 <- SS_readdat(here(update_all_comp_dir, "2025widow.dat"))

#Append the acomp data
data_2025$lencomp <- data_2025$lencomp|>
  setNames(colnames(widow_Comm_lcomps_2018_2024))|>
  rbind(widow_Comm_lcomps_2018_2024)|>
  arrange(fleet,-sex) #keeps things orderely

#Append the acomp data
data_2025$agecomp <- data_2025$agecomp|>
  setNames(colnames(widow_Comm_acomps_2018_2024))|>
  rbind(widow_Comm_acomps_2018_2024)|>
  arrange(fleet,-sex) #keeps things orderely

data_2025$endyr <- 2024
data_2025$Comments[1] <- "#C 2025 Widow Rockfish Update Assessment"
SS_writedat(data_2025, here(update_all_comp_dir, "2025widow.dat"), overwrite = TRUE)

# Update forecast.ss
fcast_2025 <- SS_readforecast(here(update_all_comp_dir, "forecast.ss"), verbose = FALSE)
fcast_2025$ForeCatch$Year <- fcast_2025$ForeCatch$Year + 6
fcast_2025$Flimitfraction_m$Year <- fcast_2025$Flimitfraction_m$Year + 6
SS_writeforecast(fcast_2025, update_all_comp_dir, overwrite = TRUE)

# Update control file
ctl <- readLines(here(update_all_comp_dir, "2025widow.ctl"))
ctl <- gsub("2019widow", "2025widow", ctl)
writeLines(ctl, here(update_all_comp_dir, "2025widow.ctl"))

# Update starter file
strt <- readLines(here(update_all_comp_dir, "starter.ss"))
strt <- gsub("2019widow", "2025widow", strt)
strt <- gsub("1 # 0=use init values in control file; 1=use ss.par",
             "0 # 0=use init values in control file; 1=use ss.par",
             strt)

writeLines(strt, here(update_all_comp_dir, "starter.ss"))





##### 4. Compare the models  ########################################
models_to_compare <- c(base_model_dir,update_acomp_dir,update_lcomp_dir,update_all_comp_dir)

model_out <- SSgetoutput(dirvec = models_to_compare)
summ_out <- SSsummarize(biglist = model_out)

dir.create("figures/pacfin_comp_plots/model_comparrison",recursive = T)

SSplotComparisons(summaryoutput = summ_out,legend_labels = c("Base","update age","update length","update_all"),plotdir = "figures/pacfin_comp_plots/model_comparrison",print = T)
