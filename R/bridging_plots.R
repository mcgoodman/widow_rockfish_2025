
library("r4ss")
library("here")
library("parallel")

launch_html <- FALSE

source(here("R", "functions", "bridging_functions.R"))

base_2019 <- here("models", "2019 base model", "Base_45_new")
databridge_dir <- here("models", "data_bridging", "finalised_data_bridging")
base_2025 <- here("models", "2025 base model")

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

# Main bridging plot --------------------------------------

# List directories and model names
models <- c(
  "2019 model" = base_2019,
  "update catch" = here(databridge_dir, "add_catches"),
  "update MWT / BT discard amount" = here(databridge_dir, "add_discard_amounts_bt_mwt_2025_hnl_2019"),
  "update discard amount" = here(databridge_dir, "add_discard_amounts_bt_mwt_combine_hnl_drop_hnl_lc"),
  "update discard composition" = here(databridge_dir, "add_discard_comps_bt_mwt_2023_hnl_removed"),
  "update indices" = here(databridge_dir, "add_indices"),
  "update age / length composition" = here(databridge_dir, "data_bridged_model_weighted"), 
  "update M, L/W, bias ramp, MWT retention (2025 base)" = base_2025
)

combined_models_list <- SSgetoutput(dirvec = models)
names(combined_models_list) <- names(models) #name the replists

# Plotting takes a long time, so do in parallel
cl <- parallel::makeCluster(length(models))

# Export required objects and packages
parallel::clusterEvalQ(cl, library(r4ss)) 
parallel::clusterExport(cl, c("models", "launch_html"))

# Run the parallel loop
combined_models_list <- parallel::clusterApply(cl = cl, x = models, fun = function(x) {
  replist <- r4ss::SS_output(x, covar = FALSE)
  r4ss::SS_plots(replist = replist, dir = x, html = launch_html)
  replist
})

parallel::stopCluster(cl) # close the cluster
names(combined_models_list) <- names(models) #name the replists

dir.create(plotdir <- here("figures", "bridging"))

# Plot comparisons
# Multiple calls for sake of legend placement

compare_ss3_mods(
  replist = combined_models_list, plot_dir = plotdir,
  plot_names = names(models), filenameprefix = "bridging_", 
  legendloc = c(0.05, 0.4), subplots = c(1:2, 11:12)
)

compare_ss3_mods(
  replist = combined_models_list, plot_dir = plotdir,
  plot_names = names(models), filenameprefix = "bridging_", 
  legendloc = c(0.05, 1), subplots = 9:10, clear_dir = FALSE
)

# HnL exploration bridging plot ---------------------------

# List directories and model names
models <- c(
  "2019 model" = base_2019,
  "update catch" = here(databridge_dir, "add_catches"),
  "update trawl disc. amnt." = here(databridge_dir, "add_discard_amounts_bt_mwt_2025_hnl_2019"),
  "update trawl + HnL disc. amnt." = here(databridge_dir, "add_discard_amounts_bt_mwt_hnl_2023_old_comps"),
  "update trawl disc. amnt., drop HnL" = here(databridge_dir, "add_discard_amounts_bt_mwt_combine_hnl_drop_hnl_lc"),
  "update trawl + HnL disc. + comp." = here(databridge_dir, "add_discard_amounts_bt_mwt_hnl_2023_new_comps"),
  "update trawl disc. + comp., drop HnL" = here(databridge_dir, "add_discard_comps_bt_mwt_2023_hnl_removed"),
  "update indices" = here(databridge_dir, "add_indices"),
  "update M, L/W, bias ramp, trawl ret. (2025 base)" = base_2025
)

combined_models_list <- SSgetoutput(dirvec = models)
names(combined_models_list) <- names(models) #name the replists

# Plotting takes a long time, so do in parallel
cl <- parallel::makeCluster(length(models))

# Export required objects and packages
parallel::clusterEvalQ(cl, library(r4ss)) 
parallel::clusterExport(cl, c("models", "launch_html"))

# Run the parallel loop
combined_models_list <- parallel::clusterApply(cl = cl, x = models, fun = function(x) {
  replist <- r4ss::SS_output(x, covar = FALSE)
  r4ss::SS_plots(replist = replist, dir = x, html = launch_html)
  replist
})

parallel::stopCluster(cl) # close the cluster
names(combined_models_list) <- names(models) #name the replists

dir.create(plotdir <- here("figures", "bridging", "HnL"))

# Plot comparisons
compare_ss3_mods(
  replist = combined_models_list,
  plot_dir = plotdir,
  plot_names = names(models), 
  filenameprefix = "bridging_HnL_", 
  legendloc = c(0.05, 1),
  subplots = c(1:2,9:12)
)
