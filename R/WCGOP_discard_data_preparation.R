library(dplyr)
library(ggplot2)
old_data <- read.csv("../2019_assessment_discard.csv") %>% mutate(source = "2019 assessment")


new_data_share <- read.csv("data_provided/wcgop/discard_rates_combined_catch_share.csv") %>% 
  select(year,fleet,observed_discard_mt)%>%
  mutate(month = 7)%>%
  mutate(stderr = NA)%>%
  mutate(fleet.name = fleet)%>%
  rename(yr = year, obs = observed_discard_mt)%>%
  mutate(fleet = case_when(
    fleet == "bottomtrawl-coastwide" ~ "1",
    fleet == "midwaterhake-coastwide" ~ "2", 
    fleet == "midwaterrockfish-coastwide" ~ "2",
    fleet == "hook-and-line-coastwide" ~ "5"))%>%
  mutate(fleet.name = case_when(
    fleet.name == "bottomtrawl-coastwide" ~ "BottomTrawl",
    fleet.name == "midwaterhake-coastwide" ~ "MidwaterTrawl", 
    fleet.name == "midwaterrockfish-coastwide" ~ "MidwaterTrawl",
    fleet.name == "hook-and-line-coastwide" ~ "HnL"))


new_data_nonshare <- read.csv("data_provided/wcgop/discard_rates_noncatch_share.csv")%>% 
  select(year,fleet,obs_discard, sd_discard)%>%
  mutate(month = 7)%>%
  mutate(fleet.name = fleet)%>%
  rename(yr = year, stderr = sd_discard, obs = obs_discard)%>%
  mutate(fleet = case_when(
    fleet == "bottomtrawl-coastwide" ~ "1",
    fleet == "hook-and-line-coastwide" ~ "5"))%>%
  mutate(fleet.name = case_when(
    fleet.name == "bottomtrawl-coastwide" ~ "BottomTrawl",
    fleet.name == "hook-and-line-coastwide" ~ "HnL"))

new_data <- rbind(new_data_nonshare,new_data_share)%>%
  group_by(yr,fleet,fleet.name)%>%
  mutate(obs = sum(obs))%>%
  distinct(yr,fleet,obs,month,fleet.name)%>%
  mutate(stderr = 0.5)%>%
  mutate(source = "2025 assessment")

a <- rbind(old_data, new_data)

ggplot(a[a$yr>2010,], aes(x = yr, y = obs, color = source)) +
  geom_point() +
  geom_line() +
  facet_wrap(~ fleet, labeller = as_labeller(c("1" = "Bottom trawl", 
                                               "2" = "Midwater trawl", 
                                               "5" = "Hook & line")), ncol = 1,scales = "free_y",) +
  labs(x = "", y = "Discard (t)", color = NULL) +
  theme_minimal()

# Option 1: Just update after 2017
# Option 2: change all the discards since 2011 

files_with_discard_new_wcgop <- rbind(old_data[old_data$yr<=2010,], new_data[new_data$yr>2010,])
files_with_discard_update_only <- rbind(old_data, new_data[new_data$yr>2017,])
write.csv(files_with_discard_update_only, "discards_2025.csv", row.names = F) # Option 1
write.csv(files_with_discard_new_wcgop, "discards_2025_opt2_new_wcgop.csv", row.names = F) # Option 2
