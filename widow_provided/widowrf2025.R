# widow rockfish 2025
# coastwide index

setwd("~/Rockfish/Rockfish assessment/chilipepper 2025/yoy indices")

library(RREAS)
library(dplyr)
library(ggplot2)
library(tidyr)
library(sdmTMB)
library(sdmTMBextra)

spname <- "widow"
spcode <- 597

setwd(paste0("./", spname))
fig.dir <- "figures/"

#load data ####
load_mdb(mdb_path = "C:/Users/trogers/Documents/Rockfish/RREAS/Survey data/juv_cruise_backup10JAN24.mdb",
         atsea_path = "C:/Users/trogers/Documents/Rockfish/RREAS/Survey data/at_sea.mdb",
         datasets = c("RREAS","ADAMS","NWFSC","PWCC"),
         activestationsonly = F)

# NWFSC 2024 data (not in database yet) ####
NWFSC2024HAUL <- read.csv("C:/Users/trogers/Documents/Rockfish/RREAS/Survey data/NWFSC_JUV_HAUL_2024.csv", colClasses = c("CRUISE"="character"))
NWFSC2024CATCH <- read.csv("C:/Users/trogers/Documents/Rockfish/RREAS/Survey data/NWFSC_JUV_CATCH_2406.csv", colClasses = c("CRUISE"="character"))
NWFSC2024LENGTH <- read.csv("C:/Users/trogers/Documents/Rockfish/RREAS/Survey data/NWFSC_JUV_LENGTH_2406.csv", colClasses = c("CRUISE"="character"))

CATCH_NWFSC <- rbind(CATCH_NWFSC, NWFSC2024CATCH)
LENGTH_NWFSC <- rbind(LENGTH_NWFSC, NWFSC2024LENGTH %>% mutate(SP_NO=1:n()))

NWFSC2024HAUL$HAUL_DATE=lubridate::mdy_hms(NWFSC2024HAUL$HAUL_DATE)

#use NET_FISHING for missing NET_IN position
NWFSC2024HAUL$NET_IN_LAT<-NWFSC2024HAUL$NET_FISHING_LAT
NWFSC2024HAUL$NET_IN_LONG<-NWFSC2024HAUL$NET_FISHING_LONG

#convert coords to dd
channel <- RODBC::odbcConnectAccess2007("C:/Users/trogers/Documents/Rockfish/RREAS/Survey data/juv_cruise_backup10JAN24.mdb")
standardstations_NWFSC<-RODBC::sqlQuery(channel, "SELECT * FROM dbo_NWFSC_STANDARD_STATIONS", stringsAsFactors = F)
RODBC::odbcCloseAll()

convertdd <- function(x) {
  DEG <- floor(x/100)
  MIN <- x - DEG*100
  DD <- DEG + MIN/60
  return(DD)
}
standardstations_NWFSC$LATDD<-convertdd(standardstations_NWFSC$LATITUDE)
standardstations_NWFSC$LONDD<-(-convertdd(standardstations_NWFSC$LONGITUDE))
NWFSC2024HAUL$NET_IN_LATDD<-convertdd(NWFSC2024HAUL$NET_IN_LAT)
NWFSC2024HAUL$NET_IN_LONDD<-(-convertdd(NWFSC2024HAUL$NET_IN_LONG))
#add year, month, and julian day
NWFSC2024HAUL$YEAR<-lubridate::year(NWFSC2024HAUL$HAUL_DATE)
NWFSC2024HAUL$MONTH<-lubridate::month(NWFSC2024HAUL$HAUL_DATE)
NWFSC2024HAUL$JDAY<-lubridate::yday(NWFSC2024HAUL$HAUL_DATE)
NWFSC2024HAUL$STANDARD_STATION<-1

