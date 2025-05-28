
library("here")
library("flextable")
library("pacfintools")
library("tidyverse")
library("r4ss")

read_rdata <- function(path) {load(path); get(ls()[ls() != "path"])}

# Executive summary tables ------------------------------------------

unlink(here("report", "tables", "exec_summ_tables"), recursive = TRUE, force = TRUE)

rep_2025 <- SS_output(here("models", "2025 base model"))

# table_exec_summary(
#   replist = rep_2025,
#   dir = here("report", "tables"),
#   ci_value = 0.95,
#   fleetnames = rep_2025$FleetNames,
#   so_units = "biomass (mt)",
#   endyr = 2025,
#   verbose = TRUE
# )

r4ss::table_all(replist = rep_2025,verbose = T,dir = here("report", "tables"))


file.rename(here("report", "tables", "tables"), here("report", "tables", "exec_summ_tables"))

# Parameter tables --------------------------------------------------

# Creates output in report/tables
table_pars(rep_2025, dir = here("report"))

# Add GMT reference points to exec summary --------------------------

# GMC reference point table
gmt_refs <- read.csv(here("data_provided", "GMT_forecast_catch", "GMT016_stock_summary.csv"))
load(here("report", "tables", "exec_summ_tables", "recent_management.rda"))

recent_management$table <- recent_management$table |>
  select(-`OFL (mt)`, -`ABC (mt)`, -`ACL (mt)`) |>
  left_join(gmt_refs |>
              filter(SPECIFICATION_NAME == "Overfishing Limit") |>
              mutate('OFL (mt)' = VAL) |>
              select(YEAR,'OFL (mt)'), by = c("Year" = "YEAR")) |>
  left_join(gmt_refs |>
              filter(SPECIFICATION_NAME == "Acceptable Bio Catch") |>
              mutate('ABC (mt)' = VAL) |>
              select(YEAR,'ABC (mt)'), by = c("Year" = "YEAR")) |>
  left_join(gmt_refs |>
              filter(SPECIFICATION_NAME == "Annual Catch Limit") |>
              mutate('ACL (mt)' = VAL) |>
              select(YEAR,'ACL (mt)'), by = c("Year" = "YEAR")) |>
  mutate(across(where(is.numeric), \(x) round(x, digits = 2))) |>
  select(Year, `OFL (mt)`, `ABC (mt)`, `ACL (mt)`, `Landings (mt)`, `Total Mortality (mt)`)

save(recent_management, file = here("report", "tables", "exec_summ_tables", "recent_management.rda"))

# Populate projection table -----------------------------------------

load(here("report", "tables", "exec_summ_tables", "projections.rda"))

gmt_25_26 <- gmt_refs |> 
  filter(YEAR == 2026) |> mutate(spec = case_when(
    SPECIFICATION_NAME == "Overfishing Limit" ~ "OFL (mt)", 
    SPECIFICATION_NAME == "Acceptable Bio Catch" ~ "ABC (mt)", 
    SPECIFICATION_NAME == "Annual Catch Limit"  ~ "ACL (mt)"
  )) |>
  filter(!is.na(spec)) |> 
  select(Year = YEAR, spec, VAL) |> 
  pivot_wider(names_from = "spec", values_from = "VAL")

projections$table <- projections$table |> rows_update(gmt_25_26, by = "Year")
  
save(projections, file = here("report", "tables", "exec_summ_tables", "projections.rda"))

# Table 1 - Landings for non-hake fleets ----------------------------

# Landings for bottom trawl, midwater trawl, net, and hook-and-line (mt) 
# fisheries from Washington, Oregon, and California.

catch_st_flt_yr <- read.csv(here("data_derived", "catches", "2025_catch_st_flt_yr.csv"))

table1_dat <- catch_st_flt_yr |> 
  filter(fleet != "hake") |> 
  mutate(
    fleet = gsub(" ", "-", gsub("And", "and", stringr::str_to_title(fleet))),
    st_fleet = paste(toupper(str_sub(state, 1, 2)), fleet, sep = "_"), 
    landings_mt = round(landings_mt, 1) 
  ) |>
  dplyr::select(Year = year, st_fleet, landings_mt) |> 
  pivot_wider(names_from = "st_fleet", values_from = "landings_mt") |> 
  dplyr::select(
    Year, 
    `CA_Bottom-Trawl`, `OR_Bottom-Trawl`, `WA_Bottom-Trawl`, 
    `CA_Midwater-Trawl`, `OR_Midwater-Trawl`, `WA_Midwater-Trawl`, 
    `CA_Net`, `WA_Net`, 
    `CA_Hook-and-Line`, `OR_Hook-and-Line`, `WA_Hook-and-Line`, 
  ) |> 
  arrange(Year)

