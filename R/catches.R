
# Authors: Maurice Goodman, Nick Grunloh 
#
# This script serves two primary purposes: 
#
# 1. Check that the catch time series from the 2015 and 2019 assessments can be
# reconstructed using PacFIN, ASHOP, and ODFW data based on the description of
# data processing steps from the 2015 assessment.
#
# 2. Update catches from the 2019 assessment by adding recent (2019-2024) catch data, 
# adjusting 1979-1980 California trawl ratios, updating 1980-1986 Oregon catch data, 
# and updating all Washington historic (pre-2015) catch data per instructions from 
# CDFW / ODFW / WDFW contacts, as well as adding in shrimp trawls which were
# excluded from 2015 assessment to inform a sensitivity run.

library("tidyverse")
library("readxl")
library("r4ss")
library("here")

dir.create(here("figures", "current_catches"))

theme_set(
  theme_classic() + 
    theme(
      strip.background = element_blank(), 
      strip.text = element_text(hjust = 0, face = "bold")
    )
)

# 1. Compare catch reconstruction to 2015 / 2019 assessments ------------------

## Data and settings ----------------------------------------------------------

## PacFIN catch data
load(here("data_provided", "PacFIN", "PacFIN.WDOW.CompFT.25.Mar.2025.RData"))

## 2015 assessment data
catch_2015 <- read.csv(here("data_provided", "2015_assessment", "catch_by_state_fleet.csv"))
catch_2015_hake <- read.csv(here("data_provided", "2015_assessment", "catch_hake_by_state.csv"))

## 2019 assessment data - aggregate to fleet (not state + fleet) level
## State-level data in 2019 assessment report does not match 2019 data file, 
## and 2014-2018 hake catches are missing from document.
catch_2019 <- r4ss::SS_readdat(here("data_provided", "2019_assessment", "2019widow.dat"))$catch

## Oregon catch reconstruction (Source: Ali Whitman, ODFW)
catch_or <- read.csv(here("data_provided", "ODFW", "Oregon Commercial landings_431_2023.csv"))
gears_or <- read.csv(here("data_provided", "ODFW", "ODFW_Gear_Codes_PacFIN.csv"))

## ASHOP catches
catch_ashop <- read_excel(here("data_provided", "ASHOP", "A-SHOP_Widow_CatchData_removedConfidentialFields_1975-2024_012325.xlsx"))

## Washington catch reconstruction (Source: Fabio Prior Caltabellotta, WDFW)
catch_wa <- read.csv(here("data_provided", "WDFW", "wdow_wa_catch_reconstruction_bygear.csv"))

### Gears and fleets ----------------------------------------------------------

states <- c("California", "Oregon", "Washington")

### Trawl gears, except shrimp trawls
trawl_names <- unique(catch.pacfin$GEAR_NAME)[grepl("TRAWL", unique(catch.pacfin$GEAR_NAME))]
trawl_names <- trawl_names[!grepl("SHRIMP", trawl_names)]

### Codes associated with trawl, hook & line, and net fleets
trawl_codes <- unique(catch.pacfin$PACFIN_GEAR_CODE[catch.pacfin$GEAR_NAME %in% trawl_names])
hk_ln_codes <- unique(catch.pacfin$PACFIN_GEAR_CODE[grepl("LINE", catch.pacfin$GEAR_NAME)])
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

### Join 2015 catch datasets --------------------------------------------------

catch_2015 <- catch_2015_hake |> 
  mutate(fleet = "hake") |> bind_rows(catch_2015) |> 
  select(year, state, fleet, sector, landings_mt) |> 
  arrange(year, state, fleet)

catch_2015$state <- states[match(catch_2015$state, toupper(substr(states, 1, 2)))]

### Clean and summarize PacFIN catch data -------------------------------------

## Filter out Puget sound, shrimp trawls
## Classify into fleets - need to add ASHOP data to hake fleet
catch_cleaned <- catch.pacfin |> 
  filter(
    !is.na(COUNTY_STATE) & 
      IOPAC_PORT_GROUP != "PUGET SOUND" & 
      PACFIN_GEAR_CODE %in% gear_codes
  ) |>
  mutate(
    state = states[match(COUNTY_STATE, toupper(substr(states, 1, 2)))],
    fleet = fleets[match(PACFIN_GEAR_CODE, gear_codes)], 
    fleet = ifelse(DAHL_GROUNDFISH_CODE %in% c("03", "17"), "hake", fleet), 
    fleet = factor(fleet , levels = fleet_lvls)
  ) |> 
  select(year = PACFIN_YEAR, state, fleet, landings_mt = LANDED_WEIGHT_MTONS)

