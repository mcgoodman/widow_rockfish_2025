
library("r4ss")
library("tidyverse")
library("nwfscSurvey")
library("cowplot")
library("magick")
library("here")

base_dat <- SS_readdat(here("models", "2025 base model", "2025Widow.dat"))
base_ctl <- SS_readctl(here("models", "2025 base model", "2025Widow.ctl"), dat = here("models", "2025 base model", "2025Widow.dat"))
base_par <- SS_output(here("models", "2025 base model"))

source(here("R", "functions", "plot_selex.R"))

plotdir <- here("figures", "2025 base model r4ss plots")

# Historical estimates of SSB ---------------------------------------

theme_set(
  theme_bw() + 
    theme(
      strip.background = element_blank(), 
      strip.text = element_text(color = "black", face = "bold", size = 11),
      panel.grid = element_blank(), 
      axis.text = element_text(color = "black"), 
      axis.ticks = element_line(color = "black"), 
      axis.title = element_text(color = "black"), 
      plot.margin = margin(t = 0.25, r = 1, b = 0.25, l = 0.25, unit = "lines")
    )
)

ssb_hist <- read.csv(here("data_provided", "2019_assessment", "historical_SSB_estimates.csv"))

ssb_hist <- ssb_hist |> 
  pivot_longer(-Year, names_to = "assessment", values_to = "SSB", names_prefix = "X") |> 
  mutate(assessment = as.integer(gsub(".assessment", "", assessment, fixed = TRUE)))

ssb_2025 <- base_par$timeseries |> 
  select(Year = Yr, SSB = SpawnBio) |> 
  mutate(assessment = 2025) |> 
  filter(Year <= 2024)

ssb_hist <- ssb_hist |> bind_rows(ssb_2025)

ssb_hist$assessment <- factor(as.character(ssb_hist$assessment), levels = as.character(sort(unique(ssb_hist$assessment))))

ssb_hist_plot <- ssb_hist |> 
  ggplot(aes(Year, SSB, color = assessment)) + 
  geom_line(linewidth = 0.8) + 
  scale_color_manual(values = r4ss::rich.colors.short(length(levels(ssb_hist$assessment)))) + 
  scale_x_continuous(breaks = seq(1915, 2025, 10)) + 
  scale_y_continuous(breaks = seq(1e+04, 11e+04, length.out = 5)) +
  theme(panel.grid.major.y = element_line(color = "grey80", linetype = "dashed")) + 
  ylab("Spawning Stock Biomass (mt)") +
  coord_cartesian(clip = "off")

ggsave(
  file.path(plotdir, "SSB_historical_comparison.png"), 
  ssb_hist_plot, height = 4, width = 8, units = "in", dpi = 300
)

# Time-varying selectivity curves 2024 ------------------------------

png(
  file.path(plotdir, "combined_select_curves.png"), 
  width = 2100, height = 1500, res = 300
)
par(mfrow = c(2, 2), cex = 0.8)
for (i in c(1:3, 5)) plot_sel_ret(base_par, i)
dev.off()

# Time-varying Retention curves 2024 --------------------------------

png(
  here(plotdir, "combined_retention_curves_tv.png"), 
  width = 2100, height = 900, res = 300
)
par(mfrow = c(1, 2), cex = 0.8)
for (i in 1:2) plot_sel_ret(base_par, i, "Ret", legendloc = c(0, 0.8))
dev.off()

# Index QQ plots ----------------------------------------------------

qq_gamma <- image_read(here("data_provided", "WCGBTS", "delta_gamma", "index", "qq.png"))
qq_lnorm <- image_read(here("data_provided", "WCGBTS", "delta_lognormal", "index", "qq.png"))

combined <- image_append(c(qq_gamma, qq_lnorm))  # side-by-side

image_write(combined, path = here("figures", "combined_qq.png"))

# Recruitment -------------------------------------------------------

rec_p1 <- image_read(file.path(plotdir, "plots", "recdevs2_withbars.png"))
rec_p2 <- image_read(file.path(plotdir, "plots", "ts11_Age-0_recruits_(1000s)_with_95_asymptotic_intervals.png"))
 
combined <- image_append(c(rec_p1, rec_p2), stack = TRUE)  # vertical stack
image_write(combined, path = file.path(plotdir, "recdev_estimates_ts.png"))

