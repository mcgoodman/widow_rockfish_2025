library(dplyr)
library(ggplot2)
library(magick)
library(tibble)
library(here)
library(r4ss)
library(flextable)
library(officer)

source(here("R","functions","bridging_functions.R"))

rep_2015 <- SS_output(here("models","2015_model","7.08_Widow2015_STARbase"))
rep_2019 <- SS_output(here("models","2019 base model","Base_45_new"))
rep_2025 <- SS_output(here("models","2025 base model"))

## PLot of VAST vs tmb fit
## Juveiles
juv_vast <- rep_2019$cpue|>filter(Fleet == 6)|>mutate(source = 'VAST')|>select(Yr,Obs,Exp,source,SE)
juv_tmb <- rep_2025$cpue|>filter(Fleet == 6, Yr >= 2003)|>mutate(source = 'TMB')|>select(Yr,Obs,Exp,source,SE)

juvenile <- rbind(juv_vast,juv_tmb)
juvenile <- juvenile|>mutate(low_int = Obs-1.96*SE, high_int = Obs+1.96*SE)

juv_vast <- rep_2019$cpue |> 
  filter(Fleet == 6) |> 
  mutate(source = 'VAST') |> 
  select(Yr, Obs, Exp, source, SE)|>
mutate(log_Obs = log(Obs),
log_low_int = log(Obs) - 1.96*SE,  # Assuming SE is already on log scale
log_high_int = log(Obs) + 1.96*SE,
log_Exp = log(Exp)
)


juv_tmb <- rep_2025$cpue |> 
  filter(Fleet == 6, Yr %in% c(2004:2009,2011,2013:2025)) |> 
  mutate(source = 'TMB') |> 
  select(Yr, Obs, Exp, source, SE)|>
  mutate(
  log_Obs = log(Obs),
log_low_int = log(Obs) - 1.96*SE,  # Assuming SE is already on log scale
log_high_int = log(Obs) + 1.96*SE,
log_Exp = log(Exp)
)



ggplot()+
  geom_point(juv_vast, mapping = aes(x = Yr, y = log_Obs, col = "VAST"), size = 2)+
  geom_errorbar(juv_vast, mapping = aes(x = Yr, ymin = log_low_int, ymax = log_high_int, col = "VAST"), width = 0.25)+
  geom_path(juv_vast,mapping = aes(x = Yr, y = log_Exp, col = "VAST"), lwd = 1)+
  geom_point(juv_tmb, mapping = aes(x = Yr+0.2, y = log_Obs, col = "TMB"), size = 2)+
  geom_errorbar(juv_tmb, mapping = aes(x = Yr+0.2, ymin = log_low_int, ymax = log_high_int, col = "TMB"), width = 0.25)+
  geom_path(juv_tmb,mapping = aes(x = Yr+0.2, y = log_Exp, col = "TMB"), lwd = 1)+
  theme_minimal()+
  xlab("Year")+
  ylab("log Index")+
  ggtitle("Comparison of VAST and TMB Estimates for Juvenile Survey") +
  theme(
    plot.title = element_text(hjust = 0.5),  # center the title
    legend.title = element_blank()          # remove legend title
  )

ggsave(here("figures","presentation_plots","vast_vs_tmb","vast_tmb_juvenile.png"))

wcgbts_vast <- rep_2019$cpue |> 
  filter(Fleet == 8) |> 
  mutate(source = 'VAST') |> 
  select(Yr, Obs, Exp, source, SE)|>
  mutate(log_Obs = log(Obs),
         log_low_int = log(Obs) - 1.96*SE,  # Assuming SE is already on log scale
         log_high_int = log(Obs) + 1.96*SE,
         log_Exp = log(Exp)
  )


wcgbts_tmb <- rep_2025$cpue |> 
  filter(Fleet == 8) |> 
  mutate(source = 'TMB') |> 
  select(Yr, Obs, Exp, source, SE)|>
  mutate(
    log_Obs = log(Obs),
    log_low_int = log(Obs) - 1.96*SE,  # Assuming SE is already on log scale
    log_high_int = log(Obs) + 1.96*SE,
    log_Exp = log(Exp)
  )



