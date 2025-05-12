library(ggplot2)
library(dplyr)
library(r4ss)
library(here)
library("nwfscSurvey")
library("mgcv")
library(tidyverse)
library(cowplot)
library(readxl)

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

# weight/length and length/age things: ------------------------------
plot_save_dir <- here("figures", "length_age_weight")

# age-length plot: figure 35
# triennial age/etc
scientific_name<-"Sebastes entomelas"

tri_bio <- nwfscSurvey::pull_bio(
  sci_name = scientific_name,
  survey = "Triennial"
) # has length_data, age_data

tri_catch <- pull_catch(sci_name = scientific_name,
                        survey = "Triennial"
)

# can pull age & length from age data
tri_bio$age_data$fleet <- rep("Triennial")

# survey age and length
# use caal_fm, caal_ml
caal_fm$Sex <- rep("female"); caal_ml$Sex <- rep("male")
surv_agelen <- rbind(caal_fm, caal_ml) %>% filter(count > 0, Lbin_lo > 0)
surv_agelen$fleet <- rep("NWFSC") # no other data w Lbin_lo > 0

# pacfin data **ADD**
# read in here
pfin_dat <- XXX
pfin_dat$fleet <- rep("PACFIN")

# ashop age and legnth etc.
ashop_age <- read_excel("data_provided/ASHOP/A_SHOP_Widow_Ages_2003-2024_removedConfidentialFields_012725.xlsx")
ashop_age$fleet <- rep("ASHOP")

# put data together for age/len plots
all_agelen <- data.frame(widow_fleet = c(surv_agelen$fleet, ashop_age$fleet, pfin_dat$fleet, tri_bio$age_data$fleet), 
                         widow_age = c(surv_agelen$age, ashop_age$AGE, pfin_dat$Age, tri_bio$age_data$Age), 
                         widow_len = c(surv_agelen$Lbin_lo, ashop_age$LENGTH, pfin_dat$length, tri_bio$age_data$Length_cm), 
                         widow_sex = c(surv_agelen$Sex, ashop_age$SEX, pfin_dat$SEX, tri_bio$age_data$Sex))

# fix up widow_sex column
all_agelen <- all_agelen %>% filter(widow_sex != "U") # remove unsexed
all_agelen$widow_sex <- ifelse(all_agelen$widow_sex == "F", "female", all_agelen$widow_sex)
all_agelen$widow_sex <- ifelse(all_agelen$widow_sex == "M", "male", all_agelen$widow_sex)

# for the lines
age_range = seq(from = min(all_agelen$widow_age, na.rm = T), to = max(all_agelen$widow_age, na.rm = T), length.out = 100)
base_model_ins <- SS_read(file.path(here("models", "2025 base model")), 
                      ss_new = FALSE)
vblFk <- base_model_ins$ctl$MG_parms["VonBert_K_Fem_GP_1", ]$INIT
vblFMin <- base_model_ins$ctl$MG_parms["L_at_Amin_Fem_GP_1", ]$INIT
vblFMax <- base_model_ins$ctl$MG_parms["L_at_Amax_Fem_GP_1", ]$INIT
vblMk <- base_model_ins$ctl$MG_parms["VonBert_K_Mal_GP_1", ]$INIT
vblMMin <- base_model_ins$ctl$MG_parms["L_at_Amin_Mal_GP_1", ]$INIT
vblMMax <- base_model_ins$ctl$MG_parms["L_at_Amax_Mal_GP_1", ]$INIT
fm_vbl_in <- vblFMax - (vblFMax - vblFMin)*exp(-vblFk*age_range)
ml_vbl_in <- vblMMax - (vblMMax - vblMMin)*exp(-vblMk*age_range)
base_model_outs <- SS_output(file.path(here("models", "2025 base model")))
vblFk <- base_model_outs$parameters["VonBert_K_Fem_GP_1", ]$Value
vblFMin <- base_model_outs$parameters["L_at_Amin_Fem_GP_1", ]$Value
vblFMax <- base_model_outs$parameters["L_at_Amax_Fem_GP_1", ]$Value
vblMk <- base_model_outs$parameters["VonBert_K_Mal_GP_1", ]$Value
vblMMin <- base_model_outs$parameters["L_at_Amin_Mal_GP_1", ]$Value
vblMMax <- base_model_outs$parameters["L_at_Amax_Mal_GP_1", ]$Value
fm_vbl_out <- vblFMax - (vblFMax - vblFMin)*exp(-vblFk*age_range)
ml_vbl_out <- vblMMax - (vblMMax - vblMMin)*exp(-vblMk*age_range)
vbl_lines <- data.frame(widow_age = c(age_range, age_range, age_range, age_range), 
                        widow_len = c(fm_vbl_out, ml_vbl_out, fm_vbl_in, ml_vbl_in), 
                        widow_sex = c(rep("female", length(fm_vbl_out)), 
                                      rep("male", length(ml_vbl_out)), 
                                      rep("female", length(fm_vbl_in)), 
                                      rep("male", length(ml_vbl_in))), 
                        vbl_type = c(rep("model estimated", length(age_range)*2), 
                                     rep("model prior", length(age_range)*2)))

