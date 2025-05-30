library(ggplot2)
library(dplyr)
library(r4ss)
library(here)
library("nwfscSurvey")
library("mgcv")
library(tidyverse)
library(cowplot)
library(readxl)

# weight/length and length/age things: ------------------------------

plot_save_dir <- here("figures", "length_age_weight")

# age-length plot: figure 35
# triennial age/etc
scientific_name<-"Sebastes entomelas"

tri_bio <- nwfscSurvey::pull_bio(
  sci_name = scientific_name,
  survey = "Triennial"
) # has length_data, age_data

tri_catch <- nwfscSurvey::pull_catch(sci_name = scientific_name,
                        survey = "Triennial"
)

# can pull age & length from age data
tri_bio$age_data$fleet <- rep("Triennial")

# survey age and length
# use caal_fm, caal_ml
caal_fm$Sex <- rep("female"); caal_ml$Sex <- rep("male")
surv_agelen <- rbind(caal_fm, caal_ml) %>% filter(count > 0, Lbin_lo > 0)
surv_agelen$fleet <- rep("WCGBTS") # no other data w Lbin_lo > 0

# pacfin data **ADD**
# read in here

load(here("data_provided", "PacFIN", "PacFIN.WDOW.bds.25.Mar.2025.RData"))

used_gears <- c("TWL","NET","MSC","POT","HKL")
good_lengths <- c("F", "T", "U")
good_methods <- c("R")
good_samples <- c("C","M","NA")
good_states <- c("WA", "OR", "CA")
good_age_method <- c("BB","B","U","NA")

bds_cleaned <- bds.pacfin |> 
  filter(SAMPLE_YEAR >= 2005) |> #Only do post 2005 data
  cleanPacFIN(
    keep_gears = used_gears,         
    CLEAN = TRUE,
    keep_age_method = good_age_method,
    keep_sample_type = good_samples,
    keep_sample_method = good_methods,
    keep_length_type = good_lengths,
    keep_states = good_states,
    spp = "widow rockfish"
  )  |> 
  left_join(gear_groups_2024,by = "AGENCY_SAMPLE_NUMBER")|> ##a ppend the gear_groups
  dplyr::mutate(stratification = paste(state,gear_group,sep = ".")) |> # Stratification is a combination of gear and state (matches catch data formatting)
  dplyr::filter(!PACFIN_GEAR_NAME %in% c("XXX","OTH-KNOWN","DNSH SEINE"))

pfin_dat <- bds_cleaned_all |> filter(!is.na(Age))
pfin_dat$fleet <- rep("PACFIN")

# ashop age and legnth etc.
ashop_age <- readxl::read_excel("data_provided/ASHOP/A_SHOP_Widow_Ages_2003-2024_removedConfidentialFields_012725.xlsx")
ashop_age$fleet <- rep("ASHOP")

# put data together for age/len plots
all_agelen <- data.frame(widow_fleet = c(surv_agelen$fleet, ashop_age$fleet, pfin_dat$fleet, tri_bio$age_data$fleet), 
                         widow_age = c(surv_agelen$age, ashop_age$AGE, pfin_dat$Age, tri_bio$age_data$Age), 
                         widow_len = c(surv_agelen$Lbin_lo, ashop_age$LENGTH, pfin_dat$lengthcm, tri_bio$age_data$Length_cm), 
                         widow_sex = c(surv_agelen$Sex, ashop_age$SEX, pfin_dat$SEX, tri_bio$age_data$Sex))

# fix up widow_sex column
all_agelen <- all_agelen %>% filter(widow_sex != "U") # remove unsexed
all_agelen$widow_sex <- ifelse(all_agelen$widow_sex == "F", "female", all_agelen$widow_sex)
all_agelen$widow_sex <- ifelse(all_agelen$widow_sex == "M", "male", all_agelen$widow_sex)

# for the lines
age_range = seq(from = min(all_agelen$widow_age, na.rm = T), to = max(all_agelen$widow_age, na.rm = T), length.out = 100)
base_model_ins <- SS_read(file.path(here("models", "2025 base model")), 
                      ss_new = FALSE)
vblFk <- base_ctl$MG_parms["VonBert_K_Fem_GP_1", ]$INIT
vblFMin <- base_ctl$MG_parms["L_at_Amin_Fem_GP_1", ]$INIT
vblFMax <- base_ctl$MG_parms["L_at_Amax_Fem_GP_1", ]$INIT
vblMk <- base_ctl$MG_parms["VonBert_K_Mal_GP_1", ]$INIT
vblMMin <- base_ctl$MG_parms["L_at_Amin_Mal_GP_1", ]$INIT
vblMMax <- base_ctl$MG_parms["L_at_Amax_Mal_GP_1", ]$INIT
fm_vbl_in <- vblFMax - (vblFMax - vblFMin)*exp(-vblFk*age_range)
ml_vbl_in <- vblMMax - (vblMMax - vblMMin)*exp(-vblMk*age_range)
base_par <- SS_output(file.path(here("models", "2025 base model")))
vblFk <- base_par$parameters["VonBert_K_Fem_GP_1", ]$Value
vblFMin <- base_par$parameters["L_at_Amin_Fem_GP_1", ]$Value
vblFMax <- base_par$parameters["L_at_Amax_Fem_GP_1", ]$Value
vblMk <- base_par$parameters["VonBert_K_Mal_GP_1", ]$Value
vblMMin <- base_par$parameters["L_at_Amin_Mal_GP_1", ]$Value
vblMMax <- base_par$parameters["L_at_Amax_Mal_GP_1", ]$Value
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