#join HAUL and standard station info, filter
HAULSTANDARD_NWFSC2024 <-dplyr::full_join(NWFSC2024HAUL, standardstations_NWFSC, by="STATION") %>%
  dplyr::filter(STANDARD_STATION==1) %>%
  dplyr::mutate(SURVEY="NWFSC",
                LATDD=ifelse(is.na(LATDD),NET_IN_LATDD,LATDD),
                LONDD=ifelse(is.na(LONDD),NET_IN_LONDD,LONDD)) %>% #LATDD and LONDD (if not from station)
  dplyr::select(SURVEY,CRUISE,HAUL_NO,YEAR,MONTH,JDAY,HAUL_DATE,STATION,NET_IN_LATDD,NET_IN_LONDD,
                LATDD,LONDD,BOTTOM_DEPTH,STATION_BOTTOM_DEPTH,STRATA,AREA,ACTIVE) %>% 
  dplyr::mutate(STRATA=ifelse(is.na(STRATA) & NET_IN_LATDD>46.25, "WA",
                              ifelse(is.na(STRATA) & NET_IN_LATDD<=46.25 & NET_IN_LATDD>=42, "OR", STRATA)))

HAULSTANDARD_NWFSC <- rbind(HAULSTANDARD_NWFSC, HAULSTANDARD_NWFSC2024)

#select species ####
rfspecies <- subset(sptable_rockfish100, SPECIES==spcode)
rfspecies$NAME <- spname

rf_100 <- get_totals(rfspecies, datasets = c("RREAS","ADAMS","NWFSC","PWCC"), 
                     what = "100day", startyear = 2001)
write.csv(rf_100, paste0(spname,"_rawdata.csv"), row.names = F)

#totals observed
aggregate(TOTAL_NO~NAME*YEAR, data = rf_100, FUN = sum)
#table(rf_100$STATION,rf_100$NAME, useNA = "i")

#state map
states <- map_data("state", region = c("california","oregon","washington"))

#exclude offshore stations
# stationtest=unique.data.frame(rf_100[,c("STATION","AREA","STRATA","LATDD","LONDD","ACTIVE")]) %>% filter(!is.na(STATION))
# ggplot(stationtest, aes(LONDD, LATDD)) + geom_text(aes(label=STATION, color=ACTIVE))
# stationtest2=unique.data.frame(subset(rf_100, SURVEY=="PWCC"))
# ggplot(stationtest2, aes(LONDD, LATDD)) + geom_text(aes(label=paste(CRUISE,HAUL_NO)))
rf_100 <- subset(rf_100, !(STATION %in% c(176:181,214:216)))

#check occurrence at all stations ####
occur <- rf_100 %>%
  #filter(!is.na(STATION)) %>%
  group_by(STATION, LONDD, LATDD, NAME) %>%
  summarize(proppos=length(which(TOTAL_NO>0))/n())
ggplot(occur, aes(LONDD, LATDD)) +
  geom_point(data=filter(occur, proppos==0), color="tomato") +
  geom_point(data=filter(occur, proppos!=0), aes(color=proppos)) +
  facet_grid(.~NAME) + scale_color_distiller(palette = "Blues", direction = 1) +
  geom_polygon( data=states, aes(x=long, y=lat, group=group),
                color="gray30", fill="transparent")

#spatial subset ####
#None
#rf_100 <- subset(rf_100, LATDD>=35)

#plot of occurrence
occur <- rf_100 %>%
  #filter(!is.na(STATION)) %>%
  group_by(STATION, LONDD, LATDD, NAME) %>%
  summarize(proppos=length(which(TOTAL_NO>0))/n())
ggplot(occur, aes(LONDD, LATDD)) +
  geom_point(data=filter(occur, proppos==0), color="tomato") +
  geom_point(data=filter(occur, proppos!=0), aes(fill=proppos),pch=21,color="black") +
  facet_grid(.~NAME) + scale_fill_distiller(palette = "Blues", direction = 1) +
  geom_polygon( data=states, aes(x=long, y=lat, group=group),
                color="gray30", fill="transparent") +
  coord_cartesian(xlim = range(occur$LONDD), ylim = range(occur$LATDD)) +
  labs(fill="Prop. Pos.\nCatches") +
  scale_y_continuous(breaks = 20:50)
ggsave(paste0(fig.dir,spname,"_1_catchpos.png"), width = 4, height = 4)

