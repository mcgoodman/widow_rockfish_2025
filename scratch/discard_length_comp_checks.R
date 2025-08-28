
library("r4ss")
library("dplyr")
library("ggplot2")

read.csv(here("data_derived/discards/discard_length_comps_April_no-midwater.csv")) %>% 
  mutate(fleet=factor(fleet, levels=c(1,5))) %>% 
  filter(fleet==1) %>% 
  ggplot(aes(x = year, y = Nsamp, fill = as.factor(sex))) +
  geom_bar(stat = "identity", position = "dodge") + 
  theme_pubclean() + 
  ylab("Length (cm)") + 
  xlab("Year") + 
  ggtitle("Counts of discard lengths in new derived data .csv") +
  scale_x_continuous(breaks = years_to_display[-1]) + 
  theme(legend.position = "right") + facet_wrap(~fleet, nrow=2, drop=T)

(SS_readdat(here("models/2025 base model/2025widow.dat")))$lencomp %>% 
  filter(part==1) %>%
  mutate(fleet=factor(fleet, levels=c(1,5))) %>% 
  ggplot(aes(x = year, y = Nsamp, fill = as.factor(sex))) +
  geom_bar(stat = "identity", position = "dodge") + 
  theme_pubclean() + 
  ylab("Length (cm)") + 
  xlab("Year") + 
  ggtitle("Counts of discard lengths in .dat file") +
  scale_x_continuous(breaks = years_to_display[-1]) + 
  theme(legend.position = "right") + facet_wrap(~fleet, nrow=2, drop=T)

read.csv(here("data_derived/discards/discard_length_comps_April_no-midwater.csv")) %>% 
  filter(fleet==1) %>% 
  pivot_longer(cols = f8:m56, names_to = "variable", values_to = "prop") %>%
  mutate(variable=as.numeric(gsub("m|f","",variable))) %>% 
  ggplot(aes(x = year, y = variable, size = prop, color=as.factor(sex))) +
  
  # Add vertical dotted lines at each unique x-axis year
  geom_vline(data = length.comps.agg.hl %>% distinct(year), 
             aes(xintercept = year), 
             linetype = "dotted", color = "gray50", alpha = 0.5) +
  
  # Plot points
  geom_point(shape = 16, position = position_dodge(0.75), alpha=0.65) + 
  theme_pubclean() + 
  ylim(c(10, 60)) + 
  ylab("Length (cm)") + 
  xlab("Year") + 
  ggtitle("Discard lengths composition in new derived data .csv") +
  scale_x_continuous(breaks = years_to_display[-1]) + 
  theme(legend.position = "right") + 
  facet_wrap(~fleet, nrow=2)

(SS_readdat(here("models/2025 base model/2025widow.dat")))$lencomp %>% 
  filter(part==1) %>% 
  pivot_longer(cols = f8:m56, names_to = "variable", values_to = "prop") %>%
  mutate(variable=as.numeric(gsub("m|f","",variable))) %>% 
  ggplot(aes(x = year, y = variable, size = prop, color=as.factor(sex))) +
  
  # Add vertical dotted lines at each unique x-axis year
  geom_vline(data = length.comps.agg.hl %>% distinct(year), 
             aes(xintercept = year), 
             linetype = "dotted", color = "gray50", alpha = 0.5) +
  
  # Plot points
  geom_point(shape = 16, position = position_dodge(0.75), alpha=0.65) + 
  theme_pubclean() + 
  ylim(c(10, 60)) + 
  ylab("Length (cm)") + 
  xlab("Year") + 
  ggtitle("Discard lengths composition in base model .dat file") +
  scale_x_continuous(breaks = years_to_display[-1]) + 
  theme(legend.position = "right") + 
  facet_wrap(~fleet, nrow=2)