## Catch by state, fleet, and year
catch_st_flt_yr <- catch_cleaned |> 
  group_by(year, state, fleet) |> 
  summarize(landings_mt = sum(landings_mt), .groups = "drop") |> 
  tidyr::complete(year, state, fleet, fill = list(landings_mt = 0))

### Partition 1981-1999 Washington trawls -------------------------------------

trawl_ratio <- catch_2015 |> 
  filter(state == "Washington" & grepl("trawl", fleet) & year %in% 1979:1999) |> 
  group_by(year) |> 
  summarize(p_mdt = landings_mt[fleet == "midwater trawl"]/sum(landings_mt))

for (y in 1981:1999) {
  
  catch_st_flt_yr$landings_mt[
    catch_st_flt_yr$year == y & catch_st_flt_yr$state == "Washington" & grepl("trawl", catch_st_flt_yr$fleet)
  ] <- c(1 - trawl_ratio$p_mdt[trawl_ratio$year == y], trawl_ratio$p_mdt[trawl_ratio$year == y]) * 
    sum(
      catch_st_flt_yr$landings_mt[
        catch_st_flt_yr$year == y & catch_st_flt_yr$state == "Washington" & grepl("trawl", catch_st_flt_yr$fleet)
      ]
    )
    
}

trawl_ratio |> ggplot(aes(year, p_mdt)) + 
  geom_line() + geom_point() + 
  scale_x_continuous(breaks = 1979:1999) + 
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0), breaks = seq(0, 1, 0.1)) + 
  theme_minimal() +
  theme(
    panel.grid.minor = element_blank(), 
    panel.grid.major.x = element_blank(), 
    plot.background = element_rect(fill = "white", color = NA),
  ) + 
  ylab("Proportion midwater trawls")

ggsave(
  here("figures", "current_catches", "Washington_trawl_proportion.png"), 
  height = 5, width = 10, units = "in", dpi = 500
)

### Replace Oregon 1981-1986 catches ------------------------------------------

catch_or_cleaned <- catch_or |> 
  pivot_longer(starts_with("X"), names_prefix = "X", names_to = "CODE", values_to = "landings_mt") |> 
  left_join(mutate(gears_or, CODE = as.character(CODE)), by = "CODE") |> 
  mutate(
    gear = tolower(GEAR_DESCR),
    fleet = case_when(
      grepl("midwater", gear) ~ "midwater trawl",
      grepl("trawl", gear) ~ "bottom trawl",
      grepl("hook|line|troll", gear) ~ "hook and line",
      grepl("net", gear) & !grepl("trawl", gear) ~ "net"
    )
  ) |> 
  filter(YEAR %in% 1981:1986 & !is.na(fleet)) |> 
  group_by(year = YEAR, fleet) |> 
  summarize(landings_mt = sum(landings_mt), .groups = "drop") |> 
  mutate(state = "Oregon")

catch_st_flt_yr <- catch_st_flt_yr |> rows_update(catch_or_cleaned, by = c("state", "fleet", "year"))

### Add ASHOP data ------------------------------------------------------------

catch_ashop_cleaned <- catch_ashop |> 
  group_by(year = YEAR) |> 
  summarize(landings_mt_ashop = sum(EXPANDED_SumOfEXTRAPOLATED_2SECTOR_WEIGHT_KG)/1000) |> 
  mutate(fleet = "hake")

catch_flt <- catch_st_flt_yr |> 
  group_by(year, fleet) |> 
  summarize(landings_mt = sum(landings_mt), .groups = "drop") |> 
  left_join(catch_ashop_cleaned, by = c("year", "fleet")) |> 
  mutate(
    landings_mt_ashop = ifelse(is.na(landings_mt_ashop), 0, landings_mt_ashop), 
    landings_mt = landings_mt + landings_mt_ashop
  ) |> 
  dplyr::select(-landings_mt_ashop)

## Comparison to past assessments ---------------------------------------------

## Match fleets from 2019 assessment
catch_modern <- catch_2019 |> 
  filter(year %in% catch_cleaned$year) |> 
  mutate(fleet_name = factor(fleet_lvls[fleet], levels = fleet_lvls))