#re-order the factor levels to place pacfin on the bottom
# make vBL plots **ADD PACFIN STILL**
# ggplot(all_agelen, aes(widow_age, widow_len, col = widow_fleet)) +
#   geom_jitter(size = 1.6,alpha = 0.5) + facet_wrap(~widow_sex, nrow = 2) +
#   geom_line(data = vbl_lines %>% filter(vbl_type == "model estimated"), col = "black", lwd = 1) + 
#   labs(x = "Age", y = "Length", col = "Fleet:") + 
#   theme_bw() + theme(legend.position = "bottom", legend.box="vertical", text = element_text(size = 22)) + 
#   scale_color_manual(values = c( "#005BFF", "#FF592F","gray", "#F6F900")) 

all_agelen <- all_agelen %>%
  mutate(widow_fleet = factor(widow_fleet, levels = c("WCGBTS", "ASHOP", "Triennial", "PACFIN")))

##Need to calculate t0 as our models has a non-traditional paramterisation of Vb, while the plot has classic
get_t0 <- function(L_min = 20, L_max = 45,A_min = 1,A_max = 40,k = 0.21){
  # Function to solve
  t0_solver <- function(t0) {
    num <- 1 - exp(-k * (A_min - t0))
    den <- 1 - exp(-k * (A_max - t0))
    ratio <- L_min / L_max
    return(num / den - ratio)
  }
  
  # Find root
  t0 <- uniroot(t0_solver, c(-10, 5))$root
  
  return(t0)
}


t0F <- get_t0(L_min = vblFMin,L_max = vblFMax,k = vblFk,A_min = 3,A_max = max(age_bins))
t0M <- get_t0(L_min = vblMMin,L_max = vblMMax,k = vblMk,A_min = 3,A_max = max(age_bins))

## Make a table of pars ests for display purposes
label_df <- data.frame(
  widow_sex = rep(c("female", "male"), each = 3),
  widow_age = c(75, 75, 75, 75, 75, 75),     # x positions
  widow_len = c(25, 20, 15, 25, 20, 15), # y positions
  label = c(paste0("Linf = ",round(vblFMax,2)),
            paste0("k = " ,round(vblFk,2)),
            paste0("t0 = ",round(t0F,2)),
            paste0("Linf = ",round(vblMMax,2)),
            paste0("k = ",round(vblMk,2)),
            paste0("t0 = ",round(t0M,2))
  ))



# Make vBL plots
ggplot(all_agelen, aes(widow_age, widow_len)) +
  # Plot PACFIN points first (will appear under other fleets)
  geom_jitter(data = filter(all_agelen, widow_fleet == "PACFIN"),
              aes(color = widow_fleet), size = 1.6) +
  # Then plot all other fleets on top
  geom_jitter(data = filter(all_agelen, widow_fleet != "PACFIN"),
              aes(color = widow_fleet), size = 1.6) +
  # VBL lines
  geom_line(data = vbl_lines %>% filter(vbl_type == "model estimated"),
            aes(widow_age, widow_len), inherit.aes = FALSE,
            color = "black", linewidth = 1) +
  #Parameetrestimate labels
  geom_text( 
    data = label_df,
    aes(x = widow_age, y = widow_len, label = label),
    inherit.aes = FALSE,
    size = 6
  ) +
  facet_wrap(~widow_sex, nrow = 2) +
  labs(x = "Age", y = "Length", color = "Fleet:") +
  theme_classic() +
  theme(
    legend.position = "bottom",
    legend.box = "vertical",
    text = element_text(size = 18)
  ) +
  scale_color_manual(
    values = c(
      "WCGBTS" = "#005BFF",
      "ASHOP" = "#FF592F",
      "Triennial" = "gray",
      "PACFIN" = "#2E8B57"
    )
  )+
  guides(colour = guide_legend(override.aes = list(size = 3)))


ggsave(file.path(plot_save_dir, 'vBL_dat.png'),  dpi = 300,  
       width = 8, height = 8, units = "in")

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
aF_2025 <- base_par$parameters["Wtlen_1_Fem_GP_1", ]$Value
bF_2025 <- base_par$parameters["Wtlen_2_Fem_GP_1", ]$Value
aM_2025 <- base_par$parameters["Wtlen_1_Mal_GP_1", ]$Value
bM_2025 <- base_par$parameters["Wtlen_2_Mal_GP_1", ]$Value
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

ggsave(file.path(plot_save_dir, 'wl_dat.png'), dpi = 300,  
       width = 5, height = 4, units = "in")

ggplot(line_est, aes(len, value, lty = name, color = name)) + 
  geom_line(lwd = 0.8) + 
  facet_wrap(~Sex) + 
  scale_linetype_manual(values = c("solid", "solid", "longdash"), labels = c("2019 assessment", "2025 assessment", "NW estimate")) + 
  scale_color_manual(values = c("gray",  "#FF592F", "#005BFF"), labels = c("2019 assessment", "2025 assessment", "NW estimate")) + 
  labs(lty = "Model", x = "Length", y = "Weight", color = "Estimate") + 
  theme_bw() + theme(legend.position = "bottom") + guides(lty="none")

ggsave(file.path(plot_save_dir, 'wl_dat_2025.png'), dpi = 300,  
       width = 5, height = 4, units = "in")

ggplot(line_est %>% filter(name != "est_2025"), aes(len, value, lty = name, color = name)) + 
  geom_line(lwd = 0.8) + 
  facet_wrap(~Sex) + 
  scale_linetype_manual(values = c("solid", "longdash"), labels = c("2019 assessment", "NW estimate")) + 
  scale_color_manual(values = c("gray", "#005BFF"), labels = c("2019 assessment", "NW estimate")) + 
  labs(lty = "Model", x = "Length", y = "Weight", color = "Estimate") + 
  theme_bw() + theme(legend.position = "bottom") + guides(lty="none")

ggsave(file.path(plot_save_dir, 'wl_dat_2019.png'), dpi = 300,  
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

