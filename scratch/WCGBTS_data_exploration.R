
# Setup ---------------------------------------------------

library("nwfscSurvey")
library("mgcv")

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

# Download data -------------------------------------------

# Pull scientific catch survey data
catch <- pull_catch(common_name = species, survey = survey)

# Age, length, weight
bio <- pull_bio(common_name = species, survey = survey)

# Plot bio patterns by depth / latitude -------------------

# Log(CPUE) by latitude, depth
plot_cpue(catch, plot = 1)

# Length & sex by latitude, depth
plot_bio_patterns(bio = bio, col_name = "Length_cm", plot = 1)

# Sex by depth
sex_gam <- gam(Sex ~ s(Depth_m, k = 6), data = mutate(bio, Sex = Sex == "F"), family = binomial(link = "logit"))
plot(sex_gam, trans = plogis, xlim = c(50, 400), ylim = c(0, 1), scheme = 1, xlab = "Depth (m)", ylab = "P(female)", shift = coef(sex_gam)[1])

# Length by depth
length_gam <- gam(log(Length_cm) ~ s(Depth_m, k = 6), data = bio)
plot(length_gam, trans = exp, xlim = c(50, 400), ylim = c(0, 50), scheme = 1, xlab = "Depth (m)", ylab = "Length (cm)", shift = coef(length_gam)[1])

# Design-based biomass index ------------------------------

biomass = get_design_based(catch, strata = strata)

# Design-based biomass over time
plot_index(biomass, plot = 1)

# Design-based biomass over time by strata
plot_index(biomass, plot = 2)

# CPUE over space and time
PlotMap.fn(dat = catch)

# Length composition data ---------------------------------

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

plot_comps(length_comps)

raw_length_comps <- get_raw_comps(
  data = bio,
  comp_bins = length_bins,
  comp_column_name = "length_cm",
  two_sex_comps = TRUE
)

# Marginal age composition --------------------------------

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

plot_comps(age_comps)

# Conditional age-at-length composition -------------------

caal <- SurveyAgeAtLen.fn(
  datAL = bio, 
  datTows = catch,
  strat.df = strata,
  lgthBins = length_bins, 
  ageBins = age_bins
)

library("tidyverse")

caal_fm <- caal$female |> 
  select(year, Lbin_lo, Lbin_hi, starts_with("f"), -fleet) |> 
  pivot_longer(cols = starts_with("f"), names_to = "age", values_to = "count") |> 
  mutate(age = as.integer(gsub("f", "", age)))

caal_fm |> 
  ggplot(aes(age, Lbin_lo, fill = count)) + 
  geom_tile() + 
  facet_wrap(~year) + 
  scale_fill_viridis_c()

caal_fm_all <- caal_fm |> group_by(age, Lbin_lo) |> summarize(count = sum(count))

caal_fm_all |> 
  ggplot(aes(age, Lbin_lo, fill = count)) + 
  geom_tile() + 
  scale_fill_viridis_c()