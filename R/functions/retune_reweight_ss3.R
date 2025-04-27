#' Retune and Reweight Stock Synthesis 3 Model
#'
#' @description
#' This function performs iterative tuning of composition data in a Stock Synthesis 3 model,
#' followed by optional reweighting to account for double counting of data.
#'
#' @param base_model_dir Character string specifying the path to the base model directory. Default is NULL.
#' @param output_dir Character string specifying the path where output directories will be created. Default is NULL.
#' @param n_tuning_runs Integer specifying the number of tuning iterations to perform. Default is 2.
#' @param tuning_method Character string specifying the tuning method. Options include "MI" (McAllister-Ianelli), 
#'        "Francis", or "harmonic mean". Default is "MI".
#' @param keep_tuning_runs Logical indicating whether to keep intermediate tuning run directories. 
#'        If FALSE, these directories will be deleted. Default is TRUE.
#' @param lambda_weight Numeric value specifying the weight to apply to fleets affected by double counting. 
#'        Default is 0.5.
#' @param marg_comp_fleets Vector of integers specifying which fleet indices should have lambdas adjusted.
#'        Default is c(1,2,3,4,5).
#'
#' @return A data frame containing the tuning information with columns for each tuning run
#'         and the final reweighted values.
#'
#' @details
#' The function performs multiple tuning iterations, storing the variance adjustments from each.
#' After tuning is complete, it applies lambda weights to account for double-counted data
#' in specified fleets. 
#'
#' @examples
#' \dontrun{
#' result <- retune_reweight_ss3(
#'   base_model_dir = "path/to/model",
#'   output_dir = "path/to/output",
#'   n_tuning_runs = 2,
#'   tuning_method = "MI",
#'   keep_tuning_runs = TRUE,
#'   lambda_weight = 0.5,
#'   marg_comp_fleets = 1:5
#' )
#' }
#'
#' @importFrom r4ss run SS_output SS_read SS_write tune_comps
#' @importFrom here here
#' @importFrom dplyr mutate
#'
retune_reweight_ss3 <- function(base_model_dir = NULL, 
                                output_dir = NULL, 
                                n_tuning_runs = 2, 
                                tuning_method = "MI", 
                                keep_tuning_runs = TRUE,
                                lambda_weight = 0.5, 
                                marg_comp_fleets = c(1,2,3,4,5)) {
  
  #' Get the model name from the base directory
  mod_name <- basename(base_model_dir)
  
  #' Lists to store tuning results and directories
  tuning_list <- list()
  tuning_dirs <- list()
  
  #' Perform multiple tuning runs
  for(i in 1:n_tuning_runs) {
    #' Calculate tuning adjustments
    tuning_temp <- tune_comps(replist = SS_output(base_model_dir),
                              dir = base_model_dir, 
                              option = tuning_method)
    
    #' Store base model variance adjustments from first run
    if(i == 1) {
      base_mod_var = tuning_temp$Old_Var_adj
    }
    
    #' Read in the model and update variance adjustments
    model_temp <- SS_read(dir = base_model_dir)
    model_temp$ctl$Variance_adjustment_list$value <- tuning_temp$New_Var_adj
    #' Create directory for this tuning run
    retune_dir <- here(output_dir, paste0(mod_name, "_retune_", i))
    
    #' Write the model to the new directory
    SS_write(inputlist = model_temp, dir = retune_dir, overwrite = TRUE)
    
    #' Copy executable files to the tuning directory
    exe_files <- list.files(base_model_dir, pattern = "\\.exe$", full.names = TRUE)
    exe_name <- basename(exe_files)
    file.copy(exe_files, to = retune_dir)
    
    #' Run the model
    cat(paste0("Starting tuning run ",i,"..."))
    r4ss::run(dir = retune_dir, exe = exe_name, extras = "-nohess",skipfinished = FALSE)
    
    #' Store tuning results and directory paths
    tuning_list[[i]] <- tuning_temp$New_Var_adj
    names(tuning_list[[i]]) <- paste0("tuning run ", i)
    tuning_dirs[[i]] <- retune_dir
  }
  
  #' Apply lambda weighting to account for double counting of data
  model_temp <- SS_read(dir = retune_dir)  # Use the last tuning directory
  model_temp$ctl$lambdas <- model_temp$ctl$lambdas |>
    mutate(value = ifelse(fleet %in% marg_comp_fleets, lambda_weight, value))
  
  #' Create directory for reweighted model
  reweight_dir <- here(output_dir, paste0(mod_name, "_reweighted"))
  
  #' Write the reweighted model
  SS_write(inputlist = model_temp, dir = reweight_dir, overwrite = TRUE)
  
  #' Copy executable files and run the reweighted model
  file.copy(exe_files, to = reweight_dir)
  cat(paste0("Starting re-weighting (lambda adjustment) run...."))
  r4ss::run(dir = reweight_dir, exe = exe_name, extras = "-nohess", skipfinished = TRUE)
  
  #' Delete tuning directories if requested
  if(keep_tuning_runs == FALSE) {
    lapply(tuning_dirs, unlink, recursive = TRUE)
  }
  
  #' Create output data frame with tuning results
  out_df <- as.data.frame(cbind(
    "data comp" = tuning_temp$`#factor`,
    "fleet" = tuning_temp$fleet,
    "fleet name" = tuning_temp$Name,
    "base mod VarAdj" = base_mod_var
  ))
  
  #' Add columns for each tuning run
  for (i in 1:length(tuning_list)) {
    column_name <- paste0("tuning_run_", i)
    out_df[[column_name]] <- unlist(tuning_list[[i]])
  }
  
  #' Add reweighted variance adjustment column
  out_df$`Reweighted var adj` = model_temp$ctl$Variance_adjustment_list$value * 
    model_temp$ctl$lambdas$value
  
  #' Add tuning method information
  out_df$`tuning method` = tuning_method
  
  return(out_df)
}
