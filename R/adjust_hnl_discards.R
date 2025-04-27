library(dplyr)
library(r4ss)
library(here)

source(here("R","functions","retune_reweight_ss3.r"))
## Read in the base file
final_bridge_model <- here("models","data_bridging","finalised_data_bridging","reweight")

mod <- r4ss::SS_read(final_bridge_model)

hnl_fleet <- 5 #fleet number
## Make changes



# Data file:
# 1. HKL discards are added to landings (lines 578-600 of the data file. You can add them to landings for corresponding years, but now they added separately, but have the same fleet number).
hnl_disc <- mod$dat$discard_data|>
  filter(fleet == hnl_fleet)|>
  select(year,obs)

hnl_catch_new <- mod$dat$catch|>
  filter(fleet == hnl_fleet)|>
  full_join(hnl_disc, by = "year")|>
  # keep every year that appears in either df
  mutate(
    catch = coalesce(obs,   0) +         # replace NAs with 0 so the sum works
      coalesce(catch, 0)
  )|>
  select(-obs)

##Overwrite the catch in the data
mod$dat$catch <- mod$dat$catch|>
  filter(fleet != hnl_fleet)|>
  rbind(hnl_catch_new)|>
  filter(year >= 0)|>
  arrange(fleet)



#Test
table(mod$dat$discard_data$fleet == hnl_fleet)

# 2. The number of fleets with discard changed from 3 to 2 on line 746.
mod$dat$N_discard_fleets  <- 2

# 3. Line 754 is commended out (that was the line for HKL fleet discard settings.
mod$dat$discard_fleet_info <- mod$dat$discard_fleet_info|> filter(fleet != hnl_fleet)
mod$dat$discard_fleet_info

# 4. HKL discards removed (commented out lines 794-806).Since we added total dead discards to landings we don't need to double count discards here.
mod$dat$discard_data <- mod$dat$discard_data|>
  filter(fleet != hnl_fleet)

# 5. HKL discard length comps removed (lines 1025-1038). The lengths from the old model are obsolete, and we have too few samples of the current data to use.
mod$dat$lencomp <- mod$dat$lencomp|>
  mutate(year = if_else(fleet == hnl_fleet & part == 1, abs(year) * - 1, year))

#test
mod$dat$lencomp |>
  filter(fleet == hnl_fleet & year >= 0)

# Control file
#
# Line 170, Discard pattern (the second number from the left) changed from 1 to 0, so that model would not expect 4 retention parameters associated with HKL fleet).
mod$ctl$size_selex_types <- mod$ctl$size_selex_types|>
  mutate(fleet = rownames(mod$ctl$size_selex_types))|>
  mutate(Discard = if_else(fleet %in% c("BottomTrawl",'MidwaterTrawl'),1,0))|>select(-fleet)

#test
cbind(mod$ctl$size_selex_types$Discard,rownames(mod$ctl$size_selex_types))


##For commenting out stuff, write the model, then use read lines to add hash signs
new_model_dir <- here("models","data_bridging","finalised_data_bridging","reweight_hnl_removed")
SS_write(inputlist = mod,dir =  new_model_dir,overwrite = T)

# HKL retention parameters are commended out (lines 228-231).
# HKL retention time-varying (block) parameters are commended out as well (lines 288-290).
ctl <- readLines(con = here(new_model_dir,"2025widow.ctl")) #read in the ctl
hnl_slex_parm_lines <- stringr::str_which(ctl, "SizeSel_PRet_(1|2|3|4)_HnL") #flag any lines which match rettion pars for hnl (and tv pars)
ctl[hnl_slex_parm_lines] <- paste0("#", ctl[hnl_slex_parm_lines]) #insert a comment where they exist
writeLines(text = ctl,con = here(new_model_dir,"2025widow.ctl")) #rewrite the model




