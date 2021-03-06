#' @export
# Plotten mit myPlot funktion ####
plotStorage <- function(prepare,
                       prod.name.for.plot = "",
                       smoother = c("loess", "loess"),
                       span = c(0.1, 0.1),
                       degree = c(1,1),
                       pch = c(16, 16),
                       col_points = c(rgb(red=0.2, green=0.2, blue=0.2, alpha=0), rgb(red=0.2, green=0.2, blue=0.2, alpha=0)), # invisible/transparent points
                       col_line = c("black", "black"),
                       lwd = c(2,2),
                       lty = c(1,2),
                       axis_side = c(2,4),
                       las = c(1,1),
                       line = c(3,3),
                       mfrow = c(1,1),
                       mar = c(4, 5, 4, 1) + 0.1,
                       add = FALSE,
                       cex.axis = 1.3,
                       cex.lab = 1.6,
                       cex.main = 1.6){
  
  # at first: check if the input is correct ####
    if (is.list(prepare) != TRUE) stop("prepare has to be a list: first element $data is a data frame, second element $name.of.product is a character string")
    if (is.data.frame(prepare[[1]]) != TRUE) stop("prepare=list[[1]] has to be a data frame")
  
  # set structure of data ####
  data <- prepare[[1]]
  name.of.product <- prepare[[2]]
  Datum <- data[,1]
  Tag_Nr <- data[,2]
  if (length(prepare) == 3) name.of.group <- prepare[[3]]
  
  # continue checking ####
    # possibilites for data/plotting
    pos <- c("Verzehr", "Warenbestand")
    if (isTRUE(colnames(data)[3] %in% pos) == FALSE) 
      stop("The 3rd column of your data frame has to be a character: Verzehr or Warenbestand")
  
  if (ncol(data) == 3) {
    if (smoother[1] == "loess") {
      lo <- loess(data[,3] ~ Tag_Nr, span = span[1], degree = degree[1])
      preds <- predict(lo)
    }
    
    # What do we have
    if (prod.name.for.plot == "") {
      warning("Main will look better if you give the product's name in prod.name.for.plot")
      if (add == FALSE) par(mfrow = mfrow, mar = mar) 
      plot(x = Datum, 
           y = data[,3], 
           xaxt = "n", 
           yaxt = "n", 
           ylab = "", 
           xlab = "", 
           ylim = c(range(preds)[1] - 0.2, range(preds)[2] + 0.2), 
           pch = pch[1], 
           main = paste(paste(colnames(data)[3], "von"), name.of.product), 
           col = col_points[1],
           cex.main = cex.main)
      } else {
        if (add == FALSE) par(mfrow = mfrow, mar = mar) 
        plot(x = Datum, 
             y = data[,3], 
             xaxt = "n", 
             yaxt = "n", 
             ylab = "", 
             xlab = "", 
             ylim = c(range(preds)[1] - 0.2, range(preds)[2] + 0.2), 
             pch = pch[1], 
             main = paste(paste(colnames(data)[3], "von"), prod.name.for.plot), 
             col = col_points[1],
             cex.main = cex.main)
      } # for lazy people filled prod.name.for.plot is not necessary!
      
      # now lines are drawed
      lines(x = Datum, y = preds, col = col_line[1], lwd = lwd[1], lty = lty[1])
      
      # and the y-axis gets a scription
      axis(side = axis_side[1], las = las[1], cex.axis = cex.axis)
      mtext(text = paste(colnames(data)[3], "in Kilo"), side = axis_side[1], line = line[1], cex = cex.lab)
    
  } # normally necessary
  
  if (ncol(data) == 4) {
    Warenbestand <- data[,3]
    Verzehr <- data[,4]
    
    # berechnen der zukünftigen Warenbestandskurve
    if (smoother[1] == "loess") {
      lo_waren <- loess(Warenbestand ~ Tag_Nr, span = span[1], degree = degree[1])
      preds_waren <- predict(lo_waren)
    }
    
    # build an empty plot
    par(mfrow=c(1,1), mar=c(2,6,2,6)+0.1)
    
    if (prod.name.for.plot == "") {
      warning("Main will look better if you give the product's name in prod.name.for.plot")
      if (add == FALSE) par(mfrow = mfrow, mar = mar) 
      plot(x = Datum, 
           y = Warenbestand, 
           xaxt = "n", 
           yaxt = "n", 
           ylab = "", 
           xlab = "", 
           ylim = c(range(preds_waren)[1] - 0.2, range(preds_waren)[2] + 0.2), 
           pch = pch[1], 
           main = paste("Warenbestand & Verzehr von", name.of.product), 
           col = col_points[1],
           cex.main = cex.main)
    } else {
      if (add == FALSE) par(mfrow = mfrow, mar = mar) 
      plot(x = Datum, 
           y = Warenbestand, 
           xaxt = "n", 
           yaxt = "n", 
           ylab = "", 
           xlab = "", 
           ylim = c(range(preds_waren)[1] - 0.2, range(preds_waren)[2] + 0.2), 
           pch = pch[1], 
           main = paste("Warenbestand & Verzehr von", prod.name.for.plot), 
           col = col_points[1],
           cex.main = cex.main)
    } # for lazy people filled prod.name.for.plot is not necessary!
    
    # now storage is getting drawed
    lines(x = Datum, y = preds_waren, col = col_line[1], lwd = lwd[1], lty = lty[1])
    
    # (left) y-axis gets its scription
    axis(side = axis_side[1], las = las[1], cex.axis = cex.axis)
    mtext(text = "Warenbestand in Kilo", side = axis_side[1], line = line[1], cex = cex.lab)
    
    # consumption is added
    par(new=TRUE)
    # predict the consumption
    if (smoother[2] == "loess") {
      lo_verzehr <- loess(Verzehr ~ Tag_Nr, span = span[2], degree = degree[2])
      preds_verzehr <- predict(lo_verzehr)
    }
    plot(x = Datum, 
         y = Verzehr, 
         xaxt = "n", 
         yaxt = "n", 
         ylab = "", 
         xlab = "", 
         ylim = c(range(preds_verzehr)[1], range(preds_verzehr)[2] + 0.2), 
         pch = pch[2], 
         main = "", 
         col = col_points[2])
    # now consumption is getting drawen
    lines(x = Datum, y = preds_verzehr, col = col_line[2], lwd = lwd[2], lty = lty[2])
    
    # (right) y-axis gets its scription
    axis(side = axis_side[2], las = las[2], cex.axis = cex.axis)
    mtext(text = "Verzehr in Kilo", side = axis_side[2], line = line[2], cex = cex.lab)
    
    legend("topleft", lty=c(lty[1], lty[2]), legend=c("Warenbestand", "Verzehr"), lwd=c(lwd[1], lwd[2]), col=c(col_line[1], col_line[2]))
  } # only needed if consumption and storage shall be plotted in one plot
  
  
  
  
  # now the x-axis gets a scription
  start_1st_date <- min(Datum)
  day(start_1st_date) <- 01
  if (month(start_1st_date) == 12) year(start_1st_date) <- year(start_1st_date) + 1
  else month(start_1st_date) <- month(start_1st_date) + 1
  end_date <- max(Datum)
  date1st <- seq(from = as.Date(start_1st_date), to = end_date, by = '1 month')
  # do the writing!
  axis(1, at=date1st, labels=month.abb[month(as.POSIXlt(date1st, format="%Y-%m-%d"))], cex.axis = cex.axis) # as.posix gives the month in number, month.abb changes the month' number in the first 3 letters; month would give the whole month' name    
      
}