
library("tidyverse")
library("pacfintools")
library("r4ss")

dir.create(file.path("figures", "current_catches"))

# Data and settings ---------------------------------------

## PacFIN catch data
load(file.path("data_provided", "PacFIN", "PacFIN.WDOW.CompFT.12.Dec.2024.RData"))

## 2015 assessment data
catch_2015 <- read.csv(file.path("data_provided", "2015_assessment", "catch_by_state_fleet.csv"))

## 2019 assessment data
data_2019 <- r4ss::SS_readdat(file.path("data_provided", "2019_assessment", "2019widow.dat"))$catch

## Gears and fleets ---------------------------------------

### Trawl gears, except shrimp trawls
trawl_names <- unique(catch.pacfin$GEAR_NAME)[grepl("TRAWL", unique(catch.pacfin$GEAR_NAME))]
trawl_names <- trawl_names[!grepl("SHRIMP", trawl_names)]

### Codes associated with trawl, hook & line, and net fleets
trawl_codes <- unique(catch.pacfin$PACFIN_GEAR_CODE[catch.pacfin$GEAR_NAME %in% trawl_names])
hk_ln_codes <- unique(catch.pacfin$PACFIN_GEAR_CODE[catch.pacfin$GEAR_NAME == "HOOK AND LINE"])
net_codes <- unique(catch.pacfin$PACFIN_GEAR_CODE[grepl("NET", catch.pacfin$GEAR_NAME)])

### Join gear codes
gear_codes <- unique(c(trawl_codes, hk_ln_codes, net_codes))

### Associate gear codes with fleets
fleets <- case_when(
  gear_codes == "MDT" ~ "midwater trawl",
  gear_codes %in% trawl_codes & gear_codes != "MDT" ~ "bottom trawl",
  gear_codes %in% hk_ln_codes ~ "hook and line",
  gear_codes %in% net_codes ~ "net"
)

fleet_lvls <- c("bottom trawl", "midwater trawl", "hake", "net", "hook and line")

# Clean and summarize catch data --------------------------

## Long format
catch_cleaned <- catch.pacfin |> 
  filter(
    !is.na(COUNTY_STATE) & 
      IOPAC_PORT_GROUP != "PUGET SOUND" & 
      PACFIN_GEAR_CODE %in% gear_codes
  ) |>
  mutate(
    FLEET = factor(fleets[match(PACFIN_GEAR_CODE, gear_codes)], levels = fleet_lvls)
  )

## Wide format  
catch_formatted <- catch_cleaned |> formatCatch(strat = "FLEET", valuename = "LANDED_WEIGHT_MTONS")

## Match fleets from 2019 assessment
catch_2019 <- data_2019 |> 
  filter(year %in% catch_cleaned$PACFIN_YEAR) |> 
  mutate(fleet_name = factor(fleet_lvls[fleet], levels = fleet_lvls))

## Aggregate catch by year, source
all_pacfin <- catch.pacfin |> group_by(year = PACFIN_YEAR) |> summarize(landings = sum(LANDED_WEIGHT_MTONS))
all_cleaned <- catch_cleaned |> group_by(year = PACFIN_YEAR) |> summarize(landings = sum(LANDED_WEIGHT_MTONS))
all_2019 <- catch_2019 |> group_by(year) |> summarize(landings = sum(catch))

# Figures -------------------------------------------------

## Pacfin vs. 2019 comparison, coastwide ------------------
  
catch_cleaned |> 
  group_by(PACFIN_YEAR, FLEET) |> 
  summarize(landings = sum(LANDED_WEIGHT_MTONS)) |> 
  mutate(year = as.integer(PACFIN_YEAR)) |> 
  ggplot(aes(year, landings)) + 
  geom_segment(aes(xend = year, y = 0, yend = landings), data = all_2019, color = "red") + 
  geom_bar(aes(fill = FLEET), stat = "identity", width = 1, color = "black") + 
  geom_point(aes(color = "2019 asessment"), data = all_2019, size = 2) + 
  geom_point(aes(color = "all PacFIN"), data = all_pacfin, size = 2) + 
  scale_fill_viridis_d(option = "mako", begin = 0.2, end = 0.8) + 
  scale_color_manual(values = c("red", "orange")) + 
  theme_classic() + 
  scale_y_continuous(expand = c(0, 0), breaks = seq(0, 25000, 5000), limits = c(0, 28000)) +
  scale_x_continuous(breaks = seq(1980, 2024, 2)) + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5)) + 
  coord_cartesian(clip = "off") + 
  labs(color = "reference", fill = "fleet", y = "landings (metric tons)")