## Aggregate catch by year, source
all_pacfin <- catch.pacfin |> group_by(year = PACFIN_YEAR) |> summarize(landings_mt = sum(LANDED_WEIGHT_MTONS))
all_cleaned <- catch_st_flt_yr |> group_by(year) |> summarize(landings_mt = sum(landings_mt))
all_2019 <- catch_modern |> filter(fleet_name != "hake") |> group_by(year) |> summarize(landings_mt = sum(catch))

### Pacfin vs. 2019 comparison, coastwide -------------------------------------

catch_st_flt_yr |> 
  group_by(year, fleet) |> 
  summarize(landings_mt = sum(landings_mt)) |> 
  ggplot(aes(year, landings_mt)) + 
  geom_segment(aes(xend = year, y = 0, yend = landings_mt), data = all_2019, color = "red") + 
  geom_bar(aes(fill = fleet), stat = "identity", width = 1, color = "black") + 
  geom_point(aes(color = "2019 asessment"), data = all_2019, size = 2) + 
  geom_point(aes(color = "all PacFIN"), data = all_pacfin, size = 2) + 
  scale_fill_viridis_d(option = "mako", begin = 0.2, end = 0.8) + 
  scale_color_manual(values = c("red", "orange")) + 
  scale_y_continuous(expand = c(0, 0), breaks = seq(0, 25000, 5000), limits = c(0, 28000)) +
  scale_x_continuous(breaks = seq(1980, 2024, 2)) + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5)) + 
  coord_cartesian(clip = "off") + 
  labs(
    color = "reference", fill = "fleet", y = "landings (metric tons)", 
    title = "Reconstructed catches by fleet (non-hake)", 
    subtitle = "vs. total 2019 assessment and all PacFIN catches"
  ) 

ggsave(
  here("figures", "current_catches", "PacFIN_landings_by_fleet.png"), 
  height = 5, width = 10, units = "in", dpi = 500
)

catch_modern |> 
  group_by(year, fleet_name) |> 
  summarize(landings_mt = sum(catch)) |>
  mutate(fleet_name = factor(fleet_name, levels = fleet_lvls)) |> 
  filter(fleet_name != "hake") |> 
  ggplot(aes(year, landings_mt)) + 
  geom_bar(aes(fill = fleet_name), stat = "identity", width = 1, color = "black") + 
  geom_point(aes(color = "reconstructed catches"), data = all_cleaned, size = 2) + 
  geom_point(aes(color = "PacFIN catches"), data = all_pacfin, size = 2) + 
  scale_fill_viridis_d(option = "mako", begin = 0.2, end = 0.8) + 
  scale_color_manual(values = c("orange", "red")) + 
  scale_y_continuous(expand = c(0, 0), breaks = seq(0, 25000, 5000), limits = c(0, 28000)) +
  scale_x_continuous(breaks = seq(1980, 2024, 2)) + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5)) + 
  coord_cartesian(clip = "off") + 
  labs(
    color = "reference", fill = "fleet", y = "landings (metric tons)", 
    title = "2019 assessment catches by fleet (non-hake)", 
    subtitle = "vs. total reconstructed and all PacFIN catches"
  )
  
ggsave(
  here("figures", "current_catches", "2019_landings_by_fleet.png"), 
  height = 5, width = 10, units = "in", dpi = 500
)

### By state ------------------------------------------------------------------

state_2015 <- catch_2015 |> group_by(year, state) |>
  summarize(landings_mt = sum(landings_mt), .groups = "drop") |> 
  filter(!is.na(state))

catch_st_flt_yr |>  
  ggplot(aes(year, landings_mt)) + 
  geom_bar(aes(fill = fleet), stat = "identity") + 
  geom_point(aes(color = "2015 assessment"), data = filter(state_2015, year >= 1981)) + 
  facet_wrap(~state, ncol = 1) + 
  scale_color_manual(values = "red") +
  scale_fill_viridis_d(option = "mako", begin = 0.2, end = 0.8) + 
  scale_x_continuous(breaks = seq(1980, 2024, 2)) + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5)) +
  labs(y = "landings (mt)", color = "", fill = "fleet")
  
ggsave(
  here("figures", "current_catches", "landings_by_state_fleet.png"), 
  height = 6, width = 10, units = "in", dpi = 500
)

### Correlation ---------------------------------------------------------------

#### All years ----------------------------------------------------------------

state_fleet_joined <- catch_2015 |>
  rename(landings_2015 = landings_mt) |> 
  right_join(rename(catch_st_flt_yr, landings_pacfin = landings_mt), by = c("year", "state", "fleet"))