write.csv(table1_dat, here("report", "tables", "landings_nonhake.csv"), row.names = FALSE)
  
# Table 2 - Hake landings -------------------------------------------

table2_dat <- catch_st_flt_yr |> 
  filter(fleet == "hake") |> 
  mutate(
    state_sector = factor(case_when(
      sector == "at-sea" ~ "At-Sea Foreign & Domestic", 
      sector == "shoreside" ~ paste(toupper(str_sub(state, 1, 2)), "Shoreside", sep = "_")
    ), levels = c("At-Sea Foreign & Domestic", "CA_Shoreside", "OR_Shoreside", "WA_Shoreside")
    ), 
    landings_mt = round(landings_mt, 1)
  ) |>
  dplyr::select(Year = year, state_sector, landings_mt) |> 
  pivot_wider(names_from = "state_sector", values_from = "landings_mt") |> 
  arrange(Year)

write.csv(table2_dat, here("report", "tables", "landings_hake.csv"), row.names = FALSE)

# Table 10 - Length trips for gear and state, non-hake --------------

source(here("R", "commerical_comps_clean_expand.R"))

catch_formatted_all <- catch.pacfin |>
  filter(gear_group %in% unique(bds_cleaned$gear_group)) |> #Only keep catch from fleets in bds
  filter(gear_group != "Hake") |>
  formatCatch(
    strat = c("state", "gear_group"),
    valuename = "LANDED_WEIGHT_MTONS"
  )|>
  rename(Year = LANDING_YEAR)

bds_cleaned_all <- cleanPacFIN(
  Pdata = bds.pacfin,
  keep_gears = used_gears,         
  CLEAN = TRUE,
  keep_age_method = good_age_method,
  keep_sample_type = good_samples,
  keep_sample_method = good_methods,
  keep_length_type = good_lengths,
  keep_states = good_states,
  spp = "widow rockfish"
) |> 
  left_join(gear_groups_2024, by = "AGENCY_SAMPLE_NUMBER") |>
  mutate(stratification = paste(state, gear_group, sep = ".")) |>
  filter(!PACFIN_GEAR_NAME %in% c("XXX", "OTH-KNOWN", "DNSH SEINE"))

length_trips <- bds_cleaned_all |> 
  filter(gear_group != 'Hake',SAMPLE_YEAR.x <= 2024) |> 
  distinct(SAMPLE_YEAR.x, gear_group, state, SAMPLE_NO) |> 
  count(SAMPLE_YEAR.x, gear_group, state, name = "n") |> 
  rename(Year = SAMPLE_YEAR.x) %>%
  complete(Year, gear_group = c("BottomTrawl", "MidwaterTrawl", "Net", "HnL"),
           state = c("CA", "OR", "WA"), fill = list(n = 0)) |> 
  pivot_wider(
    names_from = c(gear_group, state),
    values_from = n,
    names_sep = "_"
  ) %>%
  select(Year, BottomTrawl_CA, BottomTrawl_OR, BottomTrawl_WA,
         MidwaterTrawl_CA, MidwaterTrawl_OR, MidwaterTrawl_WA,
         Net_CA, Net_WA, HnL_CA, HnL_OR, HnL_WA) 

write.csv(length_trips, here("report", "tables", "length_trips_nonhake.csv"), row.names = FALSE)

# Table 11 - Length samples for gear and state, non-hake ------------

length_samples <- bds_cleaned_all %>%
  filter(gear_group != 'Hake',SAMPLE_YEAR.x <= 2024) %>%
  count(SAMPLE_YEAR.x, gear_group, state)|>
  rename(Year = SAMPLE_YEAR.x) %>%
  complete(Year, gear_group = c("BottomTrawl", "MidwaterTrawl", "Net", "HnL"),
           state = c("CA", "OR", "WA"), fill = list(n = 0)) %>%
  pivot_wider(
    names_from = c(gear_group, state),
    values_from = n,
    names_sep = "_"
  ) %>%
  select(Year, BottomTrawl_CA, BottomTrawl_OR, BottomTrawl_WA,
         MidwaterTrawl_CA, MidwaterTrawl_OR, MidwaterTrawl_WA,
         Net_CA, Net_WA, HnL_CA, HnL_OR, HnL_WA)

