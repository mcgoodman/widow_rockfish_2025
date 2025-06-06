
# Process age and length composition from WCGBTS survey
# Authors: Alaia Morell, Maurice Goodman

library("nwfscSurvey")
library("dplyr")
library("here")

dir.create(save_dir <- here("data_derived", "NWFSCCombo"))

# Retrieve data -------------------------------------------

catch = pull_catch(common_name = "widow rockfish", survey = "NWFSC.Combo")

bio = pull_bio(common_name = "widow rockfish", survey = "NWFSC.Combo")

# Length composition --------------------------------------

age_bins <- 0:40
length_bins <- seq(8, 56, by = 2)

# Define the strata
strata <- CreateStrataDF.fn(
  names = c("South - shallow", "South - deep", "North - shallow", "North - deep"), 
  depths.shallow = c(  55,  183,  55, 183),
  depths.deep    = c( 183,  400, 183, 400),
  lats.south     = c(34.5, 34.5,  40.5,  40.5),
  lats.north     = c(  40.5,   40.5,  49,  49)
)

# Length composition data 
length_comps <- get_expanded_comps(
  bio_data = bio,
  catch_data = catch,
  comp_bins = length_bins,
  strata = strata,
  comp_column_name = "length_cm",
  output = "full_expansion_ss3_format",
  two_sex_comps = TRUE,
  input_n_method = "stewart_hamel"
)

length_comps_data <- length_comps$sexed |> mutate(month = 7, fleet = 8)
  
write.csv(length_comps_data, here(save_dir, "NWFSCCombo_length_comps_data.csv"), row.names = FALSE)

plot_comps(data = length_comps)

# Conditional age-at-length -------------------------------

# each row is divided by the count and * 100 to have proportion
caal <- bio |> 
  get_raw_caal(len_bins = length_bins,age_bins = age_bins) |> 
  mutate(ageerr = 1) |> 
  filter(sex != 0) |> 
  mutate(
    across(10:91, ~ .x / input_n * 100),
    month = 7, 
    fleet = 8
  ) 

write.csv(caal, here(save_dir, "NWFSCCombo_conditional_age-at-length.csv"), row.names = FALSE)

# Summary statistics (for report) -------------------------

qvec <- c(0.01, 0.25, 0.5, 0.75, 0.99, 0.999, 1)

age_quants <- list(
  pre_2018 = quantile(bio$Age_years[bio$Year <= 2018], qvec, na.rm = TRUE, type = 1), 
  post_2018 = quantile(bio$Age_years[bio$Year >= 2018], qvec, na.rm = TRUE, type = 1), 
  all = quantile(bio$Age_years, qvec, na.rm = TRUE, type = 1)
)

saveRDS(age_quants, file = here(save_dir, "nwfsc_age_quantiles.rds"))