# Indices -----------------------------------------------------------

index_fits <- base_par$cpue |> 
  select(Fleet_name, Year = Yr, Index = Obs, Exp, SE_input, SE) |> 
  mutate(
    lower_in = qlnorm(0.025, log(Index), SE_input), 
    upper_in = qlnorm(0.975, log(Index), SE_input), 
    lower_out = qlnorm(0.025, log(Index), SE), 
    upper_out = qlnorm(0.975, log(Index), SE)
  )

index_fits$lower_in[index_fits$SE_input == index_fits$SE] <- NA
index_fits$upper_in[index_fits$SE_input == index_fits$SE] <- NA

# Limit y-axis scale for juvenile survey
index_fits$upper_out[index_fits$Fleet_name == "JuvSurvey" & index_fits$upper_out > 5e+05] <- 5e+05

index_fits$Fleet_name[index_fits$Fleet_name == "NWFSC"] <- "WCGBTS"

index_plot <- index_fits |> 
  ggplot(aes(Year, Index)) + 
  geom_pointrange(aes(ymin = lower_out, ymax = upper_out), size = 0.25, linewidth = 0.25, lineend = "round") + 
  geom_linerange(aes(ymin = lower_in, ymax = upper_in), linewidth = 0.75, lineend = "round") + 
  geom_line(aes(y = Exp), color = "blue") + 
  facet_wrap(~Fleet_name, scales = "free", ncol = 2)

ggsave(
  file.path(plotdir, "surv_abundest.png"), 
  index_plot, height = 8, width = 8, units = "in", dpi = 300
)

# Natural mortality -------------------------------------------------

# Prior and male / female posteriors
prior <-setNames(base_ctl$MG_parms["NatM_p_1_Fem_GP_1", c("PRIOR", "PR_SD"), drop = TRUE], c("mean", "sd"))
postF <- setNames(base_par$parameters["NatM_uniform_Fem_GP_1", c("Value", "Parm_StDev"), drop = TRUE], c("mean", "sd"))
postM <- setNames(base_par$parameters["NatM_uniform_Mal_GP_1", c("Value", "Parm_StDev"), drop = TRUE], c("mean", "sd"))

# evaluate prior density
Mseq <- seq(1e-3, 0.3, length.out = 500)
prior_dens <- data.frame(type = "Prior", M = Mseq, density = dlnorm(Mseq, meanlog = prior$mean, sdlog = prior$sd))
postF_dens <- data.frame(type = "Estimated (female)", M = Mseq, density = dnorm(Mseq, mean = postF$mean, sd = postF$sd))
postM_dens <- data.frame(type = "Estimated (male)", M = Mseq, density = dnorm(Mseq, mean = postM$mean, sd = postM$sd))
dens_data <- do.call("rbind", list(prior_dens, postF_dens, postM_dens))

means <- data.frame(
  type = c("Prior", "Estimated (female)", "Estimated (male)"), 
  M = c(exp(prior$mean + (prior$sd^2)/2), postF$mean, postM$mean)
)

# Plot 
M_dens_plot <- dens_data |> 
  ggplot(aes(M, density, color = type)) + 
  geom_line(linewidth = 0.8, lineend = "round") + 
  geom_point(aes(y = -Inf),  data = means, size = 3, shape = 17) +
  labs(x = "Natural Mortality", y = "Density") + 
  scale_color_manual(values = rev(c("black", r4ss::rich.colors.short(2)))) +
  theme(
    legend.position = "inside", 
    legend.position.inside = c(0.9, 0.9), 
    legend.justification = c(1, 1), 
    legend.title = element_blank()
  ) + 
  coord_cartesian(clip = "off")

ggsave(here("figures", "2025 base model r4ss plots", "NatMort_priors.png"), height = 4, width = 6, units = "in", dpi = 300)

# Discards ----------------------------------------------------------

disc_p1 <- image_read(file.path(plotdir, "plots", "discard_fitBottomTrawl.png"))
disc_p2 <- image_read(file.path(plotdir, "plots", "discard_fitMidwaterTrawl.png"))

combined <- image_append(c(disc_p1, disc_p2), stack = TRUE)  # vertical stack
image_write(combined, path = here("figures", "2025 base model r4ss plots", "pred-obs-discards.png"))

