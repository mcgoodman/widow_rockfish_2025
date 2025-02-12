####### pULL AND PLOT INDICES

#Update with path
dat_file_path <- "D:/widow_asessment_2025_fork/widow-assessment-update/data_provided/2019_assessment"


#generate the data list
widow_datlist <- r4ss::SS_readdat(file = file.path(dat_file_path,"2019widow.dat"))

widow_ctl <- r4ss::SS_readctl(file = file.path(dat_file_path,"2019widow.ctl"),datlist = widow_datlist)

#get the fleet defineitions
widow_datlist$CPUEinfo

#Pull the cpue indices
widow_indices <- widow_datlist[["CPUE"]]

#lnQ_nwfsc <- widow_ctl$Q_parms["LnQ_base_NWFSC(8)","INIT"]
#PLot
tibble(widow_indices)%>%
  filter(year >= 1900)%>% #remove the VAST index (negative years)
  filter(index == 8)%>%
  mutate(index = "NWFSC")%>% 
 # mutate(obs = obs/exp(lnQ_nwfsc))%>%#NWFSC
  ggplot(aes(x = year, y = obs, col = as.factor(index)))+
  geom_point()+
  geom_errorbar(aes(x = year, ymin = qlnorm(.025,log(obs), sd = se_log) ,  #se in log space so convert
                    ymax = qlnorm(.975,log(obs), sd = se_log) , col = as.factor(index)))+
  ggtitle("NWFSC index 2003 - 2019",subtitle = "VAST")+
  theme_minimal()

###P Comapre plot with VAST index
dodge_width <- 0.75  # Adjust this value to control spacing

tibble(widow_indices) %>%
  filter(index == 8) %>%
  mutate(model = factor(ifelse(year < 1900, "GLMM", "VAST"))) %>%
  mutate(year = abs(year)) %>%
  mutate(index = "NWFSC") %>%
  ggplot(aes(x = year, y = obs, col = as.factor(model))) +
  geom_point(position = position_dodge(width = dodge_width)) +
  geom_errorbar(aes(ymin = qlnorm(.025, log(obs), sd = se_log),
                    ymax = qlnorm(.975, log(obs), sd = se_log)),
                position = position_dodge(width = dodge_width)) +
  ggtitle("NWFSC index 2003 - 2019", 
          subtitle = "VAST vs sdmTMB")+
  theme_minimal()