#plot of spatial sampling effort
ggplot(rf_100, aes(LONDD, LATDD, col = SURVEY)) + 
  geom_polygon( data=states, aes(x=long, y=lat, group=group),
                color="gray30", fill="transparent") +
  geom_point(size=0.5) + facet_wrap(~YEAR, nrow = 3) + 
  coord_cartesian(xlim = range(rf_100$LONDD), ylim = range(rf_100$LATDD))
ggsave(paste0(fig.dir,spname,"_2_sampling_effort_st.png"), width = 10, height = 6)

#year-species combos with no catch
(totals=aggregate(TOTAL_NO~YEAR*NAME, data=rf_100, FUN=sum))
totals[totals$TOTAL_NO==0,]

#fill in missing stations (only needed for raw cpue)
rf_100$STATION=ifelse(is.na(rf_100$STATION),paste0(rf_100$CRUISE,rf_100$HAUL_NO),rf_100$STATION)

#center continuous covariates
rf_100$JDAYC <- rf_100$JDAY - mean(rf_100$JDAY)
rf_100$DEPTHC <- rf_100$BOTTOM_DEPTH - mean(rf_100$BOTTOM_DEPTH)

#select subset of space/time (if relevant) ####
focalcoast <- rf_100

#boxplot of data by year
ggplot(focalcoast, aes(x=factor(YEAR), y=N100)) + geom_boxplot() +
  labs(x="YEAR")
ggplot(focalcoast, aes(x=factor(YEAR), y=log(N100+1))) + geom_boxplot() +
  labs(x="YEAR")

# raw CPUE ####
logind=get_logcpueindex(droplevels(focalcoast),var = "N100")
ggplot(logind, aes(x=YEAR, y=N100_INDEX)) +
  geom_point() + geom_line() + labs(y="mean log(CPUE+1)") +
  scale_x_continuous(breaks = seq(2000,2025,by=2)) + theme_bw() +
  labs(title=paste(spname,"raw cpue"))
ggsave(paste0(fig.dir,spname,"_3_raw_cpue.png"), width = 6, height = 4)

# sdmtmb model ####

(totals=aggregate(TOTAL_NO~YEAR, data=focalcoast, FUN=sum))
#excludeyears=totals$YEAR[totals$TOTAL_NO==0]
excludeyears=2020
focalcoast=filter(focalcoast, !(YEAR %in% excludeyears)) %>% droplevels()
focalcoast$FYEAR <- as.factor(focalcoast$YEAR)
yearscoast=unique(focalcoast$YEAR)

#plot log mean vs log variance by year for positive data
mvaryr <- focalcoast %>% 
  filter(TOTAL_NO>0) %>% 
  group_by(YEAR) %>% 
  summarise(n=n(),
            logmean=log(mean(TOTAL_NO)), logvar=log(var(TOTAL_NO)),
            logmean100=log(mean(N100)), logvar100=log(var(N100))) %>% 
  filter(n>=10)
png(paste0(fig.dir,spname,"_4_mean_var.png"), width = 7, height = 4, res = 300, units = "in")
par(mfrow=c(1,2), mar=c(4,4,1,1))
plot(logvar~logmean, data=mvaryr); abline(a=0, b=1); abline(a=0, b=2, lty=2); abline(a=0, b=3, lty=3)
plot(logvar100~logmean100, data=mvaryr); abline(a=0, b=1); abline(a=0, b=2, lty=2); abline(a=0, b=3, lty=3)
dev.off()

#create mesh
focalcoast <- add_utm_columns(focalcoast, c("LONDD","LATDD"))
meshcoast = make_mesh(focalcoast, xy_cols = c("X","Y"), cutoff = 25)
par(mfrow=c(1,1))
plot(meshcoast)

# * fit models ####

#tweedie with spatial-temporal field
fit_tw <- sdmTMB(N100 ~ -1 + FYEAR + s(JDAYC, k=4),
                 spatiotemporal = "iid",
                 time="FYEAR",
                 spatial="on",
                 family = tweedie(),
                 mesh=meshcoast,
                 data=focalcoast)
sanity(fit_tw)
fit_tw

#delta lognormal with spatial-temporal field
fit_dln <- sdmTMB(N100 ~ -1 + FYEAR + s(JDAYC, k=4),
                  spatiotemporal = "iid",
                  time="FYEAR",
                  spatial="on",
                  family = delta_lognormal(),
                  mesh=meshcoast,
                  data=focalcoast)
