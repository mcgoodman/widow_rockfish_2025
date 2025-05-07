# May 2019 - Grant Adams
# Adapted May 2024 Mico Kinneen
library(r4ss)
library(data.table)
library(here)
####################################################
## GET BASE CASE VALUES FOR ASSESSMENT
####################################################
# directories where models were run need to be defined
# oldwd <- getwd()
# setwd("../") # Move back one
dir = here("models","2025 base model")
plot_dir <- here("figures","composition_plots")
dir.create(plot_dir)

mod1 <- SS_output(dir = dir)
data1 <- SS_readdat(file = here(dir, "2025widow.dat"))
data1$lencomp->xx

fleet_names <- data1$fleetinfo$fleetname
# Plot age comp
for(i in 1:length(unique(data1$agecomp$fleet))){
  fltsrv <- sort(unique(data1$agecomp$fleet))[i]
  flt_name <- fleet_names[i]
  
  if(fltsrv > 0){
    dat_sub <- data1$agecomp[data1$agecomp$fleet == fltsrv, ]
    dat_sub <- dat_sub[dat_sub$year > 0, ]
    dat_sub <- dat_sub[dat_sub$part %in% c(0, 2), ]
    
    ylab <- "Ages"; xlab <- "Year"
    nages <- 40
    x <- as.numeric(as.character(dat_sub$year))
    dat <- dat_sub[, 10:ncol(dat_sub)]
    inch <- 0.15
    y <- as.numeric(substring(names(dat), 2))
    y <- y[1:nages]
    xlim <- range(x)
    
    # Save plot to file
    png(filename = here(plot_dir,paste0("agecomp_fleet_", fltsrv, ".png")), width = 1000, height = 600)
    
    par(mfrow = c(2,1), mar = c(4, 4, 3, 2))  # Adjust margins if needed
    
    # Female plot
    name <- "Female"
    plot(NA, NA, xlab = xlab, ylab = ylab, xlim = xlim, ylim = c(0, nages),
         main = paste(name, fltsrv), cex.main = 1.5)
    
    for(j in 1:nrow(dat_sub)){
      if(dat_sub$year[j] > 0 && dat_sub$Lbin_lo[j] < 0 && dat_sub$sex[j] %in% c(1, 3)){
        symbols(rep(dat_sub$year[j], length(0:nages)), 0:nages,
                circles = dat[j, grep("f", colnames(dat))],
                inches = inch, add = TRUE)
      }
    }
    
    # Male plot
    name <- "Male"
    plot(NA, NA, xlab = xlab, ylab = ylab, xlim = xlim, ylim = c(0, nages),
         main = paste(name, fltsrv), cex.main = 1.5)
    
    for(j in 1:nrow(dat_sub)){
      if(dat_sub$year[j] > 0 && dat_sub$Lbin_lo[j] < 0 && dat_sub$sex[j] %in% c(2, 3)){
        symbols(rep(dat_sub$year[j], length(0:nages)), 0:nages,
                circles = dat[j, grep("m", colnames(dat))],
                inches = inch, add = TRUE)
      }
    }
    
    # Close the PNG device
    dev.off()
  }
}

# Total age historgrams
dat_sub <- data1$agecomp[which(data1$agecomp$fleet > 0),]
dat_sub <- dat_sub[which(dat_sub$year > 0),]
dat <- dat_sub[,10:ncol(dat_sub)]
fdat <- dat[,grep("f", colnames(dat))]
mdat <- dat[,grep("m", colnames(dat))]

par(mfrow = c(2, 1))
# females
plot( y = colSums(fdat), x =  0:40, type = "l", xlab = "Age", ylab = "Number observed", main = "Females")
# males
plot( y = colSums(mdat), x =  0:40, type = "l", xlab = "Age", ylab = "Number observed", main = "Males")

