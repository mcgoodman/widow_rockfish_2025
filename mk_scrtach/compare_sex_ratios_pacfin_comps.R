widow_dat_replace_2005_2018 <- widow_2019_dat
widow_dat_replace_2005_2018$lencomp ->xx
xx|>
  setNames(colnames(widow_Comm_lcomps_2005_2025))|>
  filter(fleet %in% c(1,2,3,4,5),
         year >= 2005,
         year <= 2018)|>
  group_by(fleet,sex)|>
  summarise(n_record = n())

widow_Comm_lcomps_2005_2025|>
  filter(fleet %in% c(1,2,3,4,5),
         year >= 2005,
         year <= 2018)|>
  group_by(fleet,sex)|>
  summarise(n_record = n())

new_dat <- widow_Comm_lcomps_2005_2025|>
  filter(fleet %in% c(1,2,3,4,5),
         year >= 2005,
         year <= 2018,
         partition == 2)|>
  mutate(source = "2025_analysis",
         fleet = as.numeric(fleet))|>
  select(year,fleet,sex,partition,source)

old_dat <- tibble(xx|>
                    setNames(colnames(widow_Comm_lcomps_2005_2025))|>
                    filter(fleet %in% c(1,2,3,4,5),
                           year >= 2005,
                           year <= 2018,
                           partition == 2)|>
                    mutate(source = "2019_analysis",
                           fleet = as.numeric(fleet))|>
                    select(year,fleet,sex,partition,source))

sex_ratio <- combined_dat %>%
  group_by(year, fleet, source) %>%
  summarise(
    female_count = sum(sex == 0),
    male_count = sum(sex == 3),
    female_ratio = female_count / (female_count + male_count),
    male_ratio = male_count / (female_count + male_count),
    .groups = "drop"
  )

# First, combine the two datasets
combined_dat <- bind_rows(new_dat,
                          old_dat)|>
  mutate(across(c(fleet, sex, year,partition), as.integer),
         source = as.character(source))
# Calculate the counts and proportions by year, fleet, source, and sex
sex_props <- combined_dat %>%
  group_by(year, fleet, source, sex) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(year, fleet, source) %>%
  mutate(proportion = count / sum(count),
         sex = factor(sex)) %>%
  ungroup()


combined_dat <- bind_rows(
  new_dat %>% mutate(sex = as.integer(sex)), 
  old_dat %>% mutate(sex = as.integer(sex))
)

# Calculate the proportions
sex_props <- combined_dat %>%
  group_by(year, fleet) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(year, fleet, source) %>%
  mutate(proportion = count / sum(count)) %>%
  ungroup()




combined_dat <- bind_rows(new_dat, old_dat)

# Calculate the ratio of sex=0 to sex=3 for each year, fleet, source
# Calculate the proportions
# First, reshape the data for a stacked/filled bar chart
# First, reshape the data for a stacked/filled bar chart
# First, reshape the data for a stacked/filled bar chart
# Prepare the data with custom positioning
sex_ratio_long <- sex_ratio %>%
  mutate(total = unsexed + sexed) %>%
  pivot_longer(
    cols = c(unsexed, sexed),
    names_to = "sex_category",
    values_to = "count"
  ) %>%
  group_by(year, fleet, source) %>%
  mutate(proportion = count / sum(count)) %>%
  ungroup()

# Create a custom position variable
custom_data <- sex_ratio_long %>%
  mutate(
    # Create position offsets for the bars
    x_pos = as.numeric(factor(year)) + 
      ifelse(source == "2019_analysis", -0.2, 0.2)
  )

# Plot with custom positioning and improved design
ggplot(custom_data, aes(x = x_pos, y = proportion, 
                        fill = interaction(sex_category, source), 
                        group = interaction(year, source, sex_category))) +
  geom_bar(stat = "identity", position = "fill", width = 0.35) +
  facet_wrap(~ fleet, scales = "free_x", 
             labeller = labeller(fleet = function(x) paste("Fleet", x)),
             ncol = 1) + # Change to 1 column, multiple rows
  scale_fill_manual(
    values = c("unsexed.2019_analysis" = "#4A70B0",  # Muted blue (slightly lighter)
               "sexed.2019_analysis" = "#00008B",    # Dark blue
               "unsexed.2025_analysis" = "#8B0000",  # Muted red (slightly lighter)
               "sexed.2025_analysis" = "#D74A4A"),   # Dark red
    name = "Source",
    labels = c("sexed.2025_analysis" = "2025",  # Only the desired labels
               "sexed.2019_analysis" = "2019"),
    breaks = c("sexed.2019_analysis", "sexed.2025_analysis")  # Only include these in the legend
    
  )+
  scale_x_continuous(
    breaks = unique(custom_data$x_pos[custom_data$source == "2019_analysis"]), # Show label for one bar per year
    labels = unique(custom_data$year[custom_data$source == "2019_analysis"])   # Use corresponding years as labels
  ) +
  scale_y_continuous() +
  labs(
    title = "Prop. sexed by fleet",
    x = "Year",
    y = "Prop. sexed"
  ) +
  theme_minimal() +
  theme(
    panel.grid.major.x = element_blank(),
    legend.position = "right",
    strip.background = element_rect(fill = "gray90"),
    strip.text = element_text(face = "bold"),
    panel.spacing = unit(1, "lines"))
