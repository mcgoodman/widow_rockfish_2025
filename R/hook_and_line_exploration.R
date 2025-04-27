library(here)
library(dplyr)
library(r4ss)

#-----------------------------------------------------------
### Test 1 - Replace 2019 DISCARDS WITH NEW ONES, RUNNING model to 2019
#-----------------------------------------------------------

source(here("R","functions","retune_reweight_ss3.r"))
source(here("R","functions","bridging_functions.r"))

base_45_new <- here("models","2019 base model","Base_45_new")
base_45_new_discards <- r4ss::SS_read(base_45_new)

# #new wcgop discard data
# discard_lcomps_add_years  <- read.csv(here("data_derived","discards","discard_length_comps_add-years-only.csv"))|>
#   rename(partition = part,input_n = Nsamp)|>
#   select(!X) #drop weird rownumber column from excel

discard_lcomps <- read.csv(here("data_derived","discards","discard_length_comps.csv"))|>
  rename(partition = part,input_n = Nsamp)|>
  select(!X) #drop weird rownumber column from excel


discard_amounts <- read.csv(here("data_derived","discards","discards_2025.csv"))|>
  select(!source)|>
  distinct()#some duplicate rows present

base_45_new_discards$dat$lencomp <- base_45_new_discards$dat$lencomp|>
  filter(part != 1)|> #remove old discards
  rbind(discard_lcomps|> #add new discards
          filter(partition  == 1)|>
          filter(year <= 2018)|>
          rename(part = partition, Nsamp = input_n))|>
  arrange(fleet)


base_45_new_discards$dat$discard_data <- discard_amounts|>
          filter(year <= 2018)|>
  mutate(obs = if_else(obs == 0, 0.001,obs))


##Add variance adjustment settings to allow tuning function
new_var_adj_df <- base_45_new_discards$ctl$lambdas|>
  select(like_comp,fleet,value)|>
  rename(factor = like_comp,fleet = fleet)

#Now set the lambdas to 1
base_45_new_discards$ctl$lambdas <- base_45_new_discards$ctl$lambdas|>
  mutate(value = 1)

#Now add var adjustment factors data type, fleet, value
base_45_new_discards$ctl$DoVar_adjust <- 1 # turn on var adjust
base_45_new_discards$ctl$Variance_adjustment_list <- new_var_adj_df#add vARIANCE ADJUSTMNE TLIST





#Write the model
replace_hnl_disc_2019_dir<- here("models","comp_exploration","hnl_discard_test","test_1_wcgop_replace_2019")
SS_write(base_45_new_discards,dir = replace_hnl_disc_2019_dir,overwrite = T)
file.copy(from = here(base_45_new,"ss3.exe"),to = replace_hnl_disc_2019_dir)
r4ss::run(dir = replace_hnl_disc_2019_dir,exe = "ss3",extras = "-nohess",skipfinished = FALSE)

# #Drop year version
# replace_hnl_disc_2019_dir<- here("models","comp_exploration","hnl_discard_test","test_1_wcgop_replace_2019")
# SS_write(base_45_new_discards,dir = replace_hnl_disc_2019_dir,overwrite = T)
# file.copy(from = here(base_45_new,"ss3.exe"),to = replace_hnl_disc_2019_dir)
# r4ss::run(dir = replace_hnl_disc_2019_dir,exe = "ss3",extras = "-nohess",skipfinished = FALSE)



retune_reweight_ss3(
  base_model_dir = replace_hnl_disc_2019_dir,
  output_dir = here("models", "comp_exploration", "hnl_discard_test"),
  n_tuning_runs = 2,
  tuning_method = "MI",
  keep_tuning_runs = FALSE,
  lambda_weight = 0.5
)



#Generate r4ss plots and do a compare model run 

compare_ss3_mods(
  dirs = c(base_45_new, paste0(replace_hnl_disc_2019_dir,"_reweighted")),
  plot_dir = here(paste0(replace_hnl_disc_2019_dir,"_reweighted"), "compare_hnl_dic_plots"),
  plot_names = c("Base_45", "Base_45_replace_WCGOP")
)