ggplot()+
  geom_point(wcgbts_vast, mapping = aes(x = Yr, y = log_Obs, col = "VAST"), size = 2)+
  geom_errorbar(wcgbts_vast, mapping = aes(x = Yr, ymin = log_low_int, ymax = log_high_int, col = "VAST"), width = 0.25)+
  geom_path(wcgbts_vast,mapping = aes(x = Yr, y = log_Exp, col = "VAST"), lwd = 1)+
  geom_point(wcgbts_tmb, mapping = aes(x = Yr+0.2, y = log_Obs, col = "TMB"), size = 2)+
  geom_errorbar(wcgbts_tmb, mapping = aes(x = Yr+0.2, ymin = log_low_int, ymax = log_high_int, col = "TMB"), width = 0.25)+
  geom_path(wcgbts_tmb,mapping = aes(x = Yr+0.2, y = log_Exp, col = "TMB"), lwd = 1)+
  theme_minimal()+
  xlab("Year")+
  ylab("log Index")+
  ggtitle("Comparison of VAST and TMB Estimates for WCGBTS") +
  theme(
    plot.title = element_text(hjust = 0.5),  # center the title
    legend.title = element_blank()          # remove legend title
  )

ggsave(here("figures","presentation_plots","vast_vs_tmb","vast_tmb_wcgbts.png"))


## Time blocks

#Midwater TrawlSS_plots(SS_output(here("models","model_bridging","mortality")),plot = 9,printfolder = "discard")
SS_plots(SS_output(here("models","model_bridging","mortality")),plot = 9,printfolder = "discard")
mwt_old_blocks <- image_read(here("models","model_bridging","mortality","discard","discard_log_fitMidwaterTrawl.png"))
mwt_new_blocks <- image_read(here("models","2025 base model","plots","discard_log_fitMidwaterTrawl.png"))

combined <- image_append(c(mwt_old_blocks, mwt_new_blocks), stack = FALSE)  # vertical stack
image_write(combined, path = here("figures","presentation_plots","timeblocks", "pred-obs-discards.png"))



## Sensitvitites one by one
databridge_dir <- here("models","data_bridging")
dir.create(pair_dir <- here("figures","presentation_plots","pair_wise_bridging"))

## We need an additional run here, that updates disc comp + amount for BT, MWT, but doesnt update 2019
mod <- SS_read("D:/widow_asessment_2025_fork/widow-assessment-update/models/data_bridging/add_discard_amounts_bt_mwt_hnl_2023_old_comps")

mod$dat$discard_data <- mod$dat$discard_data|>
  filter(!(fleet == 5 & year >= 2019))

dir.create(mod_dir <- "D:/widow_asessment_2025_fork/widow-assessment-update/models/data_bridging/add_discard_amounts_comps_bt_mwt_no_update_hnl")

#WRITE AND RUN THE MODEL
SS_write(inputlist = mod,dir = mod_dir,overwrite = F)
r4ss::run(dir = mod_dir,exe = get_ss3_exe(),extras = "-nohess")


models <- c(
  "2019 model" = here("models","2019 base model","Base_45_new"),
 # "update landings" = here(databridge_dir, "add_catches"),
 #  "update MWT / BT discard amount" = here(databridge_dir, "add_discard_amounts_bt_mwt_2025_hnl_2019"),
  "update landings, disc. amount, disc. comps" = here(databridge_dir, "add_discard_comps_bt_2023_hnl_2019"),
  "add HnL discards to landings" = here(databridge_dir, "add_discard_amounts_bt_mwt_combine_hnl_drop_hnl_lc"),
  "update indices" = here(databridge_dir, "add_indices"),
  "update age / length composition" = here(databridge_dir, "data_bridged_model_weighted"), 
  "update M, L/W, bias ramp, blocks (2025 base)" = here("models","2025 base model")
)

dirs <- c("","update_landings","update_disc_amount","update_disc_comps","add_hnl_to_landings","update_indices","update_comps","update_mod_bridge_steps")
dirs <- c("","update_landings_dsc_a_dsc_c","add_hnl_to_landings","update_indices","update_comps","update_mod_bridge_steps")

