
library("here")
library("flextable")
library("pacfintools")
library("tidyverse")
library("r4ss")

read_rdata <- function(path) {load(path); get(ls()[ls() != "path"])}

# Executive summary tables ------------------------------------------

unlink(here("report", "tables", "exec_summ_tables"), recursive = TRUE, force = TRUE)

rep_2025 <- SS_output(here("models", "2025 base model"))

table_exec_summary(
  replist = rep_2025,
  dir = here("report", "tables"),
  ci_value = 0.95,
  fleetnames = rep_2025$FleetNames,
  so_units = "biomass (mt)",
  endyr = 2025,
  verbose = TRUE
)

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

# Table 22 - bioloigal params ---------------------------------------

pars <- rep_2025$parameters
rownames(pars) <- NULL

df <- pars[1:20, c("Label","Init", "Active_Cnt", "Min", "Max", "Pr_type", "Prior", "Pr_SD")] |>
  mutate(
    "Initial value" = round(Init, 4),
    "Number estimated" = if_else(Active_Cnt > 0, 1, 0),
    "Bounds (low,high)" = paste0("(", round(Min, 2), "-", round(Max, 3), ")"),
    "Prior Distribution" = if_else(
      Pr_type == "No_prior",
      "",
      paste0("LN(", round(Prior, 2), ",", round(Pr_SD, 2), ")")
    ),
    "Parameter" = c(
      "Natural Mortality (M) yr^-1",
      "Length at age 3",
      "Length at age 40",
      "von Bertalanffy K",
      "ln(SD) of length at age 3",
      "ln(SD) of length at age 40",
      "Maturity-at-age inflection",
      "Maturity-at-age slope",
      "Fecundity intercept",
      "Fecundity slope",
      "Length-weight intercept",
      "Length-weight slope",
      "Natural Mortality (M) yr^-1",
      "von Bertalanffy K",
      "ln(SD) of length at age 3",
      "ln(SD) of length at age 40",
      "Fecundity intercept",
      "Fecundity slope",
      "Length-weight intercept",
      "Length-weight slope"
    )
  ) |>
  select("Parameter", "Initial value", "Number estimated", "Bounds (low,high)", "Prior Distribution")

# Insert labels
table_22_dat <- bind_rows(
  tibble(Parameter = "Female", `Initial value` = NA, `Number estimated` = NA, `Bounds (low,high)` = NA, `Prior Distribution` = NA),
  df[1:12, ],
  tibble(Parameter = "Male", `Initial value` = NA, `Number estimated` = NA, `Bounds (low,high)` = NA, `Prior Distribution` = NA),
  df[13:20, ]
)

write.csv(table_22_dat, here("report", "tables", "table_22.csv"), row.names = FALSE)

# Table 23 - parms ests with sd -------------------------------------

pars <- rep_2025$parameters[c(23,165:176,1:6,13:18),c("Value","Parm_StDev")]
table_23 <-  data.frame(
    "Estimate" =  c(10.4371000,NA,NA, -5.9952400  , 0.1643070 ,-11.1167000 ,  0.3712210 , -1.6365200,
               1.6880700 , -2.0584200  , 0.0000000 , -3.1407500 ,  0.0000000 ,-11.4354000,
                0.5779650,NA,NA,   0.1245990 , 20.6525000,  49.5239000,   0.1811070,   0.1158400,
                0.0481482,NA,NA,   0.1367750 , 21.0408000,  43.6366000,   0.2446380,   0.0941347,
                0.0568501),
    "SD" = c(0.16852800 , NA,NA,        NA, 0.06078100, 0.18970500, 0.08632240,         NA,
            0.36919200 ,0.37249900 ,        NA ,        NA ,        NA ,        NA,
             0.15171500,NA,NA, 0.00823428, 0.45710200, 0.25586000, 0.00621185, 0.00930326,
             0.00265739,NA,NA, 0.00840429, 0.39136500, 0.23452200, 0.00931440, 0.00703868,
             0.00275296),
    "Parameter" = c("LN(R0)",
                    "",
                    "Survey",
                    
                  "Bottom trawl (q)",
                  "Bottom trawl (extra SE)",
                  "Domestic at-sea hake (q)",
                  "Domestic at-sea hake (extra SE)",
                  "Juvenile (q)",
                  "Juvenile (extra SE)",
                  "Foreign at-sea hake (q)",
                  "Foreign at-sea hake (extra SE)",
                  "Triennial (q)",
                  "Triennial (extra SE)",
                  "NWFSC WCGBT (q)",
                  "NWFSC WCGBT (SE)",
                  "",
                  "Biological - Female",
                  "Natural Mortality (M)",
                  "Length at age 3",
                  "Length at age 40",
                  "Von Bertalanaffy K",
                  "SD (log) at age 3",
                  "SD (log) at age 40",
                  "",
                  "Biological - Female",
                  "Natural Mortality (M)",
                  "Length at age 3",
                  "Length at age 40",
                  "Von Bertalanaffy K",
                  "SD (log) at age 3",
                  "SD (log) at age 40"))|>
  mutate(Estimate = if_else(Parameter %in% c( "Bottom trawl (q)",
                                           "Domestic at-sea hake (q)",
                                           "Juvenile (q)",
                                           "Foreign at-sea hake (q)",
                                           "Triennial (q)",
                                           "NWFSC WCGBT (q)"),exp(Estimate),Estimate))|>
  mutate(
    Estimate = if_else(is.na(Estimate), "", sprintf("%.3f", Estimate)),
    SD = if_else(is.na(SD), "", sprintf("%.3f", SD))
  ) |>
   select(Parameter,Estimate,SD)

