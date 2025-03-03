library(tidyverse)
library(r4ss)
library(here)

wd <- here()

# directory for the base model
# Base model here is Base_45 with the CTL file shared by Ian in Discussion #27, saved as 2019widow.ctl
base_dir <- here(wd, 'models', '2019 base model', 'Base_45_new')

# set it up to run from the CTL file and to ignore par
starter_file <- file.path(base_dir, "starter.ss")
starter <- SS_readstarter(
  file = starter_file,
  verbose = TRUE
)

starter$init_values_src <- 0 # read initial files from ctl

# save starter
SS_writestarter(
  mylist =  starter ,
  dir =  base_dir, 
  overwrite = TRUE,
  verbose = TRUE
)

# run model
r4ss::run(dir = base_dir,
          exe = "ss",
          #extras = "-nohess",
          show_in_console = TRUE,
          skipfinished = F)
# With estimation and hessian it takes ~12 minutes

# Get r4ss output
replist <- SS_output(
  dir = base_dir,
  verbose = TRUE,
  printstats = TRUE,
  covar = T
)

# Plots the results (store in the 'plots' sub-directory)
SS_plots(replist,
         dir = base_dir,
         printfolder = "R_Plots"
)
