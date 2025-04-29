#' Combine HKL Discards into Landings
#'
#' This function modifies a model's catch and discard data for the HKL fleet by
#' adding the discard data into the corresponding landings. It also makes various
#' adjustments to the model's data and control files, such as removing HKL fleet 
#' discard data and updating fleet discard settings.
#'
#' @param model_dir The directory containing the model files (required).
#' @param hnl_fleet_id The fleet number for the HKL fleet. Default is 5.
#' 
#' @return None. Modifies the model in place and writes the updated files back to disk.
#' 
#' @examples
#' combine_hnl_discards("/path/to/model/directory")
#'
combine_hnl_discards <- function(model_dir, hnl_fleet_id = 5) {
  
  # Load the required library
  library(dplyr)
  
  # Create an empty list to store test results
  tests <- list()
  
  # Read the model from the given directory using r4ss
  mod <- r4ss::SS_read(model_dir)
  
  # Define the fleet number for the HKL fleet
  hnl_fleet <- hnl_fleet_id  # Fleet number for HKL fleet
  
  # Data file:
  # 1. Prepare the discard data for the HKL fleet
  hnl_disc <- mod$dat$discard_data %>%
    filter(fleet == hnl_fleet) %>%      # Filter for the specific fleet
    select(year, obs) %>%               # Select only the year and observed discard values
    distinct()                          # Ensure there are no duplicate rows
  
  # 2. Update the catch data by adding the discard data (if exists) to the catch data
  hnl_catch_new <- mod$dat$catch %>%
    filter(fleet == hnl_fleet) %>%          # Filter for the specific fleet
    full_join(hnl_disc, by = "year") %>%    # Join discard data with catch data by year (keeps all years from both)
    mutate(
      catch = coalesce(obs, 0) + coalesce(catch, 0)  # Add discard (obs) to catch, replacing NA with 0 for both
    ) %>%
    select(-obs)  # Remove the 'obs' column (discard data) after summing it to 'catch'
  
  # 3. Overwrite the original catch data with the updated catch values
  mod$dat$catch <- mod$dat$catch %>%
    filter(fleet != hnl_fleet) %>%  # Keep all data from fleets other than HKL fleet
    bind_rows(hnl_catch_new) %>%    # Add the updated catch data (with discards included)
    filter(year >= 0) %>%           # Keep only records with valid year values
    arrange(fleet)                  # Arrange data by fleet number for consistency
  
  # 4. Test: Count how many fleets have discard data
  tests$disc_flets <- table(mod$dat$discard_data$fleet)
  
  # 5. Adjust the number of discard fleets in the model
  mod$dat$N_discard_fleets <- 2
  
  # 6. Remove HKL fleet information from the discard fleet info
  mod$dat$discard_fleet_info <- mod$dat$discard_fleet_info %>% 
    filter(fleet != hnl_fleet)  # Remove HKL fleet from discard fleet info
  tests$discard_fleet_info <- mod$dat$discard_fleet_info  # Store the result in the test list
  
  # 7. Remove HKL discard data since it has been added to the catch
  mod$dat$discard_data <- mod$dat$discard_data %>%
    filter(fleet != hnl_fleet)  # Remove HKL fleet from discard data
  
  # 8. Remove length composition data: remove HKL discard length data
  mod$dat$lencomp <- mod$dat$lencomp %>%
    filter(!(fleet == hnl_fleet & part == 1))|>
    mutate(year = if_else(fleet == hnl_fleet & part == 1, abs(year) * -1, year))  # Adjust year for HKL fleet
  
  # 9. Test: Count how many length composition data points exist for each fleet
  tests$discard_lcomps <- mod$dat$lencomp %>%
    filter(year >= 0 & part == 1) %>%
    select(fleet, year) %>%
    count(fleet)  # Count the number of length composition records by fleet
  
  # 10. Adjust the control file: Set discard pattern for the fleet (for HKL fleet, change to 0)
  mod$ctl$size_selex_types <- mod$ctl$size_selex_types %>%
    mutate(fleet = rownames(mod$ctl$size_selex_types)) %>%
    mutate(Discard = if_else(fleet %in% c("BottomTrawl", "MidwaterTrawl"), 1, 0)) %>%
    select(-fleet)  # Remove fleet column after adjustment
  
  # 11. Test: Count the number of discard data points for each fleet
  tests$discard_amounts_fleets <- mod$dat$discard_data %>%
    count(fleet)
  
  # 12. Test: Show discard selection patterns
  tests$discard_sel_patterns <- cbind(mod$ctl$size_selex_types$Discard, rownames(mod$ctl$size_selex_types))
  
  #13. Delete the Hnl discard parameters
  # 13. Save the updated model (with changes) back to disk
  SS_write(inputlist = mod, dir = model_dir, overwrite = TRUE)
  
  # 14. Comment out HKL retention parameters in the control file
  ctl <- readLines(con = here(model_dir, "2025widow.ctl"))  # Read the control file
  hnl_slex_parm_lines <- stringr::str_which(ctl, "SizeSel_PRet_(1|2|3|4)_HnL")  # Identify lines with HKL retention parameters
  ctl[hnl_slex_parm_lines] <- paste0("#", ctl[hnl_slex_parm_lines])  # Comment out these lines
  writeLines(text = ctl, con = here(model_dir, "2025widow.ctl"))  # Save the modified control file back
  
  # 15. Print test results
  print(tests)
}
