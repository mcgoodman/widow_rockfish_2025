#-----------------------------------------------------------------#
#-------- Decision table -----------------------------------------#
#-----------------------------------------------------------------#

# Code to implement a decision table for Widow rockfish based on the 2019
#report. 
# States of nature: low (M, h @ 12.5% quantile), base (M,h as estimated), high(M,h @ 87.5%)
# Management actions: 1) Constant catch of F 9000 MT, 2) ACL p*0.25, sig = 0.5, 3)ACL p*0.45, sig = 0.5
# Mico Kinneen 10/05/2025

devtools::install_github("pfmc-assessments/PEPtools")

library(PEPtools)
library(r4ss)
library(tidyverse)
library(here)
library(parallel)
if (!requireNamespace("tinytex", quietly = TRUE)) {
  install.packages("tinytex")
}
library(tinytex)

#Other required code
source(here("R","functions","set_ss3_exe.R"))
format_dec_table <- "https://raw.githubusercontent.com/pfmc-assessments/yellowtail_2025/main/Rscripts/table_decision.R"
source(url(format_dec_table))# From Yellowtail 2025 assessment, @Ian Taylor

## Read in the base model
base_mod_dir <- here::here("models","2025 base model")
base_mod <- SS_read(base_mod_dir)
rep <- r4ss::SS_output(base_mod_dir)

#data
gmt_catch <- read.csv(here("data_provided","GMT_forecast_catch","GMT_forecast_catch.csv"))|>select(-c(fleet_name,Source))

#-----------------------------------------------------------------#
#-------- 1. Management actions -----------------------------------#
#-----------------------------------------------------------------#


#-------- Catch stream 1 - Constant catch of 9000 mt ------------#

cc_base <- base_mod
cc_base_dir <- here("scratch","decision_table","cc_base")
cc_base$fore$Flimitfraction <- -1
cc_base$fore$Flimitfraction_m <- 1 #No HCR, just constant catch
cc_base$fore$FirstYear_for_caps_and_allocations <- 2027
cc_base$fore$Ydecl <- 0
cc_base$fore$Yinit <- 0

### Proportions to assign catch by fleet
fleet_prop <- gmt_catch |>
  group_by(year) |>
  summarise(vec = list(catch_or_F / sum(catch_or_F)), .groups = "drop") |>
  summarise(mean_vec = list(reduce(vec, `+`) / length(vec))) |>
  pull(mean_vec) |>
  unlist()


cc_amount <- 9000 #the total catch
forc_cc <- cc_amount * fleet_prop #apportioned catch


#For all projection years, except 2025, 2026, which are determined by GMT
proj_cc <-  data.frame( 
  year = rep(2027:2036, each = length(fleet_prop)),
  seas = 1,
  fleet = rep(1:5,length(2027:2036)),
  catch_or_F = rep(forc_cc, times = length(2027:2036))
)

#All forecast catch: gmt catches + projection years
cc_base$fore$ForeCatch <- rbind(gmt_catch,proj_cc)


## Write th model and run it
SS_write(cc_base,dir = cc_base_dir)
set_ss3_exe(dir = cc_base_dir)
r4ss::run(dir = cc_base_dir,exe = "ss3","-nohess")



#-------- Catch stream 2 - ACL* P*0.25, sigma = 0.5 ------------#

p_star_25_dir <- here("scratch","decision_table","25_base")
p_star_25 <- base_mod
p_star <- 0.25
p_star_25$fore$Flimitfraction <- -1
p_star_25$fore$Flimitfraction_m <- PEPtools::get_buffer(2025:2036, sigma = 0.5, pstar = p_star)
p_star_25$fore$FirstYear_for_caps_and_allocations <- 2027
p_star_25$fore$Ydecl <- 0
p_star_25$fore$Yinit <- 0
p_star_25$fore$ForeCatch <- gmt_catch

## Write th model and run it
SS_write(p_star_25,dir = p_star_25_dir)
set_ss3_exe(dir = p_star_25_dir)
r4ss::run(dir = p_star_25_dir,exe = "ss3","-nohess")

#Read the model and add the catches back into the base file
p_star_25 <- SS_read(p_star_25_dir)
p_star_25$fore$ForeCatch <- SS_ForeCatch(replist = SS_output(p_star_25_dir),yrs = 2027:2036,average = FALSE)
SS_write(p_star_25,dir = p_star_25_dir,overwrite = T)



#-------- Catch stream 2 - ACL* P*0.25, sigma = 0.5 ------------#