# Plot length comp
for(i in 1:length(unique(data1$lencomp$fleet))){
  fltsrv <- sort(unique(data1$lencomp$fleet))[i]
  if(fltsrv > 0 ){
    dat_sub <- data1$lencomp[which(data1$lencomp$fleet == fltsrv),]
    dat_sub <- dat_sub[which(dat_sub$year > 0),]
    dat_sub <- dat_sub[which(dat_sub$part %in% c(0, 2)),]
    ylab="Length (cm)"; xlab="Year"
    if(nrow(dat_sub) > 0){
      
      nages <- 25
      x <- as.numeric(as.character(dat_sub$year))
      dat <- dat_sub[,7:ncol(dat_sub)]
      inch <- 0.1
      y <- as.numeric(substring(names(dat),2))
      y <- y[1:nages]
      xlim <- range(x)
      
      # Save plot to file
      png(filename = here(plot_dir,paste0("lencomp_fleet_", fltsrv, ".png")), width = 1000, height = 600)
      
      par(mfrow = c(2,1), mar = c(4, 4, 3, 2))  # Adjust margins if needed
      
      name <- "Female"
      plot(NA, NA,xlab=xlab,ylab=ylab,xlim=xlim, ylim = range(y), main = paste(name, "catch", fltsrv))
      for(j in 1:nrow(dat_sub)){
        if(dat_sub$year[j] > 0){
          if(dat_sub$sex[j] %in% c(1, 3)){
            symbols(rep(dat_sub$year[j], nages),y,circles=dat[j,grep("f", colnames(dat))],inches=inch, add = TRUE)
          }
        }
      }
      
      name <- "Male"
      plot(NA, NA,xlab=xlab,ylab=ylab,xlim=xlim, ylim = range(y), main = paste(name, "catch", fltsrv))
      for(j in 1:nrow(dat_sub)){
        if(dat_sub$year[j] > 0){
          if(dat_sub$sex[j] %in% c(2, 3)){
            symbols(rep(dat_sub$year[j], nages),y,circles=dat[j,grep("m", colnames(dat))],inches=inch, add = TRUE)
          }
        }
      }
    }
    dev.off()
    
  }
}




# Plot discard length comp
for(i in 1:length(unique(data1$lencomp$fleet))){
  fltsrv <- sort(unique(data1$lencomp$fleet))[i]
  if(fltsrv > 0 ){
    dat_sub <- data1$lencomp[which(data1$lencomp$fleet == fltsrv),]
    dat_sub <- dat_sub[which(dat_sub$year > 0),]
    dat_sub <- dat_sub[which(dat_sub$part %in% c(1)),]
    ylab="Length (cm)"; xlab="Year"
    if(nrow(dat_sub) > 0){
      
      nages <- 25
      x <- as.numeric(as.character(dat_sub$year))
      dat <- dat_sub[,7:ncol(dat_sub)]
      inch <- 0.1
      y <- as.numeric(substring(names(dat),2))
      y <- y[1:nages]
      xlim <- range(x)
      
      par(mfrow=c(2,1))
      
      name <- "Female"
      plot(NA, NA,xlab=xlab,ylab=ylab,xlim=xlim, ylim = range(y), main = paste(name, "discard", fltsrv))
      for(j in 1:nrow(dat_sub)){
        if(dat_sub$year[j] > 0){
          if(dat_sub$sex[j] %in% c(1, 3)){
            symbols(rep(dat_sub$year[j], nages),y,circles=dat[j,grep("f", colnames(dat))],inches=inch, add = TRUE)
          }
        }
      }
      
      name <- "Male"
      plot(NA, NA,xlab=xlab,ylab=ylab,xlim=xlim, ylim = range(y), main = paste(name, "discard", fltsrv))
      for(j in 1:nrow(dat_sub)){
        if(dat_sub$year[j] > 0){
          if(dat_sub$sex[j] == 2){
            symbols(rep(dat_sub$year[j], nages),y,circles=dat[j,grep("m", colnames(dat))],inches=inch, add = TRUE)
          }
        }
      }
    }
  }
}