# Load library
library(paletteer)


cols <- paletteer::paletteer_d("yarrr::xmen")# for(i in 2:length(models)){
#   mods <- models[1:i]
#     
#   rep <- SSgetoutput(dirvec = mods)
#   dir.create(plotdir <-  here("figures","presentation_plots","pair_wise_bridging",dirs[i]))
#   
#   
#   compare_ss3_mods(replist = rep,
#                    plot_dir = plotdir,
#                    plot_names = names(mods), plot = F)
#   
#   
#   
# }

library(furrr)
library(here)
plan(multisession)  # Or use plan(multicore) on Unix-based systems

# Wrap in a function
run_compare <- function(i) {
  mods <- models[1:i]
  rep <- SSgetoutput(dirvec = mods)
  plotdir <- here("figures", "presentation_plots", "pair_wise_bridging", dirs[i])
  dir.create(plotdir, recursive = TRUE, showWarnings = FALSE)
  
  compare_ss3_mods(replist = rep,
                   plot_dir = plotdir,
                   plot_names = names(mods),
                   plot = FALSE,
                   legendloc = "bottomleft",col = cols[1:i], lty = 1, pch = NULL)
}

future_map(1:length(models), run_compare)


run_compare(4)


## Data bridging plots that show HnL issue
# 1. 2019
# 2. Landings + discards
# 3. Rearrange HnL
# 4. 2025
# 
# 5. Indices
# ...

databridge_dir <- here("models","data_bridging")
dir.create(pair_dir <- here("figures","presentation_plots","pair_wise_bridging"))


models <- c(
  "2019 model" = here("models","2019 base model","Base_45_new"),
  "+ Update landings" =  here(databridge_dir, "add_catches"),
  "+ Update BT MWT discards" = here(databridge_dir, "add_discard_amounts_comps_bt_mwt_no_update_hnl"), #chnage this
  "+  HnL discards" = here(databridge_dir, "add_discard_amounts_bt_mwt_hnl_2023_new_comps"),
  "+ Update BT MWT discards, HnL adjust" = here(databridge_dir, "add_discard_amounts_bt_mwt_combine_hnl_drop_hnl_lc"),
  "+ Update indices" = here(databridge_dir, "add_indices"),
  "+ Update age / length composition" = here(databridge_dir, "data_bridged_model_weighted"), 
  "+ Update ramp, blocks (2025 base)" = here("models","2025 base model")
)

dirs <- c("","update_landings","update_bt_mwt_disc","update_bt_mwt_hnl_disc","update_bt_mwt_disc_hnl_adjust","update_indices","update_comps","update_mod_bridge_steps")
#dirs <- c("","update_landings_dsc_a_dsc_c","add_hnl_to_landings","update_indices","update_comps","update_mod_bridge_steps")

# Load library
library(paletteer)


cols <- paletteer::paletteer_d("yarrr::xmen")


library(furrr)
library(here)


plan(multisession)  # Or use plan(multicore) on Unix-based systems

# Wrap in a function
run_compare <- function(i) {
  #Inlcude all plots up until 5, then drop plots 3 and 4
  if(i <= 4){
    x <- 1:i
  } else {
    x <- 1:i
    x <- x[-c(3,4)]
  }
  
  
  mods <- models[x]
  rep <- SSgetoutput(dirvec = mods)
  plotdir <- here("figures", "presentation_plots", "pair_wise_bridging", dirs[i])
  dir.create(plotdir, recursive = TRUE, showWarnings = FALSE)
  
  # compare_ss3_mods(replist = rep,
  #                  plot_dir = plotdir,
  #                  plot_names = names(mods),
  #                  plot = FALSE,
  #                  legendloc = "bottomleft",col = cols[x], lty = 1, pch = NULL)
  
  compare_ss3_mods(replist = rep,
                   plot_dir = plotdir,
                   subplots = 9:12,
                   plot_names = names(mods),
                   plot = FALSE,
                   legendloc = "topleft",col = cols[x], lty = 1, pch = NULL, clear_dir = F)
  
  
}

