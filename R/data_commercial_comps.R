
# Author: Mico Kineen

library("dplyr")
library("pacfintools")
library("here")

# Setup ---------------------------------------------------

## Read data ----------------------------------------------

## PacFin data for widow 2025
load(here("data_provided", "PacFIN", "PacFIN.WDOW.bds.25.Mar.2025.RData")) #BDS
load(here("data_provided", "PacFIN", "PacFIN.WDOW.CompFT.25.Mar.2025.RData")) #Catch

## Settings -----------------------------------------------

### Filtering variables -----------------------------------

# Variables are based on the filters used in the 2015 assessment, (2019 unavilable)
# docmented in the widoww code archive and can be found in the script "CommComps.R
common_name <- "WIDOW ROCKFISH" # Species common name based on NWFSC survey data
species_code <- "WDOW" # PacFIN species code
used_gears <- c("TWL","NET","MSC","POT","HKL")
good_lengths <- c("F", "T", "U")
good_methods <- c("R")
good_samples <- c("C","M","NA")
good_states <- c("WA", "OR", "CA")
good_age_method <- c("BB","B","U","NA")

### Get fish ticket numbers of shoreside hake samples (used to split ss hake from midwater fleet)
shore_hke_dahl_codes <- c("03","17")
shore_hke_ftid <- catch.pacfin |> 
  filter(DAHL_GROUNDFISH_CODE %in% shore_hke_dahl_codes)|>
  pull(FTID)

# Bins for biological data
length_bins <- seq(8, 56, by = 2) #widow_2019_data$lbin_vector
age_bins <- seq(0, 40, by = 1) #widow_2019_data$agebin_vector

### Survey weight-length ----------------------------------

weight_length_estimates <- nwfscSurvey::estimate_weight_length(
  bds_survey <- nwfscSurvey::pull_bio(
    common_name = "widow rockfish",
    survey = "NWFSC.Combo"),
  verbose = FALSE
)

### Gear groups -------------------------------------------

#List of gear groupings as per Hicks 2015 , appended fleets are commented
gear_mapping_2024 <- list(
  ShrimpTrawl = c("SST", "SHT", "PWT", "DST"),
  BottomTrawl = c("RLT", "GFT", "GFS", "GFL", "FTS", "FFT","BTT"), #added BTT
  MidwaterTrawl = c("OTW", "MDT","MPT","TWL"), #added TWL
  MiscTrawl = c("PRT", "DNT", "BMT"),
  Pot = c("BTR", "CLP", "CPT", "FPT", "OPT", "PRW"),
  HnL = c("JIG", "LGL", "OHL", "POL", "TRL", "VHL","HKL"),
  Net = c("DPN", "DGN", "GLN", "ONT", "SEN", "STN"),
  Other = c("DVG", "USP")
)

### Create gear groups based on PACFIN gear code, and associate with an agency sample number.

# The reason for doing this is that PACFIN_GEAR_CODE is dropped during cleaning, as fleets
# are aggregated to PACFIN_GEAR_GROUP level. This combines all midwater and bottom trawl fleets into 
# 'TWL' grouping, which makes splitting them more difficult

gear_groups_2024  <- bds.pacfin %>%
  dplyr::mutate(gear_group = case_when(
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["ShrimpTrawl"]] ~ "ShrimpTrawl",
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["BottomTrawl"]] ~ "BottomTrawl",
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["MidwaterTrawl"]] &
      !FTID %in% shore_hke_ftid ~ "MidwaterTrawl",
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["MidwaterTrawl"]] & 
      FTID %in% shore_hke_ftid ~ "Hake",    
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["Pot"]] ~ "Pot",
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["HnL"]] ~ "HnL",
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["Net"]] ~ "Net",
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["MiscTrawl"]] ~ "MiscTrawl",
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["Other"]] ~ "Other"
  ))|>
  distinct(AGENCY_SAMPLE_NUMBER,gear_group,SAMPLE_YEAR)

## Clean data ---------------------------------------------

bds_cleaned <- cleanPacFIN(
  Pdata = bds.pacfin |> filter(SAMPLE_YEAR >= 2005), #Only do post 2005 data
  keep_gears = used_gears,         
  CLEAN = TRUE,
  keep_age_method = good_age_method,
  keep_sample_type = good_samples,
  keep_sample_method = good_methods,
  keep_length_type = good_lengths,
  keep_states = good_states,
  spp = "widow rockfish"
)  |> left_join(gear_groups_2024,by = "AGENCY_SAMPLE_NUMBER")|> ##a ppend the gear_groups
  dplyr::mutate(
    stratification = paste(state,gear_group,sep = ".") # Stratification is a combination of gear and state (matches catch data formatting)
  ) |>
  dplyr::filter(!PACFIN_GEAR_NAME %in% c("XXX","OTH-KNOWN","DNSH SEINE")) #drop gears in NA and Misc catgories (not used in assessment)


