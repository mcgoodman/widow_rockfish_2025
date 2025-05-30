
library("nwfscSurvey")
library("dplyr")
library("ggplot2")
library("readxl")
library("here")

# Data ----------------------------------------------------

# Species common name based on NWFSC survey data
common_name <- "widow rockfish"

# Old assessment data
Old_assessments <- read_excel(here("data_provided", "2019_assessment", "WL_oldassessments.xlsx"))

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

# Plots ---------------------------------------------------

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
all_data |> 
  filter(Source != "All") |>
  ggplot(aes(LENGTH, WEIGHT, color = Source)) +
  geom_point(alpha = 0.2) +
  geom_line(aes(linewidth = Source), data = WL_fit) + 
  scale_color_manual(values = c("black", r4ss::rich.colors.short(5)[-1])) +
  scale_linewidth_manual(values = c(1.5, rep(0.5, 4))) +
  labs(x = "Length (cm)", y = "Weight (kg)") +
  coord_cartesian(xlim = c(0, 70), ylim = c(0, 3.25)) +
  theme_classic()

# dataset to compare 2025 to previous assessments 
# (2011 and 2015; 2019 used same weight-at-length relationship as 2015 and did not update it)
comparison <- estimated_combined |> 
  filter(Source=="All"&group!="all") |> 
  select(group, A, B) |> 
  mutate(Assessment=2025)%>%
  bind_rows(Old_assessments)

knitr::kable(comparison, "markdown")

comp<-data.frame()
for(i in 1:nrow(comparison)){
  temp_wl<-wl_function(Lengths,comparison[i,2],comparison[i,3])
  temp_df<-cbind(weight=as.numeric(temp_wl), length=as.numeric(Lengths), group=comparison[i,1],Assessment=comparison[i,4])
  comp<-rbind(temp_df,comp)
}

# plotting the comparison
ggplot(data=comp,aes(x=as.numeric(length), y=as.numeric(weight),color=Assessment)) +
  facet_wrap(~group) +
  geom_point(data=ALL, aes(x=LENGTH, y=WEIGHT),col='grey', alpha=0.2) +
  geom_line(lwd=1.25) +
   ylab("Weight (kg)") +
  xlab("Length (cm)") +
  ylim(c(0,4)) +
  xlim(c(0,70)) +
  theme_classic()

ggplot(data=ALL, aes(x=LENGTH, y=WEIGHT, col=Source)) +
  #ggtitle("2025 Data") +
  # theme(plot.title = element_text(hjust = 0.5)) +
  geom_point(alpha=0.5) +
  ylab("Weight (kg)") +
  xlab("Length (cm)") +
  ylim(c(0,4)) +
  xlim(c(0,70)) +
  theme_classic()


