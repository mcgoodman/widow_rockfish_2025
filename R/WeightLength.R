library(nwfscSurvey)
library(dplyr)
library(tidyverse)
library(readxl)

# Species common name based on NWFSC survey data
common_name <- "widow rockfish"

# PacFIN species code
#species_code <- "WDOW"

# Files
#add PacFIN file here
ASHOP<-read_excel("data_provided/ASHOP/A_SHOP_Widow_Ages_2003-2024_removedConfidentialFields_012725.xlsx")
Old_assessments<-read_excel("data_provided/2019_assessment/WL_oldassessments.xlsx")
file_bds <- fs::path("data_provided/PacFIN/PacFIN.WDOW.bds.12.Dec.2024.RData")


### Age - length relationship ###
# Pull survey data fir shelf/slope combo
common_name <- "widow rockfish"
NWFSC_survey <- nwfscSurvey::pull_bio(
  common_name = common_name,
  survey = "NWFSC.Combo"
)

# Pull triennial data
scientific_name<-"Sebastes entomelas"
tri <- nwfscSurvey::pull_bio(
  sci_name = scientific_name,
  survey = "Triennial"
)

tri_survey<-tri$Ages #triennial data with weights

# combining data sources for the relationship of "All" datasets

tri_all<-tri_survey%>%
  rename(WEIGHT=Weight, LENGTH=Length_cm, SEX=Sex, YEAR=Year, PROJECT=Project)%>%
  select(WEIGHT, LENGTH, SEX, YEAR, PROJECT, Common_name)%>%
  mutate(Source="Triennial")

NWFSC_all<-NWFSC_survey%>%
  rename(WEIGHT=Weight, LENGTH=Length_cm, SEX=Sex, YEAR=Year, PROJECT=Project)%>%
  select(WEIGHT, LENGTH, SEX, YEAR, PROJECT, Common_name)%>%
  mutate(Source="NWFSC")

ASHOP_all<-ASHOP%>%
  select(WEIGHT, LENGTH, SEX, YEAR, SPECIES)%>%
  mutate(Source="ASHOP", PROJECT="ASHOP",Common_name="Widow rockfish")

# bds.pacfin
load(file_bds) #load bds data from the file path above
colnames(bds.pacfin)

bds<- bds.pacfin%>%
  select(FISH_LENGTH, FISH_WEIGHT, SEX_CODE,SAMPLE_YEAR,FISH_LENGTH_UNITS)%>%
  rename(LENGTH=FISH_LENGTH, SEX=SEX_CODE,YEAR=SAMPLE_YEAR)%>%
  mutate(Source="BDS", PROJECT="BDS", Common_name="Widow rockfish")%>%
  mutate(WEIGHT=FISH_WEIGHT/1000, LENGTH=ifelse(FISH_LENGTH_UNITS=="CM",LENGTH,LENGTH/10))%>% #convert to kg
  filter(SEX=="F"|SEX=="M")%>%
  select(-FISH_WEIGHT,-FISH_LENGTH_UNITS)
  

ALL <- NWFSC_all%>%
  bind_rows(ASHOP_all)%>%
  bind_rows(tri_all)%>%
  bind_rows(bds)

# plotting the observations by data source (see Figure 40 from 2015)

ggplot(data=ALL, aes(x=LENGTH, y=WEIGHT, col=Source))+
  #ggtitle("2025 Data")+
 # theme(plot.title = element_text(hjust = 0.5))+
  geom_point()+
  ylab("Weight (kg)")+
  xlab("Length (cm)")+
  ylim(c(0,3.25))+
  xlim(c(0,70))+
  theme_classic()

# Estimate weight-length relationship by sex for each survey type and using "All"

weight_length_estimates_NWFSC <- nwfscSurvey::estimate_weight_length(
 NWFSC_survey,
  verbose = FALSE
)%>%
  mutate(Source="NWFSC")

weight_length_estimates_tri <- nwfscSurvey::estimate_weight_length(
  tri_survey,
  verbose = FALSE
)%>%
  mutate(Source="Triennial")

colnames(ASHOP)
weight_length_ASHOP<- nwfscSurvey::estimate_weight_length(
  ASHOP,
  col_length = "LENGTH",
  col_weight = "WEIGHT",
  verbose = FALSE
)%>%
  mutate(Source="ASHOP")

weight_length_BDS<- nwfscSurvey::estimate_weight_length(
  bds,
  col_length = "LENGTH",
  col_weight = "WEIGHT",
  verbose = FALSE
)%>%
  mutate(Source="BDS")

weight_length_ALL<- nwfscSurvey::estimate_weight_length(
  ALL,
  col_length = "LENGTH",
  col_weight = "WEIGHT",
  verbose = FALSE
)%>%
  mutate(Source="All")



knitr::kable(weight_length_estimates_NWFSC, "markdown")
knitr::kable(weight_length_estimates_tri, "markdown")
knitr::kable(weight_length_ASHOP, "markdown")
knitr::kable(weight_length_BDS, "markdown")
knitr::kable(weight_length_ALL, "markdown")


# combining the estimates using each survey to plot the relationship
# this is replicating Figure 41 from 2015
# Add PacFin as another set of rows and it will add it to the plots

estimated_combined<-weight_length_estimates_NWFSC%>%
  bind_rows(weight_length_estimates_tri)%>%
  bind_rows(weight_length_ASHOP)%>%
  bind_rows(weight_length_BDS)%>%
  bind_rows(weight_length_ALL)
  
# function to plot line

wl_function <- function(Lengths,A,B) {A*Lengths^B} #equation for relationship
Lengths<-seq(0,70,0.1) #lengths to use 

pred<-data.frame()
for(i in 1:nrow(estimated_combined)){
  temp_wl<-wl_function(Lengths,estimated_combined[i,4],estimated_combined[i,5])
  temp_df<-cbind(weight=as.numeric(temp_wl), length=as.numeric(Lengths), group=estimated_combined[i,1],source=estimated_combined[i,6])
  pred<-rbind(temp_df,pred)
}



# making the plot for 2025 data
ggplot(data=pred%>%filter(group!='all'),aes(x=as.numeric(length), y=as.numeric(weight),color=source))+
  facet_wrap(~group)+
  geom_line()+
  ylab("Weight (kg)")+
  xlab("Length (cm)")+
  ylim(c(0,5.25))+
  xlim(c(0,75))+
  theme_classic()

# dataset to compare 2025 to previous assessments 
# (2011 and 2015; 2019 used same weight-at-length relationship as 2015 and did not update it)
comparison<-estimated_combined%>%
  filter(Source=="All"&group!="all")%>%
  select(group, A, B)%>%
  mutate(Assessment=2025)%>%
  bind_rows(Old_assessments)

knitr::kable(comparison, "markdown")

comp<-data.frame()
for(i in 1:nrow(comparison)){
  temp_wl<-wl_function(Lengths,comparison[i,2],comparison[i,3])
  temp_df<-cbind(weight=as.numeric(temp_wl), length=as.numeric(Lengths), group=comparison[i,1],Assessment=comparison[i,4])
  comp<-rbind(temp_df,comp)
}

# plotting the comparison
ggplot(data=comp,aes(x=as.numeric(length), y=as.numeric(weight),color=Assessment))+
  facet_wrap(~group)+
  geom_line()+
  ylab("Weight (kg)")+
  xlab("Length (cm)")+
  ylim(c(0,5.25))+
  xlim(c(0,75))+
  theme_classic()
