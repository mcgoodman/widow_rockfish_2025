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

SSplotComps(replist = mod1)
mod1 <- SS_output(dir = dir)
data1 <- SS_readdat(file = here(dir, "2025widow.dat"))
data2 <- SS_readdat(file = here("models","2019 base model","Base_45_new", "2019widow.dat"))

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


# Figure 14: Expanded marginal age compositions from the WCGBTS. 
for(i in 9){
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
      if(dat_sub$year[j] > 0 && dat_sub$Lbin_lo[j] > 0 && dat_sub$sex[j] %in% c(1, 3)){
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
      if(dat_sub$year[j] > 0 && dat_sub$Lbin_lo[j] > 0 && dat_sub$sex[j] %in% c(2, 3)){
        symbols(rep(dat_sub$year[j], length(0:nages)), 0:nages,
                circles = dat[j, grep("m", colnames(dat))],
                inches = inch, add = TRUE)
      }
    }
    
    # Close the PNG device
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
      
      png(filename = here(plot_dir,paste0("discard_fleet", fltsrv, ".png")), width = 1000, height = 600)
      
      par(mfrow = c(2,1), mar = c(4, 4, 3, 2))  # Adjust margins if needed
      
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
    dev.off()
  }
}


####### Figure 28
years <- sort(unique(data2$discard_data$year))
fleets <- sort(unique(data2$discard_data$fleet))
fleets <- 1

fleet_names <- c("Bottom Trawl", "Midwater Trawl", "Hook & Line")
# Start plotting
#pdf("discard_histograms.pdf", width = 8.27, height = 11.69)  # A4 size
png("discard_histograms.png", width = 8.27, height = 11.69, units = "in", res = 300)

layout_matrix <- matrix(1:(length(years) * length(fleets)), 
                        nrow = length(fleets), byrow = TRUE)
layout(layout_matrix)

par(mar = c(2, 2, 1, 1), oma = c(4, 5, 2, 1))  # Set outer margins

disc <- data2$discard_data
for(i in seq_along(fleets)){
  flt <- fleets[i]
  flt_years <- sort(unique(disc[disc$fleet == flt, "year"]))
  for(j in seq_along(flt_years)){
    yr <- flt_years[j]
    hist(disc[disc$fleet == flt & disc$year == yr, "obs"], 
         main = "", xlab = "", ylab = "", axes = FALSE, 
         col = "white", border = "black")
    axis(1, cex.axis = 0.7)
    axis(2, cex.axis = 0.7)
    
    if (i == 1) mtext(yr, side = 3, line = 0.5, cex = 0.8)
    if (j == 1) mtext(fleet_names[i], side = 2, line = 2.5, cex = 0.8)
  }
}

dev.off()

windows()
plot_fleet_histograms(data = disc,plots_per_row = 4,title = "xx")