state_fleet_joined |> 
  filter(!is.na(landings_2015)) |> 
  ggplot(aes(landings_2015, landings_pacfin)) + 
  geom_abline(intercept = 0, slope = 1) +
  geom_point(aes(color = fleet)) + 
  facet_wrap(~state, nrow = 1) + 
  coord_fixed() +
  labs(x = "2015 landings (mt)", y = "Reconstructed landings (mt)") + 
  scale_color_viridis_d(option = "mako", begin = 0.2, end = 0.8)

ggsave(
  here("figures", "current_catches", "cor_landings_by_state_fleet.png"), 
  height = 4, width = 10, units = "in", dpi = 500
)

#### 2000 onward --------------------------------------------------------------

state_fleet_joined |> 
  filter(year >= 2000 & !is.na(landings_2015)) |> 
  ggplot(aes(landings_2015, landings_pacfin)) + 
  geom_abline(intercept = 0, slope = 1) +
  geom_point(aes(color = fleet)) + 
  facet_wrap(~state, nrow = 1, scales = "free") + 
  labs(x = "2015 landings (mt)", y = "Reconstructed landings (mt)") + 
  scale_color_viridis_d(option = "mako", begin = 0.2, end = 0.8)

ggsave(
  here("figures", "current_catches", "cor_landings_by_state_fleet_2000-2014.png"), 
  height = 4, width = 10, units = "in", dpi = 500
)

## WA reconstruction comparison -----------------------------------------------

### Trawl ---------------------------------------------------------------------

wa_trawl_adj <- catch_2015 |> 
  bind_rows(catch_2015_hake) |> 
  filter(state == "Washington" & grepl("trawl", fleet)) |>
  group_by(year) |> 
  mutate(landings_total = sum(landings_mt)) |> ungroup() |> 
  select(year, fleet, landings_mt, landings_total) |> 
  left_join(
    dplyr::select(filter(catch_wa, gear_group == "trawl"), year, landings_wa = landings_mt), 
    by = "year"
  ) |> 
  drop_na() |> 
  mutate(
    catch_prop = ifelse(landings_total == 0, 0.5, (landings_mt / landings_total)),
    landings_new = landings_wa * catch_prop, 
    landings_diff = landings_new - landings_mt
  )

wa_trawl_adj |> 
  ggplot(aes(year, landings_total)) + 
  geom_line(aes(color = "2015 landings"), linewidth = 0.8) + 
  geom_line(aes(y = landings_wa, color = "reconstruction"), linewidth = 0.8) + 
  scale_x_continuous(breaks = seq(1935, 2015, 5)) + 
  labs(title = "Total Washington trawl catch", y = "landings (mt)", color = "source") + 
  theme(
    legend.position = "bottom", 
    axis.text.x = element_text(angle = 90, vjust = 0.5)
  )

ggsave(
  here("figures", "current_catches", "WA_reconstuction_trawl_comparison.png"), 
  height = 5, width = 8, units = "in", dpi = 500
)

### Non-trawl -----------------------------------------------------------------

wa_nontrawl_adj <- catch_2015 |> 
  bind_rows(catch_2015_hake) |> 
  filter(state == "Washington" & !grepl("trawl", fleet)) |>
  group_by(year) |> 
  mutate(landings_total = sum(landings_mt)) |> ungroup() |> 
  dplyr::select(year, fleet, landings_mt, landings_total) |> 
  left_join(
    dplyr::select(filter(catch_wa, gear_group == "non-trawl"), year, landings_wa = landings_mt), 
    by = "year"
  ) |> 
  drop_na() |> 
  mutate(
    catch_prop = ifelse(landings_total == 0, 0.5, (landings_mt / landings_total)),
    landings_new = landings_wa * catch_prop, 
    landings_diff = landings_new - landings_mt
  )

wa_nontrawl_adj |> 
  ggplot(aes(year, landings_total)) + 
  geom_line(aes(color = "2015 landings"), linewidth = 0.8) + 
  geom_line(aes(y = landings_wa, color = "reconstruction"), linewidth = 0.8) + 
  scale_x_continuous(breaks = seq(1920, 2015, 5)) + 
  labs(title = "Total Washington non-trawl catch", y = "landings (mt)", color = "source") + 
  theme(
    legend.position = "bottom", 
    axis.text.x = element_text(angle = 90, vjust = 0.5)
  )

