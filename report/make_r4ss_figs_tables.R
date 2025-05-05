# code to set base model directory and update r4ss plots and tables as needed

# location of base model (TODO: change as needed)
# path is relative to /report/
# base_mod should match what's set in /report/SAR_USWC_Yellowtail_rockfish_skeleton.qmd
# so is not set here to avoid accidental mismatch
if (!exists("base_mod")) {
  cli::cli_abort(
    "base_mod not set. Please set base_mod to match what's set in /report/SAR_USWC_Yellowtail_rockfish_skeleton.qmd."
  )
}

# read model output using r4ss
model <- r4ss::SS_output(
  dir = file.path("Model_Runs", base_mod),
  SpawnOutputLabel = "Spawning output (trillions of eggs)",
  printstats = FALSE,
  verbose = FALSE
)

# make new r4ss plots
# TODO: add better fleetnames if desired
r4ss::SS_plots(model, printfolder = "../../report/r4ss_plots", uncertainty = TRUE)

# make new tables
# TODO: add better fleetnames if desired
table_all(replist = model, dir = here::here("report"))

# standard selectivity plots but with smurfs removed because 
# the use of index units 33 bypasses selectivity
SSplotSelex(
  model,
  subplots = c(1, 2),
  fleets = which(!grepl("SMURF", model$FleetNames)),
  plotdir = "report/Figures",
  plot = FALSE,
  print = TRUE
)

# make custom selectivity plot
source("Rscripts/plot_selex.R")
plot_yellowtail_tv_selex(model)

# make custom index plot
source("Rscripts/plot_indices.R")
plot_indices(
  model,
  dir = "report/Figures",
  fit = TRUE,
  log = FALSE,
  fleets = c(6, 5, 4, 7)
)

# make custom parameter prior/est plot TODO: modify to exclude male M?
SSplotPars(
  model,
  strings = "NatM_uniform_Fem_GP_1",
  ncols = 1,
  nrows = 1,
  plot = FALSE,
  print = TRUE,
  plotdir = "report/Figures",
  pheight = 3.5,
  newheaders = "Female natural mortality (M)"
)

# NOTE: manually update comparisons with Canada via script:
# Rscripts\explore_Canadian_comparisons.R

