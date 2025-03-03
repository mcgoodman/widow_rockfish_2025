library(tidyverse)
library(r4ss)
library(here)

wd <- here()

# directory for the base model
# run Base_45 from par file (i.e. archived model)
base_dir <- here(wd, 'models', '2019 base model', 'Base_45')

# run model
r4ss::run(dir = base_dir,
          exe = "ss",
          #extras = "-nohess",
          show_in_console = TRUE,
          skipfinished = T)
# With estimation and hessian it takes ~12 minutes

# Get r4ss output
replist <- SS_output(
  dir = base_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = T
)

# Plots the results (store in the 'R_Plots' sub-directory)
SS_plots(replist,
         dir = base_dir,
         printfolder = "R_Plots"
)


# now run Base_45 with the CTL file shared by Ian in Discussion #27, saved as 2019widow.ctl
base_ctl_dir <- here(wd, 'models', '2019 base model', 'Base_45_new')

# set it up to run from the CTL file and to ignore par
starter_file <- file.path(base_ctl_dir, "starter.ss")
starter <- SS_readstarter(
  file = starter_file,
  verbose = TRUE
)

starter$init_values_src <- 0 # read initial files from ctl

# save starter
SS_writestarter(
  mylist =  starter ,
  dir =  base_ctl_dir, 
  overwrite = TRUE,
  verbose = TRUE
)

# run model
r4ss::run(dir = base_ctl_dir,
          exe = "ss",
          #extras = "-nohess",
          show_in_console = TRUE,
          skipfinished = T)
# With estimation and hessian it takes ~12 minutes

# Get r4ss output
replist <- SS_output(
  dir = base_ctl_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = T
)

# Plots the results (store in the 'R_Plots' sub-directory)
SS_plots(replist,
         dir = base_ctl_dir,
         printfolder = "R_Plots"
)

# # add new models with data updates
# 
# # ...
# 

# model comparison plots
 
folders <- list.dirs(path=here(wd, 'models', '2019 base model'), recursive=FALSE)
#folders <- folders[!grepl("Base_45\\b", folders)]

#Comparison plots produced by r4ss
Models<-SSgetoutput(dirvec=folders,getcovar=T)
Models_SS<-SSsummarize(Models)

plot_dir <- here(wd, 'models', '2019 base model', 'compare_plots')
if(!dir.exists(plot_dir)){dir.create(plot_dir)}

mod_names <-c('base',
              'base_ctl') #add model names as appropriate

#plot time series (SSB, Recruitment, Fishing mortality)
SSplotComparisons(Models_SS,
                  print=TRUE,
                  plotdir=plot_dir,
                  labels = c("Year", "Spawning biomass (t)","Relative spawning biomass", "Age-0 recruits (1,000s)",
                             "Recruitment deviations", "Index", "Log index", "1 - SPR", "Density","Management target", "Minimum stock size threshold",
                             "Spawning output","Harvest rate"),
                  densitynames=c("SSB_2019","SSB_Virgin"),
                  legendlabels=mod_names,
                  indexPlotEach = TRUE,
                  filenameprefix="Sens_base_mod")