ggsave(
  here("figures", "current_catches", "WA_reconstuction_nontrawl_comparison.png"), 
  height = 5, width = 8, units = "in", dpi = 500
)

# 2. Output catch for 2025 assessment update ----------------------------------

dir.create(save_dir <- here("data_derived", "catches/"))

## Adjust 1979-2019 CA midwater / bottom trawl ratio --------------------------

# Proportion of trawls in 1981-1982 in California which are midwater
ca_81_82 <- catch_2015 |> filter(year %in% 1981:1982 & state == "California" & grepl("trawl", fleet))
prop_mdt <- sum(ca_81_82$landings_mt[ca_81_82$fleet == "midwater trawl"])/sum(ca_81_82$landings_mt)

# Difference between expected and actual midwater landings in 1979-1980
ca_79_80 <- catch_2015 |> filter(year %in% 1979:1980 & state == "California" & grepl("trawl", fleet))
mdt_exp <- prop_mdt * aggregate(ca_79_80$landings_mt, by = list(year = ca_79_80$year), sum)$x
mdt_diff <- mdt_exp - ca_79_80$landings_mt[ca_79_80$fleet == "midwater trawl"]

# Adjust historical catch data accordingly 
catch_2019_adj <- catch_2019
catch_2019_adj$catch[catch_2019_adj$fleet == 2 & catch_2019_adj$year %in% 1979:1980] <- 
  catch_2019_adj$catch[catch_2019_adj$fleet == 2 & catch_2019_adj$year %in% 1979:1980] + mdt_diff
catch_2019_adj$catch[catch_2019_adj$fleet == 1 & catch_2019_adj$year %in% 1979:1980] <- 
  catch_2019_adj$catch[catch_2019_adj$fleet == 1 & catch_2019_adj$year %in% 1979:1980] - mdt_diff

write.csv(catch_2019_adj, here(save_dir, "2019_catch_adjusted.csv"), row.names = FALSE)

## Data since 2019 ------------------------------------------------------------

new_data <- catch_flt |> 
  filter(year >= 2019 & year <= 2024) |> 
  mutate(
    seas = 1, 
    fleet = as.integer(factor(fleet, levels = fleet_lvls)), 
    catch_se = 0.01
  ) |> 
  dplyr::select(year, seas, fleet, catch = landings_mt, catch_se) |> 
  arrange(fleet, year) |> 
  as.data.frame()

catch_2025 <- new_data |> bind_rows(catch_2019_adj) |> arrange(fleet, year)

write.csv(catch_2025, here(save_dir, "2025_catches.csv"), row.names = FALSE)

## Add shrimp trawls (sensitivity run) ----------------------------------------

catch_2025_wshrimp <- catch.pacfin |> 
  filter(!is.na(COUNTY_STATE) & IOPAC_PORT_GROUP != "PUGET SOUND") |>
  mutate(shrimp = grepl("shrimp", tolower(GEAR_NAME))) |> 
  filter(shrimp) |> 
  group_by(year = PACFIN_YEAR) |> 
  summarize(catch_shrimp = sum(LANDED_WEIGHT_MTONS), .groups = "drop") |> 
  mutate(seas = 1, fleet = 1) |> 
  right_join(catch_2025, by = c("year", "seas", "fleet")) |> 
  mutate(catch_shrimp = ifelse(is.na(catch_shrimp), 0, catch_shrimp), catch = catch + catch_shrimp) |> 
  dplyr::select(-catch_shrimp) |> 
  arrange(fleet, year)

write.csv(catch_2025_wshrimp, here(save_dir, "2025_catch_shrimp_added.csv"), row.names = FALSE)

catch_2025_wshrimp |> 
  dplyr::select(year, seas, fleet, catch_wshrimp = catch) |> 
  left_join(catch_2025) |> 
  group_by(year) |> 
  summarize(catch = sum(catch), catch_wshrimp = sum(catch_wshrimp)) |> 
  mutate(shrimp_prop = (catch_wshrimp - catch)/catch) |> 
  filter(year >= 1981) |> 
  ggplot(aes(year, shrimp_prop)) + 
  geom_line(linewidth = 1) + 
  labs(y = "Shrimp trawl catch proportion") + 
  scale_x_continuous(breaks = seq(1982, 2024, 2)) + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5))

ggsave(
  here("figures", "current_catches", "proportion_shrimp_trawls.png"), 
  height = 3, width = 6, units = "in", dpi = 500
)

