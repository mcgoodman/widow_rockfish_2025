

#' Function to install SS3 on OSX X68
#' @param dir directory to install SS3 in
#' @param url URL for SS3 OSX x86 executable
#' @param ... Other arguments to `r4ss::get_ss3_exe`
#'
#' @return string with ss executable name
set_ss_macos_x86 <- function(dir, url="https://github.com/nmfs-ost/ss3-source-code/releases/download/v3.30.23.1/ss3_osx", ...) {
  
  # Get and set filename for SS3 exe
  ss3_exe <- c("ss_osx")
  ss3_check <- vapply(ss3_exe, \(x) file.exists(file.path(dir, paste0(x, ".exe"))), logical(1))
  if (!any(ss3_check)) utils::download.file(url, destfile = file.path(dir, "ss3"), mode = "wb") #r4ss::get_ss3_exe(dir, ...)
  ss3_exe <- ss3_exe[which(vapply(ss3_exe, \(x) file.exists(file.path(dir, paste0(x, ".exe"))), logical(1)))]
  return("ss_osx")
}

#' Wrapper for r4ss::get_ss3_exe to check for, download, and return name of SS3 exe file
#' @param dir directory to install SS3 in
#' @param ... Other arguments to `r4ss::get_ss3_exe`
#'
#' @return Character string with name of downloaded SS3 exe (without extension)
set_ss3_exe <- function(dir, ...) {
  
  if (grepl("x86", sessionInfo()$R.version$platform) & grepl("darwin", sessionInfo()$R.version$os)) {
    return(set_ss_macos_x86(dir, ...))
  } else {
    # Get and set filename for SS3 exe
    ss3_exe <- c("ss", "ss3")
    ss3_exe <- c(ss3_exe, paste0(ss3_exe, ".exe"))
    ss3_check <- vapply(ss3_exe, \(x) file.exists(file.path(dir, x)), logical(1))
    if (!any(ss3_check)) r4ss::get_ss3_exe(dir, ...)
    ss3_exe <- ss3_exe[which(vapply(ss3_exe, \(x) file.exists(file.path(dir, x)), logical(1)))]
    return(ss3_exe)
  }
  
}

#' Function to add new row to parameters by copying another row
#'
#' @param data Data frame (with row names)
#' @param new_row name of new row to add
#' @param ref_row name of reference row to copy values from
#' @param ... Values to override reference with (e.g. )
#'
#' @examples
#' 
#' mtcars |> 
#'   insert_row(
#'     new_row = "Mazda RX4 Wagu", 
#'     ref_row = "Maxda RX4 Wag",
#'     mpg = 100
#'   )
#' 
insert_row <- function(data, new_row, ref_row, ...) {
  
  rownames <- row.names(data)
  
  stopifnot(ref_row %in% rownames(data))
  stopifnot(length(new_row) == 1)
  stopifnot(length(ref_row) == 1)
  stopifnot(all(names(list(...)) %in% names(data)))
  
  ref_clone <- data[ref_row,]
  rownames(ref_clone) <- new_row
  ref_clone <- modifyList(ref_clone, list(...))
  
  do.call(
    "rbind", 
    list(
      data[1:which(rownames == ref_row),], 
      ref_clone, 
      data[(which(rownames == ref_row) + 1):nrow(data),]
    )
  )
  
}

##comapre function

compare_ss3_mods <- function(dirs, replist = NULL, plot_dir, plot_names = NULL, ...){
  
  if(dir.exists(plot_dir)){
    file.remove(list.files(plot_dir,full.names = T)) #create a plot dir
    
  } else {
    dir.create(plot_dir) #create a plot dir
  }
  
  #If a replist is supplied, use that , otherwise read replists from the dirs
  if(is.null(replist)){
    
    replist <- SSgetoutput(dirvec = dirs)
  }
  
  mod_summ <- SSsummarize(biglist = replist) #summarise reports
  
  SSplotComparisons( #plot comparrisons
    mod_summ,
    print = TRUE,
    plotdir = plot_dir,
    legendlabels = plot_names,
    indexPlotEach = TRUE,
    ...
  )
  
  return(plot_dir)
}

