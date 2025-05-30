## Widow rockfish commercial discard length composition data was provided in non-confidential, expanded form by NOAA (Chantel Wetzel) from the West Coast Groundfish Observer Program (WCGOP). 
# Laura Spencer

### Install and load package


library(ggplot2)
library(reshape2)
library(here)
library(dplyr)
require(tidyverse)
library(ggpubr)
library(remotes)
library(r4ss)


### Prepare length composition data for .dat file 

# **Column order:** yr month fleet sex part Nsamp datavector(female-male)

# Year = from 1985 - 2023. Data prior to WCGOP will not change (use the same as 2019 update assessment). Data beginning 2004 
# 
# Fleet codes: 
#   - 1 = BottomTrawl <--- length data used in 2019 
# - 2 = MidwaterTrawl 
# - 3 = Hake <-- 
#   - 5 = HnL <--- length data used in 2010 
# Sex codes: 
#   - 0 = combined <-- most of WCGOP data 
# - 1 = use female only
# - 2 = use male only
# - 3 = use both as joint sexlength distribution, a couple years 
# Partition codes  
# - 0 = combined
# - 1 = discard
# - 2 = retained
# 
# 25 #_N_LengthBins; then enter lower edge of each length bin
#8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56

##  ================ OPTION 1: Update all WCGOP comps
# - Length comps from 1980's from the 2019 .dat file (Pickitch study)
# - Length comps 2004+ from new WCGOP data provided this year (2025)

#ssdat.2019 <- SS_readdat("../Downloads/2019widow.dat")
ssdat.2019 <- SS_readdat(here("data_provided/2019_assessment/", "2019widow.dat"))

# Which fleets are included in the most recent assessement? 
ssdat.2019$lencomp %>% filter(part==1) %>% 
  group_by(fleet) %>% tally()

# Discard length comps from 1980's Pickitch study. Do not change those. 
length.comps.1980s <- ssdat.2019$lencomp %>% filter(part==1) %>% filter(year<2004 & year>0) #remove negative years


### Read in sample and length comps data from WCGOP, 2025 version 
#Notice there are midwater fleet length comps now!  But we will not include them in this year's update assessment. Next full assessment will need to consider them. 

#length.n <- read.csv("../Downloads/biological_sample_sizes_length.csv")
length.n <- read.csv(here("data_provided/wcgop", "../wcgop/biological_sample_sizes_length.csv"))
length.n %>% 
  ggplot(aes(x=gear_groups,y=nsamp)) + 
  geom_boxplot(outlier.shape = NA) +
  geom_jitter(width = 0.2, size=2) + theme_minimal() + 
  ggtitle("Number of fish measured for length comp data by fleet, WCGOP (=>2004)\n2025 WCGOP data provided")


### Process length comps data 
# Here I read in the length comps file that Chantel emailed in April. There was confusion becase we received an erroneous file in February. This is the correct data file. 
# Note sex code = 0 (combined sexes) requires length comps to be replicated in the female and male bins (see stock synth. user manual pg. 28), while they are only in the female bins in the data from WCGOP. Here I read in the file from the WCGOP, replicate data in both male bins, set month to "7" (as was in the previous assessment .dat files), convert from percentages to proportions, and set fleet to 1=bottom trawl, 2=midwater rockfish, 3=midwater hake, and 4=hook and line. I then combine the 1980's data (pulled from the 2019 assessement) with the new WCGOP data.

length.comps.wcgop <- bind_cols(
  read.csv(here("data_provided/wcgop", "biological_discard_lengths.csv"), col.names = names(length.comps.1980s)) %>% #use same names as .dat from 2019 for easy row binding
#   read.csv("../Downloads/biological_discard_lengths.csv", col.names = names(length.comps.1980s)) %>% #use same names as .dat from 2019 for easy row binding    
     select(year:f56),
  read.csv(here("data_provided/wcgop", "biological_discard_lengths.csv"), col.names = names(length.comps.1980s)) %>% #use same names as .dat from 2019 for easy row binding
#   read.csv("../Downloads/biological_discard_lengths.csv", col.names = names(length.comps.1980s)) %>% #use same names as .dat from 2019 for easy row binding
  select(f8:f56) %>% rename_with(~ gsub("f", "m", .))) %>%
  mutate(month=7) %>% 
  mutate(across(matches("^[f|m]\\d+"), ~ . / 100)) %>% # get into proportions to match the 2019 .dat file (currently percentage)
  mutate(fleet=case_when(
    fleet=="bottomtrawl-coastwide"~1,
    fleet=="midwaterrockfish-coastwide"~2,
    fleet=="midwaterhake-coastwide"~3,
    fleet=="hook-and-line-coastwide"~5)) %>% 
  mutate(across(matches("^[f|m]\\d+"), ~ round(., 3))) #round 

