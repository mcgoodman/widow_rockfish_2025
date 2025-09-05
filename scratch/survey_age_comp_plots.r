## Proportion of older fish

library("nwfscSurvey")
library("dplyr")
library("here")
library(ggplot2)


widow  <-  pull_bio(common_name = "widow rockfish", survey = "NWFSC.Combo")

library(patchwork)  # for combining plots

# > 20, > 25 , >30 year plots
widow |> 
  filter(!is.na(Age_years)) |> 
  group_by(Year) |> 
  summarise(pct20 = mean(Age_years > 20), pct25 = mean(Age_years > 25), pct30 = mean(Age_years > 30)) |> 
  tidyr::pivot_longer(cols = -Year, names_to = 'age', values_to = 'pct_freq') |> 
  mutate(age = stringr::str_remove(age, 'pct')) |> 
  ggplot(aes(x = Year, y = pct_freq, fill = age)) + 
  geom_area(position = "stack", alpha = 0.7) + 
  geom_segment(x = 2018, xend = 2018, y = 0, yend = 1, 
               linetype = "longdash", color = "black", size = 1) +
  geom_segment(x = 2024, xend = 2024, y = 0, yend = 1, 
               linetype = "longdash", color = "black", size = 1) +
  annotate("text", x = 2018, y = 0, label = "2018 Survey", 
           hjust = 0.5, vjust = 2, angle = 0, color = "black", fontface = "bold") +
  annotate("text", x = 2024, y = 0, label = "2024 Survey", 
           hjust = 0.5, vjust = 2, angle = 0, color = "black", fontface = "bold") +
  scale_fill_manual(name = "Age >", values = paletteer::paletteer_d("yarrr::xmen")) +
  labs(y = "% frequency") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5)) +
  ggtitle("WCGBTS age composition 2003 - 2024")


#All ages binned plots
widow |> 
  filter(!is.na(Age_years)) |> 
  group_by(Year) |> 
  summarise(
    age_0_9 = mean(Age_years <= 9), 
    age_10_19 = mean(Age_years >= 10 & Age_years <= 19),
    age_20_24 = mean(Age_years >= 20 & Age_years <= 24),
    age_25_29 = mean(Age_years >= 25 & Age_years <= 29),
    age_30_39 = mean(Age_years >= 30 & Age_years <= 39),
    age_40_plus = mean(Age_years >= 40),
    .groups = 'drop'
  ) |> 
  tidyr::pivot_longer(cols = -Year, names_to = 'age_bin', values_to = 'pct_freq') |> 
  mutate(age_bin = factor(age_bin, 
                          levels = c("age_0_9", "age_10_19", "age_20_24", "age_25_29", "age_30_39", "age_40_plus"),
                          labels = c("0-9", "10-19", "20-24", "25-29", "30-39", "40+"))) |> 
  ggplot(aes(x = Year, y = pct_freq, fill = age_bin)) + 
  geom_area(position = "stack", alpha = 0.7) + 
  geom_segment(x = 2018, xend = 2018, y = 0, yend = 1, 
               linetype = "longdash", color = "black", size = 1) +
  geom_segment(x = 2024, xend = 2024, y = 0, yend = 1, 
               linetype = "longdash", color = "black", size = 1) +
  annotate("text", x = 2018, y = 0, label = "2018 Survey", 
           hjust = 0.5, vjust = 2, angle = 0, color = "black", fontface = "bold") +
  annotate("text", x = 2024, y = 0, label = "2024 Survey", 
           hjust = 0.5, vjust = 2, angle = 0, color = "black", fontface = "bold") +
  scale_fill_manual(name = "Age (years)", values = paletteer::paletteer_d("yarrr::xmen")) +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(y = "Proportion of sample", x = "Year") +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    legend.position = "right"
  ) +
  ggtitle("WCGBTS age composition 2003 - 2024")