# Length / age freq Pearson residuals -------------------------------

fleets <- base_dat$fleetnames

flt1_l <- image_read(file.path(plotdir, "plots", "comp_lenfit_residsflt1mkt2_page3.png"))
flt1_l <- flt1_l |> image_annotate(paste(fleets[1], "lengths"), size = 72, location = "+200+80")

flt1_a <- image_read(file.path(plotdir, "plots", "comp_agefit_residsflt1mkt2_page2.png"))
flt1_a <- flt1_a |> image_annotate(paste(fleets[1], "ages"), size = 72, location = "+200+80")

flt2_l <- image_read(file.path(plotdir, "plots", "comp_lenfit_residsflt2mkt2_page2.png"))
flt2_l <- flt2_l |> image_annotate(paste(fleets[2], "lengths"), size = 72, location = "+200+80")

flt2_a <- image_read(file.path(plotdir, "plots", "comp_agefit_residsflt2mkt2_page2.png"))
flt2_a <- flt2_a |> image_annotate(paste(fleets[2], "ages"), size = 72, location = "+200+80")

flt3_l <- image_read(file.path(plotdir, "plots", "comp_lenfit_residsflt3mkt0_page2.png"))
flt3_l <- flt3_l |> image_annotate(paste(fleets[3], "lengths"), size = 72, location = "+200+80")

flt3_a <- image_read(file.path(plotdir, "plots", "comp_agefit_residsflt3mkt0_page2.png"))
flt3_a <- flt3_a |> image_annotate(paste(fleets[3], "ages"), size = 72, location = "+200+80")

flt4_l <- image_read(file.path(plotdir, "plots", "comp_lenfit_residsflt4mkt0.png"))
flt4_l <- flt4_l |> image_annotate(paste(fleets[4], "lengths"), size = 72, location = "+200+80")

flt4_a <- image_read(file.path(plotdir, "plots", "comp_agefit_residsflt4mkt0.png"))
flt4_a <- flt4_a |> image_annotate(paste(fleets[4], "ages"), size = 72, location = "+200+80")

flt5_l <- image_read(file.path(plotdir, "plots", "comp_lenfit_residsflt5mkt0_page2.png"))
flt5_l <- flt5_l |> image_annotate(paste(fleets[5], "lengths"), size = 72, location = "+200+80")

flt5_a <- image_read(file.path(plotdir, "plots", "comp_agefit_residsflt5mkt0.png"))
flt5_a <- flt5_a |> image_annotate(paste(fleets[5], "ages"), size = 72, location = "+200+80")

# First three fleets
combined1 <- image_append(c(flt1_l, flt1_a))  # side-by-side
combined2 <- image_append(c(flt2_l, flt2_a))  # side-by-side
combined3 <- image_append(c(flt3_l, flt3_a))  # side-by-side
combined <- image_append(c(combined1, combined2, combined3), stack = TRUE) # vertical stack

image_write(combined, path = file.path(plotdir, "lenage-pears-res-trawl.png"))

# Other two fleets
combined1 <- image_append(c(flt4_l, flt4_a))  # side-by-side
combined2 <- image_append(c(flt5_l, flt5_a))  # side-by-side
combined <- image_append(c(combined1, combined2), stack = TRUE)  # vertical stack
image_write(combined, path = file.path(plotdir, "lenage-pears-res-hklnet.png"))

# Survey length comp fits -------------------------------------------

# Triennial survey
tri_pnl <- image_read(file.path(plotdir, "plots", "comp_lenfit_residsflt7mkt0.png"))
tri_pnl <- tri_pnl |> image_annotate(paste(fleets[7], "lengths"), size = 72, location = "+200+80")

nwfsc_pnl <- image_read(file.path(plotdir, "plots", "comp_lenfit_residsflt8mkt0.png"))
nwfsc_pnl <- nwfsc_pnl |> image_annotate(paste(fleets[8], "lengths"), size = 72, location = "+200+80")

combined <- image_append(c(tri_pnl, nwfsc_pnl))  # vertical stack
image_write(combined, path = file.path(plotdir, "comp-lenfit-trien.png"))

# Conditional age-at-lengths ----------------------------------------

# fig-condAAL-andreplot

