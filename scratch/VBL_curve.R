
library("tidyverse")
library("r4ss")
library("here")
library("nwfscSurvey")
library("mgcv")
library("cowplot")
library("readxl")

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
