
dat_2019 <- SS_readdat(here(base_model_dir, "2019widow.dat"))

new_dat_2005_2019 <- widow_Comm_lcomps_2005_2025|>
  filter(year >= 2005 & year <= 2018)



#### Comapre comps
combi_input <- dat_2019$lencomp |>
  filter(FltSvy %in%c(1,2,3,5),
         Yr >= 2005)|>
  setNames(colnames(new_dat_2005_2019))|>
  mutate(source = "2019")|>
  
  rbind(new_dat_2005_2019|>
          mutate(source = "new_exp"))

library(tidyr)


# Pivot f columns
df_f <- combi_input %>%
  select(- matches("^m\\d+$")) |>
  pivot_longer(
    cols = matches("^f\\d+$"),   # Select only columns like "f26", "f28", etc.
    names_to = "len",            # Extract length information
    names_prefix = "f",          # Remove "f" prefix
    values_to = "value"          # Store values in "value"
  ) %>%
  mutate(sex = "f", len = as.numeric(len)) 

# Pivot m columns
df_m <- combi_input %>%
  select(- matches("^f\\d+$")) |>
  pivot_longer(
    cols = matches("^m\\d+$"),   # Select only columns like "m26", "m28", etc.
    names_to = "len",            # Extract length information
    names_prefix = "m",          # Remove "m" prefix
    values_to = "value"          # Store values in "value"
  ) %>%
  mutate(sex = "m", len = as.numeric(len)) 
# Combine both datasets
combi_long <- bind_rows(df_f, df_m)
combi_long_prop_len <- combi_long |>
  group_by(source,year,fleet,sex,partition)|>
  mutate(prop = value/sum(value))



library(ggplot2)

### age comp comparrison for Bottom Trawl fleet
new_exp_lencomp_props_BT <- ggplot()+
  geom_point(combi_long_prop_len |> filter(source == "2019", year <= 2019, sex == "f", fleet == 1), mapping = aes(x = year, y = len, size = prop, col = source))+
  geom_point(combi_long_prop_len |> filter(source == "new_exp",  year <= 2019, sex == "f", fleet == 1), mapping = aes(x = year+0.2, y = len, size = prop, col = source))+
  theme_minimal()+
  facet_wrap(~fleet, scales = "free")+
  ggtitle("Bottom Trawl",subtitle = "Age comp 2005 - 2019")
ggsave("plots_dir/new_exp_agecomp_props_BT.png",new_exp_agecomp_props_BT)

## len comp compparison for Midwater trawl fleet 
new_exp_lencomp_props_MWT<- ggplot()+
  geom_point(combi_long_prop_len |> filter(source == "2019", year <= 2019, fleet == 2), mapping = aes(x = year, y = len, size = prop, col = source))+
  geom_point(combi_long_prop_len |> filter(source == "new_exp",  year <= 2019, fleet == 2), mapping = aes(x = year+0.2, y = len, size = prop, col = source))+
  theme_minimal()+
  facet_wrap(~sex, scales = "free")+
  ggtitle("Midwater Trawl",subtitle = "len comp 2005 - 2019")
ggsave("plots_dir/new_exp_lencomp_props_MT.png",new_exp_lencomp_props_MWT)

#Hake
## len comp compparison for Hake
new_exp_lencomp_props_HKE<- ggplot()+
  geom_point(combi_long_prop_len |> filter(source == "2019", year <= 2019, sex == "f", fleet == 3), mapping = aes(x = year, y = len, size = prop, col = source))+
  geom_point(combi_long_prop_len |> filter(source == "new_exp",  year <= 2019, sex == "f", fleet == 3), mapping = aes(x = year+0.2, y = len, size = prop, col = source))+
  theme_minimal()+
  facet_wrap(~fleet, scales = "free")+
  ggtitle("Hake (SS+ASHOP)",subtitle = "len comp 2005 - 2019")

## len comp compparison for Hook and Line fleet 
new_exp_lencomp_props_HNL<- ggplot()+
  geom_point(combi_long_prop_len |> filter(source == "2019", year <= 2019, sex == "f", fleet == 5), mapping = aes(x = year, y = len, size = prop, col = source))+
  geom_point(combi_long_prop_len |> filter(source == "new_exp",  year <= 2019, sex == "f", fleet == 5), mapping = aes(x = year+0.2, y = len, size = prop, col = source))+
  theme_minimal()+
  facet_wrap(~fleet, scales = "free")+
  ggtitle("Hook and Line",subtitle = "len comp 2005 - 2019")
ggsave("plots_dir/new_exp_lencomp_props_HNL.png",new_exp_lencomp_props_HNL)



##### Age comps
#### Comapre comps
new_dat_2005_2019_age <- widow_Comm_acomps_2005_2025|>
  filter(year >= 2005 & year <= 2018)

combi_input_age <- dat_2019$agecomp |>
  filter(FltSvy %in%c(1,2,3,5),
         Yr >= 2005)|>
  setNames(colnames(new_dat_2005_2019_age))|>
  mutate(source = "2019")|>
  
  rbind(new_dat_2005_2019_age|>
          mutate(source = "new_exp"))

library(tidyr)