## P*0.45 base
p_star_45_dir <- here("scratch","decision_table","45_base")
p_star_45 <- base_mod
p_star <- 0.45
p_star_45$fore$Flimitfraction <- -1
p_star_45$fore$Flimitfraction_m <- PEPtools::get_buffer(2025:2036, sigma = 0.5, pstar = p_star)
p_star_45$fore$FirstYear_for_caps_and_allocations <- 2027
p_star_45$fore$Ydecl <- 0
p_star_45$fore$Yinit <- 0
p_star_45$fore$ForeCatch <- gmt_catch

## Write th model and run it
SS_write(p_star_45,dir = p_star_45_dir,overwrite = TRUE)
set_ss3_exe(dir = p_star_45_dir)
r4ss::run(dir = p_star_45_dir,exe = "ss3","-nohess",skipfinished = FALSE)

#Read the model and add the catches back into the base file
p_star_45 <- SS_read(p_star_45_dir)
p_star_45$fore$ForeCatch <- SS_ForeCatch(replist = SS_output(p_star_45_dir),yrs = 2027:2036,average = FALSE)
SS_write(p_star_45,dir = p_star_45_dir,overwrite = T)


#### Combined all the forecast catches into a single list, with f limit and forcast catches

catch_series <-
  list(
  "cc" = list(  # Catch stream 1
    "f_limit_frac" = cc_base$fore$Flimitfraction_m,
    "forc_catch" = cc_base$fore$ForeCatch),
  
  "25" = list( #Catch stream 2
    "f_limit_frac" =  p_star_25$fore$Flimitfraction_m,
    "forc_catch" = p_star_25$fore$ForeCatch
  ),
  
  "45" = list( #Catch stream 3
    "f_limit_frac" =  p_star_45$fore$Flimitfraction_m,
    "forc_catch" = p_star_45$fore$ForeCatch 
  )
)


#-----------------------------------------------------------------#
#-------- 2. States of nature  -----------------------------------#
#-----------------------------------------------------------------#


#Get all the params into a table
pars_table <- rep$parameters|> #make sure to ppull from report, not input file so est values are used
  mutate(
         value = Value,
         sd = if_else(is.na(Parm_StDev),Pr_SD,Parm_StDev))|> #If est par, use param sd, otherwise use prior sd
  filter(Num %in% c(1,13,27))|> #natM Female, natM male, steepness
  select(value,sd)|>
  mutate(
    q125 = qnorm(0.125,mean = value,sd = sd), #apply the quantiles
    q875 = qnorm(0.875,mean = value,sd = sd),
    phase = -1,
    name = c("NatM_p_1_Fem_GP_1", #name the parms - easier to do manually as report and r4ss::read() have different parameter names
             "NatM_p_1_Mal_GP_1",
             "SR_BH_steep") 
  )


##Plot the params to check they make sense and quantiles are resonable
par(mfrow = c(1,3))

for(i in 1:3){
  curve(
    dnorm(x, mean = pars_table[i,"value"], sd = pars_table[i,"sd"]),
    from = pars_table[i,"value"] - 4*pars_table[i,"sd"],
    to = parsdecision_table.R_table[i,"value"] + 4*pars_table[i,"sd"],
    ylab = "Density",
    xlab = pars_table[i,"name"]
  )
  abline(v = pars_table[i,"value"],col = "red",lty = 2)
  abline(v = pars_table[i,"q125"],col = "blue",lty = 3)
  abline(v = pars_table[i,"q875"],col = "blue",lty = 3)
  if(i == 3){
  legend("topright",
         legend = c("MLE", "q0.125,q0.875"),
         col = c("red", "blue"),
         lty = c(2, 3),
         bty = "n")  # 'bty = "n"' removes the legend box (optional)
  }
}

#Dirs
dirs <- c(here("scratch","decision_table","cc_low"),      #low SON, P*0.25 
              here("scratch","decision_table","25_low"),  #low SON, P*0.45
              here("scratch","decision_table","45_low"),  #low SON cc
              here("scratch","decision_table","cc_high"), #High SON, P*0.25 
              here("scratch","decision_table","25_high"), #High SON, P*0.45
              here("scratch","decision_table","45_high")  #High SON cc
)