write.csv(length_samples, here("report", "tables", "length_samples_nonhake.csv"), row.names = FALSE)

# Table 12 - Number of trips for hake -------------------------------

ashop_hke <- readxl::read_excel(here('data_provided','ashop','A_SHOP_Widow_Lengths_1976-2024_removedConfiendtialFields_012725.xlsx'))|>
  select(HAUL_JOIN,YEAR,LENGTH)|>
  mutate(source = "ASHOP")|>
  rename(SAMPLE_NO = HAUL_JOIN)

ss_hake <- bds_cleaned_all|>filter(gear_group == "Hake")|>
  select(SAMPLE_NO,SAMPLE_YEAR.x,length)|>
  rename(YEAR = SAMPLE_YEAR.x,
         LENGTH = length)|>
  mutate(source = "SS")

## The number of landings sampled
trips_sampled <- ashop_hke |> 
  rbind(ss_hake)|>
  select(!LENGTH)|>
  group_by(YEAR, source) %>%
  summarise(unique_count = n_distinct(SAMPLE_NO))|>
  pivot_wider(
    names_from = source,
    values_from = unique_count,
    values_fill = 0
  )|>
  rename('landings_At-Sea' = ASHOP,
         'landings_Shoreside' = SS)

## The number of length sampled
lengths_sampled <- ashop_hke |> 
  rbind(ss_hake) |>
  filter(!is.na(LENGTH)) |>
  group_by(YEAR, source) |> 
  summarise(total_rows = n(), .groups = "drop") |> 
  pivot_wider(
    names_from = source,
    values_from = total_rows,
    values_fill = 0
  ) |>
  rename('lengths_At-Sea' = ASHOP,
         'lengths_Shoreside' = SS)

##bind all together and write to a csv
hake_lengths <- trips_sampled |> left_join(lengths_sampled, by = 'YEAR')
write.csv(hake_lengths, here("report", "tables", "lengths_hake.csv"), row.names = FALSE)

# Table 13 - sampled age trips by fleet and state for non-hake ------

table_13_dat <- bds_cleaned_all %>%
  filter(!is.na(Age))|>
  filter(gear_group != 'Hake',SAMPLE_YEAR.x <= 2024) %>%
  distinct(SAMPLE_YEAR.x, gear_group, state, SAMPLE_NO) %>%
  count(SAMPLE_YEAR.x, gear_group, state, name = "n") %>%
  rename(Year = SAMPLE_YEAR.x) %>%
  complete(Year, gear_group = c("BottomTrawl", "MidwaterTrawl", "Net", "HnL"),
           state = c("CA", "OR", "WA"), fill = list(n = 0)) %>%
  pivot_wider(
    names_from = c(gear_group, state),
    values_from = n,
    names_sep = "_"
  ) %>%
  select(Year, BottomTrawl_CA, BottomTrawl_OR, BottomTrawl_WA,
         MidwaterTrawl_CA, MidwaterTrawl_OR, MidwaterTrawl_WA,
         Net_CA, Net_WA, HnL_CA, HnL_OR, HnL_WA) 

write.csv(table_13_dat, here("report", "tables", "age_trips_nonhake.csv"), row.names = FALSE)

# Table 14 - age samples by fleet and state for non-nake ------------

table_14_dat <- bds_cleaned_all %>%
  filter(!is.na(Age))|>
  filter(gear_group != 'Hake',SAMPLE_YEAR.x <= 2024) %>%
  count(SAMPLE_YEAR.x, gear_group, state)|>
  rename(Year = SAMPLE_YEAR.x) %>%
  complete(Year, gear_group = c("BottomTrawl", "MidwaterTrawl", "Net", "HnL"),
           state = c("CA", "OR", "WA"), fill = list(n = 0)) %>%
  pivot_wider(
    names_from = c(gear_group, state),
    values_from = n,
    names_sep = "_"
  ) %>%
  select(Year, BottomTrawl_CA, BottomTrawl_OR, BottomTrawl_WA,
         MidwaterTrawl_CA, MidwaterTrawl_OR, MidwaterTrawl_WA,
         Net_CA, Net_WA, HnL_CA, HnL_OR, HnL_WA)


write.csv(table_14_dat, here("report", "tables", "age_samples_nonhake.csv"), row.names = FALSE)

