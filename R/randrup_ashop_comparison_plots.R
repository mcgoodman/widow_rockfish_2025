# compare ashop data from 2019 assessment and present ashop data
# code initally from Sebastes_ruberrimus_2025 repository -- Claire Rosemond and Elizabeth Perl
# modified by Kristina Randrup for FISH 576 & 577

# load libraries
library(here)
library(tidyverse)
library(nwfscSurvey)

# Comparison plots
# IPHC lengths
# Read new data
ashop_lengths_new <- read.csv(here("data", "cleaned", "ASHOP_lengths_1992-2024_sexed.csv"))
ashop_lengths_new <- ashop_lengths_new %>% 
  mutate(assessment = "Current") %>% 
  dplyr::select(-month, -fleet, -sex, -partition)
ashop_lengths_new <- ashop_lengths_new %>% 
  tidyr::pivot_longer(cols = c(-year, -assessment, -input_n), names_to = "bin", values_to = "freq") %>% 
  mutate(sex = str_sub(bin, 1, 1), length = as.integer(str_sub(bin, 2))) %>% 
  dplyr::group_by(year) %>% 
  dplyr::mutate(
    freq = freq / sum(freq),
    # NsampsFreq = freq/unique(Nsamps), still waiting on these
    length = as.numeric(length)
  )

# Read old data
#ashop_old <- r4ss::SS_read(dir = file.path(getwd(), "model", "2017_yelloweye_model_updated_ss3_exe"))
ashop_old <- r4ss::SS_readdat(file = here("data", "2019widow.dat"))

ashop_lengths_old <- ashop_old$lencom %>% 
  dplyr::filter(fleet == 3) %>% 
  mutate(assessment = "Previous") %>% 
  dplyr::select(-month, -fleet, -sex, -part) %>% 
  tidyr::pivot_longer(cols = c(-year, -assessment, -Nsamp), names_to = "bin", values_to = "freq") %>% 
  mutate(sex = str_sub(bin, 1, 1), length = as.integer(str_sub(bin, 2))) %>% 
  dplyr::group_by(year) %>% 
  dplyr::mutate(
    freq = freq / sum(freq),
    # NsampsFreq = freq/unique(Nsamps), still waiting on these
    length = as.numeric(length)
  )

together <- rbind(ashop_lengths_old, ashop_lengths_new)
comparison_plot_dodge <- together %>% 
  dplyr::filter(freq > 0) %>% 
  ggplot2::ggplot(aes(x = year, y = length, col = assessment, size = freq)) +
  ggplot2::geom_point(position = position_dodge(0.5))
comparison_plot <- together %>% 
  dplyr::filter(freq > 0) %>% 
  ggplot2::ggplot(aes(x = year, y = length, col = assessment, size = freq)) +
  ggplot2::geom_point(position = position_dodge(0))
ggsave(plot = comparison_plot_dodge, here("data", "cleaned", "ashop_length_comp_comparisons_dodged.png"))
ggsave(plot = comparison_plot, here("data", "cleaned", "ashop_length_comp_comparisons.png"))



ashop_ages_new <- read.csv(here("data", "cleaned", "ASHOP_age_sexed.csv"))
ashop_ages_new <- ashop_ages_new %>% 
  mutate(assessment = "Current") %>% 
  dplyr::select(-month, -fleet, -sex, -partition)
ashop_ages_new <- ashop_ages_new %>% 
  tidyr::pivot_longer(cols = c(-year, -assessment, -input_n), names_to = "bin", values_to = "freq") %>% 
  mutate(sex = str_sub(bin, 1, 1), age = as.integer(str_sub(bin, 2))) %>% 
  dplyr::group_by(year) %>% 
  dplyr::mutate(
    freq = freq / sum(freq),
    # NsampsFreq = freq/unique(Nsamps), still waiting on these
    age = as.numeric(age)
  )

# Read old data
#ashop_old <- r4ss::SS_read(dir = file.path(getwd(), "model", "2017_yelloweye_model_updated_ss3_exe"))
ashop_old <- r4ss::SS_readdat(file = here("data", "2019widow.dat"))

ashop_ages_old <- ashop_old$agecomp %>% 
  dplyr::filter(fleet == 3) %>% 
  mutate(assessment = "Previous") %>% 
  dplyr::select(-month, -fleet, -sex, -part) %>% 
  tidyr::pivot_longer(cols = c(-year, -assessment, -Nsamp), names_to = "bin", values_to = "freq") %>% 
  mutate(sex = str_sub(bin, 1, 1), age = as.integer(str_sub(bin, 2))) %>% 
  dplyr::group_by(year) %>% 
  dplyr::mutate(
    freq = freq / sum(freq),
    # NsampsFreq = freq/unique(Nsamps), still waiting on these
    age = as.numeric(age)
  )

together_age <- rbind(ashop_ages_old, ashop_ages_new)
comparison_plot_dodge_age <- together_age %>% 
  dplyr::filter(freq > 0) %>% 
  ggplot2::ggplot(aes(x = year, y = age, col = assessment, size = freq)) +
  ggplot2::geom_point(position = position_dodge(0.5))
comparison_plot_age <- together_age %>% 
  dplyr::filter(freq > 0) %>% 
  ggplot2::ggplot(aes(x = year, y = age, col = assessment, size = freq)) +
  ggplot2::geom_point(position = position_dodge(0))
ggsave(plot = comparison_plot_dodge_age, here("data", "cleaned", "ashop_length_comp_comparisons_dodged_age.png"))
ggsave(plot = comparison_plot_age, here("data", "cleaned", "ashop_length_comp_comparisons_age.png"))