sanity(fit_dln)
fit_dln

#delta gamma with spatial-temporal field
fit_dgam <- sdmTMB(N100 ~ -1 + FYEAR + s(JDAYC, k=4),
                   spatiotemporal = "iid",
                   time="FYEAR",
                   spatial="on",
                   family = delta_gamma(),
                   mesh=meshcoast,
                   data=focalcoast)
sanity(fit_dgam)
fit_dgam

# * residual plots (standard) ####

# predictions_tw=predict(fit_tw)
# predictions_tw$resids <- residuals(fit_tw)
# par(mfrow=c(2,2))
# qqnorm(predictions_tw$resids);abline(a = 0, b = 1)
# plot(resids~est, data=predictions_tw); abline(h=0, lty=2)
# plot(resids~YEAR, data=predictions_tw); abline(h=0, lty=2)
# plot(resids~JDAYC, data=predictions_tw); abline(h=0, lty=2)
# ggplot(predictions_tw, aes(X, Y, col = resids)) + scale_colour_gradient2() +
#   geom_point(size=2) + facet_wrap(~YEAR) + ggtitle("Residual") 
# 
# predictions_dln=predict(fit_dln, type="response")
# #binomial model
# predictions_dln$resids1 <- residuals(fit_dln, model = 1)
# qqnorm(predictions_dln$resids1);abline(a = 0, b = 1)
# plot(resids1~est1, data=predictions_dln); abline(h=0, lty=2)
# plot(resids1~YEAR, data=predictions_dln); abline(h=0, lty=2)
# plot(resids1~JDAYC, data=predictions_dln); abline(h=0, lty=2)
# ggplot(predictions_dln, aes(X, Y, col = resids1)) + scale_colour_gradient2() +
#   geom_point(size=2) + facet_wrap(~YEAR) + ggtitle("Residual") 
# #positive model
# predictions_dln$resids2 <- residuals(fit_dln, model = 2)
# qqnorm(predictions_dln$resids2);abline(a = 0, b = 1)
# plot(resids2~est2, data=predictions_dln); abline(h=0, lty=2)
# plot(resids2~YEAR, data=predictions_dln); abline(h=0, lty=2)
# plot(resids2~JDAYC, data=predictions_dln); abline(h=0, lty=2)
# ggplot(predictions_dln, aes(X, Y, col = resids2)) + scale_colour_gradient2() +
#   geom_point(size=2) + facet_wrap(~YEAR) + ggtitle("Residual") 
# 
# predictions_dgam=predict(fit_dgam, type="response")
# #binomial model
# predictions_dgam$resids1 <- residuals(fit_dgam, model = 1)
# qqnorm(predictions_dgam$resids1);abline(a = 0, b = 1)
# plot(resids1~est1, data=predictions_dgam); abline(h=0, lty=2)
# plot(resids1~YEAR, data=predictions_dgam); abline(h=0, lty=2)
# plot(resids1~JDAYC, data=predictions_dgam); abline(h=0, lty=2)
# ggplot(predictions_dgam, aes(X, Y, col = resids1)) + scale_colour_gradient2() +
#   geom_point(size=2) + facet_wrap(~YEAR) + ggtitle("Residual") 
# #positive model
# predictions_dgam$resids2 <- residuals(fit_dgam, model = 2)
# qqnorm(predictions_dgam$resids2);abline(a = 0, b = 1)
# plot(resids2~est2, data=predictions_dgam); abline(h=0, lty=2)
# plot(resids2~YEAR, data=predictions_dgam); abline(h=0, lty=2)
# plot(resids2~JDAYC, data=predictions_dgam); abline(h=0, lty=2)
# ggplot(predictions_dgam, aes(X, Y, col = resids2)) + scale_colour_gradient2() +
#   geom_point(size=2) + facet_wrap(~YEAR) + ggtitle("Residual") 

# * residual plots (dharma) ####

s_tw <- simulate(fit_tw, nsim = 500, type = 'mle-mvn')
s_dln <- simulate(fit_dln, nsim = 500, type = 'mle-mvn') 
s_dgam <- simulate(fit_dgam, nsim = 500, type = 'mle-mvn') 

