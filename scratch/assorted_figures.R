library(ggplot2)
library(dplyr)
library(r4ss)
library(here)
library("nwfscSurvey")
library("mgcv")
library(tidyverse)
library(cowplot)

# sdmTMB-based biomass index ------------------------------
plot_save_dir <- here("figures", "WCGBTS_survey")

dat_2019 <- SS_readdat(here("models", "2019 base model", "Base_45", "2019widow.dat"))
widow_indices <- dat_2019$CPUE
  
index_gm <- read.csv("data_provided/WCGBTS/delta_gamma/index/est_by_area.csv")
index_gm$source <- "sdmTMB delta-\ngamma, 2025"
index_gm <- index_gm %>% filter(area == "Coastwide")

index_ln <- read.csv("data_provided/WCGBTS/delta_lognormal/index/est_by_area.csv")
index_ln$source <- "sdmTMB delta-\nlognorm, 2025"
index_ln <- index_ln %>% filter(area == "Coastwide")

# reorganize old data
old_index <- widow_indices %>% filter(index == 8) %>%
  mutate(model = factor(ifelse(year < 1900, "GLMM", "VAST")))
old_index$source <- old_index$model
old_index$year <- abs(old_index$year)

# new data v. VAST/GLMM
# combine the data frames
index_ln$obs <- index_ln$est; index_ln$se_log <- index_ln$se
index_gm$obs <- index_gm$est; index_gm$se_log <- index_gm$se
all_dat <- rbind(old_index[, c(1, 4, 5, 7)],index_ln[, c(2, 10, 11, 9)], index_gm[, c(2, 10, 11, 9)])

dodge_width <- 0.9  # Adjust this value to control spacing
surv_comp_plot <- ggplot(all_dat, aes(year, obs, col = source)) + 
  geom_errorbar(data = all_dat, aes(ymin = qlnorm(.025, log(obs), sd = se_log), 
                                      ymax = qlnorm(.975, log(obs), sd = se_log)), 
                position = position_dodge(width = dodge_width)) + 
  geom_line(position = position_dodge(width = dodge_width)) +
  geom_point(position = position_dodge(width = dodge_width)) +
  labs(y = "index", col = "Model:") + 
  theme_bw() + theme(legend.position = "bottom") + 
  scale_color_manual(values = c("gray","black", "#005BFF", "#FF592F"))


ggsave(file.path(plot_save_dir, 'survey_comparision_plot.png'),  dpi = 300,  
       width = 5, height = 4, units = "in")

# length-at-age comps ------------------------------

species <- "widow rockfish"
survey <- "NWFSC.Combo"

age_bins <- 0:40
length_bins <- seq(8, 56, by = 2)

strata <- CreateStrataDF.fn(
  names = c("South - shallow", "South - deep", "North - shallow", "North - deep"), 
  depths.shallow = c(  55,  183,  55, 183),
  depths.deep    = c( 183,  400, 183, 400),
  lats.south     = c(34.5, 34.5,  40.5,  40.5),
  lats.north     = c(  40.5,   40.5,  49,  49)
)

# Pull scientific catch survey data
catch <- pull_catch(common_name = species, survey = survey)

# Age, length, weight
bio <- pull_bio(common_name = species, survey = survey)

# caal plots
caal <- get_raw_caal(
  data = bio, 
  len_bins = length_bins,
  age_bins = age_bins
)

caal_fm <- caal %>% select(year, Lbin_lo, Lbin_hi, starts_with("f"), -fleet) %>% 
  pivot_longer(cols = starts_with("f"), names_to = "age", values_to = "count") %>%
  mutate(age = as.integer(gsub("f", "", age)))

caal_ml <- caal %>% select(year, Lbin_lo, Lbin_hi, starts_with("m"), -month, -fleet) %>% 
  pivot_longer(cols = starts_with("m"), names_to = "age", values_to = "count") %>%
  mutate(age = as.integer(gsub("m", "", age)))

caal_fm_plot <- ggplot(caal_fm, aes(age, Lbin_lo, size = log(count+1))) + 
  geom_point(col = "#FF592F", pch = 'o') + facet_wrap(~year) + 
  labs(x = "Age", y = "Length") + theme_bw() + 
  scale_size_continuous(range = c(0.5, 6)) + guides(size="none")

caal_ml_plot <- ggplot(caal_ml, aes(age, Lbin_lo, size = log(count+1))) + 
  geom_point(col = "#005BFF", pch = 'o') + facet_wrap(~year) + 
  labs(x = "Age", y = "Length") + theme_bw() + 
  scale_size_continuous(range = c(0.5, 6)) + guides(size="none")

caal_WCGBTS <- plot_grid(caal_fm_plot, caal_ml_plot, nrow = 2)

ggsave(file.path(plot_save_dir, 'caal_WCGBTS_plot.png'),  dpi = 300,  
       width = 7, height = 10, units = "in")

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

plot_comps(length_comps, dir = file.path(plot_save_dir))

age_comps <- get_expanded_comps(
  bio_data = bio,
  catch_data = catch,
  comp_bins = age_bins,
  strata = strata,
  comp_column_name = "age",
  output = "full_expansion_ss3_format",
  two_sex_comps = TRUE,
  input_n_method = "stewart_hamel"
)

plot_comps(age_comps, dir = file.path(plot_save_dir, "age_plots"))

# weight/length and length/age things: STILL TO BE MADE ------------------------------

# dat_2025 <- SS_readdat(here("models", "2025 base model", "2025widow.dat"))
# 
# age_length_dat <- dat_2025$agecomp
# # age_length_dat <- age_length_dat %>% filter(year > 0, fleet > 0) # only use data used in base model
# age_length_dat$abs_year <- abs(age_length_dat$year)
# age_length_dat$abs_fleet <- abs(age_length_dat$fleet)
# 
# fm_agelen <- age_length_dat %>% select(abs_year, Lbin_lo, Lbin_hi, abs_fleet, c(10:50)) %>% 
#   pivot_longer(cols = starts_with("f"), names_to = "age", values_to = "count") %>%
#   mutate(age = as.integer(gsub("f", "", age))) %>% mutate(sex = "female")
# 
# ml_agelen <- age_length_dat %>% select(abs_year, Lbin_lo, Lbin_hi, abs_fleet, c(51:91), -month) %>% 
#   pivot_longer(cols = starts_with("m"), names_to = "age", values_to = "count") %>%
#   mutate(age = as.integer(gsub("m", "", age))) %>% mutate(sex = "male")
# 
# agelen <- rbind(fm_agelen, ml_agelen) %>% filter(count > 0)
# 
# ggplot(agelen, aes(age, Lbin_lo, col = as.factor(abs_fleet))) + 
#   geom_point() + facet_wrap(~sex) + 
#   labs(x = "Age", y = "Length", col = "Fleet:") + theme_bw() 
# 
