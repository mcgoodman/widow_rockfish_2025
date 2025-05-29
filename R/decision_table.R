#-----------------------------------------------------------------#
#-------- Decision table -----------------------------------------#
#-----------------------------------------------------------------#

# Code to implement a decision table for Widow rockfish based on the 2019
#report. 
# States of nature: low (M, h @ 12.5% quantile), base (M,h as estimated), high(M,h @ 87.5%)
# Management actions: 1) Constant catch of F 9000 MT, 2) ACL p*0.40, sig = 0.5, 3)ACL p*0.45, sig = 0.5
# Mico Kinneen 10/05/2025
 


#### Fomrtting the decision table 
library(dplyr)
library(tidyr)
library(stringr)
df <- read.csv(here("data_derived","decision_table","dec_table_results.csv"))
colnames(df)

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
  arrange(factor(scenario, levels = c("cc", "40", "45")), yr) %>%
  # Final column order
  select(
    scenario, yr, catch,
    SpawnBio_low, dep_low,
    SpawnBio_base, dep_base,
    SpawnBio_high, dep_high
  )|>
  mutate(scenario = case_when(
    scenario == "cc" ~ "Constant catch",
    scenario == "40" ~ "P*0.40",
    scenario == "45" ~ "P*0.45"
    
  ))

write.csv(dec_table_formatted,here("report","tables","dec_table_formatted.csv"))
write.csv(dec_table_formatted,here("data_derived","decision_table","dec_table_formatted.csv"))

#### Load the rdata files
#exec_tables <- 

###### End
# compare_ss3_mods(
#   replist = list(dec_table_reps[['cc_base']], dec_table_reps[['cc_low']], SS_output(here("scratch","decision_table","cc_high_fix_trienn_q"))),
#   plot_dir = here("figures", "decision_table","cc_plots_fix_par"),
#   plot_names = c("Base", "Low", "High"),
#   subplots = 1:17,
#   endyrvec = rep(2036, 3),
#   shadeForecast = TRUE,
#   tickEndYr = TRUE
# )



### Dec tbale wording 
# Priot assessments included ad additional axis of uncertainty, the strength of recent year classes. As no recent year classes were signicantly larger than average, this axis was not inlcuded 