SS_plots(SS_output(dir = paste0(replace_hnl_disc_2019_dir,"_reweighted")))








#-----------------------------------------------------------
## Test 2 --- Compare append model vs replace model 
#-----------------------------------------------------------

append_2025_model <- here("models","data_bridging","finalised_data_bridging","reweight")
replace_2025_model <- SS_read(append_2025_model)


## Correct the wgcop data
replace_2025_model$dat$lencomp <- replace_2025_model$dat$lencomp|>
  filter(part != 1)|> #remove old discards
  rbind(discard_lcomps|> #add new discards
          filter(partition  == 1)|>
          rename(part = partition, Nsamp = input_n))|>
  arrange(fleet)


replace_2025_model$dat$discard_data <- discard_amounts|>
  mutate(obs = if_else(obs == 0, 0.001,obs))



#Write the model
test_2_wcgop_replace_2025_dir <- here("models","comp_exploration","hnl_discard_test","test_2_wcgop_replace_2025")
SS_write(replace_2025_model,dir = test_2_wcgop_replace_2025_dir,overwrite = T)
file.copy(from = here(base_45_new,"ss3.exe"),to = test_2_wcgop_replace_2025_dir)
r4ss::run(dir = test_2_wcgop_replace_2025_dir,exe = "ss3",extras = "-nohess")

retune_reweight_ss3(
  base_model_dir = test_2_wcgop_replace_2025_dir,
  output_dir = here("models", "comp_exploration", "hnl_discard_test"),
  n_tuning_runs = 2,
  tuning_method = "MI",
  keep_tuning_runs = FALSE,
  lambda_weight = 0.5
)


compare_ss3_mods(
  dirs = c(append_2025_model,  paste0(test_2_wcgop_replace_2025_dir,"_reweighted")),
  plot_dir = here( paste0(test_2_wcgop_replace_2025_dir,"_reweighted"), "compare_hnl_dic_plots"),
  plot_names = c("append_2025_hnl_disc", "replace_2025_hnl_disc"),png = TRUE
)

SS_plots(SS_output(dir = paste0(test_2_wcgop_replace_2025_dir,"_reweighted")))




#-----------------------------------------------------------
### test 3 - Downweight contribtuion of HnL discards to 0 (via lambdas)
#-----------------------------------------------------------

test_3_drop_disc_2019 <- r4ss::SS_read(base_45_new)


#Drop the nl dicards all together
test_3_drop_disc_2019$dat$lencomp <- test_3_drop_disc_2019$data$lencomp|>
  mutate(year = if_else(fleet == 5 & part == 1,abs(year)*-1,year ))

test_3_drop_disc_2019$dat$discard_data <- test_3_drop_disc_2019$dat$discard_data|>
  mutate(year = if_else(fleet == 5,abs(year)*-1,year ))

test_3_drop_disc_2019_dir <- here("models","comp_exploration","hnl_discard_test","test_3_drop_disc_2019")
SS_write(test_3_drop_disc_2019,dir = test_3_drop_disc_2019_dir,overwrite = T)
file.copy(from = here(base_45_new,"ss3.exe"),to = test_3_drop_disc_2019_dir)
r4ss::run(dir = test_3_drop_disc_2019_dir,exe = "ss3",extras = "-nohess",skipfinished = F)

retune_reweight_ss3(
  base_model_dir = test_3_drop_disc_2019_dir,
  output_dir = here("models", "comp_exploration", "hnl_discard_test"),
  n_tuning_runs = 2,
  tuning_method = "MI",
  keep_tuning_runs = FALSE,
  lambda_weight = 0.5
)


compare_ss3_mods(
  dirs = c(base_45_new,  test_3_drop_disc_2019_dir),
  plot_dir = here( test_3_drop_disc_2019_dir, "compare_hnl_dic_plots"),
  plot_names = c("2019 base", "20119 base drop HnL discards"),png = TRUE
)


SS_plots(SS_output(dir = test_3_drop_disc_2019_dir))