panel1 <- image_read(file.path(plotdir, "plots", "comp_condAALfit_Andre_plotsflt8mkt0_page1.png"))
panel2 <- image_read(file.path(plotdir, "plots", "comp_condAALfit_Andre_plotsflt8mkt0_page2.png"))

panel3 <- image_read(file.path(plotdir, "plots", "comp_condAALfit_Andre_plotsflt8mkt0_page3.png"))
panel4 <- image_read(file.path(plotdir, "plots", "comp_condAALfit_Andre_plotsflt8mkt0_page4.png"))

panel5 <- image_read(file.path(plotdir, "plots", "comp_condAALfit_Andre_plotsflt8mkt0_page5.png"))
panel6 <- image_read(file.path(plotdir, "plots", "comp_condAALfit_Andre_plotsflt8mkt0_page6.png"))

combined1 <- image_append(c(panel1, panel2))  # side-by-side
combined2 <- image_append(c(panel3, panel4))  # side-by-side
combined3 <- image_append(c(panel5, panel6))  # side-by-side

combined <- image_append(c(combined1, combined2, combined3), stack = TRUE)  # vertical stack
image_write(combined, path = file.path(plotdir, "condAAL-andreplot.png"))

# fig-condAAL-resids

panel1 <- image_read(file.path(plotdir, "plots", "comp_condAALfit_residsflt8mkt0_page1.png"))
panel2 <- image_read(file.path(plotdir, "plots", "comp_condAALfit_residsflt8mkt0_page2.png"))
panel3 <- image_read(file.path(plotdir, "plots", "comp_condAALfit_residsflt8mkt0_page3.png"))

combined1 <- image_append(c(panel1, panel2))  # side-by-side
combined <- image_append(c(combined1, panel3), stack = TRUE)  # vertical stack
image_write(combined, path = file.path(plotdir, "condAAL-resids.png"))

# Retrospectives ----------------------------------------------------

panel1 <- image_read(here("figures", "diagnostics", "Retros", "compare1_spawnbio.png"))
panel2 <- image_read(here("figures", "diagnostics", "Retros", "compare9_recruits.png"))

combined <- image_append(c(panel1, panel2), stack = TRUE)
image_write(combined, path = here("figures", "diagnostics", "retros.png"))

# Likelihood profiles -----------------------------------------------

panel1 <- image_read(here("figures", "diagnostics", "Like_profile_Female_M.png"))
panel2 <- image_read(here("figures", "diagnostics", "Like_profile_Male_M.png"))

combined <- image_append(c(panel1, panel2), stack=TRUE)
image_write(combined, path = here("figures", "diagnostics", "Nat_Mort.png"))

# Decision table plot -----------------------------------------------

# pnl_cc <- image_read(here("figures", "decision_table", "cc_plots", "compare4_Bratio_uncertainty.png"))
# pnl_cc <- pnl_cc |> image_annotate("Constant catch", size = 48, location = "+200+0")

pnl_25 <- image_read(here("figures", "decision_table", "25_plots", "compare4_Bratio_uncertainty.png"))
pnl_25 <- pnl_25 |> image_annotate("ACL = p*0.25", size = 48, location = "+200+0")

pnl_45 <- image_read(here("figures", "decision_table", "45_plots", "compare4_Bratio_uncertainty.png"))
pnl_45 <- pnl_45 |> image_annotate("ACL = p*0.45", size = 48, location = "+200+0")

# combined <- image_append(c(image_append(c(pnl_cc, pnl_25)), pnl_45), stack = TRUE)
# image_write(combined, path = here("figures", "decision_table", "combined_ssb_with_interval.png"))

combined <- image_append(c(pnl_25, pnl_45), stack = TRUE)
image_write(combined, path = here("figures", "decision_table", "combined_ssb_with_interval.png"))

# Appendix A: bottom trawl retained length comps --------------------

panel1 <- image_read(file.path(plotdir, "plots", "comp_lenfit_flt1mkt2_page1.png"))
panel2 <- image_read(file.path(plotdir, "plots", "comp_lenfit_flt1mkt2_page2.png"))
panel3 <- image_read(file.path(plotdir, "plots", "comp_lenfit_flt1mkt2_page3.png"))

combined1 <- image_append(c(panel1, panel2), stack = TRUE)  # side-by-side
combined <- image_append(c(combined1, panel3), stack = TRUE)  # vertical stack
image_write(combined, path = file.path(plotdir, "App_A", "bottom_lenfit.png"))