## WA catch reconstruction (sensitivity run) ----------------------------------

wa_adj <- bind_rows(
  dplyr::select(wa_trawl_adj, year, fleet, landings_diff), 
  dplyr::select(wa_nontrawl_adj, year, fleet, landings_diff)
)

wa_adj$fleet <- match(wa_adj$fleet, fleet_lvls)

catch_2025_wa <- catch_2025 |> 
  left_join(wa_adj, by = c("year", "fleet")) |> 
  mutate(catch = catch + ifelse(is.na(landings_diff), 0, landings_diff)) |> 
  dplyr::select(-landings_diff) |> 
  arrange(fleet, year)

write.csv(catch_2025_wa, here(save_dir, "2025_catch_wa_reconstruction.csv"), row.names = FALSE)

## Catch by state, fleet, and year (tables 1 and 2) ---------------------------

## Catches from 2019 are carried forward, but the state-level catches in the 2019
## assessment document are wrong (do not match dat file). For table 1, total catches from 
## 2015-2018 in 2019 widow dat are partitioned among states using the ratios in the recently
## queried PacFin data. Total catches by fleet 2014-2018 match closely between PacFin
## and 2019 widow dat so the error from this approach is not large.

## Apply midwater / bottom trawl adjustment for CA 1979-1980
catch_2015$landings_mt[catch_2015$year %in% 1979:1980 & catch_2015$state == "California" & catch_2015$fleet == "midwater trawl"] <- 
  catch_2015$landings_mt[catch_2015$year %in% 1979:1980 & catch_2015$state == "California" & catch_2015$fleet == "midwater trawl"] + mdt_diff
catch_2015$landings_mt[catch_2015$year %in% 1979:1980 & catch_2015$state == "California" & catch_2015$fleet == "bottom trawl"] <- 
  catch_2015$landings_mt[catch_2015$year %in% 1979:1980 & catch_2015$state == "California" & catch_2015$fleet == "bottom trawl"] - mdt_diff

## Rescale PacFin catches 2015-2018 to match 2019 widow dat
catch_15_18 <- catch_2019 |> 
  mutate(fleet = factor(fleet_lvls[fleet], levels = fleet_lvls)) |> 
  dplyr::select(year, fleet, landings_tot = catch) |> 
  right_join(filter(catch_st_flt_yr, year %in% 2015:2018), by = c("year", "fleet")) |> 
  group_by(year, fleet) |> 
  mutate(landings_mt = ifelse(landings_mt == 0, 0, landings_tot * (landings_mt/sum(landings_mt)))) |> 
  ungroup() |> 
  dplyr::select(year, state, fleet, landings_mt) |> 
  filter(fleet != "hake")

# At-Sea foreign and domestic hake 2015-2024
catch_ashop_15_24 <- catch_ashop_cleaned |> 
  filter(year >= 2015 & year <= 2024) |> 
  mutate(
    fleet = factor("hake", levels = fleet_lvls), 
    sector = "at-sea"
  ) |> 
  dplyr::select(year, fleet, sector, landings_mt = landings_mt_ashop)

# Shoreside hake 2015-2024
catch_hake_15_24 <- catch_st_flt_yr |> 
  filter(fleet == "hake" & year >= 2015 & year <= 2024) |>
  mutate(sector = "shoreside") |> 
  bind_rows(catch_ashop_15_24)

# Rescale 2015-2018 hake to match 2019 assessment dat
catch_hake_15_24 <- catch_2019 |> 
  mutate(fleet = factor(fleet_lvls[fleet], levels = fleet_lvls)) |> 
  dplyr::select(year, fleet, landings_tot = catch) |> 
  filter(fleet == "hake") |> 
  right_join(catch_hake_15_24, by = c("year", "fleet"))  |> 
  group_by(year) |> 
  mutate(landings_mt = ifelse(is.na(landings_tot), landings_mt, landings_tot * (landings_mt/sum(landings_mt)))) |> 
  dplyr::select(year, state, fleet, sector, landings_mt)
  
catch_formatted <- catch_2015 |> 
  bind_rows(catch_15_18) |> 
  bind_rows(catch_hake_15_24) |> 
  bind_rows(filter(catch_st_flt_yr, year >= 2019 & fleet != "hake")) |> 
  filter(year <= 2024)

write.csv(catch_formatted, here(save_dir, "2025_catch_st_flt_yr.csv"), row.names = FALSE)