length.comps <- bind_rows(length.comps.1980s, length.comps.wcgop) 

length.comps %>% 
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
  ggtitle("Discard lengths composition by fleet, Pickitch and WCGOP") +
  scale_x_continuous(breaks = years_to_display[-1]) + 
  theme(legend.position = "right") + 
  facet_wrap(~fleet, nrow=2)


#### Write length comps to files --> to be used in model bridging

#Including all four fleets 
write.csv(length.comps, file = here("data_derived/discards/discard_length_comps_April.csv"))

#Excluding midwater fleets (new this year) 
write.csv(length.comps %>% filter(fleet %in% c(1,5)), file = here("data_derived/discards/discard_length_comps_April_no-midwater.csv"))

## OPTION 2: Only extend comps(new data for years 2018+ only) 

###  ---- > NOTE: we ultimately used just bottom trawl discard lengths, and those historic data were identifcal to those received this year from WCGOP. Therefore, this option only impacts the Hook & Line fleet and is for sensitivity testing only. 

# - Length comps through 2017 are from the 2019 .dat file
# - Add only new length comps (2018+) from new WCGOP data provided this year (2025)

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
write.csv(length.comps.updateonly %>% mutate(across(matches("^[f|m]\\d+"), ~ round(., 3))) %>% 
            filter(fleet %in% c(1,5)), file = here("data_derived/discards/discard_length_comps_add-years-only_April_no-midwater.csv"))


##### ============ VISUALIZATION

## Plot lenght comps to compare .dat years (2015, 2019, current)

### --- Bottom Trawl 

years_to_display <- c(1985, 2004, 2007, 2010, 2013, 2016, 2019, 2022)

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

# Compare new comps previous assessment data 

# # 2015 data retrieved from 2015 assessment Word doc (.dat file, starting at pg 181)
# length.comps.agg.2015.bt <- read.csv(here("data_provided/2015_assessment", "2015_discard-length-data.csv"), col.names=names(length.comps.1980s)) %>% 
#   filter(part==1) %>% filter(year>0)  %>%
#   filter(fleet==1) %>% 
#   pivot_longer(cols = f8:m56, names_to = "variable", values_to = "prop") %>%
#   mutate(count=round(Nsamp*prop)) %>%
#   select(year, sex, variable, count) %>% 
#   mutate(variable=as.numeric(gsub("m|f","",variable))) %>% 
#   group_by(year,variable,sex) %>%
#   mutate(value = sum(count)) %>%
#   distinct(year, sex, variable, value) %>% 
#   left_join(length.comps %>% group_by(year) %>% summarize(n_total=sum(Nsamp))) %>% 
#   mutate(prop_total=value/n_total) %>% 
#   mutate(dat="2015 .dat")

#2019 from .dat file 
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

# Plot all assessment years' data same plot 
print(bind_rows(length.comps.agg.2019.bt, #length.comps.agg.2015.bt, 
                length.comps.agg.bt %>% mutate(dat="2025 WGCOP & Pikitch")) %>% 
        mutate(sex=as.factor(as.character(sex))) %>% 
        mutate(sex_desc=as.factor(case_when(
          sex==0~"combined",
          sex==1~"female",
          sex==2~"male",
          sex==3~"joint distribution"))) %>% 
        filter(prop_total>0) %>% #filter(dat!="2015 .dat") %>% 
        #    filter(year>1990) %>% 
        mutate(dat=case_when(dat=="2025 WGCOP & Pikitch"~"New 2025 Data",
                             dat=="2019 .dat"~"2019 Assessment",
                             dat=="2015 .dat"~"2015 Assessment")) %>% 
        droplevels() %>% 
        ggplot(aes(x = year, y = variable, color = dat, size = prop_total)) +
        
        # Add vertical dotted lines at each unique x-axis year
        geom_vline(data = length.comps.agg.bt %>% distinct(year), #%>% filter(year>1990), 
                   aes(xintercept = year), 
                   linetype = "dotted", color = "gray50", alpha = 0.5) +
        
        # Plot points
        geom_point(shape = 16, position = position_dodge(0.85), alpha=0.6) + 
        theme_pubclean() + 
        ylim(c(10, 60)) + 
        ylab("Length (cm)") + 
        xlab("Year") + 
        ggtitle("Bottom Trawl, assessment comparison") +
        scale_x_continuous(breaks = years_to_display[-1]) + 
        theme(legend.position = "right") + 
        #facet_wrap(~dat, nrow=2) + 
        guides(color = guide_legend(order=1, title = "Assessment .dat"), size = "none"))

