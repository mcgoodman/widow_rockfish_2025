
library("tidyverse")
library("here")
library("sdmTMB")
library("sf")
library("rnaturalearth")
library("cartomisc") # devtools::install_github("statnmap/cartomisc)
library("nwfscSurvey")

# Spatial information: Port code, Pacfin catch area code
load(here("data_provided", "PacFIN", "PacFIN.WDOW.CompFT.25.Mar.2025.RData"))

# WCGBTS
load(here("data_provided", "WCGBTS", "delta_gamma", "index", "predictions.rdata"))

predictions <- predictions |>
  mutate(biomass = plogis(est1) * exp(est2))

# Make sf grid to predict on 
crs <- sdmTMB::get_crs(predictions, c("longitude", "latitude"))

# Grid to reample predictions onto for plotting
grid <- predictions |> 
  mutate(x = x * 1000, y = y * 1000) |> 
  select(x, y) |> unique() |> 
  st_as_sf(coords = c("x", "y"), crs = crs) |> 
  st_bbox() |> 
  st_make_grid(n = c(150, 300)) |> 
  st_as_sf()

# Resample predictions by year

years <- unique(predictions$year)
preds <- setNames(vector("list", length = length(years)), years)

for (i in seq_along(years)) {
  
  preds_i <- predictions |> 
    filter(year == years[i]) |> 
    mutate(x = x * 1000, y = y * 1000) |> 
    st_as_sf(coords = c("x", "y"), crs = crs)
  
  preds[[i]] <- grid |> 
    st_join(preds_i) |> 
    filter(!is.na(biomass))
  
}

# State shapefiles
coast <- ne_states(
  country = c('United States of America', "Canada", "Mexico"), 
  returnclass = 'sf'
  ) |> 
  st_transform(crs) |> 
  st_crop(st_buffer(grid, 1.5e5))

# Convert to relative biomass
preds_sf <- preds |> 
  bind_rows() |> 
  group_by(year) |>
  mutate(rel_biomass = biomass/sum(biomass))

# Plot log absolute biomass
preds_map <- preds_sf |> 
  ggplot() +
  geom_sf(data = coast, color = "white") + 
  geom_sf(aes(fill = log(biomass)), color = NA) + 
  facet_wrap(~year, nrow = 3) + 
  scale_fill_viridis_c() + 
  theme_void() + 
  theme(
    strip.background = element_blank(), 
    plot.background = element_rect(fill = "white", color = NA),
    legend.position = "bottom"
  )

ggsave(here("scratch", "WCGBTS_fit_gridded.png"), preds_map, height = 10, 
       width = 12, units = "in", dpi = 500)  

# Plot log relative biomass within each year
preds_map <- preds_sf |> 
  ggplot() +
  geom_sf(data = coast, color = "white") + 
  geom_sf(aes(fill = log(rel_biomass)), color = NA) + 
  facet_wrap(~year, nrow = 3) + 
  scale_fill_viridis_c() + 
  theme_void() + 
  theme(
    strip.background = element_blank(), 
    plot.background = element_rect(fill = "white", color = NA),
    legend.position = "bottom"
  )

ggsave(here("scratch", "WCGBTS_fit_gridded_relative.png"), preds_map, height = 10, 
       width = 12, units = "in", dpi = 500)  

# Summarize by state
states <- coast |> 
  filter(name_id %in% c("Washington", "Oregon", "California") & !is.na(name_id)) |> 
  select(state = name_id)

state_buffers <- states |> 
  regional_seas(
    group = "state",
    dist = units::set_units(100, km),
    density = units::set_units(0.1, 1/km) 
  )

state_buffers <- state_buffers |> 
  st_difference(st_union(coast)) |> 
  st_crop(st_buffer(grid, 1e5)) |> 
  filter(!is.na(state))

preds_sf$state <- st_join(st_centroid(preds_sf), state_buffers)$state

# Parititon sdmTMB predictions by state over time
sdmTMB_props <- preds_sf |> 
  st_drop_geometry() |> 
  filter(!is.na(state)) |> 
  group_by(year, state) |> 
  summarize(biomass = sum(biomass), .groups = "drop") |> 
  group_by(year) |> 
  mutate(prop_biomass = biomass/sum(biomass))

sdmTMB_props |> 
  ggplot(aes(year, prop_biomass, fill = state)) + 
  geom_bar(stat = "identity", position = position_stack())

catch <- pull_catch(common_name = "widow rockfish", survey = "NWFSC.Combo")
catch <- catch |> st_as_sf(coords = c("Longitude_dd", "Latitude_dd"), crs = 4326) |> 
  st_transform(crs = crs)
catch$state <- st_join(catch, state_buffers)$state

# Partition observed WCGBTS catch by state over time
wcgbts_props <- catch |> 
  st_drop_geometry() |> 
  filter(!is.na(state)) |> 
  group_by(Year, state) |> 
  summarize(biomass = sum(cpue_kg_km2), .groups = "drop") |> 
  group_by(Year) |> 
  mutate(prop_biomass = biomass/sum(biomass))

wcgbts_props |> 
  ggplot(aes(Year, prop_biomass, fill = state)) + 
  geom_bar(stat = "identity", position = position_stack())

wcgbts_props |> 
  ggplot(aes(Year, prop_biomass, color = state)) + 
  geom_hline(
    aes(yintercept = mean), linetype = "dashed",
    data = wcgbts_props |> group_by(state) |> summarize(mean = mean(prop_biomass))
  ) + 
  geom_point() + 
  geom_line() + 
  facet_wrap(~state, ncol = 1)
