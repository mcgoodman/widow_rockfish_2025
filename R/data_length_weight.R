
library("nwfscSurvey")
library("dplyr")
library("ggplot2")
library("readxl")
library("here")
library("r4ss")

dir.create(data_dir <- here("data_derived", "length_weight"))
dir.create(fig_dir <- here("figures", "length_weight"))

# Data ----------------------------------------------------

# Species common name based on NWFSC survey data
common_name <- "widow rockfish"

# 2011-205 assessment data
old_assessments <- read_excel(here("data_provided", "2019_assessment", "WL_oldassessments.xlsx"))
old_assessments <- old_assessments |> rename(sex = group)

# 2019 assessment data
ctrl_2019 <- r4ss::SS_readctl(
  here("models", "2019 base model", "Base_45_new", "2019widow.ctl"), 
  dat = here("models", "2019 base model", "Base_45_new", "2019widow.dat")
)

WL_2019 <- data.frame(
  Assessment = 2019, 
  sex = c("female", "male"),
  A = ctrl_2019$MG_parms[c("Wtlen_1_Fem_GP_1", "Wtlen_1_Mal_GP_1"),]$INIT, 
  B = ctrl_2019$MG_parms[c("Wtlen_2_Fem_GP_1", "Wtlen_2_Mal_GP_1"),]$INIT
)

old_assessments <- bind_rows(old_assessments, WL_2019)

# ASHOP data
ASHOP <- read_excel(here("data_provided", "ASHOP", "A_SHOP_Widow_Ages_2003-2024_removedConfidentialFields_012725.xlsx"))

# PacFIN biological data
file_bds <- here("data_provided", "PacFIN", "PacFIN.WDOW.bds.25.Mar.2025.RData")
load(file_bds)

# Pull survey data for shelf/slope combo
common_name <- "widow rockfish"
NWFSC_survey <- nwfscSurvey::pull_bio(
  common_name = common_name,
  survey = "NWFSC.Combo"
)

# Pull triennial data
scientific_name <- "Sebastes entomelas"
tri_survey <- nwfscSurvey::pull_bio(
  sci_name = scientific_name,
  survey = "Triennial"
)

# Combine data --------------------------------------------

tri_all <- tri_survey$age_data |>
  rename(WEIGHT = Weight, LENGTH = Length_cm, SEX = Sex, YEAR = Year) |>
  select(WEIGHT, LENGTH, SEX, YEAR)

NWFSC_all <- NWFSC_survey |>
  rename(WEIGHT = Weight, LENGTH = Length_cm, SEX = Sex, YEAR = Year) |>
  select(WEIGHT, LENGTH, SEX, YEAR)

ASHOP_all <- ASHOP |>
  select(WEIGHT, LENGTH, SEX, YEAR, SPECIES)

bds <- bds.pacfin |>
  select(LENGTH = FISH_LENGTH, FISH_WEIGHT, SEX = SEX_CODE, YEAR = SAMPLE_YEAR, FISH_LENGTH_UNITS) |>
  mutate(WEIGHT = FISH_WEIGHT/1000) |> # convert to kg as that is what other data uses
  mutate(LENGTH = ifelse(FISH_LENGTH_UNITS == "CM", LENGTH, LENGTH / 10)) |> # some lengths are mm other cm; convert mm data to cm to align wiht other data
  filter(SEX == "F" | SEX == "M") |> # only getting data that we have sex id
  select(-FISH_WEIGHT, -FISH_LENGTH_UNITS)

data_list <- list(
  "WCGBTS" = NWFSC_all, 
  "ASHOP" = ASHOP_all, 
  "Triennial" = tri_all,
  "PacFIN" = bds
)

all_data <- bind_rows(data_list, .id = "Source")

# Estimate L/W relationship -------------------------------

WL_ests <- lapply(data_list, nwfscSurvey::estimate_weight_length, col_length = "LENGTH", col_weight = "WEIGHT")
WL_ests$All <- nwfscSurvey::estimate_weight_length(all_data, col_length = "LENGTH", col_weight = "WEIGHT")
WL_ests <- bind_rows(WL_ests, .id = "Source")

