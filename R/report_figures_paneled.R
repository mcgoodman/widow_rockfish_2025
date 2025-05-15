
library("r4ss")
library("dplyr")
library("ggplot2")
library("magick")
library("here")

base_dat <- SS_readdat(here("models", "2025 base model", "2025Widow.dat"))
base_par <- SS_output(here("models", "2025 base model"))

source(here("R", "functions", "plot_selex.R"))

plotdir <- here("figures", "2025 base model r4ss plots")

# Time-varying selectivity curves 2024 ------------------------------

png(
  file.path(plotdir, "combined_select_curves.png"), 
  width = 1800, height = 1800, res = 300
)
par(mfrow = c(3, 2))
for (i in 1:5) plot_sel_ret(base_par, i)
dev.off()

# Time-varying Retention curves 2024 --------------------------------

png(
  here(plotdir, "combined_retention_curves_tv.png"), 
  width = 1800, height = 1800, res = 300
)
par(mfrow = c(3, 2))
for (i in 1:5) plot_sel_ret(base_par, i, "Ret", legendloc = c(0, 0.8))
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

theme_set(
  theme_bw() + 
    theme(
      strip.background = element_blank(), 
      strip.text = element_text(color = "black", face = "bold", size = 11),
      panel.grid = element_blank(), 
      axis.text = element_text(color = "black"), 
      axis.ticks = element_line(color = "black"), 
      axis.title = element_text(color = "black"), 
      plot.margin = margin(r = 1, unit = "lines")
    )
)

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