## install packages
# we need to have all these installed before installing "nwfscDiag"
#install.packages("adnuts", repos = c("https://noaa-fisheries-integrated-toolbox.r-universe.dev", "https://cloud.r-project.org"))
library(adnuts)

#install.packages("renv")
library(renv)
renv::init()

library(r4ss)
library(nwfscSurvey)

#install.packages("remotes")
#remotes::install_github("pfmc-assessments/nwfscDiag")
library(nwfscDiag)
library(here)

### MODEL DIAGNOSTIC ##################################

directory <- here::here("models/model_bridging")
base_model_name <- "2025_base_model"
exe_dir<- "/Users/raquelrd/Desktop/Stock assessment course/Widow_assessment_update/models/model_bridging/2025_base_model"

r4ss::get_ss3_exe(dir = here::here("models/model_bridging", "2025_base_model"))
exe_loc <- here::here(exe_dir, 'ss_osx.exe')

## RUN RETROS
model_settings_retros <- get_settings(
  settings = list(
    base_name = base_model_name,
    exe= exe_loc,
    run = "retro",
    verbose = TRUE,
    retro_yrs = -1:-5)
)

run_diagnostics(mydir = directory, model_settings = model_settings_retros)

## Re-RUN with uncertainty (not neede)
retros<- list.dirs("/Users/raquelrd/Desktop/Stock assessment course/Widow_assessment_update/models/model_bridging/2025_base_model_retro_5_yr_peel/retro")[-1]

for (i in 1:length(retros)) {
  r4ss::run(
    dir = retros[i],
    exe = "ss_osx",
    #extras = "-nohess",
    show_in_console = TRUE,
    skipfinished = FALSE
  )
}

## PLOT RETROS (with uncertainty)
mydir <- here::here("models/model_bridging/2025_base_model_retro_5_yr_peel/")

retroModels <- SSgetoutput(
  dirvec = file.path(mydir, "retro", paste("retro", -1:-5, sep = "")))

retroSummary <- SSsummarize(retroModels)
endyrvec <- retroSummary[["endyrs"]] + -1:-5

SSplotComparisons(retroSummary,
                  endyrvec = endyrvec,
                  legendlabels = paste("Data", -1:-5, "years"), print = TRUE, png = TRUE,plotdir = here(mydir,"plots"))