for(i in 1:length(models)){
  run_compare(i)
}

future_map(1:length(models), run_compare)







## Comapre model based on Kiva feedback
compare_ss3_mods(replist = SSgetoutput(dirvec = models[c(1,4)]),
                 plot_dir = here("figures", "presentation_plots", "pair_wise_bridging", "kiva_plot"),
                 plot_names = names(models[c(1,4)]),
                 plot = FALSE,
                 legendloc = "bottomleft",col = cols[1:i], lty = 1, pch = NULL)


#### 3. HnL discard comparisons
#mods <- c(
#   "2019" = here("models", "2019 base model", "Base_45_new"),
#   "update landings",
#   "update dicards (BT, MWT, HNL)",
#   "update dicards + comps(BT, MWT, HNL)",
#   "add HNL disc to landigns, remvoe HNL comps",
#   
# )

models <- c(
  "2019 model" = here("models","2019 base model","Base_45_new"),
#  "update catch" = here(databridge_dir, "add_catches"),
 # "update trawl disc. amnt." = here(databridge_dir, "add_discard_amounts_bt_mwt_2025_hnl_2019"),
  "update trawl,Hnl disc. amnt + comps." = here(databridge_dir, "add_discard_amounts_bt_mwt_hnl_2023_new_comps"),
 # "drop HnL disc. comp, add amnt to landings" = here(databridge_dir, "add_discard_comps_bt_mwt_2023_hnl_removed"),
  "2025 base model" = here("models","2025 base model")
)

combined_models_list <- SSgetoutput(dirvec = models)

names(combined_models_list) <- names(models) #name the replists
model_summary <- SSsummarize(combined_models_list)

dir.create(plotdir <- here("figures","presentation_plots","hnl_disc_comparison"))

SSplotComparisons(
  model_summary, plotdir = plotdir,
  legendlabels = names(models), filenameprefix = "bridging_HnL_", 
  legendloc = "bottomleft", subplots = c(1:2), 
  plot = T, png = TRUE,col = cols
)

SSplotComparisons(
  model_summary, plotdir = plotdir,
  legendlabels = names(models), filenameprefix = "bridging_HnL_", 
  legendloc = "topleft", subplots = c(3,9:12), 
  plot = T, png = TRUE, col = cols
)

##Zooomed in plot of recent recruitments
model_summary_zoomed <- model_summary
model_summary_zoomed$startyrs <- 2015

SSplotComparisons(
  model_summary_zoomed, plotdir = plotdir,
  legendlabels = names(models), filenameprefix = "bridging_HnL__zoomed_rec", 
  legendloc = "topright", subplots = 9, 
  plot = T, png = TRUE, col = cols, xlim = c(2010,2024)
)



SS_plots(SS_output(here("models","model_bridging","mortality")),plot = 9,printfolder = "discard")



### Comparing the indices





#####
## 2019, 2025 model Estimate comparisoon
####




# Create summary and comparison table
here("models","2015_model","7.08_Widow2015_STARbase")
D:\widow_asessment_2025_fork\widow-assessment-update\models\2015_model\7.08_Widow2015_STARbase
rep_2015 <- SS_output(C:\Users\Michael Kinneen\Downloads\2015 model-20250806T211017Z-1-001.zip\2015 model\7.08_Widow2015_STARbase)
summ <- SSsummarize(biglist = list(rep_2019, rep_2025))
comp_table <- SStableComparisons(summaryoutput = summ,likenames = NULL, names = c( "Recr_Virgin",
                                                                      "R0",
                                                                      "steep",
                                                                      "NatM",
                                                                      "L_at_Amax",
                                                                      "L_at_Amin",
                                                                      "VonBert_K",
                                                                  "CV_young","CV_old",
                                                                      "SSB_Virg"), modelnames = c("base 2019", "base 2025"))