write.csv(table_23, here("report", "tables", "table_23.csv"), row.names = FALSE)

# Table 24 - Param ests and sd for selex pars -----------------------

temp <- rep_2025$parameters[179:270,c("Value","Parm_StDev","Phase")]
temp <- temp|>filter(Phase >= 1)
names <- rownames(temp)  

table_24 <- temp |>
  mutate(`Selectivity Parameter` = names) |>
  rename(
    Estimate = Value,
    SD = Parm_StDev
  ) |>
  mutate(Fleet = case_when(
    grepl("BottomTrawl", `Selectivity Parameter`) ~ "Bottom trawl",
    grepl("MidwaterTrawl", `Selectivity Parameter`) ~ "Midwater trawl",
    grepl("Hake", `Selectivity Parameter`) ~ "Hake",
    grepl("Net", `Selectivity Parameter`) ~ "Net",
    grepl("HnL", `Selectivity Parameter`) ~ "Hook and Line",
    grepl("NWFSC", `Selectivity Parameter`) ~ "NWFSC",
    TRUE ~ "Other"
  )) |>
  mutate(`Time block` = case_when(
    grepl("1916", `Selectivity Parameter`) ~ "1916",
    grepl("1983", `Selectivity Parameter`) ~ "1983",
    grepl("1998", `Selectivity Parameter`) ~ "1998",
    grepl("1982", `Selectivity Parameter`) ~ "1982",
    grepl("1990", `Selectivity Parameter`) ~ "1990",
    grepl("2002", `Selectivity Parameter`) ~ "2002",
    grepl("2011", `Selectivity Parameter`) ~ "2011",
    TRUE ~ "NA"
  ))|>
  select(c('Selectivity Parameter',Estimate,SD,Fleet,'Time block'))

rownames(table_24) <- NULL

write.csv(table_24, here("report", "tables", "table_24.csv"), row.names = FALSE)

# Table 25 - Liketemp## Table 25 - Likelihood results ---------------

rep_2025$N_estimated_parameters
lik_vals <-   c(rep_2025$N_estimated_parameters,NA,NA,7.66449e+03, 1.30223e+01, 5.41079e+03, 8.54968e+02,
              1.36628e+03, 1.78401e+01, 6.00503e-01, 9.83289e-01)

lik_names <- c("N parameters","","Log-likelihoods","Total","Indices","Discard","Length-frequency data", "Age-frequency data","Recruitment","Priors","Parameter Softbound")


table_25 <- data.frame(
  Description = lik_names,
  Values = round(lik_vals,5)
)|>
  mutate(Values = if_else(is.na(Values), "", as.character(Values)))

rownames(table_25) <- NULL

write.csv(table_25, here("report", "tables", "table_25.csv"), row.names = FALSE)


# Table 28 - recruitment deviates -----------------------------------

temp <- rep_2025$parameters[44:152,c("Value","Parm_StDev")]
names <- rownames(temp)
years <- as.numeric(stringr::str_extract(names, "(?<=_)\\d{4}"))
table_28 <- tibble(
  "Year" = years,
  "Recruitment Deviate" = temp$Value,
  "SD" = temp$Parm_StDev
  
)

write.csv(table_28, here("report", "tables", "table_28.csv"), row.names = FALSE)

# Table 27 - Time series of population estimates --------------------

unf_bio <- rep_2025$timeseries$SpawnBio[1]
rep_2025$timeseries |>
  filter(Yr %in% 1916:2025) |>
  group_by(Yr) |>
  summarise(
    'Total biomass(mt)' = Bio_all,
    'SpawningBiomass (mt)' = SpawnBio,
    'Age 4+ biomass(mt)' = mature_bio,
    'SpawningDepletion(%)' = SpawnBio/unf_bio,
    'Age-0 recruits' = Recruit_0,
    'Estimated Total Catch(mt)' = sum(as.numeric(unlist(select(rep_2025$timeseries[rep_2025$timeseries$Yr == Yr,], 
                                                               matches("obs_cat:_[1-5]")))), na.rm = TRUE)
  ) |>
  mutate(
    # Add the SPR data properly joined by year
    `1- SPR(%)` = 1 - rep_2025$sprseries[match(Yr, rep_2025$sprseries$Yr), "SPR"],
    # Calculate the exploitation rate using the numeric columns
    `Relative exploitation rate (%)` = `Estimated Total Catch(mt)` / `SpawningBiomass (mt)` * 100
  )->table_27_dat

write.csv(table_27_dat, here("report", "tables", "table_27.csv"), row.names = FALSE)

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
