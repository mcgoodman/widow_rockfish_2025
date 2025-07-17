
library("tidyverse")
library("r4ss")
library("here")

source(here("R", "functions", "bridging_functions.R"))

ss3_exe <- here("models", set_ss3_exe(here("models")))

# Base model ------------------------------------------------------------------

base_dir <- here("models", "2025 base model")
base_2025 <- SS_output(base_dir)

quants <- list(base_2025 = base_2025$derived_quants[c("Dead_Catch_MSY", "OFLCatch_2027"),])

# Fix natural mortality at 2015 estimate --------------------------------------

dir.create(M2015_dir <- here("models", "sensitivities", "M2015"))

copy_SS_inputs(base_dir, M2015_dir)

ctrl <- SS_readctl(here(M2015_dir, "2025widow.ctl"), datlist = here(M2015_dir, "2025widow.dat"))

# Fix female mortality
ctrl$MG_parms["NatM_p_1_Fem_GP_1", "INIT"] <- 0.1362
ctrl$MG_parms["NatM_p_1_Fem_GP_1", "PHASE"] <- -5

# Fix male mortality
ctrl$MG_parms["NatM_p_1_Mal_GP_1", "INIT"] <- 0.1705
ctrl$MG_parms["NatM_p_1_Mal_GP_1", "PHASE"] <- -5

SS_writectl(ctrl, here(M2015_dir, "2025widow.ctl"), overwrite = TRUE)

r4ss::run(M2015_dir, exe = ss3_exe)

M2015 <- SS_output(M2015_dir)

quants$M2015 <- M2015$derived_quants[c("Dead_Catch_MSY", "OFLCatch_2027"),]

# Fix natural mortality at 2019 estimate --------------------------------------

base_2019 <- SS_output(here("models", "2019 base model", "Base_45_new"))

dir.create(M2019_dir <- here("models", "sensitivities", "M2019"))

copy_SS_inputs(base_dir, M2019_dir)

ctrl <- SS_readctl(here(M2019_dir, "2025widow.ctl"), datlist = here(M2019_dir, "2025widow.dat"))

# Fix female mortality
ctrl$MG_parms["NatM_p_1_Fem_GP_1", "INIT"] <- base_2019$parameters["NatM_uniform_Fem_GP_1", "Value"]
ctrl$MG_parms["NatM_p_1_Fem_GP_1", "PHASE"] <- -5

# Fix male mortality
ctrl$MG_parms["NatM_p_1_Mal_GP_1", "INIT"] <- base_2019$parameters["NatM_uniform_Mal_GP_1", "Value"]
ctrl$MG_parms["NatM_p_1_Mal_GP_1", "PHASE"] <- -5

SS_writectl(ctrl, here(M2019_dir, "2025widow.ctl"), overwrite = TRUE)

r4ss::run(M2019_dir, exe = ss3_exe)

M2019 <- SS_output(M2019_dir)

quants$M2019 <- M2019$derived_quants[c("Dead_Catch_MSY", "OFLCatch_2027"),]

# Join ------------------------------------------------------------------------

quants <- quants |> 
  bind_rows(.id = "Model") |> 
  select(Model, Label, Value, StdDev) |> 
  as_tibble()

write.csv(quants, here("figures", "sensitivities", "mortality_past_assessments.csv"), row.names = FALSE)