## This loops through each combinatio of SON and manegment action, creating the relavent models
for( i in seq_along(dirs)){
  
  #create the dir
  temp_dir <- dirs[i]
  scenario <- sub("_(low|high)$", "", basename(temp_dir))  # extract "cc", "25", or "45"


  #Copy the base model
  copy_SS_inputs(dir.old = cc_base_dir,
                 dir.new = temp_dir,
                 overwrite = T,
                 create.dir = T)
  
  #ACondtitionally choose quantile, depending on SON
  new_vals <- if (grepl("low", basename(temp_dir))) {
    pars_table$q125
  } else {
    pars_table$q875
  }    
  
  #Update the control file, altering M, h pars
  SS_changepars(dir = temp_dir,ctlfile = "2025widow.ctl",
                newctlfile = "2025widow.ctl",
                strings = pars_table$name,
                newvals = new_vals,
                newphs = pars_table$phase) #seeting negative, so not estimate
  
  # Read in the model, update the forecast and change
  mod <- SS_read(dir = temp_dir)
  mod$fore$Flimitfraction_m <- catch_series[[scenario]]$f_limit_frac
  mod$fore$ForeCatch <- catch_series[[scenario]]$forc_catch
  SS_write(inputlist = mod,dir = temp_dir,overwrite = T)
  set_ss3_exe(dir = temp_dir)
}
              


#-----------------------------------------------------------------#
#-------- 3. Model runs and processing  --------------------------#
#-----------------------------------------------------------------#

run_paralell <- TRUE

if (run_paralell == TRUE) {
  n_cores <- length(dirs)
  cl <- makeCluster(n_cores)
  # Export needed variables and packages to workers
  clusterExport(cl, varlist = c("dirs"))
  clusterEvalQ(cl, library(r4ss))
  
  # Run SS3 in parallel
  parLapply(cl, dirs, function(x) {
    r4ss::run(dir = x,
              exe = "ss3",
              show_in_console = TRUE,
              skipfinished = FALSE)
    
  })
  
  # Stop the cluster
  stopCluster(cl)
} else {
  lapply(list.dirs(here("scratch", "decision_table"))[-1], function(x) {
    r4ss::run(dir = x,
              exe = "ss3",
              show_in_console = T,
              skipfinished = FALSE)
    
  })
}

#Make the decision table
#Start by gathering all the directories
all_dirs <-  c(here("scratch","decision_table","cc_low"),
           here("scratch","decision_table","cc_base"),
           here("scratch","decision_table","cc_high"),
           here("scratch","decision_table","45_low"),
           here("scratch","decision_table","45_base"),
           here("scratch","decision_table","45_high"),
           here("scratch","decision_table","25_low"),
           here("scratch","decision_table","25_base"),
           here("scratch","decision_table","25_high"))

dec_table_reps <- SSgetoutput(dirvec = all_dirs)
names(dec_table_reps) <- basename(all_dirs)


#Use Ians code to generate latex
dec_table_latex <- table_decision(
  list(dec_table_reps[['cc_low']], dec_table_reps[['cc_base']], dec_table_reps[['cc_high']]),
  list(dec_table_reps[['25_low']], dec_table_reps[['25_base']], dec_table_reps[['25_high']]),
  list(dec_table_reps[['45_low']], dec_table_reps[['45_base']], dec_table_reps[['45_high']]),
  years = 2027:2036
)

saveRDS(dec_table_latex,file = here("data_derived", "decision_table","dec_table_latex.RDS"))

### Pull the values to save them
dec_table_results <- imap_dfr(dec_table_reps, function(x, name) {
  df <- SS_decision_table_stuff(x, yrs = 2027:2036, digits = c(0, 0, 3))
  df$name <- name
  df
})

write.csv(dec_table_results,file = here("data_derived", "decision_table","dec_table_results.csv"))



#-----------------------------------------------------------------#
#-------- 4. Plotting  --------------------------#
#-----------------------------------------------------------------#

dir.create(here("figures", "decision_table"))

## Plot the 9000 MT scenario for each SON
compare_ss3_mods(
  replist = list(dec_table_reps[['cc_base']], dec_table_reps[['cc_low']], dec_table_reps[['cc_high']]),
  plot_dir = here("figures", "decision_table","cc_plots"),
  plot_names = c("Base", "Low", "High"),
  subplots = 1:17,
  endyrvec = rep(2036, 3),
  shadeForecast = TRUE,
  tickEndYr = TRUE
)

compare_ss3_mods(
  replist = list(dec_table_reps[['45_base']], dec_table_reps[['45_low']], dec_table_reps[['45_high']]),
  plot_dir = here("figures", "decision_table","45_plots"),
  plot_names = c("Base", "Low", "High"),
  subplots = 1:17,
  endyrvec = rep(2036, 3),
  shadeForecast = TRUE,
  tickEndYr = TRUE
)

compare_ss3_mods(
  replist = list(dec_table_reps[['25_base']], dec_table_reps[['25_low']], dec_table_reps[['25_high']]),
  plot_dir = here("figures", "decision_table","25_plots"),
  plot_names = c("Base", "Low", "High"),
  subplots = 1:17,
  endyrvec = rep(2036, 3),
  shadeForecast = TRUE,
  tickEndYr = TRUE
)


###### End