rownames(comp_table) <- c("Virgin recruitment (millions)","log(R0)","Steepness","Natural Mortality(Female)","Natural Mortality(Male)",
                          "Length at Amax (Male)","Length at Amax (Female)","Length at Amin (Male)","Length at Amin (Female)",
                          "Von Bert K (Female)","Von bert K (Male)","CV young (Female)","CV young (Male)","CV old (Female)","CV old (Male)","Virgin SSB (1000 mt)")
# Convert row names to a column (e.g., "Comparison")
comp_table <- rownames_to_column(as.data.frame(comp_table), var = "Parameter")

num_cols <- names(comp_table)[3:ncol(comp_table)]

# First, identify which row is row 10 (last row)
last_row <- comp_table[nrow(comp_table), ]

comp_table <- comp_table %>%
  slice(-n()) %>%  # Remove the last row temporarily
  add_row(last_row, .after = 1) %>%  # Insert it after row 1 (making it row 2)
  mutate(across(all_of(num_cols), ~ round(as.numeric(.x), 3))) %>%
  mutate(`% change` = round(-100*(1 - `base 2025`/`base 2019`), 2))|>
  mutate(`% change` = if_else(`% change` > 0,paste0("+", as.character(`% change`)),as.character(`% change`)))
# Define formatting function
port_tab_style <- function(ft, wd = 1) {
  ft %>% 
    font(fontname = "Times New Roman", part = "all") %>%
    fontsize(size = 9, part = "all") %>% 
    bold(part = "header") %>%
    hline(part = "header") %>%
    hline_top(part = "header") %>% 
    hline_bottom() %>%
    align(align = "center", part = "header") %>%
    align(align = "center", part = "body") %>%
    width(width = wd)
}

# Create flextable including the new "Comparison" column
ft <- flextable(comp_table[-1,], col_keys = c("Parameter", "base 2019", "base 2025","% change")) %>%
  colformat_num(
    j = c("base 2019", "base 2025","% change"),
    big.mark = ",",
    digits = 0
  ) %>%
  port_tab_style(wd = 0.8) %>%                     # Apply general style first
  width(j = "Parameter", width = 2.5)   

doc <- read_docx() %>%
  body_add_flextable(ft)

print(doc, target = here("figures","presentation_plots","comparison_table.docx"))




### Diagnostics plots/





nat_m_res_2025 <- read.csv(here("models","diagnostics","2025 base model_profile_NatM_uniform_Fem_GP_1","NatM_uniform_Fem_GP_1_results.csv"))
mod_lik <- min(nat_m_res_2025$likelihood)
nat_m_res_2019 <- data.frame(
  diff_ll =  c( 32.7,23.8,17.3,12.80,10.10,8.90,8.80,9.80,11.90,14.80)-8.80,
  parameter_value = c(0.091,0.102,0.113,0.124,0.135,0.145,0.156,0.167,0.178,0.189),
  source = "2019"
)

nat_m_res_2025|>
  mutate(diff_ll = likelihood - mod_lik)|>  # Keep original (no inversion)
  mutate(source = "2025")|>
  select(diff_ll,parameter_value,source)|>
  rbind(nat_m_res_2019)|>  # No inversion needed for 2019 data either
  
  ggplot(aes(x = parameter_value, y = diff_ll, col = source))+
  geom_point(size = 2)+
  geom_path(lwd = 1)+
  geom_hline(yintercept = 1.92, linetype = "dashed", color = "black", size = 0.5)+
  annotate("text", x = Inf, y = 1.92, label = "95% CI", 
           hjust = 1.1, vjust = -0.5, size = 3.5, color = "black")+
  xlab("Natural Mortality (Female)")+
  ylab(expression(Delta * " Negative log-likelihood"))+
  ggtitle("Comparison of likelihood profiles over M")+
  theme_minimal()+
  theme(
    plot.title = element_text(hjust = 0.5),
    legend.title = element_blank()
  )+
  ylim(c(-1, 30))+
  scale_colour_manual(name = "Model", values = paletteer::paletteer_d("yarrr::xmen"))
  