# Plot just 2025 comps with sex data 
print(length.comps.agg.bt %>% mutate(sex=as.factor(as.character(sex))) %>% 
        mutate(sex_desc=as.factor(case_when(
          sex==0~"combined",
          sex==1~"female",
          sex==2~"male",
          sex==3~"joint distribution"))) %>% 
        filter(prop_total>0) %>% 
        ggplot(aes(x = year, y = variable, col = sex_desc, size = prop_total)) +
        
        # Add vertical dotted lines at each unique x-axis year
        geom_vline(data = length.comps.agg.bt %>% distinct(year), 
                   aes(xintercept = year), 
                   linetype = "dotted", color = "gray50", alpha = 0.5) +
        
        # Plot points
        geom_point(shape = 16, position = position_dodge(0.75)) + 
        theme_pubclean() + 
        ylim(c(10, 60)) + 
        ylab("Length (cm)") + 
        xlab("Year") + 
        ggtitle("Bottom Trawl, new data by sex") +
        scale_x_continuous(breaks = years_to_display) + 
        theme(legend.position = "right") + 
        guides(color = guide_legend(order=1, title = "sex"), size = "none"))

### --- Hook & Line

length.comps.agg.hl <- length.comps %>%
  filter(fleet==5) %>% 
  pivot_longer(cols = f8:m56, names_to = "variable", values_to = "prop") %>%
  filter(grepl("f", variable)) %>% 
  mutate(variable=as.numeric(gsub("m|f","",variable))) %>% 
  mutate(dat="2025 WGCOP & Pikitch")

# # 2015 data retrieved from 2015 assessment Word doc (.dat file, starting at pg 181)
# length.comps.agg.2015.hl <- read.csv(here("data_provided/2015_assessment", "2015_discard-length-data.csv"), col.names=names(length.comps.1980s)) %>% 
#   filter(part==1) %>% filter(year>0)  %>%
#   filter(fleet==5) %>% 
#   pivot_longer(cols = f8:m56, names_to = "variable", values_to = "prop") %>%
#   filter(grepl("f", variable)) %>% 
#   mutate(variable=as.numeric(gsub("m|f","",variable))) %>% 
#   mutate(dat="2015 .dat")

#2019 from .dat file 
length.comps.agg.2019.hl <- ssdat.2019$lencomp %>% 
  filter(part==1) %>% filter(year>0)  %>%
  filter(fleet==5) %>% 
  pivot_longer(cols = f8:m56, names_to = "variable", values_to = "prop") %>%
  filter(grepl("f", variable)) %>% 
  mutate(variable=as.numeric(gsub("m|f","",variable))) %>% 
  mutate(dat="2019 .dat")


# Plot all assessment years' data same plot 

# Figure for report! 

jpeg(here("figures/discard_comps/hook_line_discard_lengths_comparison.jpeg"), width = 2100, height = 1200, res = 300)
print(bind_rows(length.comps.agg.2019.hl,  #length.comps.agg.2015.hl, 
                length.comps.agg.hl) %>% 
        filter(prop>0) %>% #filter(dat!="2015 .dat") %>% 
        mutate(dat=case_when(dat=="2025 WGCOP & Pikitch"~"2025 WCGOP Data",
                             dat=="2019 .dat"~"2019 Assessment",
                             dat=="2015 .dat"~"2015 Assessment")) %>% 
        
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
        guides(color = guide_legend(order=1, title = "Data Source"), size = "none"))
dev.off()

# Plot just 2025 comps 
print(length.comps.agg.hl %>%
        mutate(sex_desc=as.factor(case_when(
          sex==0~"combined",
          sex==1~"female",
          sex==2~"male",
          sex==3~"joint distribution"))) %>% 
        filter(prop>0) %>% 
        ggplot(aes(x = year, y = variable, size = prop, col=sex_desc)) +
        
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
        ggtitle("Hook & Line discard lengths, new WCGOP data") +
        scale_x_continuous(breaks = years_to_display[-1]) + 
        theme(legend.position = "right"))


### --- Midwater - only have length comps in the new WCGOP data 

length.comps.agg.mid <- length.comps %>%
  filter(part==1) %>% filter(year>0)  %>%
  filter(fleet%in%c(2,3)) %>% 
  pivot_longer(cols = f8:m56, names_to = "variable", values_to = "prop") %>%
  filter(grepl("f", variable)) %>% 
  mutate(variable=as.numeric(gsub("m|f","",variable))) %>% 
  mutate(dat="2025 WGCOP")