#' One-time use function to update SS3 data file for data bridging
#' @param new_dir 
#' @param base_dir 
#' @param new_dat 
#' @param datlist_name 
#' @param assessment_yr 
#' @param run_after_write 
#' @param ss_exe_loc 
#' @param ... 
#'
#' @return silent
update_ss3_dat <- function(new_dir, base_dir = here(wd, 'models', '2019 base model', 'Base_45_new'), new_dat = NULL, datlist_name = NULL, assessment_yr, run_after_write = FALSE, ss_exe_loc = ss3_exe, ...){
  
  temp <- SS_read(base_dir)
  mod_end_yr <- assessment_yr - 1 #data ends year previous
  #update the data
  # data_temp <- new_dat[new_dat$year <= mod_end_yr,] #filter base on model end year
  # 
  # temp[["dat"]][[datlist_name]] <- data_temp #update the object based on data name
  if(!is.null(new_dat)){
    for(i in 1:length(new_dat)){
      dat <- new_dat[[i]]
      data_temp <- dat|>filter(year <= mod_end_yr)
      temp[["dat"]][[datlist_name[[i]]]] <- data_temp #update the object based on data name
      data_temp <- NULL
    }
    
  }
  
  
  temp[["dat"]]["Comments"][1] <- "#C 2025 Widow Rockfish Update Assessment"
  #for extending the model
  cat("base model and new model end years are different, updating input files...")
  dir.create(new_dir)#create the dir
  old_assesment_yr <- temp[["dat"]][["endyr"]] + 1
  
  year_diff <- mod_end_yr-temp[["dat"]][["endyr"]]
  temp[["dat"]][["endyr"]] <- mod_end_yr
  temp[["dat"]][["endyr"]]
  
  #Update the miniumum sample sizes
  temp[["dat"]][["age_info"]][["minsamplesize"]] <- 0.01
  temp[["dat"]][["len_info"]][["minsamplesize"]] <- 0.01
  
  #Update and write the control file
  ctl <- temp$ctl
  ctl$MainRdevYrLast <- 2020
  
  ##Swap lambdas and variacne adjustmne tfactors
  new_var_adj_df <- ctl$lambdas|>
    select(like_comp,fleet,value)|>
    rename(factor = like_comp,fleet = fleet)
  
  #Now set the lambdas to 1
  ctl$lambdas <- ctl$lambdas|>
    mutate(value = 1)
  
  #Now add var adjustment factors data type, fleet, value
  ctl$DoVar_adjust <- 1 # turn on var adjust
  ctl$Variance_adjustment_list <- new_var_adj_df#add vARIANCE ADJUSTMNE TLIST
  
  ##Add the timae varying selex for hake
  if(ctl$N_Block_Designs != 11 ){
    
    ctl$N_Block_Designs <- 11
    ctl$blocks_per_pattern <- c(ctl$blocks_per_pattern ,"blocks_per_pattern_12" = 1)
    ctl$Block_Design[[11]] <- c(1916, 2019)
    
    #Adjust the blocks on hake selx pars 1,2,3
    old_sel_pars <- ctl$size_selex_parms[c("SizeSel_P_1_Hake(3)","SizeSel_P_2_Hake(3)","SizeSel_P_3_Hake(3)"),]
    new_sel_pars <- old_sel_pars|>
      mutate(Block = 11,
             Block_Fxn = 2)
    
    #replace the ctl model ones
    
    #Add some to the trimmed verion
    ctl$size_selex_parms[c("SizeSel_P_1_Hake(3)","SizeSel_P_2_Hake(3)","SizeSel_P_3_Hake(3)"),] <- new_sel_pars
    ctl$size_selex_parms_tv <- rbind(ctl$size_selex_parms_tv[1:24,], #up to midwater sel pars
                                     new_sel_pars[,1:7], # new hake sel pars
                                     ctl$size_selex_parms_tv[25:29,]) #hnl onward sl pars
  }
  
  SS_writectl(ctllist = ctl,here(new_dir,paste0(assessment_yr,"widow.ctl")),overwrite = T)
  
  #Correct names
  ctl <- readLines(list.files(path = here::here(new_dir),pattern = "\\.ctl$",full.names = TRUE))
  ctl <- gsub(paste0(old_assesment_yr,"widow"), "2025widow", ctl)
  writeLines(ctl, here(new_dir, paste0(assessment_yr,"widow.ctl")))
  
  
  
  #updat the starter file 
  strt <- readLines(here(base_dir, "starter.ss"))
  strt <- gsub(paste0(old_assesment_yr,"widow"), paste0(assessment_yr,"widow"), strt)
  writeLines(strt, here(new_dir, "starter.ss"))
  
  #update the forecastr file
  forc <- SS_readforecast(here(base_dir, "forecast.ss"))
  temp[["fore"]][["ForeCatch"]][["year"]] <-  temp[["fore"]][["ForeCatch"]][["year"]]+year_diff
  temp[["fore"]][["Flimitfraction_m"]][["year"]] <-  temp[["fore"]][["Flimitfraction_m"]][["year"]]+year_diff
  
  r4ss::SS_writeforecast(temp[["fore"]],dir = new_dir,overwrite = TRUE)
  
  #update and write the data file
  r4ss::SS_writedat(temp[["dat"]],outfile = here(new_dir,paste0(assessment_yr,"widow.dat")),overwrite= T)
  
  cat("Model files written to: ",new_dir)
  
  #Set the executable
  file.copy(file.path(base_dir,"ss3.exe"),to = file.path(new_dir,"ss3.exe"))
  
  if(run_after_write == TRUE){
    cat("running model...")
    r4ss::run(
      dir = new_dir,
      exe = "ss3",
      show_in_console = T,
      ...
    )
  }
  
  
}

