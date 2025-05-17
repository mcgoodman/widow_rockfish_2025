### Processing WCGOP discard data ####
## authors Alaia M, Laura Spencer, Mico Kinneen ###



library(dplyr)
library(ggplot2)
library(nwfscSurvey)
library(r4ss)
library(here)

wd <- here::here() #set directory
base_dir <- here(wd, 'models', '2019 base model', 'Base_45_new') #the base input model


old_data <- SS_read(base_dir)[["dat"]][["discard_data"]]%>% 
  mutate(source = "2019 assessment")

#---------------- Catch share data 
# Observer rate Trawl fleets is close to 100%, so use 0.05 as the standard error
new_data_share <- read.csv("data_provided/wcgop/discard_rates_combined_catch_share.csv") %>% 
select(year,fleet,observed_discard_mt)%>%
  mutate(month = 7)%>%
  rename(obs = observed_discard_mt)%>%
  filter(fleet != "midwaterhake-coastwide")%>%
  mutate(fleet = case_when(
    fleet == "bottomtrawl-coastwide" ~ "1",
    fleet == "midwaterrockfish-coastwide" ~ "2",
    fleet == "hook-and-line-coastwide" ~ "5"))|>
  mutate(stderr = if_else(fleet == 5,
                          0.5, # Observed at 13 % so make this large
                          0.05))%>% # 100% obsered
  
  arrange(fleet)



#---------------- Non-cacth share
new_data_nonshare <- read.csv("data_provided/wcgop/discard_rates_noncatch_share.csv")%>% 
  select(year,fleet,obs_discard, sd_discard,median_discard)%>%
  mutate(month = 7,
         stderr = sd_discard/median_discard)%>%
  mutate(fleet = case_when(
    fleet == "bottomtrawl-coastwide" ~ "1",
    fleet == "hook-and-line-coastwide" ~ "5"))|>
  rename(obs = obs_discard)|>
  select(year,fleet,obs,stderr)



#To pupulate NaN and 0 values, for HnL fleets, use an average over non-0 years. 
hnl_ncs_mean_cv <- new_data_nonshare|>filter(fleet  == 5 & stderr != 0)|>
  group_by(fleet)|>
  summarise(mean_cv = mean(stderr,na.rm = T))|>
  select(mean_cv)


#Now add it back into the non catch share
new_data_nonshare <-  new_data_nonshare |>
  dplyr::mutate(
    stderr = dplyr::if_else(
      fleet == 5 & (stderr == 0 | is.na(stderr)),
      hnl_ncs_mean_cv$mean_cv,
      stderr
    )
  )


#-------------- Combine the fleets
combined_discard_data <- bind_rows(new_data_share, new_data_nonshare) |>
  group_by(year,fleet) |>
  summarise(
    obs = sum(obs, na.rm = TRUE),
    stderr = mean(stderr, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(obs = if_else(obs == 0, 0.001,obs))|> # model wotn fit 0's, so make small number
  arrange(fleet)|>
  mutate(month = 7)|>
  select(year,month,fleet,obs,stderr)


## - PLot to check
ggplot(combined_discard_data, aes(x = year, y = log(obs)),col = fleet) +
  geom_point() +
  geom_errorbar(aes(
    ymin = log(obs) - 1.96 * sqrt(log(1 + stderr^2)),
    ymax = log(obs) + 1.96 * sqrt(log(1 + stderr^2)),
    col = fleet
  ), width = 0.2) +
  facet_grid(rows = vars(fleet), labeller = as_labeller(c("1" = "Bottom trawl", 
                                                          "2" = "Midwater trawl", 
                                                          "5" = "Hook & line"))) +
  labs(
    y = "Log(Observed value)",
    x = "Year",
    title = "Log-scale Dsicards with 95% CI Error Bars (from CV)"
  ) +
  theme_minimal()

write.csv(combined_discard_data, "data_derived/discards/discards_2025.csv", row.names = F) # Option 1

