# make vBL plots **ADD PACFIN STILL**
ggplot(all_agelen, aes(widow_age, widow_len, col = as.factor(widow_fleet))) +
  geom_jitter(size = 1.6) + facet_wrap(~widow_sex, nrow = 2) +
  geom_line(data = vbl_lines %>% filter(vbl_type == "model estimated"), col = "black", lwd = 1) + 
  labs(x = "Age", y = "Length", col = "Fleet:") + 
  theme_bw() + theme(legend.position = "bottom", legend.box="vertical", text = element_text(size = 22)) + 
  scale_color_manual(values = c("gray", "#005BFF", "#FF592F", "#F6F900")) 

ggsave(file.path(plot_save_dir, 'vBL_dat.png'),  dpi = 300,  
       width = 7, height = 10, units = "in")

# length-weight plot: figure 31
# values from 2019
aF_2019 <- 1.7355e-5
bF_2019 <- 2.9617
aM_2019 <- 1.4824e-5
bM_2019 <- 3.0047
# values from NWFSC
weight_length_estimates_NWFSC <- nwfscSurvey::estimate_weight_length(
  bio,
  verbose = FALSE
)
aF_NW <- weight_length_estimates_NWFSC$A[1]
bF_NW <- weight_length_estimates_NWFSC$B[1]
aM_NW <- weight_length_estimates_NWFSC$A[2]
bM_NW <- weight_length_estimates_NWFSC$B[2]
# values from 2025
aF_2025 <- base_model_outs$parameters["Wtlen_1_Fem_GP_1", ]$Value
bF_2025 <- base_model_outs$parameters["Wtlen_2_Fem_GP_1", ]$Value
aM_2025 <- base_model_outs$parameters["Wtlen_1_Mal_GP_1", ]$Value
bM_2025 <- base_model_outs$parameters["Wtlen_2_Mal_GP_1", ]$Value
# lengths
len <- seq(from = 1, to = 60, length.out = 100)
# female lines
fem_lw <- data.frame(len = len, 
                     est_2019 = aF_2019*len^bF_2019, 
                     est_NW = aF_NW*len^bF_NW,
                     est_2025 = aF_2025*len^bF_2025,
                     Sex = "female")
# male lines
mal_lw <- data.frame(len = len, 
                     est_2019 = aM_2019*len^bM_2019, 
                     est_NW = aM_NW*len^bM_NW,
                     est_2025 = aM_2025*len^bM_2025,
                     Sex = "male")
# merge and pivot
rbind(mal_lw, fem_lw) |> pivot_longer(cols = c(-len, -Sex)) -> line_est
# data points: bio$Age; bio$Length_cm
bio_filter <- bio %>% filter(Sex != "U") # remove unsexed
bio_filter$Sex <- ifelse(bio_filter$Sex == "F", "female", bio_filter$Sex)
bio_filter$Sex <- ifelse(bio_filter$Sex == "M", "male", bio_filter$Sex)

