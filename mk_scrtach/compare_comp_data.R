


compare_ss3_comps <- function(old_dat,new_dat,comp_type,compare_years = NULL,compare_fleets = c(1,2,3,5),fleet_labels = c("Bottom Trawl","Midwater Trawl","Hake","Hook and Line")){
  
  browser()

  #Start by filtering and combining the two datasets.
  combined_dat <- old_dat|>
    setNames(colnames(new_dat))|>
    mutate(source = "old data")|>
    rbind(new_dat|>
            mutate(source = "new data"))|>
    filter(year %in% compare_years, #seelct the years and fleets 
           fleet %in% compare_fleets)
  

  #Split up into males and females
  # Create a function to handle the pivoting pattern
  split_sexes <- function(data, sex_filter, sex_code, keep_prefix, remove_prefix) {
    data %>%
      filter(sex == sex_filter) %>%
      select(-matches(paste0("^", remove_prefix, "\\d+$"))) %>%
      tidyr::pivot_longer(
        cols = matches(paste0("^", keep_prefix, "\\d+$")),
        names_to = comp_type_x,
        names_prefix = keep_prefix,
        values_to = "value"
      ) %>%
      mutate(sex = sex_code)
  }
  
  # Process all groups with a single function call
  df_f <- split_sexes(combined_dat, 3, "f", "f", "m")
  df_m <- split_sexes(combined_dat, 3, "m", "m", "f")
  df_u <- split_sexes(combined_dat, 0, "u", "f", "m")
  
    
  return(combined_dat)
}

old_dat <- SS_readdat(here(base_model_dir, "2019widow.dat"))[["lencomp"]]
new_dat <- widow_Comm_lcomps_2005_2025

compare_ss3_comps(old_dat = old_dat,new_dat = new_dat,comp_type = "LEN",compare_years = 2005:2018)