ggsave("figures/current_catches/PacFIN_landings_by_fleet.png", height = 5, width = 10, units = "in", dpi = 500)

catch_2019 |> 
  group_by(year, fleet_name) |> 
  summarize(landings = sum(catch)) |>
  mutate(fleet_name = factor(fleet_name, levels = fleet_lvls)) |> 
  filter(fleet_name != "hake") |> 
  ggplot(aes(year, landings)) + 
  geom_bar(aes(fill = fleet_name), stat = "identity", width = 1, color = "black") + 
  geom_point(aes(color = "cleaned PacFIN"), data = all_cleaned, size = 2) + 
  geom_point(aes(color = "all PacFIN"), data = all_pacfin, size = 2) + 
  scale_fill_viridis_d(option = "mako", begin = 0.2, end = 0.8) + 
  scale_color_manual(values = c("red", "orange")) + 
  theme_classic() + 
  scale_y_continuous(expand = c(0, 0), breaks = seq(0, 25000, 5000), limits = c(0, 28000)) +
  scale_x_continuous(breaks = seq(1980, 2024, 2)) + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5)) + 
  coord_cartesian(clip = "off") + 
  labs(color = "reference", fill = "fleet", y = "landings (metric tons)")
  
ggsave("figures/current_catches/2019_landings_by_fleet.png", height = 5, width = 10, units = "in", dpi = 500)

## By state -----------------------------------------------

states <- c("California", "Oregon", "Washington")
state_2015 <- catch_2015 |> group_by(year = Year, state) |> summarize(landings = sum(landings_mt))
state_2015$state <- states[match(state_2015$state, toupper(substr(states, 1, 2)))]
catch_cleaned$state <- states[match(catch_cleaned$COUNTY_STATE, toupper(substr(states, 1, 2)))]

catch_cleaned |> 
  group_by(year = PACFIN_YEAR, state, FLEET) |> 
  summarize(landings = sum(LANDED_WEIGHT_MTONS)) |> 
  ggplot(aes(year, landings)) + 
  geom_bar(aes(fill = FLEET), stat = "identity") + 
  geom_point(aes(color = "2015 assessment"), data = filter(state_2015, year >= 1980)) + 
  facet_wrap(~state, ncol = 1) + 
  scale_color_manual(values = "red") +
  scale_fill_viridis_d(option = "mako", begin = 0.2, end = 0.8) + 
  theme_classic() + 
  theme(
    strip.background = element_blank(), 
    strip.text = element_text(hjust = 0, face = "bold")
  ) + 
  labs(y = "landings (mt)", color = "", fill = "fleet")
  
ggsave("figures/current_catches/landings_by_state_fleet.png", height = 6, width = 10, units = "in", dpi = 500)

# Correlation -----------------------------------------------

state_fleet_pacfin <- catch_cleaned |> 
  group_by(year = PACFIN_YEAR, state, fleet = FLEET) |> 
  summarize(landings_pacfin = sum(LANDED_WEIGHT_MTONS), .groups = "drop")

state_fleet_joined <- catch_2015 |>
  mutate(state = states[match(state, toupper(substr(states, 1, 2)))]) |> 
  rename(landings_2015 = landings_mt, year = Year) |> 
  right_join(state_fleet_pacfin, by = c("year", "state", "fleet"))

state_fleet_joined |> 
  ggplot(aes(landings_2015, landings_pacfin)) + 
  geom_abline(intercept = 0, slope = 1) +
  geom_point(aes(color = fleet)) + 
  facet_wrap(~state, nrow = 1) + 
  coord_fixed() + 
  theme_bw() + 
  theme(
    strip.background = element_blank(), 
    strip.text = element_text(hjust = 0, face = "bold")
  ) + 
  labs(x = "2015 landings (mt)", y = "2019 landings (mt)") + 
  scale_color_viridis_d(option = "mako", begin = 0.2, end = 0.8)

ggsave("figures/current_catches/cor_landings_by_state_fleet.png", height = 6, width = 10, units = "in", dpi = 500)
