
# Process discard length composition data
# Authors: Laura Spencer, Maurice Goodman

## Widow rockfish commercial discard length composition data was provided 
## in non-confidential, expanded form by NOAA (Chantel Wetzel) from WCGOP

library("here")
library("tidyverse")
library("ggpubr")
library("r4ss")

# Read in data --------------------------------------------

ssdat.2019 <- SS_readdat(here("data_provided", "2019_assessment", "2019widow.dat"))

# Discard length comps from 1980's Pickitch study. Do not change those. 
length.comps.1980s <- ssdat.2019$lencomp %>% filter(part==1) %>% filter(year<2004 & year>0) #remove negative years

## Read in sample and length comps data from WCGOP, 2025 version 
## Notice there are midwater fleet length comps now!  But we will not include them 
## in this year's update assessment. Next full assessment will need to consider them. 

length.n <- read.csv(here("data_provided", "wcgop", "biological_sample_sizes_length.csv"))
length.n %>% 
  ggplot(aes(x=gear_groups,y=nsamp)) + 
  geom_boxplot(outlier.shape = NA) +
  geom_jitter(width = 0.2, size=2) + theme_minimal() + 
  ggtitle("Number of fish measured for length comp data by fleet, WCGOP (=>2004)\n2025 WCGOP data provided")


## Process length comps data 
## Here I read in the length comps file that Chantel emailed in April. There was confusion 
## because we received an erroneous file in February. This is the correct data file. 
## Note sex code = 0 (combined sexes) requires length comps to be replicated in the 
## female and male bins (see stock synth. user manual pg. 28), while they are only in 
## the female bins in the data from WCGOP. Here I read in the file from the WCGOP, replicate
## data in both male bins, set month to "7" (as was in the previous assessment .dat files), 
## convert from percentages to proportions, and set fleet to 1=bottom trawl, 2=midwater rockfish, 
## 3=midwater hake, and 4=hook and line. I then combine the 1980's data (pulled from the 2019 
## assessement) with the new WCGOP data.

length.comps.wcgop <- read.csv(
  here("data_provided/wcgop", "biological_discard_lengths.csv"), 
  col.names = names(length.comps.1980s)
  ) %>% 
  select(year:f56) |>  bind_cols(
    read.csv(
      here("data_provided/wcgop", "biological_discard_lengths.csv"),
      col.names = names(length.comps.1980s)
    ) %>% 
      select(f8:f56) %>% rename_with(~ gsub("f", "m", .))
  ) %>%
  mutate(month=7) %>% 
  mutate(across(matches("^[f|m]\\d+"), ~ . / 100)) %>% # get into proportions to match the 2019 .dat file (currently percentage)
  mutate(fleet=case_when(
    fleet=="bottomtrawl-coastwide"~1,
    fleet=="midwaterrockfish-coastwide"~2,
    fleet=="midwaterhake-coastwide"~3,
    fleet=="hook-and-line-coastwide"~5)) %>% 
  mutate(across(matches("^[f|m]\\d+"), ~ round(., 3)))

length.comps <- bind_rows(length.comps.1980s, length.comps.wcgop) 

# Aggregate data by fleets --------------------------------

## Bottom trawl -------------------------------------------

length.comps.agg.bt <- length.comps %>%
  filter(fleet==1) %>% 
  pivot_longer(cols = f8:m56, names_to = "variable", values_to = "prop") %>%
  mutate(count=round(Nsamp*prop)) %>%
  select(year, sex, variable, count) %>% 
  mutate(variable=as.numeric(gsub("m|f","",variable))) %>% 
  group_by(year,variable,sex) %>%
  mutate(value = sum(count)) %>%
  distinct(year, sex, variable, value) %>% 
  left_join(length.comps %>% group_by(year) %>% summarize(n_total=sum(Nsamp))) %>% 
  mutate(prop_total=value/n_total)

length.comps.agg.2019.bt <- ssdat.2019$lencomp %>% 
  filter(part==1) %>% filter(year>0)  %>%
  filter(fleet==1) %>% 
  pivot_longer(cols = f8:m56, names_to = "variable", values_to = "prop") %>%
  mutate(count=round(Nsamp*prop)) %>%
  select(year, sex, variable, count) %>% 
  mutate(variable=as.numeric(gsub("m|f","",variable))) %>% 
  group_by(year,variable,sex) %>%
  mutate(value = sum(count)) %>%
  distinct(year, sex, variable, value) %>% 
  left_join(length.comps %>% group_by(year) %>% summarize(n_total=sum(Nsamp))) %>% 
  mutate(prop_total=value/n_total) %>% 
  mutate(dat="2019 .dat")