ggplot(NULL, aes(NULL)) + 
  geom_point(data = bio_filter, aes(Length_cm, Weight_kg), size = 0.8, col = "#005BFF") + 
  geom_line(data = line_est, aes(len, value, lty = name)) + 
  facet_wrap(~Sex) + 
  scale_linetype(labels = c("2019 assessment", "2025 assessment", "NW estimate")) + 
  labs(lty = "Model", x = "Length", y = "Weight") + 
  theme_bw()

ggsave(file.path(plot_save_dir, 'wl_dat.png'),  dpi = 300,  
       width = 5, height = 4, units = "in")

ggplot(line_est, aes(len, value, lty = name, color = name)) + 
  geom_line(lwd = 0.8) + 
  facet_wrap(~Sex) + 
  scale_linetype_manual(values = c("solid", "solid", "longdash"), labels = c("2019 assessment", "2025 assessment", "NW estimate")) + 
  scale_color_manual(values = c("gray",  "#FF592F", "#005BFF"), labels = c("2019 assessment", "2025 assessment", "NW estimate")) + 
  labs(lty = "Model", x = "Length", y = "Weight", color = "Estimate") + 
  theme_bw() + theme(legend.position = "bottom") + guides(lty="none")

ggsave(file.path(plot_save_dir, 'wl_dat_2025.png'),  dpi = 300,  
       width = 5, height = 4, units = "in")

ggplot(line_est %>% filter(name != "est_2025"), aes(len, value, lty = name, color = name)) + 
  geom_line(lwd = 0.8) + 
  facet_wrap(~Sex) + 
  scale_linetype_manual(values = c("solid", "longdash"), labels = c("2019 assessment", "NW estimate")) + 
  scale_color_manual(values = c("gray", "#005BFF"), labels = c("2019 assessment", "NW estimate")) + 
  labs(lty = "Model", x = "Length", y = "Weight", color = "Estimate") + 
  theme_bw() + theme(legend.position = "bottom") + guides(lty="none")

ggsave(file.path(plot_save_dir, 'wl_dat_2019.png'),  dpi = 300,  
       width = 5, height = 4, units = "in")


# sensitivity table--weighting comps ------------------------------
base_dir <- here("models", "2025 base model")
frans_dir <- here("models", "sensitivities", "Francis")

big_sensitivity_output <- SSgetoutput(dirvec = c(base_dir, frans_dir)) |>
  setNames(c('2025 base model', 'Francis weighting'))

frans_tc <- tune_comps(big_sensitivity_output$`Francis weighting`, dir = frans_dir)
base_tc <- tune_comps(big_sensitivity_output$`2025 base model`, dir = base_dir)

# get effN from big_sensitity_output directly
effN_F <- rbind(big_sensitivity_output$`Francis weighting`$Age_Comp_Fit_Summary[, c(1, 18, 21)], big_sensitivity_output$`Francis weighting`$Length_Comp_Fit_Summary[, c(1, 18, 21)])
effN_B <- rbind(big_sensitivity_output$`2025 base model`$Age_Comp_Fit_Summary[, c(1, 18, 21)], big_sensitivity_output$`2025 base model`$Length_Comp_Fit_Summary[, c(1, 18, 21)])
colnames(effN_F) <- c("Data_type", "Mean effN, Francis", "Fleet_name")
colnames(effN_B) <- c("Data_type", "Mean effN, 2025 base model", "Fleet_name")
effN <- merge(effN_B, effN_F , by = c("Fleet_name", "Data_type"))
effN$`Mean effN, 2025 base model` <- log(effN$`Mean effN, 2025 base model`)
effN$`Mean effN, Francis` <- log(effN$`Mean effN, Francis`)

# make the table
tc <- data.frame(Fleet_name = frans_tc$Name, 
                 Data_type = frans_tc$`#factor`, 
                 base_MI = base_tc$New_Var_adj, 
                 frans_MI = frans_tc$New_Var_adj)

