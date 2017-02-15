#### function for multiplying different other functions

multiply <- function(FUN, 
                     group, 
                     par = list(), 
                     data = kornumsatz, 
                     current.storage = TRUE, 
                     reduce = FALSE,
                     test = FALSE) {
  
  if (is.data.frame(data) == FALSE)
    stop("data must be a data frame with 10 columns. For details type help(prepare).")
  dates <- data$Datum
  products <- data$Produkt
  comul.change <- data$MengeKum
  food.storage <- data$Bestand_Einheit
  VPE <- data$VPE
  
  
  # security checks first: 
  # Only factors are allowed for the vector of products!
  if (is.factor(products) == FALSE) 
    stop("Vector of products has to be a factor")
  
  lev <- levels(products)
  group_size = length(group)
  if (length(unique(group %in% lev)) !=1 && unique(group %in% lev) != TRUE)
    stop("Vector of products has to contain ALL name.of.product[s]")
  
  #if (FUN == "prepare") {
    if (length(par) == 0) {
      par <- list(what.plotting = "Warenbestand", from = "", to = "", more.than = 15, correction = 0.05)
    } else {
      necessary <- c("what.plotting", "from", "to", "more.than", "correction")
      if (!(names(par) %in% necessary)) 
        stop("par must be a list consisting of following arguments: what.plotting, from, to, more.than, correction")
    }
    
    if (par$what.plotting == "Warenbestand") {
      for (i in 1:group_size) {
        if (i == 1) {
          table <- prepare(group[i], par$what.plotting, par$from, par$to, par$correction, par$more.than, current.storage = current.storage)
          colnames(table)[3] <- group[i]
        } else {
          new.column <- prepare(group[i], par$what.plotting, par$from, par$to, par$correction, par$more.than, current.storage = current.storage)[,3]
          if (nrow(table) != length(new.column)) 
            stop("products of this group have not the same length")
          table <- cbind(table, new.column = new.column)
          colnames(table)[i + 2] <- group[i]
        } 
      }
      
      if (reduce == TRUE) table <- data.frame(Datum = table[,1], 
                                               Warenbestand = rowSums(table[, 3:ncol(table)]))
      
      if (reduce == FALSE && current.storage == TRUE) {
        Warenbestand <- t(table[,-c(1,2)])
        colnames(Warenbestand)[1] <- "Kilo"
        #return(class(Warenbestand))
        full <- Warenbestand[Warenbestand[,1] > 0.03, ]
        empty <- Warenbestand[Warenbestand[,1] <= 0.03, ]
        if (length(empty) == 1) {
          all.names <- names(Warenbestand[,1])
          names.full <- names(full)
          empty <- suppressWarnings(all.names[!all.names == names.full])
        }
        return(list(Warenbestand = full, Leer = empty, Datum = table$Datum[1]))
      }
    }
    
  
    if (test == TRUE) return("yes")
    return(table)
  #}
}