#check number of zeros
sum(focalcoast$N100 == 0) / length(focalcoast$N100)
sum(s_tw == 0)/length(s_tw)
sum(s_dln == 0)/length(s_dln)
sum(s_dgam == 0)/length(s_dgam)

png(paste0(fig.dir,spname,"_5_qqplots.png"), width = 8, height = 4, res = 300, units = "in")
par(mfrow=c(1,3))
dharma_residuals(s_tw, fit_tw)
title("tweedie", line=0)
dharma_residuals(s_dln, fit_dln)
title("delta-lognormal", line=0)
dharma_residuals(s_dgam, fit_dgam)
title("delta-gamma", line=0)
dev.off()

# * predictions ####

activestations=filter(focalcoast, ACTIVE=="Y")
gridstations <- unique.data.frame(select(activestations, STATION, STRATA, LATDD, X, Y))
new_grid=expand_grid(gridstations, YEAR=yearscoast)
new_grid$JDAYC=0
new_grid$FYEAR <- factor(new_grid$YEAR)

pred_tw=predict(fit_tw, newdata = new_grid, return_tmb_object = T)
ind_tw=get_index(pred_tw, bias_correct = T)
ind_tw$model=paste("tweedie spatial-temporal",spname)

pred_dln=predict(fit_dln, newdata = new_grid, return_tmb_object = T)
ind_dln=get_index(pred_dln, bias_correct = T)
ind_dln$model=paste("delta-logn spatial-temporal",spname)

pred_dgam=predict(fit_dgam, newdata = new_grid, return_tmb_object = T)
ind_dgam=get_index(pred_dgam, bias_correct = T)
ind_dgam$model=paste("delta-gamma spatial-temporal",spname)

# * plots of spatial fields ####

plot_map <- function(dat, column, pointsize=2) {
  ggplot(dat, aes(X, Y, color = {{ column }})) +
    geom_point(size=pointsize) + scale_colour_gradient2()
}

#observed
plot_map(focalcoast, log(N100)) + facet_wrap(~YEAR) + ggtitle(paste("Observed", spname))  +
  geom_point(data=filter(focalcoast, N100>0), pch=1, color="tomato")
ggsave(paste0(fig.dir,spname,"_observed.png"), width = 10, height = 8)

#tweedie with spatial-temporal field

#random fields
plot_map(pred_tw$data, omega_s, pointsize = 5) + ggtitle("Spatial random effects")
plot_map(pred_tw$data, epsilon_st) + facet_wrap(.~YEAR) + ggtitle("Spatial-temporal offsets")
plot_map(pred_tw$data, est_rf) + facet_wrap(.~YEAR) + ggtitle("Spatial-temporal random effects")

#predicted
predictions_tw=predict(fit_tw)
plot_map(predictions_tw, est) + facet_wrap(~YEAR) + ggtitle(paste("Predicted", spname)) 
ggsave(paste0(fig.dir,spname,"_predicted.png"), width = 10, height = 8)

#predicted to active stations
plot_map(pred_tw$data, est) + facet_wrap(.~YEAR) + ggtitle(paste("Predicted to grid", spname))
ggsave(paste0(fig.dir,spname,"_predictedgrid.png"), width = 10, height = 8)

