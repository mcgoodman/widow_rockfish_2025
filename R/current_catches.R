
library("tidyverse")
library("pacfintools")
library("r4ss")

dir.create(file.path("figures", "current_catches"))

# Data and settings ---------------------------------------

## PacFIN catch data
load(file.path("data_provided", "PacFIN", "PacFIN.WDOW.CompFT.12.Dec.2024.RData"))

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

# Catch data ----------------------------------------------

catch_cleaned <- catch.pacfin |> 
  filter(
    !is.na(COUNTY_STATE) & 
      IOPAC_PORT_GROUP != "PUGET SOUND" & 
      PACFIN_GEAR_CODE %in% gear_codes
  ) |>
  mutate(
    FLEET = factor(fleets[match(PACFIN_GEAR_CODE, gear_codes)], levels = fleet_lvls)
  )
  
catch_formatted <- catch_cleaned |> formatCatch(strat = "FLEET", valuename = "LANDED_WEIGHT_MTONS")

catch_2019 <- data_2019 |> 
  filter(year %in% catch_cleaned$PACFIN_YEAR) |> 
  mutate(fleet_name = factor(fleet_lvls[fleet], levels = fleet_lvls))

# Figures -------------------------------------------------

all_pacfin <- catch.pacfin |> group_by(year = PACFIN_YEAR) |> summarize(landings = sum(LANDED_WEIGHT_MTONS))
all_2019 <- catch_2019 |> group_by(year) |> summarize(landings = sum(catch))
all_cleaned <- catch_cleaned |> group_by(year = PACFIN_YEAR) |> summarize(landings = sum(LANDED_WEIGHT_MTONS))
  
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

catch_cleaned |> 
  group_by(PACFIN_YEAR, COUNTY_STATE, FLEET) |> 
  summarize(landings = sum(LANDED_WEIGHT_MTONS)) |> 
  ggplot(aes(PACFIN_YEAR, landings, fill = FLEET)) + 
  geom_bar(stat = "identity") + 
  facet_wrap(~COUNTY_STATE, ncol = 1)
  