combine_hnl_discards <- function(model_dir,hnl_fleet_id = 5){
  library(dplyr)
  tests <- list()
  browser()
  mod <- r4ss::SS_read(model_dir)
  hnl_fleet <- hnl_fleet_id #fleet number
  
  # Data file:
  # 1. HKL discards are added to landings (lines 578-600 of the data file. You can add them to landings for corresponding years, but now they added separately, but have the same fleet number).
  hnl_disc <- mod$dat$discard_data|>
    filter(fleet == hnl_fleet)|>
    select(year,obs)|>
    distinct()
  
  hnl_catch_new <- mod$dat$catch|>
    filter(fleet == hnl_fleet)|>
    full_join(hnl_disc, by = "year")|>
    # keep every year that appears in either df
    mutate(
      catch = coalesce(obs,   0) +         # replace NAs with 0 so the sum works
        coalesce(catch, 0)
    )|>
    select(-obs)
  
  ##Overwrite the catch in the data
  mod$dat$catch <- mod$dat$catch|>
    filter(fleet != hnl_fleet)|>
    rbind(hnl_catch_new)|>
    filter(year >= 0)|>
    arrange(fleet)
  
  #Test
  tests$disc_flets <- table(mod$dat$discard_data$fleet)
  
  # 2. The number of fleets with discard changed from 3 to 2 on line 746.
  mod$dat$N_discard_fleets  <- 2
  # 3. Line 754 is commended out (that was the line for HKL fleet discard settings.
  mod$dat$discard_fleet_info <- mod$dat$discard_fleet_info|> filter(fleet != hnl_fleet)
  tests$discard_fleet_info <- mod$dat$discard_fleet_info
  # 4. HKL discards removed (commented out lines 794-806).Since we added total dead discards to landings we don't need to double count discards here.
  mod$dat$discard_data <- mod$dat$discard_data|>filter(fleet != hnl_fleet)
  # 5. HKL discard length comps removed (lines 1025-1038). The lengths from the old model are obsolete, and we have too few samples of the current data to use.
  mod$dat$lencomp <- mod$dat$lencomp|>
    mutate(year = if_else(fleet == hnl_fleet & part == 1, abs(year) * - 1, year))
  #test
  tests$discard_lcomps <- mod$dat$lencomp |>
    filter(year >= 0 & part == 1)|>select(fleet,year)|>count(fleet)
  
  # Control file changes
  # Line 170, Discard pattern (the second number from the left) changed from 1 to 0, so that model would not expect 4 retention parameters associated with HKL fleet).
  mod$ctl$size_selex_types <- mod$ctl$size_selex_types|>
    mutate(fleet = rownames(mod$ctl$size_selex_types))|>
    mutate(Discard = if_else(fleet %in% c("BottomTrawl",'MidwaterTrawl'),1,0))|>select(-fleet)

  
  tests$discard_amounts_fleets <- mod$dat$discard_data|>
    count(fleet)
  #test
  tests$discard_sel_patterns <- cbind(mod$ctl$size_selex_types$Discard,rownames(mod$ctl$size_selex_types))
  
  
  ##For commenting out stuff, write the model, then use read lines to add hash signs
 # tests <- here("models","data_bridging","finalised_data_bridging","reweight_hnl_removed")
  SS_write(inputlist = mod,dir =  model_dir,overwrite = T)
  
  # HKL retention parameters are commended out (lines 228-231).
  # HKL retention time-varying (block) parameters are commended out as well (lines 288-290).
  ctl <- readLines(con = here(model_dir,"2025widow.ctl")) #read in the ctl
  hnl_slex_parm_lines <- stringr::str_which(ctl, "SizeSel_PRet_(1|2|3|4)_HnL") #flag any lines which match rettion pars for hnl (and tv pars)
  ctl[hnl_slex_parm_lines] <- paste0("#", ctl[hnl_slex_parm_lines]) #insert a comment where they exist
  writeLines(text = ctl,con = here(model_dir,"2025widow.ctl")) #rewrite the model
  
  print(tests)
  
}




#Run if to vhekc if everything is ok
file.copy(here(model_dir,"ss3.exe"),new_model_dir)
r4ss::run(dir = new_model_dir,exe = "ss3.exe",extras = "-nohess",show_in_console = T,skipfinished = FALSE)
r4ss::SS_plots(SS_output(new_model_dir))



#Retune and reweihgt the model as chnages have been made
retune_reweight_ss3(
  base_model_dir = here("models","data_bridging","finalised_data_bridging","reweight_hnl_removed"),
  output_dir = here("models","data_bridging","finalised_data_bridging"),
  n_tuning_runs = 2,
  tuning_method = "MI",
  keep_tuning_runs = FALSE,
  lambda_weight = 0.5,
  marg_comp_fleets = 1:5
)