## Format PacFIN dataset ----------------------------------

## add gear groups to the catch
catch.pacfin <- catch.pacfin %>%
  mutate(gear_group = case_when(
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["ShrimpTrawl"]] ~ "ShrimpTrawl",
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["BottomTrawl"]] ~ "BottomTrawl",
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["MidwaterTrawl"]] & !FTID %in% shore_hke_ftid ~ "MidwaterTrawl",
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["MidwaterTrawl"]] & FTID %in% shore_hke_ftid ~ "Hake",    
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["Pot"]] ~ "Pot",
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["HnL"]] ~ "HnL",
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["Net"]] ~ "Net",
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["MiscTrawl"]] ~ "MiscTrawl",
    PACFIN_GEAR_CODE %in% gear_mapping_2024[["Other"]] ~ "Other"
  ))


catch_formatted <- catch.pacfin |>
  filter(gear_group %in% unique(bds_cleaned$gear_group))|> #Only keep catch from fleets in bds
  
  filter(LANDING_YEAR >= 2005) |>
  formatCatch(
    strat = c("state","gear_group"),
    valuename = "LANDED_WEIGHT_MTONS"
  )

#Check the column names in formatted catch against the gear_group in bds
sort(colnames(catch_formatted)[-1]) == sort(unique(bds_cleaned$stratification))

# Composition expansions ----------------------------------

expand_and_write_pacfin <- function(cleaned_bds_dat = NULL, formatted_catch = NULL, comp_type = NULL, lbin_vector = NULL, abin_vector = NULL, ...) {
  
  # browser()
  # Collect dots arguments
  dots <- list(...)
  
  # Extract arguments for get_pacfin_expansions
  # (assuming maxExp is only for get_pacfin_expansions)
  expansion_args <- list(
    Pdata = cleaned_bds_dat, 
    Catch = formatted_catch, 
    weight_length_estimates = weight_length_estimates,
    Units = "LB"
  )
  
  # Add any expansion-specific arguments from dots
  # You may need to modify this list based on what get_pacfin_expansions accepts
  expansion_param_names <- c("maxExp", "verbose", "Exp_WA")
  for (param in expansion_param_names) {
    if (param %in% names(dots)) {
      expansion_args[[param]] <- dots[[param]]
    }
  }
  
  # Call get_pacfin_expansions with specific arguments
  expanded_comps <- do.call(get_pacfin_expansions, expansion_args)
  
  if(comp_type == "AGE") {
    # Create argument list for getComps (without maxExp)
    comps_args <- list(
      Pdata = dplyr::filter(expanded_comps, !is.na(Age)),
      Comps = comp_type,
      strat = "gear_group",
      defaults = c("gear_group", "fleet", "fishyr", "season"),
      weightid = "Final_Sample_Size_A"
    )
    
    # Add any getComps-specific arguments from dots
    # You may need to modify this list based on what getComps accepts
    comps_param_names <- c("verbose") # Add other params getComps accepts
    for (param in comps_param_names) {
      if (param %in% names(dots)) {
        comps_args[[param]] <- dots[[param]]
      }
    }
    
    # Call getComps with specific arguments
    age_comps_long <- do.call(getComps, comps_args) |>
      mutate(
        fleet = case_when(
          gear_group == "BottomTrawl" ~ "1",
          gear_group == "MidwaterTrawl" ~ "2",
          gear_group == "Hake" ~ "3",
          gear_group == "Net" ~ "4",
          gear_group == "HnL" ~ "5"
        ))
    
    # Similar approach for writeComps
    writeComps_args <- list(
      inComps = age_comps_long %>% select(-gear_group),
      month = as.numeric(7),
      fname = NULL,
      comp_bins = abin_vector,
      verbose = TRUE,
      column_with_input_n  = "n_stewart"
    )
    
    # Add any writeComps-specific arguments
    writeComps_param_names <- c("verbose") # Add other params writeComps accepts
    for (param in writeComps_param_names) {
      if (param %in% names(dots)) {
        writeComps_args[[param]] <- dots[[param]]
      }
    }
    
    comp_data <- do.call(writeComps, writeComps_args)
    
    ### Apply rules
    #1. Aging error is 2 until 2010, then 1 after
    #2. Month is always 7 for commercial data
    comp_data <- comp_data |>
      mutate(ageerr = if_else(year <= 2010, 2, 1)) |>
      select(-gear_group)|>
      rename(f0 = f00000,
             m0 = m00000)
      
    
  } else if(comp_type == "LEN") {
    
    
    # Create argument list for getComps for length
    comps_args <- list(
      Pdata = dplyr::filter(expanded_comps, !is.na(length)),
      Comps = comp_type,
      strat = "gear_group",
      defaults = c("fleet", "fishyr", "season"),
      weightid = "Final_Sample_Size_L"
    )
    
    # Add getComps-specific arguments
    comps_param_names <- c("verbose")
    
    for (param in comps_param_names) {
      if (param %in% names(dots)) {
        comps_args[[param]] <- dots[[param]]
      }
    }
    
    # Call getComps with specific arguments
    len_comps_long <- do.call(getComps, comps_args) |>
      mutate(
        fleet = case_when(
          gear_group == "BottomTrawl" ~ "1",
          gear_group == "MidwaterTrawl" ~ "2",
          gear_group == "Hake" ~ "3",
          gear_group == "Net" ~ "4",
          gear_group == "HnL" ~ "5"
        ))
    
    # Configure writeComps arguments for length
    writeComps_args <- list(
      inComps = len_comps_long %>% select(-gear_group),
      comp_bins = lbin_vector,
      verbose = TRUE,
      month = as.numeric(7),
      column_with_input_n  = "n_stewart"
      
    )
    

    # Add writeComps-specific arguments
    writeComps_param_names <- c("verbose", "month")
    for (param in writeComps_param_names) {
      if (param %in% names(dots)) {
        writeComps_args[[param]] <- dots[[param]]
      }
    }
    
    comp_data <- do.call(writeComps, writeComps_args)
    
    ### Apply rules
    #1. If the fish are unsex (sex = 0), then use partition - 1, otherwise 2
    comp_data <- comp_data |>
      select(-gear_group)
    
      } else {
        comp_data <- NULL 

      }
  
  #Fix the columns types
  comp_data <- comp_data|>
    mutate(month = as.numeric(as.character(month)),
           fleet = as.numeric(fleet))

  return(comp_data)
}