write.csv(WL_ests, here(data_dir, "weight_length_estimates.csv"), row.names = FALSE)

# Plots ---------------------------------------------------

theme_set(
  theme_classic() + 
    theme(
      strip.background = element_blank(), 
      strip.text = element_text(size = 14)
    )
)

# function to plot line
WL_function <- function(Lengths, A, B) A * Lengths ^ B #equation for relationship

WL_fit <- WL_ests |> 
  filter(sex == "all") |> 
  group_by(Source) |> 
  reframe(
    LENGTH = seq(0, 70, 0.1),
    WEIGHT = WL_function(LENGTH, A, B)
  )

# plotting the observations by data source (see Figure 40 from 2015)
fits_all_sources <- all_data |> 
  filter(Source != "All") |>
  ggplot(aes(LENGTH, WEIGHT, color = Source)) +
  geom_point(alpha = 0.2) +
  geom_line(aes(linewidth = Source), data = WL_fit) + 
  scale_color_manual(values = c("black", r4ss::rich.colors.short(5)[-1])) +
  scale_linewidth_manual(values = c(1.5, rep(0.5, 4))) +
  labs(x = "Length (cm)", y = "Weight (kg)") +
  coord_cartesian(xlim = c(0, 70), ylim = c(0, 3.25))

ggsave(here(fig_dir, "WL_fits_by_sex.png"), fits_all_sources, height = 4, width = 6, units = "in", dpi = 300)

# Dataset to compare 2025 to previous assessments
comparison <- WL_ests |> 
  filter(Source == "All" & sex != "all") |> 
  select(sex, A, B) |> 
  mutate(Assessment = 2025) |> 
  bind_rows(old_assessments) |> 
  mutate(Assessment = factor(Assessment))

# Curves by assessment
comparison_curves <- comparison |> 
  group_by(Assessment, sex) |> 
  reframe(
    LENGTH = seq(0, 70, 0.1),
    WEIGHT = WL_function(LENGTH, A, B)
  )

plot_data <- all_data |>
  rename(sex = SEX) |> 
  mutate(sex = case_when(sex == "M" ~ "male", sex == "F" ~ "female")) |> 
  filter(!is.na(sex))

# Plot comparison for all years
fits_all_assessments <- comparison_curves |> 
  ggplot(aes(LENGTH, WEIGHT)) +
  facet_wrap(~sex) +
  geom_point(col = 'grey', alpha = 0.2, data = plot_data) +
  scale_color_manual(values = r4ss::rich.colors.short(4)) +
  geom_line(aes(color = Assessment), linewidth = 1.25) +
  ylab("Weight (kg)") +
  xlab("Length (cm)") +
  labs(x = "Length (cm)", y = "Weight (kg)") +
  coord_cartesian(xlim = c(0, 70), ylim = c(0, 4))

ggsave(here(fig_dir, "WL_fits_by_assessment.png"), fits_all_assessments, height = 4, width = 8, units = "in", dpi = 300)

# Compare only 2019 and 2025
fits_2019_2025 <- comparison_curves |> 
  filter(Assessment %in% c("2019", "2025")) |> 
  ggplot(aes(LENGTH, WEIGHT)) +
  facet_wrap(~sex) +
  geom_point(col = 'grey', alpha = 0.2, data = plot_data) +
  geom_line(aes(color = Assessment), linewidth = 1) +
  scale_color_manual(values = c("2019" = "#FF3300FF", "2025" = "#000040FF")) +
  ylab("Weight (kg)") +
  xlab("Length (cm)") +
  labs(x = "Length (cm)", y = "Weight (kg)") +
  coord_cartesian(xlim = c(0, 70), ylim = c(0, 4))

ggsave(here(fig_dir, "WL_fits_2019_2025.png"), fits_2019_2025, height = 4, width = 8, units = "in", dpi = 300)