ggsave(here("figures","presentation_plots","M_like_prof_2019_2025.png"))
nat_m_res_2025|>
  mutate(diff_ll = (likelihood - mod_lik) * -1)|>  # Multiply by -1 to invert
  mutate(source = "2025")|>
  select(diff_ll,parameter_value,source)|>
  # Also need to invert the 2019 data
  rbind(nat_m_res_2019 |> mutate(diff_ll = diff_ll * -1))|>
  
  ggplot(aes(x = parameter_value, y = diff_ll, col = source))+
  geom_point(size = 2)+
  geom_path(lwd = 1)+
  geom_hline(yintercept = -1.92, linetype = "dashed", color = "black", size = 0.5)+  # Also invert the CI line
  annotate("text", x = Inf, y = -1.92, label = "95% CI", 
           hjust = 1.1, vjust = 1.5, size = 3.5, color = "black")+  # Adjust vjust
  xlab("Natural Mortality (Female)")+
  ylab(expression(Delta * " Negative log-likelihood"))+  # Add delta symbol here
  ggtitle("Comparison of likelihood profiles over M")+
  theme_minimal()+
  theme(
    plot.title = element_text(hjust = 0.5),
    legend.title = element_blank()
  )+
  ylim(c(-30, 1))+  # Flip the y-limits too
  scale_colour_manual(name = "Model", values = paletteer::paletteer_d("yarrr::xmen"))



# nat_m_res_male_2025 <- read.csv(here("models","diagnostics","2025 base model_profile_NatM_uniform_Mal_GP_1","NatM_uniform_Mal_GP_1_results.csv"))
# mod_lik <- min(nat_m_res_male_2025$likelihood)
# nat_m_res_mal_2019 <- data.frame(
#   diff_ll =  c( 32.7,23.8,17.3,12.80,10.10,8.90,8.80,9.80,11.90,14.80,18.50)-8.80,
#   parameter_value = c(0.091,0.102,0.113,0.124,0.135,0.145,0.156,0.167,0.178,0.189,0.2),
#   source = "2019"
# )
# 
# nat_m_res_male_2025|>
#   mutate(diff_ll = likelihood - mod_lik)|>
#   mutate(source = "2025")|>
#   select(diff_ll,parameter_value,source)|>rbind(nat_m_res_mal_2019)|>
#   
#   ggplot(aes(x = parameter_value, y = diff_ll, col = source))+
#   geom_point(size = 2)+
#   geom_path(lwd = 1)+
#   geom_hline(yintercept = 1.92, linetype = "dashed", color = "black", size = 0.8)+
#   annotate("text", x = Inf, y = 1.92, label = "95% CI", 
#            hjust = 1.1, vjust = -0.5, size = 3.5, color = "black")+
#   xlab("Natural Mortality (Female)")+
#   ylab("Change in -log-likelihood")+
#   ggtitle("Comparison of likelihood profiles over M")+
#   theme_minimal()+
#   theme(
#     plot.title = element_text(hjust = 0.5),
#     legend.title = element_blank()
#   )+
#   ylim(c(-1,30))
# ggsave(here("figures","presentation_plots","M_like_prof_2019_2025.png"))
# 







#Nat M profile F
# Just plotting total liklihood for nat M 




### Comparison with 2019
compare_ss3_mods(replist = list(rep_2019,rep_2025),
                 plot_dir = here("figures","presentation_plots","compare_2025_2019"),
                 plot_names = c("2019","2025"))


## Comparison with 2019 and 2025
compare_ss3_mods(replist = list(rep_2015,rep_2019,rep_2025),
                 plot_dir = here("figures","presentation_plots","compare_2025_2019_2015"),
                 plot_names = c("2015","2019","2025"))

#zoomed_rec
##Zooomed in plot of recent recruitments


compare_ss3_mods(replist = list(rep_2015,rep_2019,rep_2025),
                 plot_dir = here("figures","presentation_plots","compare_2025_2019_2015"),
                 plot_names = c("2015","2019","2025"), xlim = c(2010, 2025), legendloc = "topright", subplots = 9,"rec_zoomed", clear_dir = F)