# ##test the function
# update_ss3_dat(new_dir = here(bridge_2_dir,"extend_catch"),new_dat = catch,datlist_name = "catch",assessment_yr = 2025,run_after_write = TRUE,ss_exe_loc = ss3_exe,skipfinished = FALSE)
# 
# update_ss3_dat(new_dir = here(bridge_2_dir,"hist_catch_year"),new_dat = catch,datlist_name = "catch",assessment_yr = 2019,run_after_write = TRUE,ss_exe_loc = ss3_exe,skipfinished = FALSE)
# 
# hist_catch_year <- here(bridge_2_dir,"hist_catch_year")
# #Compare
# compare_ss3_mods(dirs = c(base_dir,hist_catch_year,update_hist_catch_dir),plot_dir = here(bridge_2_dir,"hist_catch_year","compare_plots"),plot_names = c("base_45","fn hist catch","update_hist_catch"))
# 

#' Function to re-weight comp data in stock synthesis model
#' @param model_dir 
#' @param new_weight_dir 
#' @param weight_method 
#' @param weight_mult 
#' @param exe 
#' @param expanded_fleets 
#' @param run_after_write 
#'
#' @return Differences to console
update_model_weights <- function(model_dir, new_weight_dir, weight_method = "MI", weight_mult = 0.5, exe = ss3_exe, expanded_fleets = 1:5, run_after_write = TRUE){
  
  #generate a report from the model
  rep <- r4ss::SS_output(model_dir)
  tune_weights <- r4ss::tune_comps(rep,dir = model_dir,option = weight_method)
  
  new_tune_weights <- tune_weights|>
    select("#factor",fleet,New_Var_adj)|>
    mutate(New_Var_adj = if_else( #if the fleet has been expanded, downweight the data
      fleet %in% expanded_fleets,
      New_Var_adj     * weight_mult,
      New_Var_adj
    ))|>
    rename(like_comp = "#factor")
  
  ## Now read in the ctl file
  base_mod <- SS_read(model_dir)
  old_lambdas <- base_mod$ctl$lambdas
  survey_lambdas <- old_lambdas|> 
    filter(!fleet %in% expanded_fleets)|>
    select(like_comp,fleet,value)
  
  
  
  new_lambdas <- new_tune_weights|>filter(fleet %in% expanded_fleets)|>
    rename(value = New_Var_adj)|>
    rbind(survey_lambdas)|>
    arrange(like_comp)|>
    select(value)
  
  #replace the values
  new_lambda_table <- old_lambdas|> mutate(value = unlist(new_lambdas))
  
  
  base_mod$ctl$lambdas <- new_lambda_table
  
  #Overwrite the model with new ctl file containting lambdas
  r4ss::SS_write(base_mod,new_weight_dir,overwrite = T)
  
  #If requested, re-run the model
  if(run_after_write == TRUE){
    
    r4ss::run(dir = new_weight_dir,
              exe = ss3_exe,
              skipfinished = FALSE,
              extras = "-nohess",
              show_in_console = TRUE)
  }
  
  #Print the differences to the console
  compare_df <- new_lambdas|>
    mutate(value = round(value,3))|>
    rename(new_lambda = value)|>
    cbind("old_lambda" = old_lambdas$value)
  
  print(compare_df)
}
