

# Bridging plots ------------------------------------------

# List directories and model names
models <- c(
  "2019 model" = here("models", "2019 base model", "Base_45_new"),
  "update catch" = here(databridge_dir, "add_catches"),
  "update trawl disc. amnt." = here(databridge_dir, "add_discard_amounts_bt_mwt_2025_hnl_2019"),
  "update trawl + HnL disc. amnt." = here(databridge_dir, "add_discard_amounts_bt_mwt_hnl_2023_old_comps"),
  "update disc_amnt_bt_mwt_drop_hnl" = here(databridge_dir, "add_discard_amounts_bt_mwt_combine_hnl_drop_hnl_lc"),
  "update_disc_amnt_and_comps_bt_mwt_hnl" = here(databridge_dir, "add_discard_amounts_bt_mwt_hnl_2023_new_comps"),
  "update_disc_amnt_and_comps_bt_mwt_drop_hnl" = here(databridge_dir, "add_discard_comps_bt_mwt_2023_hnl_removed"),
  "update indices" = here(databridge_dir, "add_indices"),
  "update age / length comp." = basedir, 
  "" = mle_dir
  
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


# Plot comparisons
compare_ss3_mods(
  replist = combined_models_list,
  plot_dir = here("figures", "bridging"),
  plot_names = names(models), 
  filenameprefix = "bridging_", 
  legendloc = c(0.05, 1),
  subplots = c(1:2,9:12)
)