## Midwater trawl -----------------------------------------

length.comps.agg.mid <- length.comps %>%
  filter(part==1) %>% filter(year>0)  %>%
  filter(fleet%in%c(2,3)) %>% 
  pivot_longer(cols = f8:m56, names_to = "variable", values_to = "prop") %>%
  filter(grepl("f", variable)) %>% 
  mutate(variable=as.numeric(gsub("m|f","",variable))) %>% 
  mutate(dat="2025 WGCOP")

length.comps.agg.2019.mid <- ssdat.2019$lencomp %>% 
  filter(part==1) %>% filter(year>0)  %>%
  filter(fleet%in%c(2,3)) %>% 
  pivot_longer(cols = f8:m56, names_to = "variable", values_to = "prop") %>%
  filter(grepl("f", variable)) %>% 
  mutate(variable=as.numeric(gsub("m|f","",variable))) %>% 
  mutate(dat="2019 .dat")

## Hook & Line --------------------------------------------

length.comps.agg.hl <- length.comps %>%
  filter(fleet==5) %>% 
  pivot_longer(cols = f8:m56, names_to = "variable", values_to = "prop") %>%
  filter(grepl("f", variable)) %>% 
  mutate(variable=as.numeric(gsub("m|f","",variable))) %>% 
  mutate(dat="2025 WGCOP & Pikitch")

length.comps.agg.2019.hl <- ssdat.2019$lencomp %>% 
  filter(part==1) %>% filter(year>0)  %>%
  filter(fleet==5) %>% 
  pivot_longer(cols = f8:m56, names_to = "variable", values_to = "prop") %>%
  filter(grepl("f", variable)) %>% 
  mutate(variable=as.numeric(gsub("m|f","",variable))) %>% 
  mutate(dat="2019 .dat")

# Write data files ----------------------------------------

#Including all four fleets 
write.csv(length.comps, here("data_derived", "discards", "discard_length_comps_April.csv"), row.names = FALSE)

#Excluding midwater fleets (new this year)
length.comps |> 
  filter(fleet %in% c(1,5)) |> 
  write.csv(here("data_derived", "discards", "discard_length_comps_April_no-midwater.csv"), row.names = FALSE)

## OPTION 2: Only extend comps(new data for years 2018+ only) 
## NOTE: We ultimately used just bottom trawl discard lengths, 
## and those historic data were identical to those received this year 
## from WCGOP. Therefore, this option only impacts the Hook & Line fleet and 
## is for sensitivity testing only. 
## - Length comps through 2017 are from the 2019 .dat file
## - Add only new length comps (2018+) from new WCGOP data provided this year (2025)

length.comps.2019assess.opt2 <- ssdat.2019$lencomp %>% filter(part==1) %>% filter(year>0)

length.comps.new.opt2 <- bind_cols(
  read.csv(here("data_provided/wcgop", "biological_discard_lengths.csv"), col.names = names(length.comps.1980s)) %>% #use same names as .dat from 2019 for easy row binding
    filter(year>2017) %>% select(year:f56),
  read.csv(here("data_provided/wcgop", "biological_discard_lengths.csv"), col.names = names(length.comps.1980s)) %>% #use same names as .dat from 2019 for easy row binding
    filter(year>2017) %>% select(f8:f56) %>% rename_with(~ gsub("f", "m", .))) %>% 
  mutate(month=7) %>% 
  mutate(across(matches("^[f|m]\\d+"), ~ . / 100)) %>% # get into proportions to match the 2019 .dat file (currently percentage)
  mutate(fleet=case_when(
    fleet=="bottomtrawl-coastwide"~1,
    fleet=="midwaterrockfish-coastwide"~2,
    fleet=="midwaterhake-coastwide"~3,
    fleet=="hook-and-line-coastwide"~5)) %>% 
  mutate(across(matches("^[f|m]\\d+"), ~ round(., 3))) #round 

length.comps.updateonly <- bind_rows(length.comps.2019assess.opt2, length.comps.new.opt2)

# An alternative discard length comps file, should we want to only add the new years from the new WCGOP data file
length.comps.updateonly |> 
  mutate(across(matches("^[f|m]\\d+"), ~ round(., 3))) |>  
  filter(fleet %in% c(1,5)) |> 
  write.csv(here("data_derived", "discards", "discard_length_comps_add-years-only_April_no-midwater.csv"), row.names = FALSE)

# Plots ---------------------------------------------------

## Hook-and-line 2019 vs. 2025 ----------------------------

years_to_display <- c(1985, 2004, 2007, 2010, 2013, 2016, 2019, 2022)

