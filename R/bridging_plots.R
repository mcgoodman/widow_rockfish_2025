
library("r4ss")
library("here")
library("parallel")
library("ggplot2")
library("dplyr")

dir.create(plotdir <- here("figures", "bridging"))

launch_html <- FALSE
if (!exists("rerun_base")) rerun_base <- TRUE

source(here("R", "functions", "bridging_functions.R"))

base_2019 <- here("models", "2019 base model", "Base_45_new")
databridge_dir <- here("models", "data_bridging", "finalised_data_bridging")
base_2025 <- here("models", "2025 base model")

# Rerun base 2019 & 2025 ----------------------------------

# With Hessian, to show uncertainty in both 
r4ss::run(base_2019, exe = set_ss3_exe(base_2019), skipfinished = !rerun_base)
r4ss::run(base_2025, exe = set_ss3_exe(base_2025), skipfinished = !rerun_base)

# Base model plots ----------------------------------------

base_rep <- SS_output(base_2025)
base_plotdir <- here("figures", "2025 base model r4ss plots")

SS_plots(replist = base_rep, dir = base_plotdir, html = launch_html)

# Taller length-at-age plot
png(
  file.path(base_plotdir, "plots", "bio2_sizeatage_plus_CV_and_SD.png"), 
  width = 2000, height = 1750, units = "px", res = 250
  )
SSplotBiology(replist = base_rep, subplots = 2)
dev.off()

# Base models, 2019 & 2025 --------------------------------

dir.create(base_compare_dir <- file.path(plotdir, "base_19_25_comparison"))

models <- c("2019 assessment" = base_2019, "2025 assessment" = base_2025)

combined_models_list <- SSgetoutput(dirvec = models)
names(combined_models_list) <- names(models) 
model_summary <- SSsummarize(combined_models_list)

# Two calls to `SSplotComparisons` for different legend placement
SSplotComparisons(
  model_summary, plotdir = base_compare_dir,
  legendlabels = names(models), filenameprefix = "base_19_25_", 
  legendloc = c(0.05, 0.2), subplots = c(2, 4, 11:12), 
  plot = FALSE, png = TRUE
)

SSplotComparisons(
  model_summary, plotdir = base_compare_dir,
  legendlabels = names(models), filenameprefix = "base_19_25_", 
  legendloc = c(0.05, 0.9), subplots = 9:10, 
  plot = FALSE, png = TRUE
)

# Main bridging plots -------------------------------------

## SSB, SPR, etc. -----------------------------------------

models <- c(
  "2019 model" = base_2019,
  "update landings" = here(databridge_dir, "add_catches"),
  "update MWT / BT discard amount" = here(databridge_dir, "add_discard_amounts_bt_mwt_2025_hnl_2019"),
  "add HnL discards to landings" = here(databridge_dir, "add_discard_amounts_bt_mwt_combine_hnl_drop_hnl_lc"),
  "update discard composition" = here(databridge_dir, "add_discard_comps_bt_mwt_2023_hnl_removed"),
  "update indices" = here(databridge_dir, "add_indices"),
  "update age / length composition" = here(databridge_dir, "data_bridged_model_weighted"), 
  "update M, L/W, bias ramp, MWT retention (2025 base)" = base_2025
)

combined_models_list <- SSgetoutput(dirvec = models)
names(combined_models_list) <- names(models) #name the replists
model_summary <- SSsummarize(combined_models_list)

SSplotComparisons(
  model_summary, plotdir = plotdir,
  legendlabels = names(models), filenameprefix = "bridging_", 
  legendloc = c(0.05, 0.4), subplots = c(1:3, 11:12), 
  plot = FALSE, png = TRUE
)

SSplotComparisons(
  model_summary, plotdir = plotdir,
  legendlabels = names(models), filenameprefix = "bridging_", 
  legendloc = c(0.05, 1), subplots = 9:10, 
  plot = FALSE, png = TRUE
)

## Natural mortality --------------------------------------

models <- c(
  "2019 model" = base_2019,
  "update removals, discard composition" = here(databridge_dir, "add_catches"),
  "update indices" = here(databridge_dir, "add_indices"),
  "update length composition" = here(databridge_dir, "add_lcomps"),
  "update age composition" = here(databridge_dir, "data_bridged_model_weighted"), 
  "update M prior" = here("models", "model_bridging", "mortality"), 
  "update L/W, bias ramp, MWT retention (2025 base)" = base_2025
)

