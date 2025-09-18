theme_set(theme_bw())

# Get data
observer <- read.csv('data_provided/wcgop/ward_oken_observer_data_2024-09-10.csv') |>
  as_tibble() |>
  filter(sector == 'Midwater Rockfish',
         DATATYPE == 'Analysis Data',
         species == 'Widow Rockfish') 

em <- read.csv('data_provided/wcgop/ward_oken_em_data_2024-12-03.csv') |>
  as_tibble() |> 
  filter(species == 'Widow Rockfish',
         sector == 'Midwater Rockfish EM') |>
  mutate(DRVID = as.character(DRVID))

widow_catch <- nwfscSurvey::pull_catch(survey = 'NWFSC.Combo', common_name = 'widow rockfish')
widow_bio <- nwfscSurvey::pull_bio(survey = 'NWFSC.Combo', common_name = 'widow rockfish')

#### Following code copied from Eric ####
# Goal to to filter out tows on land and outside the U.S. EEZ

# Convert to sf and then SpatVector crs 4326 = WGS84
tows_v <- bind_rows(observer, em) |>
  sf::st_as_sf(coords = c('AVG_LONG', 'AVG_LAT'), crs = 4326) |>
  terra::vect()

# US EEZ
eez_all <- terra::vect("data_provided/wcgop/World_EEZ_v12_20231025/eez_v12.shp")
us_eez <- eez_all[eez_all$GEONAME == "United States Exclusive Economic Zone", ]

# land vs ocean
land_vect <- rnaturalearth::ne_countries(scale = 10, returnclass = "sf") |>
  terra::vect()

# create a raster template (same for both masks)
# make 'res' finer for finer scale resolion, 0.1 ~ 11km, 0.01 ~ 1.1km
r_template <- terra::rast(res = 0.01, extent = terra::ext(tows_v), crs = "EPSG:4326")

# rasterize land and EEZ separately
r_land <- terra::rasterize(land_vect, r_template, field = 1)  # land = 1, ocean = NA
r_eez  <- terra::rasterize(us_eez, r_template, field = 1)     # in EEZ = 1, outside = NA

# extract land and EEZ values ----
vals_land <- terra::extract(r_land, tows_v)[,2]
vals_eez  <- terra::extract(r_eez, tows_v)[,2]

#########################################

catch_by_lat <- bind_rows(observer, em) |> 
  mutate(is_ocean = is.na(vals_land) & !is.na(vals_eez)) |>
  filter(is_ocean, AVG_LAT > 42) |> # only 2 vessels fish south of 42 deg, confidentiality issues
  ggplot() +
  geom_histogram(aes(y = AVG_LAT, weight = MT), bins = 30) + # KLO has checked weight argument works as expected, plots total MT/bin
  theme(legend.position = 'none') +
  scale_x_reverse() + 
  scale_y_continuous(limits = c(32.5, 49), expand = c(0,0)) +
  labs(x = 'Total midwater rockfish catch, 2012-2023 (mt)',
       y = 'Latitude (degrees N)')

# confidentiality check
bind_rows(observer, em) |> 
  mutate(is_ocean = is.na(vals_land) & !is.na(vals_eez)) |>
  filter(is_ocean, AVG_LAT > 42) |>
  left_join(y = ggplot_build(catch_by_lat)$data[[1]], 
            by = join_by(AVG_LAT >= ymin, AVG_LAT <= ymax )) |>
  group_by(y) |> 
  summarise(n = length(unique(DRVID))) |>
  arrange(n)
# minimum n = 3, looks good

age_by_lat <- filter(widow_bio, !is.na(Age_years)) |> 
  mutate(yr_bin = cut(Year, breaks = c(2002, 2008, 2013, 2018, 2024))) |> 
  ggplot(aes(x = Latitude_dd, y = Age_years, col = yr_bin)) + 
  geom_point(alpha = 0.25) + 
  geom_smooth(se = FALSE, ) +
  coord_flip(xlim = c(32.5, 49), expand = FALSE) +
  scale_y_reverse() +
  theme(axis.text.y = element_blank(), 
        axis.title.y = element_blank(),
        legend.position = 'none') +
  viridis::scale_color_viridis(discrete = TRUE, option = 'mako', direction = -1) +
  NULL

coast <- rnaturalearth::ne_coastline(scale = 10)
states <- rnaturalearth::ne_states(country = c('united states of america', 'canada'))

widow_map <- widow_catch |>
  filter(cpue_kg_km2 > 0) |>
  mutate(yr_bin = cut(Year, breaks = c(2002, 2008, 2013, 2018, 2024))) |> 
  ggplot() +
  geom_point(aes(x = Longitude_dd, y = Latitude_dd, size = cpue_kg_km2, col = yr_bin), 
             alpha = 0.25) +
  guides(color = guide_legend(override.aes = list(alpha = 1, 
                                                  linetype = 1), 
                              title = 'Year bin')) +
  xlab('Longitude (degrees W)') +
#  geom_sf(data = coast) +
  geom_sf(data = states) +
  coord_sf(xlim = c(-117, -125.8), ylim = c(32.5, 49), expand = FALSE) +
  scale_x_continuous(breaks = seq(-125, -117, 2)) +
  theme(axis.text.y = element_blank(),
        axis.title.y = element_blank()) +
  viridis::scale_color_viridis(discrete = TRUE, option = 'mako', direction = -1) +
  NULL
  
cowplot::plot_grid(catch_by_lat, age_by_lat, widow_map, 
                   nrow = 1, rel_widths = c(1, 1, 1.25), labels = 'auto')

# explore binning by latitude, smothing by year
catch_by_lat +
  geom_hline(yintercept = 45.5) +
  geom_hline(yintercept = 47.25) +
  geom_hline(yintercept = 43.5) +
  NULL

widow_bio |>
  mutate(lat_bin = cut(Latitude_dd, breaks = c(31, 43.5, 45.5, 47.25, 49))) |>
  filter(Latitude_dd > 40, Year >= 2017) |>
  ggplot(aes(x = Year, y = Age_years, col = lat_bin)) +
  geom_point(alpha = 0.25) +
  stat_smooth(method = 'lm') +
  geom_vline(xintercept = 2018.5) +
  viridis::scale_color_viridis(discrete = TRUE, option = 'mako')

# spatial map of fishery catch (likely confidential)
bind_rows(observer, em) |> 
  mutate(is_ocean = is.na(vals_land) & !is.na(vals_eez)) |>
  filter(is_ocean) |>
  ggplot() +
  geom_sf(data = states) +
  coord_sf(xlim = c(-117, -131), ylim = c(32.5, 49), expand = FALSE) +
  # geom_point(aes(x = AVG_LONG, y = AVG_LAT, color = is_ocean))
  stat_summary_hex(aes(x = AVG_LONG, y = AVG_LAT, z = MT), fun = 'sum') +
  #  geom_sf(data = coast) +
  # scale_x_continuous(breaks = seq(-135, -117, 2)) +
  theme(axis.text.y = element_blank(),
        axis.title.y = element_blank()) +
  viridis::scale_color_viridis(discrete = TRUE, option = 'mako', direction = -1) +
  NULL

old_widow_map <- 
  