full_tab <- merge(effN, tc, by = c("Fleet_name", "Data_type")) %>% arrange(Data_type)

colnames(full_tab) <- c("Fleet", "Composition data type", 
                        "Log(Mean effN), 2025 base model", "Log(Mean effN), Francis", 
                        "Base model (McAllister Ianelli) weighting", "Francis weighting")

full_tab$`Composition data type` <- ifelse(full_tab$`Composition data type` == 4, "Length", "Age")

full_tab |> write.csv(file.path(here("figures","sensitivities"), "weighting_comps.csv"), row.names = FALSE)

# survey positive tows ------------------------------
plot_save_dir <- here("figures", "WCGBTS_survey")

pos_catch <- data.frame(
  Year = 1977:2024
)

# use the catch dataframe for positive tows
# tri
tri_catch |> group_by(Year) |> 
  filter(cpue_kg_km2 > 0) |>
  summarise("Number of positive tows, Tri"=length(unique(Trawl_id))) -> T_tot_catch
pos_catch <- merge(pos_catch, T_tot_catch, by = "Year", all = TRUE)

# nw
catch |> group_by(Year) |> 
  filter(cpue_kg_km2 > 0) |>
  summarise("Number of positive tows, NW"=length(unique(Trawl_id))) -> tot_catch
pos_catch <- merge(pos_catch, tot_catch, by = "Year", all = TRUE)

# use the bio dataframe for tows w/lengths, ages and the nubmer of each
tri_bio$length_data |> group_by(Year) |> 
  filter(!is.na(Length_cm)) |> 
  summarise("Number of tows with lengths, Tri"=length(unique(Trawl_id))) -> T_tot_len_tows
pos_catch <- merge(pos_catch, T_tot_len_tows, by = "Year", all = TRUE)

bio |> group_by(Year) |> 
  filter(!is.na(Length_cm)) |> 
  summarise("Number of tows with lengths, NW"=length(unique(Trawl_id))) -> tot_len_tows
pos_catch <- merge(pos_catch, tot_len_tows, by = "Year", all = TRUE)

tri_bio$length_data |> group_by(Year) |> 
  filter(!is.na(Length_cm)) |> 
  summarise("Number of lengths, Tri"=n()) -> T_tot_len_num
pos_catch <- merge(pos_catch, T_tot_len_num, by = "Year", all = TRUE)

bio |> group_by(Year) |> 
  filter(!is.na(Length_cm)) |> 
  summarise("Number of lengths, NW"=n()) -> tot_len_num
pos_catch <- merge(pos_catch, tot_len_num, by = "Year", all = TRUE)

tri_bio$age_data |> group_by(Year) |> 
  filter(!is.na(Age)) |> 
  summarise("Number of twos with ages, Tri"=length(unique(Trawl_id))) -> T_tot_age_tows
pos_catch <- merge(pos_catch, T_tot_age_tows, by = "Year", all = TRUE)

bio |> group_by(Year) |> 
  filter(!is.na(Age)) |> 
  summarise("Number of tows with ages, NW"=length(unique(Trawl_id))) -> tot_age_tows
pos_catch <- merge(pos_catch, tot_age_tows, by = "Year", all = TRUE)

tri_bio$age_data |> group_by(Year) |> 
  filter(!is.na(Age)) |> 
  summarise("Number of ages, Tri"=n()) -> T_tot_age_num
pos_catch <- merge(pos_catch, T_tot_age_num, by = "Year", all = TRUE)

bio |> group_by(Year) |> 
  filter(!is.na(Age)) |> 
  summarise("Number of ages, NW"=n()) -> tot_age_num
pos_catch <- merge(pos_catch, tot_age_num, by = "Year", all = TRUE)

pos_catch[(is.na(pos_catch))] <- "" # cleaning for csv

pos_catch |> 
  write.csv(file.path(plot_save_dir, "survey_pos_catch.csv"), row.names = FALSE)