# #delta lognormal random field - spatial temporal
# 
# #random fields
# # plot_map(pred_dlnr, omega_s1, pointsize = 5) + ggtitle("Spatial random effects - binomial")
# # plot_map(pred_dlnr, omega_s2, pointsize = 5) + ggtitle("Spatial random effects - positive")
# # plot_map(pred_dlnr, epsilon_st1) + facet_wrap(.~YEAR) + ggtitle("Spatial-temporal random effects - binomial")
# # plot_map(pred_dlnr, epsilon_st2) + facet_wrap(.~YEAR) + ggtitle("Spatial-temporal random effects - positive")
# plot_map(pred_dln$data, est_rf1) + facet_wrap(.~YEAR) + ggtitle("Spatial random effects - binomial")
# plot_map(pred_dln$data, est_rf2) + facet_wrap(.~YEAR) +  ggtitle("Spatial random effects - positive")
# 
# #predicted
# plot_map(predictions_dln, log(est)) + facet_wrap(~YEAR) + ggtitle("Predicted") 
# 
# #predicted to active stations
# pred_dlnr=predict(fit_dln, newdata = new_grid, type = "response")
# plot_map(pred_dlnr, log(est)) + facet_wrap(.~YEAR) + ggtitle("Predicted to grid")
# 
# #delta gamma random field - spatial temporal
# 
# #random fields
# # plot_map(pred_dgamr, omega_s1, pointsize = 5) + ggtitle("Spatial random effects - binomial")
# # plot_map(pred_dgamr, omega_s2, pointsize = 5) + ggtitle("Spatial random effects - positive")
# # plot_map(pred_dgamr, epsilon_st1) + facet_wrap(.~YEAR) + ggtitle("Spatial-temporal random effects - binomial")
# # plot_map(pred_dgamr, epsilon_st2) + facet_wrap(.~YEAR) + ggtitle("Spatial-temporal random effects - positive")
# plot_map(pred_dgam$data, est_rf1) + facet_wrap(.~YEAR) + ggtitle("Spatial random effects - binomial")
# plot_map(pred_dgam$data, est_rf2) + facet_wrap(.~YEAR) +  ggtitle("Spatial random effects - positive")
# 
# #predicted
# plot_map(predictions_dgam, log(est)) + facet_wrap(~YEAR) + ggtitle("Predicted") 
# 
# #predicted to active stations
# pred_dgamr=predict(fit_dgam, newdata = new_grid, type = "response")
# plot_map(pred_dgamr, log(est)) + facet_wrap(.~YEAR) + ggtitle("Predicted to grid")

# * compare indices ####

#compare different error structures
ind_comp=rbind(ind_tw, ind_dln, ind_dgam)
ind_comp=ind_comp %>% 
  mutate(YEAR=as.numeric(as.character(FYEAR)))
ind_comp=ind_comp %>% right_join(expand.grid(model=unique(ind_comp$model),
                                             YEAR=min(yearscoast):max(yearscoast))) %>% 
  arrange(model, YEAR)
ggplot(ind_comp, aes(x=YEAR, y=log_est,color=model, fill=model, group=model)) +
  geom_line(size=1) +
  geom_ribbon(aes(ymin=log(lwr), ymax=log(upr)), alpha=0.1) +  
  labs(color="model", fill="model", y="log index") +
  theme_bw() + 
  theme(legend.position = "top", legend.direction = "vertical") +
  scale_x_continuous(breaks = seq(2000,2025,by=2))
ggsave(paste0(fig.dir,spname,"_comparison_error_dist.png"), width = 6, height = 6)

ggplot(ind_comp, aes(x=YEAR, y=est,color=model, fill=model, group=model)) +
  geom_line(size=1) +
  geom_ribbon(aes(ymin=lwr, ymax=upr), alpha=0.1) +  
  labs(color="model", fill="model", y="index")  +
  scale_x_continuous(breaks = seq(2000,2025,by=2))

# #correlation matrices
# ind_comp_wide=spread(select(ind_comp, YEAR, model, log_est_sc), model, log_est_sc)
# pcor=cor(select(ind_comp_wide, -YEAR))
# scor=cor(select(ind_comp_wide, -YEAR), method = "spearman")

#plot final index
ind_comp=rbind(ind_tw)
ind_comp=ind_comp %>% 
  mutate(YEAR=as.numeric(as.character(FYEAR)))
ind_comp=ind_comp %>% right_join(expand.grid(model=unique(ind_comp$model),
                                             YEAR=min(yearscoast):max(yearscoast))) %>% 
  arrange(model, YEAR)

# ggplot(ind_comp, aes(x=YEAR, y=log_est, color=model, fill=model, group=model)) +
#   geom_ribbon(aes(ymin=log(lwr), ymax=log(upr)), outline.type = "full", alpha=0.1) +  
#   geom_ribbon(aes(ymin=log_est-se, ymax=log_est+se), color=NA, alpha=0.1) +  
#   geom_line(size=1) + geom_point(size=1) +
#   labs(color="model", fill="model", y="log index")  +
#   theme(legend.position = "top")
# ggsave(paste0(fig.dir,spname,"_indexcomparison_log.png"), width = 6, height = 4)

