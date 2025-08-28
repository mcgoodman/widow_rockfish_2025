
library("dplyr")
library("tidyr")
library("cowplot")
library("ggplot2")

####### pULL AND PLOT INDICES from 2019 assessment

#Update with path
dat_file_path <- file.path("models", "2019 base model", "Base_45")


#generate the data list
widow_datlist <- r4ss::SS_readdat(file = file.path(dat_file_path, "2019widow.dat"))

widow_ctl <- r4ss::SS_readctl(file = file.path(dat_file_path, "2019widow.ctl"), datlist = widow_datlist)

#get the fleet defineitions
widow_datlist$CPUEinfo

#Pull the cpue indices
widow_indices <- widow_datlist[["CPUE"]]

#lnQ_nwfsc <- widow_ctl$Q_parms["LnQ_base_NWFSC(8)","INIT"]
#PLot
tibble(widow_indices) %>%
  filter(year >= 1900) %>% #remove the VAST index (negative years)
  filter(index == 8) %>%
  mutate(index = "NWFSC") %>%
  # mutate(obs = obs/exp(lnQ_nwfsc))%>%#NWFSC
  ggplot(aes(x = year, y = obs, col = as.factor(index))) +
  geom_point() +
  geom_errorbar(aes(
    x = year,
    ymin = qlnorm(.025, log(obs), sd = se_log) ,
    #se in log space so convert
    ymax = qlnorm(.975, log(obs), sd = se_log) ,
    col = as.factor(index)
  )) +
  ggtitle("NWFSC index 2003 - 2019", subtitle = "VAST") +
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

### now get modern indices to plot/comp with

# sdmTMB-based biomass index ------------------------------
index_gm <- read.csv(file.path("data_provided", "WCGBTS", "delta_gamma", "index", "est_by_area.csv"))
index_gm$source <- "sdmTMB delta-\ngamma, 2025"
index_gm <- index_gm %>% filter(area == "Coastwide")

index_ln <- read.csv(file.path("data_provided", "WCGBTS", "delta_lognormal", "index", "est_by_area.csv"))
index_ln$source <- "sdmTMB delta-\nlognorm, 2025"
index_ln <- index_ln %>% filter(area == "Coastwide")

# reorganize old data
old_index <- widow_indices %>% filter(index == 8) %>%
  mutate(model = factor(ifelse(year < 1900, "GLMM", "VAST")))
old_index$source <- old_index$model
old_index$year <- abs(old_index$year)

# plotting all the things... tho not sure it's good! ------
# old data as plot 1
dodge_width <- 0.75  # Adjust this value to control spacing
old_comp <- ggplot(NULL, aes(x = year, col = source)) + 
  geom_errorbar(data = old_index, aes(ymin = qlnorm(.025, log(obs), sd = se_log), 
                                      ymax = qlnorm(.975, log(obs), sd = se_log)), 
                position = position_dodge(width = dodge_width)) + 
  geom_point(data = old_index, aes(y = obs), 
             position = position_dodge(width = dodge_width)) + 
  # geom_line(data = rbind(index_gm, index_ln), aes(y = est), lwd = 0.8) +
  theme_bw() + theme(legend.position = "none") + 
  labs(y = "index") + 
  scale_color_manual(values = c("gray", "black"))

# new data v. VAST as plot 2
# combine the data frames
index_ln$obs <- index_ln$est; index_ln$se_log <- index_ln$se
index_gm$obs <- index_gm$est; index_gm$se_log <- index_gm$se
all_dat <- rbind(old_index[, c(1, 4, 5, 7)] %>% filter(source == "VAST"),index_ln[, c(2, 10, 11, 9)], index_gm[, c(2, 10, 11, 9)])

dodge_width <- 0.9  # Adjust this value to control spacing
new_comp <- ggplot(all_dat, aes(year, obs, col = source)) + 
  geom_errorbar(aes(ymin = qlnorm(.025, log(obs), sd = se_log),
                    ymax = qlnorm(.975, log(obs), sd = se_log)),
                position = position_dodge(width = dodge_width)) +
  geom_point(position = position_dodge(width = dodge_width)) +
  labs(y = "index") + 
  theme_bw() + theme(legend.position = "bottom") + 
  scale_color_manual(values = c("black", "#26828e", "#6ece58"))

plot_grid(old_comp, new_comp, nrow = 2, rel_heights = c(0.9, 1))

# juvenile index ------------------------------

# new index
juv_index <- read.csv("data_provided/RREAS/widow_indices.csv")
colnames(juv_index) <- c("year", "obs", "se_log")
juv_index$source <- rep("Update")

# get the old index from the base model
juv_old <- widow_indices %>% filter(index == 6) %>%
  mutate(model = factor(ifelse(year < 1900, "Past unused", "Past used")))
juv_old$source <- juv_old$model
juv_old$year <- abs(juv_old$year)

# merge
juv_dat <- rbind(juv_index, juv_old[,c(1,4,5,7)])

# plot 1 is unlogged
dodge_width <- 0.25  # Adjust this value to control spacing
no_log_plot <- ggplot(juv_dat, aes(year, obs, col = source)) + 
  geom_pointrange(aes(ymin = qlnorm(.025, log(obs), sdlog = se_log),
                      ymax = qlnorm(.975, log(obs), sdlog = se_log)),
                position = position_dodge(width = dodge_width)) +
  labs(y = "index") + 
  theme_bw() + theme(legend.position = "none") + 
  scale_color_manual(values = c("gray", "black", "#fde725"))

# plot 2 is logged
log_plot <- ggplot(juv_dat, aes(year, log(obs), col = source)) + 
  geom_pointrange(aes(ymin = qnorm(.025, log(obs), sd = se_log),
                    ymax = qnorm(.975, log(obs), sd = se_log)),
                position = position_dodge(width = dodge_width)) +
  labs(y = "log(index)") + 
  theme_bw() + theme(legend.position = "bottom") + 
  scale_color_manual(values = c("gray", "black", "#fde725"))

plot_grid(no_log_plot, log_plot, nrow = 2, rel_heights = c(0.9, 1))

# Log correlation
juv_dat |> select(-se_log) |> 
  pivot_wider(names_from = "source", values_from = "obs") |> 
  select(-year) |> 
  cor(use = "pairwise.complete.obs")

## Write out new index
## Removing 2001-2003, 2010, 2012 to conform with previous assessment, 
## which only used estimates from years with coastwide data
juv_index |> 
  filter(!(year %in% c(2001:2003, 2010, 2012))) |> 
  mutate(obs = round(obs, 4), se_log = round(se_log, 4), month = 7, index = 6) |> 
  select(year, month, index, obs, se_log) |> 
  write.csv(file.path("data_derived", "juvenile_survey.csv"), row.names = FALSE)