combined_models_list <- SSgetoutput(dirvec = models)
names(combined_models_list) <- names(models) #name the replists

M_2015 <- data.frame(
  model = "2015 model",
  type = c("Prior", "Female", "Male"), 
  median = c(0.081, 0.1572, 0.1705), 
  lower = c(0.029, 0.1362, 0.1485), 
  upper = c(0.225, 0.1782, 0.1925)
)

M_bridge <- setNames(vector("list", length(combined_models_list)), names(combined_models_list))

for (i in seq_along(M_bridge)) {

  MFi <- combined_models_list[[i]]$parameters["NatM_uniform_Fem_GP_1",]
  MMi <- combined_models_list[[i]]$parameters["NatM_uniform_Mal_GP_1",]
  
  M_bridge[[i]] <- data.frame(
    model = names(M_bridge)[i],
    type = c("Prior", "Female", "Male"), 
    median = c(exp(MFi$Prior), MFi$Value, MMi$Value), 
    lower = c(qlnorm(0.025, MFi$Prior, MFi$Pr_SD), MFi$`Value-1.96*SD`, MMi$`Value-1.96*SD`), 
    upper = c(qlnorm(0.975, MFi$Prior, MFi$Pr_SD), MFi$`Value+1.96*SD`, MMi$`Value+1.96*SD`)
  )
  
}

M_bridge <- do.call("rbind", append(M_bridge, list(M_2015)))
M_bridge$model <- factor(M_bridge$model, levels = rev(c("2015 model", names(combined_models_list))))

M_plot <- M_bridge |> 
  ggplot(aes(model, median, color = type)) + 
  geom_pointrange(
    aes(ymin = lower, ymax = upper), position = position_dodge(width = 0.5), 
    size = 0.5, linewidth = 0.8, lineend = "round"
  ) + 
  scale_x_discrete(labels = function(x) stringr::str_wrap(x, width = 30)) + 
  scale_color_manual(values = rev(c("grey20", r4ss::rich.colors.short(2)))) +
  guides(color = guide_legend(reverse = TRUE)) +
  labs(y = "Natural Mortality (M)", color = "") + 
  coord_flip(clip = "off") + 
  expand_limits(y = 0) + 
  theme_bw() + 
  theme(
    panel.grid.major.y = element_blank(), 
    axis.text = element_text(size = 12, color = "black"), 
    axis.ticks = element_line(color = "black"), 
    axis.title = element_text(color = "black"), 
    plot.margin = margin(t = 0.25, r = 1, b = 0.25, l = 0.25, unit = "lines"), 
    axis.title.y = element_blank()
  )

ggsave(here(plotdir, "NatM_bridging.png"), M_plot, height = 5, width = 9, units = "in", dpi = 300)

write.csv(M_bridge, here(plotdir, "NatM_bridging.csv"), row.names = FALSE)

# HnL exploration bridging plots --------------------------

# List directories and model names
models <- c(
  "2019 model" = base_2019,
  "update catch" = here(databridge_dir, "add_catches"),
  "update trawl disc. amnt." = here(databridge_dir, "add_discard_amounts_bt_mwt_2025_hnl_2019"),
  "update trawl + HnL disc. amnt." = here(databridge_dir, "add_discard_amounts_bt_mwt_hnl_2023_old_comps"),
  "update trawl + HnL disc. + comp." = here(databridge_dir, "add_discard_amounts_bt_mwt_hnl_2023_new_comps"),
  "drop HnL disc. amnt." = here(databridge_dir, "add_discard_amounts_bt_mwt_combine_hnl_drop_hnl_lc"),
  "drop HnL disc. comp." = here(databridge_dir, "add_discard_comps_bt_mwt_2023_hnl_removed"),
  "update indices" = here(databridge_dir, "add_indices"),
  "update M, L/W, bias ramp, trawl ret. (2025 base)" = base_2025
)

combined_models_list <- SSgetoutput(dirvec = models)
names(combined_models_list) <- names(models) #name the replists
model_summary <- SSsummarize(combined_models_list)

dir.create(plotdir <- here("figures", "bridging", "HnL"))

SSplotComparisons(
  model_summary, plotdir = plotdir,
  legendlabels = names(models), filenameprefix = "bridging_HnL_", 
  legendloc = c(0.05, 1), subplots = c(1:2, 9:12), 
  plot = FALSE, png = TRUE
)