## Split formatted bds and catch data up by fleet ---------

# The reason for doing this is the the shore side hake needs to combined with the ashop data.
# and requires additional processing
bds_clean_BT_MWT_HNL <- bds_cleaned |> filter(gear_group %in% c("HnL","MidwaterTrawl","BottomTrawl"))
catch_formatted_BT_MWT_HNL <- catch_formatted|>select(c(LANDING_YEAR,any_of(contains(c("HnL","MidwaterTrawl","BottomTrawl")))))

bds_clean_HKE <- bds_cleaned |> filter(gear_group == "Hake")
catch_formatted_HKE <- catch_formatted|>select(c(LANDING_YEAR,any_of(contains("Hake"))))



## Generate the comp data for each group of fleets --------

## Bottom Trawl, Midwater and Hook nd Line
acomp_BT_MWT_HNL <- expand_and_write_pacfin(cleaned_bds_dat = bds_clean_BT_MWT_HNL,
                                            formatted_catch = catch_formatted_BT_MWT_HNL,
                                            maxExp = 300,
                                            comp_type = "AGE",
                                            abin_vector = age_bins )


lcomp_BT_MWT_HNL <- expand_and_write_pacfin(cleaned_bds_dat = bds_clean_BT_MWT_HNL,
                                            formatted_catch = catch_formatted_BT_MWT_HNL,
                                            maxExp = 300,
                                            comp_type = "LEN",
                                            lbin_vector = length_bins)

# Hake
acomp_HKE <- expand_and_write_pacfin(cleaned_bds_dat = bds_clean_HKE,
                                     formatted_catch = catch_formatted_HKE,
                                     maxExp = 300,
                                     comp_type = "AGE",
                                     abin_vector = age_bins )

lcomp_HKE <- expand_and_write_pacfin(cleaned_bds_dat = bds_clean_HKE,
                                     formatted_catch = catch_formatted_HKE,
                                     maxExp = 300,
                                     comp_type = "LEN",
                                     lbin_vector = length_bins)



# Combine Shoreside hake data with ASHOP ------------------