#What is mean rec ago 0 ?
# Filter data for all datasets
rep_2025_filtered <- rep_2025$recruit[rep_2025$recruit$Yr > 2010 & rep_2025$recruit$Yr <= 2025, ]
rep_2019_filtered <- rep_2019$recruit[rep_2019$recruit$Yr > 2010 & rep_2019$recruit$Yr <= 2019, ]
rep_2015_filtered <- rep_2015$recruit[rep_2015$recruit$Yr > 2010 & rep_2015$recruit$Yr <= 2015, ]

# Calculate averages
avg_2025 <- mean(rep_2025_filtered$pred_recr)
avg_2019 <- mean(rep_2019_filtered$pred_recr)
avg_2015 <- mean(rep_2015_filtered$pred_recr)

# Create the plot with y-axis in millions - suppress original y-axis
plot(x = rep_2025_filtered$Yr, 
     y = rep_2025_filtered$pred_recr, 
     type = 'l', 
     col = "green",
     xlab = "Year",
     ylab = "Age-0 Recruits (millions)",
     ylim = c(0, max(c(rep_2025_filtered$pred_recr, rep_2019_filtered$pred_recr, rep_2015_filtered$pred_recr))),
     yaxt = "n")

# Add other lines
lines(x = rep_2019_filtered$Yr, 
      y = rep_2019_filtered$pred_recr, 
      col = "red")

lines(x = rep_2015_filtered$Yr, 
      y = rep_2015_filtered$pred_recr, 
      col = "blue")

# Add dashed horizontal lines for averages
abline(h = avg_2025, col = "green", lty = 2)
abline(h = avg_2019, col = "red", lty = 2)
abline(h = avg_2015, col = "blue", lty = 2)

# Add custom y-axis tick marks
axis(2, at = c(0, 50000, 100000, 150000, 200000, 250000), labels = c(0, 50, 100, 150, 200, 250))

# Add legend
legend("topright", 
       legend = c("2025", "2019", "2015"), 
       col = c("green", "red", "blue"), 
       lty = 1, 
       lwd = 2)


## Projected plots of catch
dir.create(forc_ssb_dir <- here("figures","presentation_plots","ssb_projection"))
SS_plots(replist = rep_2025,plot = c(3,7),forecastplot = T,dir = forc_ssb_dir)




### All surevy indices - single panel 
dir <- "D:/widow-index-test/figures/2025 base model r4ss plots/plots"

ind_bt <- image_read(file.path(dir,"index5_logcpuefit_BottomTrawl.png"))
ind_hke <- image_read(file.path(dir,"index5_logcpuefit_Hake.png"))
ind_juv <- image_read(file.path(dir,"index5_logcpuefit_JuvSurvey.png"))
ind_tri <- image_read(file.path(dir,"index5_logcpuefit_Triennial.png"))
ind_wcgbt <- image_read(file.path(dir,"index5_logcpuefit_WCGBTS.png"))
ind_fas <- image_read(file.path(dir,"index5_logcpuefit_ForeignAtSea.png"))

# Add titles to each plot
ind_bt_titled <- image_annotate(ind_bt, "Bottom Trawl", 
                                size = 60, color = "black", 
                                gravity = "north", location = "+0+1" ,weight = 700)
ind_hke_titled <- image_annotate(ind_hke, "Hake Survey", 
                                 size = 60, color = "black", 
                                 gravity = "north", location = "+0+1" ,weight = 700)
ind_juv_titled <- image_annotate(ind_juv, "Juvenile Survey", 
                                 size = 60, color = "black", 
                                 gravity = "north", location = "+0+1" ,weight = 700)
ind_tri_titled <- image_annotate(ind_tri, "Triennial Survey", 
                                 size = 60, color = "black", 
                                 gravity = "north", location = "+0+1" ,weight = 700)
ind_wcgbt_titled <- image_annotate(ind_wcgbt, "WCGBTS Survey", 
                                   size = 60, color = "black", 
                                   gravity = "north", location = "+0+1" ,weight = 700)
ind_fas_titled <- image_annotate(ind_fas, "Foreign At-Sea", 
                                 size = 60, color = "black", 
                                 gravity = "north", location = "+0+1" ,weight = 700)