ggplot(ind_comp, aes(x=YEAR, y=log_est)) +
  facet_wrap(.~model, scales = "free_y") +
  geom_line(size=1) + geom_point(size=0.5) +
  geom_errorbar(aes(ymin=log(lwr), ymax=log(upr)), alpha=0.5, width=0.3) +  
  geom_errorbar(aes(ymin=log_est-se, ymax=log_est+se), alpha=0.5, width=0, size=2) +  
  labs(y="log index") + theme_bw() +
  scale_x_continuous(breaks = seq(2000,2025,by=2))
ggsave(paste0(fig.dir,spname,"_index_log.png"), width = 8, height = 4)

ggplot(ind_comp, aes(x=YEAR, y=est)) +
  facet_wrap(.~model, scales = "free_y") +
  geom_line(size=1) + geom_point(size=0.5) +
  geom_errorbar(aes(ymin=lwr, ymax=upr), alpha=0.5, width=0.3) +  
  labs(y="index") + theme_bw() +
  scale_x_continuous(breaks = seq(2000,2025,by=2))
ggsave(paste0(fig.dir,spname,"_index.png"), width = 8, height = 4)

# * JDAY effect ####
png(paste0(fig.dir,spname,"_jday_effect.png"), width = 4, height = 4, res = 300, units = "in")
visreg::visreg(fit_tw, xvar = "JDAYC")
dev.off()

# * export final index ####
#tweedie, st field
ind_export <- select(ind_tw, YEAR=FYEAR, est, logse=se) %>% filter(YEAR!=2020)
write.csv(ind_export, paste0(spname,"_indices.csv"), row.names = F)

save(fit_tw, fit_dln, fit_dgam, file = paste0(spname,"_models.Rdata"))

# more alternate models ####

# * without st field ####