##Read in the ASHOP data
#ASHOP catch
ashop_catch <- readxl::read_xlsx(here("data_provided","ASHOP","A-SHOP_Widow_CatchData_removedConfidentialFields_1975-2024_012325.xlsx")) |>
  mutate(catch_mt = EXPANDED_SumOfEXTRAPOLATED_2SECTOR_WEIGHT_KG/1000)|>
  filter(YEAR >= 2005)|>
  select(YEAR,catch_mt)


### Unsexd ashop comps are not being used - do not read
#ASHOP comps sexed
ashop_age_comp_sex <- read.csv(here("data_derived","ASHOP_composition","ASHOP_age_sexed.csv"))

#age comp needs some light editing
ashop_age_comp <- ashop_age_comp_sex|>
  filter(year >= 2005)|>
  mutate(month = as.factor(month),
       ageerr = ifelse(year <= 2010,2,1))

#len comps
ashop_len_comp <- read.csv(here("data_derived","ASHOP_composition","ASHOP_lengths_1992-2024_sexed.csv"))

ashop_len_comp <- ashop_len_comp|>
  filter(year >= 2005)|>
  mutate(month = as.factor(month),
         partition = 2)

### Calculate the weighting factors based on catch

# Sum catches by year
weight_factors <- catch_formatted_HKE |>
  group_by(LANDING_YEAR)|>
  summarise(catch_mt_pacfin = CA.Hake + OR.Hake + WA.Hake)|> #get total landings by year
  left_join(ashop_catch |> rename(catch_mt_ashop = catch_mt),by = c("LANDING_YEAR" = "YEAR"))|> #join the ashop catches
  group_by(LANDING_YEAR) |> #calculate weighting factor by year (prop. by year)
  summarise(catch_mt_pacfin = catch_mt_pacfin,
            catch_mt_ashop = catch_mt_ashop,
            ashop_wf = catch_mt_ashop/sum(catch_mt_ashop,catch_mt_pacfin),
            pacfin_wf = catch_mt_pacfin/sum(catch_mt_ashop,catch_mt_pacfin))

### Now reweight the comps based on catch

## Check column names are the same
colnames(ashop_age_comp) == colnames(acomp_HKE)
age_col_order <- colnames(acomp_HKE)

hake_age_comps_combined <- acomp_HKE |>
  mutate(source = "pacfin" ) |>
  filter(sex != 0)|> # Drop the unsexed fish
  rbind(ashop_age_comp |> mutate(source = "ashop"))|>
  left_join(weight_factors , by = c("year" = "LANDING_YEAR"))|> #add the weighting factors
  mutate(across(f1:m40, ~ ifelse(source == "ashop", . * ashop_wf, . * pacfin_wf)))|> #weight the values
  group_by(year,fleet,sex) |> 
  summarise(across(input_n:m40,function(x){round(sum(x))}))|> #add the sample size - shoreside hake have been corrected already, so it just adds to ashop
  ungroup() |>
  mutate(ageerr = ifelse(year <= 2010,2,1), #append the dropped columns
         Lbin_lo = -1,
         Lbin_hi = -1,
         partition = 2,
         month = 7)|>
  select(all_of(age_col_order), everything())|> #Reorder baed on old df
  arrange(year,month,fleet,sex)


##Do the same fro length comps 
colnames(ashop_len_comp) == colnames(lcomp_HKE)
len_col_order <- colnames(lcomp_HKE)

hake_len_comps_combined <-lcomp_HKE |>
  mutate(source = "pacfin" ) |>
  filter(sex != 0)|> # Drop the unsexed fish
  rbind(
    ashop_len_comp|>mutate(source = "ashop"))|>
  
  left_join(weight_factors , by = c("year" = "LANDING_YEAR"))|> #add the weighting factors
  
  mutate(across(f8:m56, ~ ifelse(source == "ashop", . * ashop_wf, . * pacfin_wf)))|> #weight the values
  
  group_by(year,fleet,sex,month,partition) |> 
  summarise(across(input_n:m56,function(x){round(sum(x))}))|> #add the sample size - shoreside hake have been corrected already, so it just adds to ashop
  ungroup() |>
  mutate(
         partition = 2,
         month = 7)|>
  select(all_of(len_col_order), everything())|> #Reorder baed on old df
  arrange(year,month,fleet,sex)


# Combine age and length comps and save -------------------

widow_Comm_lcomps_2005_2025 <- rbind(lcomp_BT_MWT_HNL,hake_len_comps_combined)|>
  arrange(fleet,-sex)

widow_Comm_acomps_2005_2025 <- rbind(acomp_BT_MWT_HNL,hake_age_comps_combined)|>
  arrange(fleet,-sex)