# Pivot f columns
df_f_a <- combi_input_age %>%
  select(- matches("^m\\d+$")) |>
  pivot_longer(
    cols = matches("^f\\d+$"),   # Select only columns like "f26", "f28", etc.
    names_to = "age",            # Extract agegth information
    names_prefix = "f",          # Remove "f" prefix
    values_to = "value"          # Store values in "value"
  ) %>%
  mutate(sex = "f", age = as.numeric(age)) 

# Pivot m columns
df_m_a <- combi_input_age %>%
  select(- matches("^f\\d+$")) |>
  pivot_longer(
    cols = matches("^m\\d+$"),   # Select only columns like "m26", "m28", etc.
    names_to = "age",            # Extract agegth information
    names_prefix = "m",          # Remove "m" prefix
    values_to = "value"          # Store values in "value"
  ) %>%
  mutate(sex = "m", age = as.numeric(age)) 
# Combine both datasets
combi_long_a <- bind_rows(df_f_a, df_m_a)
combi_long_prop_age <- combi_long_a |>
  group_by(source,year,fleet,sex,partition)|>
  mutate(prop = value/sum(value))



library(ggplot2)

### age comp comparrison for Bottom Trawl fleet
new_exp_agecomp_props_BT <- ggplot()+
  geom_point(combi_long_prop_age |> filter(source == "2019", year <= 2019, sex == "f", fleet == 1), mapping = aes(x = year, y = age, size = prop, col = source))+
  geom_point(combi_long_prop_age |> filter(source == "new_exp",  year <= 2019, sex == "f", fleet == 1), mapping = aes(x = year+0.2, y = age, size = prop, col = source))+
  theme_minimal()+
  facet_wrap(~fleet, scales = "free")+
  ggtitle("Bottom Trawl",subtitle = "Age comp 2005 - 2019")
ggsave("plots_dir/new_exp_agecomp_props_BT.png",new_exp_agecomp_props_BT)

## age comp compparison for Midwater trawl fleet 
new_exp_agecomp_props_MWT<- ggplot()+
  geom_point(combi_long_prop_age |> filter(source == "2019", year <= 2019, sex == "f", fleet == 2), mapping = aes(x = year, y = age, size = prop, col = source))+
  geom_point(combi_long_prop_age |> filter(source == "new_exp",  year <= 2019, sex == "f", fleet == 2), mapping = aes(x = year+0.2, y = age, size = prop, col = source))+
  theme_minimal()+
  facet_wrap(~fleet, scales = "free")+
  ggtitle("Midwater Trawl",subtitle = "age comp 2005 - 2019")
ggsave("plots_dir/new_exp_agecomp_props_MT.png",new_exp_agecomp_props_MWT)

#Hake
## age comp compparison for Hake
new_exp_agecomp_props_HKE<- ggplot()+
  geom_point(combi_long_prop_age |> filter(source == "2019", year <= 2019, sex == "f", fleet == 3), mapping = aes(x = year, y = age, size = prop, col = source))+
  geom_point(combi_long_prop_age |> filter(source == "new_exp",  year <= 2019, sex == "f", fleet == 3), mapping = aes(x = year+0.2, y = age, size = prop, col = source))+
  theme_minimal()+
  facet_wrap(~fleet, scales = "free")+
  ggtitle("Hake (SS+ASHOP)",subtitle = "age comp 2005 - 2019")

## age comp compparison for Hook and Line fleet 
new_exp_agecomp_props_HNL<- ggplot()+
  geom_point(combi_long_prop_age |> filter(source == "2019", year <= 2019, sex == "f", fleet == 5), mapping = aes(x = year, y = age, size = prop, col = source))+
  geom_point(combi_long_prop_age |> filter(source == "new_exp",  year <= 2019, sex == "f", fleet == 5), mapping = aes(x = year+0.2, y = age, size = prop, col = source))+
  theme_minimal()+
  facet_wrap(~fleet, scales = "free")+
  ggtitle("Hook and Line",subtitle = "age comp 2005 - 2019")
ggsave("plots_dir/new_exp_agecomp_props_HNL.png",new_exp_agecomp_props_HNL)

ggplot()+
  geom_point(combi_long_prop_age |> filter(source == "2019", year <= 2019, sex == "m", fleet == 5), mapping = aes(x = year, y = age, size = prop, col = source))+
  geom_point(combi_long_prop_age |> filter(source == "new_exp",  year <= 2019, sex == "m", fleet == 5), mapping = aes(x = year+0.2, y = age, size = prop, col = source))+
  theme_minimal()+
  facet_wrap(~fleet, scales = "free")+
  ggtitle("Hook and Line",subtitle = "age comp 2005 - 2019")



## All the plots
windows()
gridExtra::grid.arrange(new_exp_lencomp_props_BT,new_exp_lencomp_props_MWT,new_exp_lencomp_props_HKE,new_exp_lencomp_props_HNL,ncol = 4)
gridExtra::grid.arrange(new_exp_agecomp_props_BT,new_exp_agecomp_props_MWT,new_exp_agecomp_props_HKE,new_exp_agecomp_props_HNL,ncol = 4)


















compare_ss3_comps <- function(old_dat,new_dat,comp_type,compare_years = NULL,fleet_labels = c("Bottom Trawl","Midwater Trawl","Hake","Hook and Line")){
  
}




















