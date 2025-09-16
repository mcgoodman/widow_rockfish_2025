
observer <- read.csv('C:/users/kiva.oken/desktop/yellowtail_2025/data/confidential/wcgop_logbook/ward_oken_observer_data_2024-09-10.csv') |>
  as_tibble() |>
  filter(AVG_LAT > 40+1/6, 
         sector == 'Midwater Rockfish',
         DATATYPE == 'Analysis Data',
         species == 'Widow Rockfish') 

em <- read.csv('C:/users/kiva.oken/desktop/yellowtail_2025/data/confidential/wcgop_logbook/ward_oken_em_data_2024-12-03.csv') |>
  as_tibble() |> 
  filter(AVG_LAT > 40+1/6, sector == 'Midwater Rockfish EM',
         species == 'Widow Rockfish') |>
  mutate(DRVID = as.character(DRVID))

theme_set(theme_bw())

catch_by_lat <- bind_rows(observer, em) |> 
  # mutate(lat_bin = cut(AVG_LAT, 25)) |>
  # tidyr::separate_wider_delim(cols = lat_bin, delim = ',', 
  #                             names = c('lo', 'hi')) |>
  # mutate(across(lo:hi, ~ as.numeric(stringr::str_remove(., '(^[:punct:])|([:punct:]$)')))) |> # punctuation at start or end of string
  # rowwise() |>
  # mutate(lat_num = mean(c_across(lo:hi))) |>
  # ungroup() |>
  # mutate(Latitude = factor(lat_num, levels = sort(unique(lat_num)))) |> 
  # group_by(Latitude) |>
  # mutate(n_tow = n()) |> 
  # filter(n_tow >= 3) |> 
  ggplot() +
  # geom_bar(aes(y = Latitude, x = -MT), stat = 'sum') +
  geom_histogram(aes(y = AVG_LAT, weight = MT)) + # KLO has checked weight argument works as expected, plots total MT/bin
  theme(legend.position = 'none') +
  scale_x_reverse() +
  scale_y_continuous(limits = c(32.5, 48.5), expand = c(0,0)) +
  # scale_x_continuous(labels = ~ -1 * .) +
  labs(x = 'Total midwater rockfish catch, 2012-2023 (mt)',
       y = 'Latitude (degrees N)')

# confidentiality check
bind_rows(observer, em) |>
  left_join(y = ggplot_build(catch_by_lat)$data[[1]], 
            by = join_by(AVG_LAT >= ymin, AVG_LAT <= ymax )) |>
  count(y) |> 
  arrange(n)
# Looks good.
  
age_by_lat <- filter(widow_bio, !is.na(Age_years)) |> 
  mutate(yr_bin = cut(Year, breaks = c(2002, 2008, 2013, 2018, 2024))) |> 
  ggplot(aes(x = Latitude_dd, y = Age_years, col = yr_bin)) + 
  geom_point(alpha = 0.25) + 
  geom_smooth(se = FALSE, ) +
  coord_flip(xlim = c(32.5, 48.5), expand = FALSE) +
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
#  geom_sf(data = coast) +
  geom_sf(data = states) +
  coord_sf(xlim = c(-117, -125.8), ylim = c(32.5, 48.5), expand = FALSE) +
  scale_x_continuous(breaks = seq(-125, -117, 2)) +
  theme(axis.text.y = element_blank(),
        axis.title.y = element_blank(),
        axis.title.x = element_text(color = 'white')) +
  viridis::scale_color_viridis(discrete = TRUE, option = 'mako', direction = -1) +
  NULL
  
cowplot::plot_grid(catch_by_lat, age_by_lat, widow_map, 
                   nrow = 1, rel_widths = c(1, 1, 1.25), labels = 'auto')


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
  