## Read in the 2019 data file
widow_2019_dat <- r4ss::SS_readdat(file = here("data_provided",'2019_assessment',"2019widow.dat"))


# Check the combinations of fleet and sex by year for each flight.

update_yrs <- 2005:2018
update_fleets <- c(1,2,3,5)

widow_2019_dat$lencomp|>
  setNames(colnames(widow_Comm_lcomps_2005_2025))|>
  filter(year %in% update_yrs & fleet %in% update_fleets)|>
  group_by(year,fleet)|>
  summarise(
  partition_levels = n_distinct(partition),
sex_levels = n_distinct(sex),
.groups = "drop")->xxx



widow_2019_dat$lencomp|>
  setNames(colnames(widow_Comm_lcomps_2005_2025))|>
  filter(year %in% update_yrs & fleet %in% update_fleets)|>
group_by(year, fleet) %>%
  summarise(
    partition_levels = list(as.numeric(unique(partition))),
    sex_levels = list(as.numeric(unique(sex))))|>
  arrange(fleet)

# This checks the different levels of sex (0,3) by year for each fleet
# This matters as post 2019, unsexed fish are used, instead of assigning them to a sex
widow_2019_dat$lencomp|> 
  setNames(colnames(widow_Comm_lcomps_2005_2025))|>
  filter(year %in% update_yrs & fleet %in% update_fleets)|>
  group_by(year, fleet) %>%
  summarise(
    partition_levels = list(as.numeric(unique(partition))),
    sex_levels = list(as.numeric(unique(sex))))|>
  arrange(fleet)->sex_fleet_year

## The number of rows are different as in 2019 all unsexed fish were apportioned to 
## sexes, so only has rows of se = 3.

#length comps
widow_dat_replace_2005_2018_lencomp <- widow_2019_dat$lencomp |>
  setNames(colnames(widow_Comm_lcomps_2005_2025))|> #fix the names to new r4ss version
  filter(!(year %in% update_yrs & fleet %in% update_fleets))%>%  #Drop rows that have the relavent fleets
  bind_rows(widow_Comm_lcomps_2005_2025|>
              filter(year %in% update_yrs & fleet %in% update_fleets)) #add new data that has the realent fleet

#age comps
widow_dat_replace_2005_2018_age_comp <- widow_2019_dat$agecomp |>
  setNames(colnames(widow_Comm_acomps_2005_2025))|> #fix the names to new r4ss version
  filter(!(year %in% update_yrs & fleet %in% update_fleets))%>%  #Drop rows that have the relavent fleets
  bind_rows(widow_Comm_acomps_2005_2025|>
              filter(year %in% update_yrs & fleet %in% update_fleets)) #add new data that has the realent fleet


# #Save as csv files
write.csv(widow_dat_replace_2005_2018_lencomp,file = here("data_derived","PacFIN_compdata_2025","widow_dat_replace_2005_2018_lencomp.csv"),row.names = F)
write.csv(widow_dat_replace_2005_2018_age_comp,file = here("data_derived","PacFIN_compdata_2025","widow_dat_replace_2005_2018_agecomp.csv"),row.names = F)


#ii) 2019 model with yrs 2018 - 2025 appended
widow_pacfin_lencomp_2025 <- widow_2019_dat$lencomp |>
  setNames(colnames(widow_Comm_lcomps_2005_2025))|> #fix the names to new r4ss version
  rbind(widow_Comm_lcomps_2005_2025|> filter(year >= 2019))|>
  arrange(fleet,-sex)

widow_pacfin_agecomp_2025 <- widow_2019_dat$agecomp |>
  setNames(colnames(widow_Comm_acomps_2005_2025))|> #fix the names to new r4ss version
  rbind(widow_Comm_acomps_2005_2025|> filter(year >= 2019))|>
  arrange(fleet,-sex)

write.csv(widow_pacfin_lencomp_2025,file = here("data_derived","PacFIN_compdata_2025","widow_pacfin_lencomp_2025.csv"),row.names = F)
write.csv(widow_pacfin_agecomp_2025,file = here("data_derived","PacFIN_compdata_2025","widow_pacfin_agecomp_2025.csv"),row.names = F)

#iii) Raw 2005 - 2025 comp data files 
write.csv(widow_Comm_lcomps_2005_2025,file = here("data_derived","PacFIN_compdata_2025","Widow_Comm_lcomps_2005_2025.csv"),row.names = F)
write.csv(widow_Comm_acomps_2005_2025,file = here("data_derived","PacFIN_compdata_2025","Widow_Comm_acomps_2005_2025.csv"),row.names = F)