# Table 15 - age trips / samples for hake fleet ---------------------

## Number of landings and number of ages sampled from the at-sea hake and shoreside hake fisheries. 

ashop_hke_age <- readxl::read_excel(here('data_provided','ashop','A_SHOP_Widow_Ages_2003-2024_removedConfidentialFields_012725.xlsx'))|>
  select(HAUL_JOIN,YEAR,AGE)|>
  mutate(source = "ASHOP")|>
  rename(SAMPLE_NO = HAUL_JOIN)

ss_hake_age <- bds_cleaned_all|>filter(gear_group == "Hake")|>
  filter(!is.na(Age))|>
  select(SAMPLE_NO,SAMPLE_YEAR.x,Age)|>
  rename(YEAR = SAMPLE_YEAR.x,
         AGE = Age)|>
  mutate(source = "SS")

## The number of landings sampled
age_landings_sampled <- ashop_hke_age |> 
  rbind(ss_hake_age)|>
  filter(!is.na(AGE))|>
  group_by(YEAR,source) %>%
  summarise(unique_count = n_distinct(SAMPLE_NO))|>
  pivot_wider(
    names_from = source,
    values_from = unique_count,
    values_fill = 0
  )|>
  rename('landings_At-Sea' = ASHOP,
         'landings_Shoreside' = SS)

## The number of ages sampled
ashop_hke_age |> 
  rbind(ss_hake_age)|>
  filter(!is.na(AGE))|>
  group_by(YEAR,source) %>%
  summarise(total_rows = n(), .groups = "drop") %>%
  pivot_wider(
    names_from = source,
    values_from = total_rows,
    values_fill = 0
  )|>
  rename('ages_At-Sea' = ASHOP,
         'ages_Shoreside' = SS)->ages_sampled

##bind all together and write to a csv
table_15_dat <- age_landings_sampled |> left_join(ages_sampled, by = 'YEAR') |> rename(Year = YEAR)
write.csv(table_15_dat, here("report", "tables", "ages_hake.csv"), row.names = FALSE)

# Table 25 - Liketemp## Table 25 - Likelihood results ---------------

lik_vals <- rep_2025$likelihoods_used |> 
  rownames_to_column("component") |> 
  mutate(values = round(values, 3)) |>
  filter(values > 0) |> 
  rename(`log-likelihood` = values) |> 
  mutate(
    component = case_when(
      component == "TOTAL" ~ "Total", 
      grepl("_comp", component) ~ gsub("_comp", " composition", component), 
      component == "Forecast_Recruitment" ~ "Forecast Recruitment", 
      component == "Parm_priors" ~ "Priors",
      component == "Parm_softbounds" ~ "Softbounds", 
      .default = component
    )
  )

write.csv(lik_vals, here("report", "tables", "likelihood_components.csv"), row.names = FALSE)

# Decision analysis table -------------------------------------------


df <- read.csv(here("data_derived", "decision_table", "dec_table_results.csv"))

dec_table_formatted <- df %>%
  # Extract scenario and level from name
  mutate(
    scenario = str_extract(name, "^[^_]+"),
    level = str_extract(name, "(?<=_)\\w+"),
    dep = round(dep*100,2)
  ) %>%
  # Select relevant columns
  select(yr, catch, scenario, level, SpawnBio, dep) %>%
  # Group by scenario and year, as each has multiple levels
  group_by(scenario, yr) %>%
  # Take the first catch (should be same across levels)
  mutate(catch = first(catch)) %>%
  ungroup() %>%
  # Pivot wider for SpawnBio and dep
  pivot_wider(
    names_from = level,
    values_from = c(SpawnBio, dep),
    names_glue = "{.value}_{level}"
  ) %>%
  # Reorder by scenario and year
  arrange(factor(scenario, levels = c("cc", "25", "45")), yr) %>%
  # Final column order
  select(
    scenario, yr, catch,
    SpawnBio_low, dep_low,
    SpawnBio_base, dep_base,
    SpawnBio_high, dep_high
  )|>
  mutate(scenario = case_when(
    scenario == "cc" ~ "Constant catch",
    scenario == "25" ~ "P*0.25",
    scenario == "45" ~ "P*0.45"
    
  ))

write.csv(dec_table_formatted, here("report", "tables", "dec_table_formatted.csv"), row.names = FALSE)
write.csv(dec_table_formatted, here("data_derived", "decision_table", "dec_table_formatted.csv"), row.names = FALSE)