# # 2015 data retrieved from 2015 assessment Word doc (.dat file, starting at pg 181)
# length.comps.agg.2015.mid <- read.csv(here("data_provided/2015_assessment", "2015_discard-length-data.csv"), col.names=names(length.comps.1980s)) %>% 
#   filter(part%in%c(2,3)) %>% filter(year>0)  %>%
#   filter(fleet%in%c(2,3)) %>% 
#   pivot_longer(cols = f8:m56, names_to = "variable", values_to = "prop") %>%
#   filter(grepl("f", variable)) %>% 
#   mutate(variable=as.numeric(gsub("m|f","",variable))) %>% 
#   mutate(dat="2015 .dat")

#2019 from .dat file 
length.comps.agg.2019.mid <- ssdat.2019$lencomp %>% 
  filter(part==1) %>% filter(year>0)  %>%
  filter(fleet%in%c(2,3)) %>% 
  pivot_longer(cols = f8:m56, names_to = "variable", values_to = "prop") %>%
  filter(grepl("f", variable)) %>% 
  mutate(variable=as.numeric(gsub("m|f","",variable))) %>% 
  mutate(dat="2019 .dat")

# Plot all assessment years' data same plot 
print(
  bind_rows(length.comps.agg.2019.mid, #length.comps.agg.2015.mid, 
            length.comps.agg.mid) %>% 
    filter(prop>0) %>% #filter(dat!="2015 .dat") %>% 
    mutate(dat=case_when(dat=="2025 WGCOP"~"New 2025 Data",
                         dat=="2019 .dat"~"2019 Assessment",
                         dat=="2015 .dat"~"2015 Assessment")) %>% 
    mutate(dat=factor(dat, levels=c("2015 Assessment", "2019 Assessment", "New 2025 Data"))) %>% 
    
    ggplot(aes(x = year, y = variable, color = as.factor(sex), size = prop)) +
    
    # Add vertical dotted lines at each unique x-axis year
    geom_vline(data = length.comps.agg.mid %>% distinct(year), 
               aes(xintercept = year), 
               linetype = "dotted", color = "gray50", alpha = 0.5) +
    
    # Plot points
    geom_point(shape = 16, position = position_dodge(0.85), alpha=0.65) + 
    theme_pubclean() + 
    ylim(c(10, 60)) + 
    ylab("Length (cm)") + 
    xlab("Year") + 
    ggtitle("Midwater fleets, assessment comparison") +
    scale_x_continuous(breaks = years_to_display) + 
    theme(legend.position = "right") + 
    facet_wrap(~dat, nrow=2, drop=F) + 
    guides(color = guide_legend(order=1, title = "Sex"), size = "none"))

# Plot just 2025 comps 
print(length.comps.agg.mid %>%
        filter(prop>0) %>% 
        ggplot(aes(x = year, y = variable, size = prop)) +
        
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
        ggtitle("Midwater fleets discard lengths, new WCGOP data") +
        scale_x_continuous(breaks = years_to_display[-1]) + 
        theme(legend.position = "right") + facet_wrap(~fleet))


## ------ Double check lengths in .dat look good after data bridging, bottom trawl only 

read.csv(here("data_derived/discards/discard_length_comps_April_no-midwater.csv"))[-1] %>% 
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

read.csv(here("data_derived/discards/discard_length_comps_April_no-midwater.csv"))[-1] %>% 
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


# ======= Figures for report mimicking 2019 plots 
lcomps.2025 <-(SS_readdat(here("models/2025 base model/2025widow.dat")))$lencomp

# Plot Bottom Trawl from WCGOP

jpeg(here("figures/discard_comps/bottom_trawl_pikitch.jpg"), width = 2550, height = 3300, res = 300)

  fltsrv <- ""
  dat_sub <- lcomps.2025[which(lcomps.2025$fleet == 1),]
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

jpeg(here("figures/discard_comps/bottom_trawl_wcgop.jpg"), width = 2550, height = 1650, res = 300)

# Plot Bottom Trawl from WCGOP 
  par(mfrow=c(1,1))
  fltsrv <- "Bottom Trawl Discard, WCGOP"
  dat_sub <- lcomps.2025[which(lcomps.2025$fleet == 1),]
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


##Plot Midwater Trawl WCGOP 
jpeg(here("figures/discard_comps/midwater_trawl_wcgop.jpg"), width = 2550, height = 1650, res = 300)

# Plot Bottom Trawl from WCGOP 
par(mfrow=c(1,1))
fltsrv <- "Midwater Trawl Discard, WCGOP"
dat_sub <- lcomps.2025[which(lcomps.2025$fleet == 2),]
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