# Create left column (3 plots stacked vertically)
left_column <- image_append(c(ind_bt_titled, ind_hke_titled, ind_juv_titled), stack = TRUE)
# Create right column (3 plots stacked vertically)  
right_column <- image_append(c(ind_tri_titled, ind_wcgbt_titled, ind_fas_titled), stack = TRUE)
# Combine the two columns side-by-side
combined <- image_append(c(left_column, right_column), stack = FALSE)
image_write(combined, path = here("figures","presentation_plots","combined_log_indices.png"))



## Par ests plots

# Load required libraries
library(ggplot2)
library(dplyr)

# Create the data frame
fisheries_data <- data.frame(
  Parameter = c(
    "Virgin SSB (1000 mt)",
    "log(R0)",
    "Steepness", 
    "Natural Mortality (Female)",
    "Natural Mortality (Male)",
    "Length at Amax (Male)",
    "Length at Amax (Female)",
    "Length at Amin (Male)",
    "Length at Amin (Female)",
    "Von Bert K (Female)",
    "Von Bert K (Male)",
    "CV young (Female)",
    "CV young (Male)",
    "CV old (Female)",
    "CV old (Male)"
  ),
  Percent_Change = c(-2.88, -3.29, 0, -15.28, -12.9, -1.78, -1.29, -0.84, -0.78, 
                     5.23, 3.81, 9.43, 10.47, 9.09, 3.7),
  Base_2019 = c(87.995, 10.813, 0.720, 0.144, 0.155, 50.391, 44.179, 20.832, 21.183,
                0.172, 0.236, 0.106, 0.086, 0.044, 0.054),
  Base_2025 = c(85.461, 10.457, 0.720, 0.122, 0.135, 49.492, 43.608, 20.658, 21.018,
                0.181, 0.245, 0.116, 0.095, 0.048, 0.056)
)

# Create color variable for positive/negative changes
fisheries_data$Color <- ifelse(fisheries_data$Percent_Change > 0, "Increase", 
                               ifelse(fisheries_data$Percent_Change < 0, "Decrease", "No Change"))

# Reorder parameters by percent change for better visualization
fisheries_data$Parameter <- reorder(fisheries_data$Parameter, fisheries_data$Percent_Change)

# Create the horizontal lollipop chart
p <- ggplot(fisheries_data, aes(x = Percent_Change, y = Parameter, color = Color)) +
  geom_segment(aes(x = 0, xend = Percent_Change, y = Parameter, yend = Parameter), 
               color = "gray70", linewidth = 0.8) +
  geom_point(size = 3) +
  geom_vline(xintercept = 0, color = "black", linewidth = 0.5) +
  scale_color_manual(values = c("Decrease" = "#ef4444", "Increase" = "#10b981", "No Change" = "#6b7280")) +
  scale_x_continuous(limits = c(-20, 16), expand = expansion(mult = c(0.05, 0.05))) +
  labs(
    title = "Comparison of 2019 and 2025 parameter estimates",
    subtitle = " ",
    x = "% Change",
    y = "Parameter",
    color = NULL
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray20"),
    axis.title.x = element_text(size = 12, face = "bold"),
    axis.title.y = element_text(size = 12, face = "bold"),
    axis.text.y = element_text(size = 10),
    axis.text.x = element_text(size = 10),
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 10),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    plot.margin = margin(20, 20, 20, 20)
  ) +
  geom_text(aes(label = paste0(ifelse(Percent_Change > 0, "+", ""), Percent_Change, "%")),
            hjust = ifelse(fisheries_data$Percent_Change >= 0, -0.2, 1.2),
            color = "black", size = 3.5)

# Display the plot
print(p)

ggsave(here("figures","presentation_plots","param_perc_change_2019_2025.png"))



p +  theme(axis.text.y = element_text(size = 10, 
                                face = ifelse(grepl("Natural Mortality", levels(fisheries_data$Parameter)), "bold", "plain")))

ggsave(here("figures","presentation_plots","param_perc_change_2019_2025_bold_mort.png"))

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
