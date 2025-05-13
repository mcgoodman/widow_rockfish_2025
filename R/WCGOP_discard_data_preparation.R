library(dplyr)
library(ggplot2)
library(nwfscSurvey)
library(r4ss)
library(here)

wd <- here::here() #set directory
base_dir <- here(wd, 'models', '2019 base model', 'Base_45_new') #the base input model


old_data <- SS_read(base_dir)[["dat"]][["discard_data"]]%>% 
        mutate(source = "2019 assessment")


new_data_share <- read.csv("data_provided/wcgop/discard_rates_combined_catch_share.csv") %>% 
  select(year,fleet,observed_discard_mt)%>%
  mutate(month = 7)%>%
  mutate(stderr = 0)%>%
  rename(obs = observed_discard_mt)%>%
  filter(fleet != "midwaterhake-coastwide")%>%
  mutate(fleet = case_when(
    fleet == "bottomtrawl-coastwide" ~ "1",
    fleet == "midwaterrockfish-coastwide" ~ "2",
    fleet == "hook-and-line-coastwide" ~ "5"))


new_data_nonshare <- read.csv("data_provided/wcgop/discard_rates_noncatch_share.csv")%>% 
  select(year,fleet,obs_discard, sd_discard)%>%
  mutate(month = 7)%>%
  rename(stderr = sd_discard, obs = obs_discard)%>%
  mutate(fleet = case_when(
    fleet == "bottomtrawl-coastwide" ~ "1",
    fleet == "hook-and-line-coastwide" ~ "5"))

new_data <- rbind(new_data_nonshare,new_data_share)%>%
  group_by(year,fleet)%>%
  mutate(obs = sum(obs))%>%
  mutate(stderr = sum(stderr))%>%
  distinct(year,fleet,obs,month,stderr)%>%
  # mutate(stderr = NA)%>%
  mutate(source = "2025 assessment")

a <- rbind(old_data, new_data)

ggplot(a, aes(x = year, y = obs, color = source)) +
  geom_point() +
  geom_line() +
  facet_wrap(~ fleet, labeller = as_labeller(c("1" = "Bottom trawl", 
                                               "2" = "Midwater trawl", 
                                               "5" = "Hook & line")), ncol = 1,scales = "free_y",) +
  labs(x = "", y = "Discard (t)", color = NULL) +
  theme_minimal()

# Option 1: BT and H&L : Just extend after 2017 + MWT update entire dataset after 2010

## Bottom trawl: old data pre 2018, new data post 2018
## Midwater trawl: old data pre 2010, new data post 2010
##Hnl: no old data, only new data
new_discards_2025 <- rbind(old_data[old_data$year<=2017&old_data$fleet==1,],
                           new_data[new_data$year>=2018&new_data$fleet==1,],
                           old_data[old_data$year<=2009&old_data$fleet==2,],
                           new_data[new_data$year>=2010&new_data$fleet==2,], 
                           new_data[new_data$fleet==5,])|>
  mutate(stderr = if_else(stderr == 0, NA, stderr))
  

#sd = mean sd for discard for the fleet
new_discards_2025 <- new_discards_2025 %>%
  group_by(fleet) %>%
  mutate(stderr = if_else(
    is.na(stderr),
#    mean(stderr, na.rm = TRUE), # no longer using this line - replaced NA values with fleet mean error 
     0.05,  # fill 0.05 CV for years/fleets without error (b/c catch share, 100% observed)  
    stderr
  )) %>%
  ungroup()|>
  distinct()
  
  
write.csv(new_discards_2025, "data_derived/discards/discards_2025.csv", row.names = F) # Option 1


gemm_discard <- pull_gemm(common_name = "widow rockfish")%>% 
  mutate(sector = case_when(
    sector == "Midwater Rockfish EM" ~ "Midwater trawl",
    sector == "Midwater Rockfish" ~ "Midwater trawl", 
    sector == "Shoreside Hake" ~ "Midwater trawl", 
    sector == "CS - Bottom Trawl" ~ "Bottom trawl", 
    sector == "CS EM - Bottom Trawl" ~ "Bottom trawl", 
    sector == "LE Sablefish - Hook & Line" ~ "Hook & Line", 
    sector == "OA Fixed Gear - Hook & Line" ~ "Hook & Line", 
    sector == "CS - Hook & Line" ~ "Hook & Line", 
    sector == "CS - Bottom and Midwater Trawl" ~ "Midwater trawl"))%>%
  filter(sector %in% c("Hook & Line", "Midwater trawl", "Bottom trawl")) %>%
  group_by(year, sector)%>%
  mutate(total_discard_mt = sum(total_discard_mt))%>%
  rename(fleet.name = sector , 
         obs = total_discard_mt, 
         year = year)%>%
  mutate(month = 7, stderr = NA, source = "GEMM")%>%
  mutate(fleet = fleet.name)%>%
  mutate(fleet = case_when(
    fleet == "Midwater trawl" ~ 2,
    fleet == "Bottom trawl" ~ 1, 
    fleet == "Hook & Line"~ 5))%>%
  ungroup()%>%
  select(year, month, fleet, obs, stderr, source)


total <- rbind(a, gemm_discard)
  
ggplot(total[total$year>2010,], aes(x = year, y = obs, color = source)) +
  geom_point() +
  geom_line() +
  facet_wrap(~ fleet, labeller = as_labeller(c("1" = "Bottom trawl", 
                                               "2" = "Midwater trawl", 
                                               "5" = "Hook & line")), ncol = 1,scales = "free_y",) +
  labs(x = "", y = "Discard (t)", color = NULL) +
  theme_minimal()

