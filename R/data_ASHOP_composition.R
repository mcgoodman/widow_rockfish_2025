
# Author: Kristina Randup
# ASHOP age and length data

library("here")
library("tidyverse")
library("nwfscSurvey")
library("readxl")

# Read in data --------------------------------------------

historical_length <- 
  here("data_provided", "ASHOP","A_SHOP_Widow_Lengths_1976-2024_removedConfiendtialFields_012725.xlsx") |> 
  read_excel(sheet = 2) |> 
  mutate(common_name = "widow rockfish", trawl_id = HAUL_JOIN) |> 
  uncount(weights = FREQUENCY) |> 
  as.data.frame()

modern_length <- 
  here("data_provided", "ASHOP", "A_SHOP_Widow_Lengths_1976-2024_removedConfiendtialFields_012725.xlsx") |> 
  read_excel(sheet = 1) |> 
  mutate(common_name = "widow rockfish", trawl_id = HAUL_JOIN) |> 
  uncount(weights = FREQUENCY) |> 
  as.data.frame()

ashop_age <- 
  here("data_provided", "ASHOP", "A_SHOP_Widow_Ages_2003-2024_removedConfidentialFields_012725.xlsx") |> 
  read_excel(sheet = 1) |> 
  mutate(common_name = "widow rockfish", trawl_id = HAUL_JOIN) |> 
  as.data.frame()

# Compute comps -------------------------------------------

raw_ashop_lengths_historic <- get_raw_comps(
  data = historical_length,
  comp_bins = c(8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46, 48, 50, 52, 54, 56),
  comp_column_name = "SIZE_GROUP",
  input_n_method = "tows", 
  two_sex_comps = TRUE,
  month = "7",
  fleet = "3",
  partition = 0,
  dir = NULL,
  printfolder = "forSS3",
  verbose = TRUE
)

raw_ashop_lengths_modern <- get_raw_comps(
  data = modern_length,
  comp_bins = c(8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46, 48, 50, 52, 54, 56),
  comp_column_name = "LENGTH",
  input_n_method = "tows", 
  two_sex_comps = TRUE,
  month = "7",
  fleet = "3",
  partition = 0,
  dir = NULL,
  printfolder = "forSS3",
  verbose = TRUE
)

raw_ashop_age <- get_raw_comps(
  data = ashop_age,
  comp_bins = c(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 
                27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40),
  comp_column_name = "AGE",
  input_n_method = "tows", 
  two_sex_comps = TRUE,
  month = "7",
  fleet = "3",
  partition = 2,
  age_error = 1,
  dir = NULL,
  printfolder = "forSS3",
  verbose = TRUE
)

# Save ----------------------------------------------------

write_csv(raw_ashop_lengths_historic$sexed, file = here("data_derived", "ASHOP_composition", "ASHOP_lengths_1976-1986_sexed.csv"))
write_csv(raw_ashop_lengths_historic$unsexed, file = here("data_derived", "ASHOP_composition", "ASHOP_lengths_1976-1986_unsexed.csv"))

write_csv(raw_ashop_lengths_modern$sexed, file = here("data_derived", "ASHOP_composition", "ASHOP_lengths_1992-2024_sexed.csv"))
write_csv(raw_ashop_lengths_modern$unsexed, file = here("data_derived", "ASHOP_composition", "ASHOP_lengths_1992-2024_unsexed.csv"))

write_csv(raw_ashop_age$sexed, file = here("data_derived", "ASHOP_composition", "ASHOP_age_sexed.csv"))
write_csv(raw_ashop_age$unsexed, file = here("data_derived", "ASHOP_composition", "ASHOP_age_unsexed.csv"))

save(raw_ashop_lengths_historic, raw_ashop_lengths_modern, raw_ashop_age, 
     file = here("data_derived", "ASHOP_composition", "ASHOP_comps.RData"))