length_plot_hl <- 
  length.comps.agg.2019.hl |> 
  bind_rows(length.comps.agg.hl) |> 
  filter(prop>0) |>
  mutate(dat = case_when(dat == "2025 WGCOP & Pikitch" ~ "2025 WCGOP Data",
                         dat == "2019 .dat" ~ "2019 Assessment",
                         dat == "2015 .dat" ~ "2015 Assessment")) |> 
  
  ggplot(aes(x = year, y = variable, color = dat, size = prop)) +
  
  # Add vertical dotted lines at each unique x-axis year
  geom_vline(data = length.comps.agg.hl %>% distinct(year), 
             aes(xintercept = year), 
             linetype = "dotted", color = "gray50", alpha = 0.5) +
  
  # Plot points
  geom_point(shape = 16, position = position_dodge(0.85), alpha=0.65) + 
  theme_pubclean() + 
  ylim(c(10, 60)) + 
  labs(title ="Hook & Line discard length comps", subtitle = "Data comparison", y="Length (cm)", x="Year") +
  scale_x_continuous(breaks = years_to_display) + 
  theme(legend.position = "right") + 
  scale_color_manual(values=c("skyblue4","salmon3")) + 
  guides(color = guide_legend(order=1, title = "Data Source"), size = "none")

ggsave(
  here("figures", "discard_comps", "hook_line_discard_lengths_comparison.jpeg"), 
  plot = length_plot_hl, width = 2100, height = 1200, dpi = 300, units = "px"
)

## Bottom trawl (WCGOP) -----------------------------------

jpeg(here("figures", "discard_comps", "bottom_trawl_wcgop.jpg"), width = 2550, height = 1650, res = 300)

# Plot Bottom Trawl from WCGOP 
par(mfrow=c(1,1))
fltsrv <- "Bottom Trawl Discard, WCGOP"
dat_sub <- length.comps[which(length.comps$fleet == 1),]
dat_sub <- dat_sub[which(dat_sub$year > 1990),]
dat_sub <- dat_sub[which(dat_sub$part %in% c(1)),]
ylab="Length (cm)"; xlab="Year"

nbins <- 25
x <- as.numeric(as.character(dat_sub$year))
dat <- dat_sub[,7:31]
inch <- 0.1
y <- as.numeric(substring(names(dat),2))
y <- y[1:nbins]
xlim <- range(x)

plot(NA, NA,xlab=xlab,ylab=ylab,xlim=xlim, ylim = range(y), main = fltsrv)
for(j in 1:nrow(dat_sub)){
  if(dat_sub$year[j] > 1990){
    symbols(rep(dat_sub$year[j], nbins),y,circles=dat[j,grep("f", colnames(dat))],inches=inch, add = TRUE)
  }
}
dev.off() 

## Pikitch data -------------------------------------------

jpeg(here("figures", "discard_comps", "bottom_trawl_pikitch.jpg"), width = 2550, height = 3300, res = 300)

  fltsrv <- ""
  dat_sub <- length.comps[which(length.comps$fleet == 1),]
  dat_sub <- dat_sub[which(dat_sub$year > 0),]
  dat_sub <- dat_sub[which(dat_sub$part %in% c(1)),]
  ylab="Length (cm)"; xlab="Year"
  if(nrow(dat_sub) > 0){
    
    nbins <- 25
    x <- as.numeric(as.character(dat_sub$year))
    dat <- dat_sub[,7:ncol(dat_sub)]
    inch <- 0.1
    y <- as.numeric(substring(names(dat),2))
    y <- y[1:nbins]
    xlim <- range(x)
    
    par(mfrow=c(2,1))
    
    name <- "Female"
    plot(NA, NA,xlab=xlab,ylab=ylab,xlim=xlim, ylim = range(y), main = paste(name, "discard", fltsrv))
    for(j in 1:nrow(dat_sub)){
      if(dat_sub$year[j] > 0){
        if(dat_sub$sex[j] %in% c(1, 3)){
          symbols(rep(dat_sub$year[j], nbins),y,circles=dat[j,grep("f", colnames(dat))],inches=inch, add = TRUE)
        }
      }
    }
    
    name <- "Male"
    plot(NA, NA,xlab=xlab,ylab=ylab,xlim=xlim, ylim = range(y), main = paste(name, "Discard", fltsrv))
    for(j in 1:nrow(dat_sub)){
      if(dat_sub$year[j] > 0){
        if(dat_sub$sex[j] == 2){
          symbols(rep(dat_sub$year[j], nbins),y,circles=dat[j,grep("m", colnames(dat))],inches=inch, add = TRUE)
        }
      }
    }
  }
  
dev.off()