# Appendix A: midwater trawl retained length comps ------------------

panel1 <- image_read(file.path(plotdir, "plots", "comp_lenfit_flt2mkt2_page1.png"))
panel2 <- image_read(file.path(plotdir, "plots", "comp_lenfit_flt2mkt2_page2.png"))

combined1 <- image_append(c(panel1, panel2), stack = TRUE)  # side-by-side
image_write(combined1, path = file.path(plotdir, "App_A", "midwater_lenfit.png"))

# Appendix A: hake retained length comps ----------------------------

panel1 <- image_read(file.path(plotdir, "plots", "comp_lenfit_flt3mkt0_page1.png"))
panel2 <- image_read(file.path(plotdir, "plots", "comp_lenfit_flt3mkt0_page2.png"))

combined1 <- image_append(c(panel1, panel2), stack = TRUE)  # side-by-side
image_write(combined1, path = file.path(plotdir, "App_A", "hake_lenfit.png"))

# Appendix A: HnL retained length comps -----------------------------

panel1 <- image_read(file.path(plotdir, "plots", "comp_lenfit_flt5mkt0_page1.png"))
panel2 <- image_read(file.path(plotdir, "plots", "comp_lenfit_flt5mkt0_page2.png"))

combined1 <- image_append(c(panel1, panel2), stack = TRUE)  # side-by-side
image_write(combined1, path = file.path(plotdir, "App_A", "hkl_lenfit.png"))

# Appendix A: bottom trawl retained age comps -----------------------

panel1 <- image_read(file.path(plotdir, "plots", "comp_agefit_flt1mkt2_page1.png"))
panel2 <- image_read(file.path(plotdir, "plots", "comp_agefit_flt1mkt2_page2.png"))

combined1 <- image_append(c(panel1, panel2), stack = TRUE)
image_write(combined1, path = file.path(plotdir, "App_A", "bottom_agefit.png"))

# Appendix A: midwater trawl retained age comps -----------------

panel1 <- image_read(file.path(plotdir, "plots", "comp_agefit_flt2mkt2_page1.png"))
panel2 <- image_read(file.path(plotdir, "plots", "comp_agefit_flt2mkt2_page2.png"))

combined1 <- image_append(c(panel1, panel2), stack = TRUE)  # side-by-side
image_write(combined1, path = file.path(plotdir, "App_A", "midwater_agefit.png"))

# Appendix A: hake retained age comps -------------------------------

panel1 <- image_read(file.path(plotdir, "plots", "comp_agefit_flt3mkt0_page1.png"))
panel2 <- image_read(file.path(plotdir, "plots", "comp_agefit_flt3mkt0_page2.png"))

combined1 <- image_append(c(panel1, panel2), stack = TRUE)  # side-by-side
image_write(combined1, path = file.path(plotdir, "App_A", "hake_agefit.png"))

# sdmTMB-based biomass index ----------------------------------------

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


ggsave(
  here("figures", "WCGBTS_survey", "survey_comparision_plot.png"), 
  surv_comp_plot, dpi = 300,  
  width = 5, height = 4, units = "in"
)

# length-at-age comps -----------------------------------------------

species <- "widow rockfish"
survey <- "NWFSC.Combo"

age_bins <- 0:40
length_bins <- seq(8, 56, by = 2)

strata <- nwfscSurvey::CreateStrataDF.fn(
  names = c("South - shallow", "South - deep", "North - shallow", "North - deep"), 
  depths.shallow = c(  55,  183,  55, 183),
  depths.deep    = c( 183,  400, 183, 400),
  lats.south     = c(34.5, 34.5,  40.5,  40.5),
  lats.north     = c(  40.5,   40.5,  49,  49)
)

# Pull scientific catch survey data
catch <- nwfscSurvey::pull_catch(common_name = species, survey = survey)

# Age, length, weight
bio <- nwfscSurvey::pull_bio(common_name = species, survey = survey)

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

ggsave(here("figures", "WCGBTS_survey", 'caal_WCGBTS_plot.png'), caal_WCGBTS, dpi = 300,  
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

plot_comps(length_comps, dir = here("figures", "WCGBTS_survey"))

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

plot_comps(age_comps, dir = here("figures", "WCGBTS_survey", "age_plots"))