# fit_tw_alt <- sdmTMB(N100 ~ -1 + FYEAR + s(JDAYC, k=4),
#                      spatiotemporal = "off",
#                      time="FYEAR",
#                      spatial="on",
#                      family = tweedie(),
#                      mesh=meshcoast,
#                      data=focalcoast)
# sanity(fit_tw_alt)
# fit_tw_alt
# 
# pred_tw_alt=predict(fit_tw_alt, newdata = new_grid, return_tmb_object = T)
# ind_tw_alt=get_index(pred_tw_alt, bias_correct = T)
# ind_tw_alt$model=paste("tweedie spatial", spname)
# 
# plot_map(pred_tw_alt$data, est) + facet_wrap(.~YEAR) + ggtitle("Predicted to grid")
# 
# #residuals
# predictions_tw=predict(fit_tw_alt)
# predictions_tw$resids <- residuals(fit_tw_alt)
# par(mfrow=c(2,2))
# qqnorm(predictions_tw$resids);abline(a = 0, b = 1)
# plot(resids~est, data=predictions_tw); abline(h=0, lty=2)
# plot(resids~YEAR, data=predictions_tw); abline(h=0, lty=2)
# plot(resids~JDAYC, data=predictions_tw); abline(h=0, lty=2)
# ggplot(predictions_tw, aes(X, Y, col = resids)) + scale_colour_gradient2() +
#   geom_point(size=2) + facet_wrap(~YEAR) + ggtitle("Residual") 
# 
# s_tw_alt <- simulate(fit_tw_alt, nsim = 500)
# #check number of zeros
# sum(focalcoast$N100 == 0) / length(focalcoast$N100)
# sum(s_tw_alt == 0)/length(s_tw_alt)
# sdmTMBextra::dharma_residuals(s_tw_alt, fit_tw_alt)
# 
# #compare indices
# ind_comp=rbind(ind_tw, ind_tw_alt)
# ind_comp=ind_comp %>% 
#   mutate(YEAR=as.numeric(as.character(FYEAR)))
# ind_comp=ind_comp %>% right_join(expand.grid(model=unique(ind_comp$model),
#                                              YEAR=min(yearscoast):max(yearscoast))) %>% 
#   arrange(model, YEAR)
# #overlaid with CIs
# ggplot(ind_comp, aes(x=YEAR, y=log_est, color=model, fill=model, group=model)) +
#   geom_ribbon(aes(ymin=log(lwr), ymax=log(upr)), outline.type = "full", alpha=0.1) +  
#   geom_ribbon(aes(ymin=log_est-se, ymax=log_est+se), color=NA, alpha=0.1) +  
#   geom_line(size=1) + geom_point(size=1) +
#   labs(color="model", fill="model", y="log index")  +
#   theme(legend.position = "top")
# ggsave(paste0(fig.dir,spname,"_s_st_comparison.png"), width = 6, height = 4)
# 
# ggplot(ind_comp, aes(x=YEAR, y=est,color=model, fill=model, group=model)) +
#   geom_ribbon(aes(ymin=lwr, ymax=upr),outline.type = "full", alpha=0.1) +  
#   geom_line(size=1) + geom_point(size=1) +
#   labs(color="model", fill="model", y="index") +
#   theme(legend.position = "top")
# ggsave(paste0(fig.dir,spname,"_s_st_comparison2.png"), width = 6, height = 4)
# 
# # * predictions for each state ####
# 
# #OR: no sampling in 2010
# #WA: no sampling in 2001, 2002, 2003, 2010, 2012, 2014, 2017, 2021
# (totals=aggregate(TOTAL_NO~YEAR*STRATA, data=rf_100, FUN=sum))
# totals[totals$TOTAL_NO==0,]
# 
# new_grid_CA = subset(new_grid, LATDD<=42)
# new_grid_OR = subset(new_grid, LATDD>=42 & LATDD<46.5)
# new_grid_WA = subset(new_grid, LATDD>=46.5)
# 
# pred_tw_CA=predict(fit_tw, newdata = new_grid_CA, return_tmb_object = T)
# ind_tw_CA=get_index(pred_tw_CA, bias_correct = T)
# ind_tw_CA$model="tweedie spatial-temporal CA"
# 
# pred_tw_OR=predict(fit_tw, newdata = new_grid_OR, return_tmb_object = T)
# ind_tw_OR=get_index(pred_tw_OR, bias_correct = T)
# ind_tw_OR$model="tweedie spatial-temporal OR"
# 
# pred_tw_WA=predict(fit_tw, newdata = new_grid_WA, return_tmb_object = T)
# ind_tw_WA=get_index(pred_tw_WA, bias_correct = T)
# ind_tw_WA$model="tweedie spatial-temporal WA"
# 
# #compare indices
# ind_comp=rbind(ind_tw, ind_tw_CA, ind_tw_OR, ind_tw_WA)
# ind_comp=ind_comp %>% 
#   mutate(YEAR=as.numeric(as.character(FYEAR)))
# ind_comp=ind_comp %>% right_join(expand.grid(model=unique(ind_comp$model),
#                                              YEAR=min(yearscoast):max(yearscoast))) %>% 
#   arrange(model, YEAR)
# #overlaid with CIs
# ggplot(ind_comp, aes(x=YEAR, y=log_est, color=model, fill=model, group=model)) +
#   facet_wrap(.~model, nrow = 2) +
#   geom_ribbon(aes(ymin=log(lwr), ymax=log(upr)), outline.type = "full", alpha=0.1) +  
#   geom_ribbon(aes(ymin=log_est-se, ymax=log_est+se), color=NA, alpha=0.1) +  
#   geom_line(size=1) + geom_point(size=1) +
#   labs(color="model", fill="model", y="log index")  +
#   theme(legend.position = "off")
# ggsave(paste0(fig.dir,spname,"_state_comparison.png"), width = 6, height = 6)
# 
# ggplot(ind_comp, aes(x=YEAR, y=est,color=model, fill=model, group=model)) +
#   facet_wrap(.~model, nrow = 2, scales = "free_y") +
#   geom_ribbon(aes(ymin=lwr, ymax=upr),outline.type = "full", alpha=0.1) +  
#   geom_line(size=1) + geom_point(size=1) +
#   labs(color="model", fill="model", y="index") +
#   theme(legend.position = "off")
