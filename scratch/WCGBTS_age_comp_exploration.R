
library("tidyverse")
library("nwfscSurvey")
library("modi")
library("here")

dir.create(fig_dir <- here("scratch", "wcgbts_agecomp"))

catch = pull_catch(common_name = "widow rockfish", survey = "NWFSC.Combo")

bio = pull_bio(common_name = "widow rockfish", survey = "NWFSC.Combo")

# Overall summary statistics over time
age_summary_coastwide <- bio |> 
  group_by(Year) |> 
  filter(!is.na(Age)) |> 
  summarize(mean = mean(Age), 
            q75 = quantile(Age, 0.75), 
            q80 = quantile(Age, 0.80),
            q85 = quantile(Age, 0.85), 
            q90 = quantile(Age, 0.90),
            q95 = quantile(Age, 0.95),
            q97.5 = quantile(Age, 0.975),
            q99 = quantile(Age, 0.99)) |> 
  pivot_longer(cols = c(mean, starts_with("q")), names_to = "statistic", values_to = "age") 
  
age_summary_coastwide |> 
  ggplot(aes(Year, age, color = statistic)) + 
  geom_line(linewidth = 1) + 
  scale_color_viridis_d(option = "mako", end = 0.9) + 
  theme_bw() + 
  theme(strip.background = element_blank(), 
        strip.text = element_text(hjust = 0)) + 
  expand_limits(y = 0)

# Define latitudinal strata

strata <- strata <- CreateStrataDF.fn(
  names = c("CA", "OR", "WA"), 
  depths.shallow = rep(55, 3),
  depths.deep    = rep(400, 3),
  lats.south     = c(32.5, 42.0, 46.0),
  lats.north     = c(42.0, 46.0, 49.0)
)

# Compute comps by strata

comps_strata <- vector("list", nrow(strata))

for (i in seq_len(nrow(strata))) {
  
  bio_i <- bio |> filter(
    Latitude_dd >= strata$Latitude_dd.1[i] & Latitude_dd < strata$Latitude_dd.2[i] & 
      Depth_m >= strata$Depth_m.1[i] & Depth_m < strata$Depth_m.2[i]
  )
  
  catch_i <- catch |> filter(
    Latitude_dd >= strata$Latitude_dd.1[i] & Latitude_dd < strata$Latitude_dd.2[i] & 
      Depth_m >= strata$Depth_m.1[i] & Depth_m < strata$Depth_m.2[i]
  )
  
  comps <- get_expanded_comps(
    bio_data = bio_i,
    catch_data = catch_i,
    comp_bins = 1:40,
    strata = strata[i,],
    comp_column_name = "Age",
    output = "full_expansion_ss3_format",
    two_sex_comps = FALSE,
    input_n_method = "stewart_hamel"
  )
  
  comps_strata[[i]] <- comps$unsexed |> mutate(strata = strata$name[i])
  
}

comps_strata <- do.call("rbind", comps_strata)

# Proportion by age bins
age_binned <- comps_strata |> 
  pivot_longer(starts_with("u"), names_to = "age", values_to = "comp", names_prefix = "u") |> 
  mutate(age = as.integer(age)) |> 
  mutate(
    age_bin = floor(age/5)*5,
    age_label = factor(paste0(age_bin, "+"), rev(paste0(seq(0, 40, 5), "+")))
    ) |> 
  group_by(year, strata, age_bin, age_label) |> 
  summarize(comp = sum(comp))

age_binned |> 
  ggplot(aes(year, comp, fill = age_label)) + 
  geom_area() + 
  facet_wrap(~strata, ncol = 1) + 
  scale_fill_viridis_d(option = "mako", end = 0.9) + 
  theme_bw() + 
  theme(strip.background = element_blank(), 
        strip.text = element_text(hjust = 0)) + 
  labs(y = "% age composition", fill = "age bin") + 
  coord_cartesian(expand = FALSE)

age_binned |> 
  filter(age_bin >= 20) |> 
  ggplot(aes(year, comp, fill = age_label)) + 
  geom_area() + 
  facet_wrap(~strata, ncol = 1) + 
  scale_fill_viridis_d(option = "mako", end = 0.9) + 
  theme_bw() + 
  theme(strip.background = element_blank(), 
        strip.text = element_text(hjust = 0)) + 
  labs(y = "% age composition", fill = "age bin") + 
  coord_cartesian(expand = FALSE)

ggsave(file.path(fig_dir, "WCGBTS_age_binned.png"), height = 6, width = 6, units = "in", dpi = 500, scale = 1.2)

# Compute mean age and age quantiles by state and year

age_stats <- comps_strata |> 
  pivot_longer(starts_with("u"), names_to = "age", values_to = "comp", names_prefix = "u") |> 
  mutate(age = as.integer(age)) |> 
  group_by(year, strata) |> 
  summarize(mean = weighted.mean(age, comp), 
            q75 = weighted.quantile(age, comp, 0.75), 
            q80 = weighted.quantile(age, comp, 0.80),
            q85 = weighted.quantile(age, comp, 0.85), 
            q90 = weighted.quantile(age, comp, 0.90),
            q95 = weighted.quantile(age, comp, 0.95)) |> 
  pivot_longer(cols = c(mean, starts_with("q")), names_to = "statistic", values_to = "age") 

age_stats |> 
  ggplot(aes(year, age, color = statistic)) + 
  geom_point(alpha = 0.5) + 
  geom_smooth(se = FALSE) + 
  facet_wrap(~strata, ncol = 1) +
  expand_limits(y = 0) + 
  theme_bw() + 
  theme(strip.background = element_blank(), 
        strip.text = element_text(hjust = 0)) + 
  labs(y = "age (WCGBTS)", color = "statistic") + 
  scale_color_viridis_d(option = "mako", end = 0.8)

ggsave(file.path(fig_dir, "WCGBTS_age_quantiles_loess.png"), height = 6, width = 6, units = "in", dpi = 500, scale = 1.2)

age_stats |> 
  ggplot(aes(year, age, color = statistic)) + 
  geom_point(alpha = 0.5) + 
  geom_smooth(method = "lm", se = FALSE) + 
  facet_wrap(~strata, ncol = 1) +
  expand_limits(y = 0) + 
  theme_bw() + 
  theme(strip.background = element_blank(), 
        strip.text = element_text(hjust = 0)) + 
  labs(y = "age (WCGBTS)", color = "statistic") + 
  scale_color_viridis_d(option = "mako", end = 0.8)

ggsave(file.path(fig_dir, "WCGBTS_age_quantiles_linear.png"), height = 6, width = 6, units = "in", dpi = 500, scale = 1.2)
