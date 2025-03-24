################################################################################
#### Script to append comp data to 2019 data file and test model ###############
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

#fn tto set up the ss3 exe (Albi)
set_ss3_exe <- function(dir, ...) {
  
  # Get and set filename for SS3 exe
  ss3_exe <- c("ss", "ss3")
  ss3_check <- vapply(ss3_exe, \(x) file.exists(file.path(dir, paste0(x, ".exe"))), logical(1))
  if (!any(ss3_check)) r4ss::get_ss3_exe(dir, ...)
  ss3_exe <- ss3_exe[which(vapply(ss3_exe, \(x) file.exists(file.path(dir, paste0(x, ".exe"))), logical(1)))]
  return(ss3_exe)
  
}



#' Create a Copy of an SS3 Model
#'
#' This function creates a copy of an existing SS3 model, including necessary input files. 
#' If the destination directory does not exist, it is created. If `overwrite = TRUE`, existing 
#' files in the destination are removed before copying.
#'
#' @param new_model_path Character. Path to the new model directory where files will be copied.
#' @param base_model_path Character. Path to the base model directory from which files will be copied.
#' @param overwrite Logical. If `TRUE`, existing files in `new_model_path` will be removed before copying. Default is `FALSE`.
#'
#' @return This function does not return a value. It creates a new model directory with copied files.
#' @export
#'
#' @examples
#' \dontrun{
#' create_copy_model("path/to/new_model", "path/to/base_model", overwrite = TRUE)
#' }
create_copy_model <- function(new_model_path, base_model_path, overwrite = FALSE) {
  
  # Check if the new model directory exists
  if (!dir.exists(new_model_path)) {
    dir.create(new_model_path, recursive = TRUE)
    
    r4ss::copy_SS_inputs(base_model_path, new_model_path, overwrite = overwrite)
    
    files_rename <- list.files(new_model_path)[grepl("2019", list.files(new_model_path))]
    file.copy(file.path(base_model_path, "ss3.exe"), file.path(new_model_path, "ss3.exe"), overwrite = overwrite)
    
  } else {
    if (overwrite) {
      lapply(list.files(new_model_path, full.names = TRUE), file.remove)
      r4ss::copy_SS_inputs(base_model_path, new_model_path, overwrite = overwrite)
      files_rename <- list.files(new_model_path)[grepl("2019", list.files(new_model_path))]
      file.copy(file.path(base_model_path, "ss3.exe"), file.path(new_model_path, "ss3.exe"), overwrite = overwrite)
    }
  }
}


#### 1. Read in the data 
widow_dat_replace_2005_2018_lencomp <- read.csv(file = file.path("data_derived","PacFIN_compdata_2025","widow_dat_replace_2005_2018_lencomp.csv"))
widow_dat_replace_2005_2018_agecomp <- read.csv(file = file.path("data_derived","PacFIN_compdata_2025","widow_dat_replace_2005_2018_agecomp.csv"))


### 2. 

#directory for the base model
base_model_dir <-  file.path("models","2019 base model","Base_45_new")

start <- r4ss::SS_readstarter(file.path(base_model_dir,"starter.ss"))
start$init_values_src <- 0 #change to 0 so model uses initial values#update the starter to run from initial values





base_model_test <- file.path("models", "data_updates","pacfin_comp_compare_2019", "Base_45_new")

create_copy_model(new_model_path = base_model_test,base_model_path = base_model_dir,overwrite = T)
ss3_exe <- set_ss3_exe(base_model_test, version = "v3.30.16")
r4ss::SS_writestarter(start,base_model_test,overwrite = T)


### Updating age comps
update_acomp_dir <- file.path("models", "data_updates","pacfin_comp_compare_2019", "update_acomp_data")
create_copy_model(update_acomp_dir,base_model_test,overwrite = T)
# Append acomp data for the model
data_2019 <- SS_readdat(here(update_acomp_dir, "2019widow.dat"))
data_2019$agecomp <- widow_dat_replace_2005_2018_agecomp #Append the acomp data
SS_writedat(data_2019,here(update_acomp_dir, "2019widow.dat"),overwrite = T) #new comp

r4ss::SS_writestarter(start,update_acomp_dir,overwrite = T) #init values tarter


#### Updating  the lencomps
update_lcomp_dir <- file.path("models", "data_updates","pacfin_comp_compare_2019", "update_lcomp_data")
create_copy_model(update_lcomp_dir,base_model_test,overwrite = T)

# Append acomp data for the model
data_2019 <- SS_readdat(here(update_lcomp_dir, "2019widow.dat"))
data_2019$lencomp <- widow_dat_replace_2005_2018_lencomp #Append the acomp data

SS_writedat(data_2019,here(update_lcomp_dir, "2019widow.dat"),overwrite = T)
r4ss::SS_writestarter(start,update_lcomp_dir,overwrite = T) #init values tarter



## Updating all comps
#### Updating  the lencomps
update_all_comp_dir <- file.path("models", "data_updates","pacfin_comp_compare_2019", "update_all_comp_data")
create_copy_model(update_all_comp_dir,base_model_test,overwrite = T)


data_2019 <- SS_readdat(here(update_all_comp_dir, "2019widow.dat"))
data_2019$lencomp <- widow_dat_replace_2005_2018_lencomp #update len comps
data_2019$agecomp <- widow_dat_replace_2005_2018_agecomp #update age comp

SS_writedat(data_2019,here(update_all_comp_dir, "2019widow.dat"),overwrite = T)
r4ss::SS_writestarter(start,update_all_comp_dir,overwrite = T) #init values tarter




### 2. Run all the models 
models<- c(base_model_test,update_acomp_dir,update_lcomp_dir,update_all_comp_dir)

cl <- parallel::makeCluster(length(models)) #create cluster
parallel::parSapply(cl,models,function(x){
  exe_name <-  basename(list.files(x, pattern = "\\.exe$", full.names = TRUE)) #pull the .exe in the file
  
  r4ss::run(dir = x,
            exe = exe_name,
            extras = "-nohess",
            show_in_console = FALSE)

  
})
parallel::stopCluster(cl)

##### 4. Compare the models  ########################################

model_out <- SSgetoutput(dirvec = models,getcovar = F)
summ_out <- SSsummarize(biglist = model_out)
windows()
par(mfrow = c(2,2))
SSplotData(model_out[[1]])
SSplotData(model_out[[2]])




dir.create("figures/pacfin_comp_plots/pacfin_comp_compare_2019",recursive = T)

SSplotComparisons(summaryoutput = summ_out,
                  legendlabels = c("base","+ update age"," + update length"," + update_all"),
                  plotdir = "figures/pacfin_comp_plots/pacfin_comp_compare_2019",
                  print = F)

windows()
par(mfrow = c(2,2))
  SSplotData(model_out[[1]])
  SSplotData(model_out[[2]])
  




###### Compare composition data 



