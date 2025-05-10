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

# survey age and length
dat_2025 <- SS_readdat(here("models", "2025 base model", "2025widow.dat"))
survey_age_length_dat <- dat_2025$agecomp
# age_length_dat <- age_length_dat %>% filter(year > 0, fleet > 0) # only use data used in base model
survey_age_length_dat$abs_year <- abs(survey_age_length_dat$year)
survey_age_length_dat$abs_fleet <- abs(survey_age_length_dat$fleet)

fm_agelen <- survey_age_length_dat %>% select(abs_year, Lbin_lo, Lbin_hi, abs_fleet, c(10:50)) %>%
  pivot_longer(cols = starts_with("f"), names_to = "age", values_to = "count") %>%
  mutate(age = as.integer(gsub("f", "", age))) %>% mutate(sex = "female")

ml_agelen <- survey_age_length_dat %>% select(abs_year, Lbin_lo, Lbin_hi, abs_fleet, c(51:91), -month) %>%
  pivot_longer(cols = starts_with("m"), names_to = "age", values_to = "count") %>%
  mutate(age = as.integer(gsub("m", "", age))) %>% mutate(sex = "male")

surv_agelen <- rbind(fm_agelen, ml_agelen) %>% filter(count > 0, Lbin_lo > 0)
surv_agelen$fleet <- rep("NWFSC") # no other data w Lbin_lo > 0

# pacfin data **ADD**
# read in here
pfin_dat <- XXX
pfin_dat$fleet <- rep("PACFIN")

# ashop age and legnth etc.
ashop_age <- read_excel("data_provided/ASHOP/A_SHOP_Widow_Ages_2003-2024_removedConfidentialFields_012725.xlsx")
ashop_age$fleet <- rep("ASHOP")

# put data together for age/len plots
all_agelen <- data.frame(widow_fleet = c(surv_agelen$fleet, ashop_age$fleet, pfin_dat$fleet), 
                         widow_age = c(surv_agelen$age, ashop_age$AGE, pfin_dat$Age), 
                         widow_len = c(surv_agelen$Lbin_lo, ashop_age$LENGTH, pfin_dat$length), 
                         widow_sex = c(surv_agelen$sex, ashop_age$SEX, pfin_dat$SEX))

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
                        widow_sex = c(rep("female", length(fm_vbl)), 
                                      rep("male", length(ml_vbl)), 
                                      rep("female", length(fm_vbl)), 
                                      rep("male", length(ml_vbl))), 
                        vbl_type = c(rep("model estimated", length(age_range)*2), 
                                     rep("model prior", length(age_range)*2)))

# make vBL plots **ADD PACFIN STILL**
ggplot(all_agelen, aes(widow_age, widow_len, col = as.factor(widow_fleet))) +
  geom_jitter(size = 0.8) + facet_wrap(~widow_sex, nrow = 2) +
  geom_line(data = vbl_lines %>% filter(vbl_type == "model estimated"), col = "black", lwd = 1) + 
  labs(x = "Age", y = "Length", col = "Fleet:") + 
  theme_bw() + theme(legend.position = "bottom", legend.box="vertical", text = element_text(size = 16)) + 
  scale_color_manual(values = c("gray", "#005BFF", "#FF592F"))

ggsave(file.path(plot_save_dir, 'vBL_dat.png'),  dpi = 300,  
       width = 7, height = 10, units = "in")

# length-weight plots

# ashop data has the length/weight
# bio from NWFSCSurvey package has length/weigth
# PACFIN **ADD**
surv_wl <- bio %>% filter(Sex != "U")
surv_wl$Sex <- ifelse(surv_wl$Sex == "F", "female", surv_wl$Sex)
surv_wl$Sex <- ifelse(surv_wl$Sex == "M", "male", surv_wl$Sex)
ashop_wl <- ashop_age %>% filter(SEX != "U")
ashop_wl$SEX <- ifelse(ashop_wl$SEX == "F", "female", ashop_wl$SEX)
ashop_wl$SEX <- ifelse(ashop_wl$SEX == "M", "male", ashop_wl$SEX)
# pfin_dat might need the same processing as ashop re: sex codes
pfin_wl <- pfin_dat %>% filter(SEX != "U")
pfin_wl$SEX <- ifelse(pfin_wl$SEX == "F", "female", pfin_wl$SEX)
pfin_wl$SEX <- ifelse(pfin_wl$SEX == "M", "male", pfin_wl$SEX)

# get data together
all_weightlen <- data.frame(w = c(surv_wl$Weight_kg, ashop_wl$WEIGHT, pfin_dat$weightkg), 
                            l = c(surv_wl$Length_cm, ashop_wl$LENGTH, pfin_dat$length), 
                            s = c(surv_wl$Sex, ashop_wl$SEX, pfin_dat$SEX), 
                            f = c(rep("NWFSC", dim(surv_wl)[1]), 
                                  rep("ASHOP", dim(ashop_wl)[1]), 
                                  rep("PACFIN", dim(pfin_wl)[1])))

# weight-length lines
aF_p <- base_model_ins$ctl$MG_parms["Wtlen_1_Fem_GP_1", ]$INIT
bF_p <- base_model_ins$ctl$MG_parms["Wtlen_2_Fem_GP_1", ]$INIT
aF <- base_model_outs$parameters["Wtlen_1_Fem_GP_1", ]$Value
bF <- base_model_outs$parameters["Wtlen_2_Fem_GP_1", ]$Value
aM_p <- base_model_ins$ctl$MG_parms["Wtlen_1_Mal_GP_1", ]$INIT
bM_p <- base_model_ins$ctl$MG_parms["Wtlen_2_Mal_GP_1", ]$INIT
aM <- base_model_outs$parameters["Wtlen_1_Mal_GP_1", ]$Value
bM <- base_model_outs$parameters["Wtlen_2_Mal_GP_1", ]$Value
len_range <- seq(from = min(all_weightlen$l), to = max(all_weightlen$l), length.out = 100)
fm_wl_in <- aF_p*len_range^bF_p
ml_wl_in <- aM_p*len_range^bM_p
fm_wl_out <- aF*len_range^bF
ml_wl_out <- aM*len_range^bM
wl_lines <- data.frame(l = c(len_range, len_range, len_range, len_range), 
                       w = c(fm_wl_out, ml_wl_out, fm_wl_in, ml_wl_in), 
                       s = c(rep("female", length(fm_wl_in)), 
                             rep("male", length(ml_wl_in)), 
                             rep("female", length(fm_wl_in)),
                             rep("male", length(ml_wl_in))), 
                       t = c(rep("model estimated", length(len_range)*2), 
                             rep("model prior", length(len_range)*2)))

ggplot(all_weightlen, aes(l, w, col = as.factor(f))) +
  geom_point(size = 0.8) + facet_wrap(~s, nrow = 1) +
  geom_line(data = wl_lines %>% filter(t == "model estimated"), col = "black", lwd = 1) + 
  labs(x = "Length(cm)", y = "Weight (kg)", col = "Fleet:") + 
  theme_bw() + theme(legend.position = "bottom", legend.box="vertical", text = element_text(size = 16)) + 
  scale_color_manual(values = c("gray", "#005BFF", "#FF592F"))

ggsave(file.path(plot_save_dir, 'wl_dat.png'),  dpi = 300,  
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

