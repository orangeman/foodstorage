prepare <- function(name.of.product,
                    what.plotting = "regression",
                    vec.of.products = kornumsatz$Produkt,
                    vec.of.Dates  = kornumsatz$Datum,
                    vec.of.names = lieferanten_namen,
                    plotting.options = list(comul.change = kornumsatz$MengeKum,
                                            food.storage = kornumsatz$Bestand_Einheit,
                                            VPE = kornumsatz$VPE),
                    from = "",
                    to = "",
                    correction = 0.05, 
                    more.than = 15) {
  
  ##### at first: check if the input is correct! ####
    # for is.Date; cheeck if vec.of.Dates is a Date 
    require(lubridate) 
    if (is.Date(vec.of.Dates) == FALSE) 
      stop("Your vector of Dates has to be in format as.Date()")
  
    # Only factors are allowed for the vector of products!
    if (is.factor(vec.of.products) == FALSE) 
      stop("Vector of products has to be a factor")
    
    # name of product has to be in vector of products!
    lev <- levels(vec.of.products)
    if (length(name.of.product) == 1) {
      if (isTRUE(name.of.product %in% lev) == FALSE) 
        stop("Vector of products has to contain name.of.product")
    } else {
      for (i in 1:length(name.of.product)) {
        if (isTRUE(name.of.product[i] %in% lev) == FALSE) 
          stop("Vector of products has to contain ALL name.of.product[s]")
      }
    }
    
    # possibilites for "what.plotting"
    possibilities <- c("allall", "alles", "Verzehr", "Warenbestand", "regression")
    if (isTRUE(what.plotting %in% possibilities) == FALSE) 
      stop("what.plotting has to be a character: regression, allall, all.verzehr, all.lager, Verzehr or Warenbestand!")
  
  ##### create sortbydays and sortbypos ####
    Datum <- seq(from=range(vec.of.Dates)[1], 
                 to=range(vec.of.Dates)[2], 
                 by="day") 
    Tag_Nr <- 1:length(Datum)
    sortbydays <- data.frame(Datum, Tag_Nr)
    
    # create sortbypos - cbind "Produkt" with "Position" ####
    Position <- 1:length(vec.of.products)
    sortbypos <- data.frame(Position = Position, Produkt = vec.of.products)
    sortbypos <- cbind(sortbypos, Datum = vec.of.Dates[sortbypos$Position])
  
  
  ##### What do you wanna plot? #####
    # only one product or a group?
  if (length(name.of.product) == 1) {
    # first at all: security checks ##
      if (is.numeric(plotting.options$comul.change) == FALSE) 
        stop("To plot consumption, at least daily change is necessary (as data type numeric)")
      if (length(plotting.options$comul.change[sortbypos$Position]) != nrow(sortbypos)) 
        stop("length differ! Probably you didn't specify the product for comulative change")
      # checks only for storage and "all"
      if (what.plotting == "alles" | what.plotting == "Warenbestand" | what.plotting == "regression") {
        if (is.numeric(plotting.options$food.storage) == FALSE) 
          stop("If you want to plott food storage, you need a vector of storage. Of course, same length as the comulative one.")
        if (length(plotting.options$food.storage) != length(vec.of.Dates)) 
          stop("length differ! Probably you didn't specify food storage.")
      } 
    
    #### start here: sortbypos only for name.of.product ####
      sortbypos <- sortbypos[sortbypos$Produkt == name.of.product, ] 
      sortbypos <- cbind(sortbypos, 
                         MengeKum = plotting.options$comul.change[sortbypos$Position])
      if (what.plotting == "alles" | what.plotting == "Warenbestand" | what.plotting == "regression") {
        sortbypos <- cbind(sortbypos,
                           Bestand_Einheit=plotting.options$food.storage[sortbypos$Position]) 
      }
      if (what.plotting == "regression") VPE <- plotting.options$VPE[sortbypos$Position][1]
      
    #### join daily change to sortbypos ####
      # merge sortbypos and sortbydays, by days of course
      require(data.table) # v1.9.5+
      sortbydays <- merge(sortbydays, sortbypos, by='Datum', all=T)
      
      # fill NAs with numbers
      sortbydays$MengeKum[is.na(sortbydays$MengeKum)] <- 0
      if (what.plotting == "alles" | what.plotting == "Warenbestand" | what.plotting == "regression") {
        for (i in 1:nrow(sortbydays)) sortbydays$Bestand_Einheit[i] <- sum(sortbydays$MengeKum[1:i])
      }
      # looking for an error - each row should represent one date ##
      # two same dates behind each other are not allowed ###
      if(class(look.for.errors(sortbydays$Datum, sortbydays, warnings = FALSE)) == "Date") {
        double.date <- look.for.errors(sortbydays$Datum, sortbydays, warnings = FALSE) 
        days.to.correct <- unique(double.date)
        for (i in 1:length(days.to.correct)) {
          sortbydays[sortbydays$Datum == days.to.correct[i],]$MengeKum[1] <- sum(sortbydays[sortbydays$Datum == days.to.correct[i],]$MengeKum) # replace storage changing
          nr <- nrow(sortbydays[sortbydays$Datum == days.to.correct[i],])
          sortbydays <- sortbydays[-which(sortbydays$Datum == days.to.correct[i])[(2:nr)], ]
          sortbydays[sortbydays$Datum == days.to.correct[i],]$Bestand_Einheit <- sortbydays[sortbydays$Datum == days.to.correct[i],]$MengeKum + sortbydays[sortbydays$Datum == days.to.correct[i] - 1,]$Bestand_Einheit # replace food.storage
        }
      }
      
    
      ## make the '5% correction' ##
      if (what.plotting == "regression") {
        Prozent5 <- correction * VPE
        candidates <- sortbydays[abs(sortbydays$Bestand_Einheit) < Prozent5,]
        candidates_dif <- unique(candidates$Bestand_Einheit)
        dates <- as.Date(character())
        for (i in 1:length(candidates_dif)) {
          if (nrow(candidates[candidates$Bestand_Einheit == candidates_dif[i],]) > more.than) {
            dates_new <- candidates[candidates$Bestand_Einheit == candidates_dif[i],]$Datum
            dates <- c(dates, dates_new)
          }
        }
        dif.storage <- unique(candidates[which(candidates$Datum %in% dates),]$Bestand_Einheit)
        for (i in 1:length(dif.storage)) {
          MengeKum <- candidates[which(candidates$Datum %in% dates) & candidates$Bestand_Einheit == dif.storage[i],]$MengeKum[1]
          
          # 4 possibilities, but result is the same
           # case: storage was refilled, but too much -> MengeKum gets smaller
           # case: storage was refilled, but too less --> MengeKum gets bigger
           # case: storage was cleared, but too much
           # case: storage was cleared, but too less
          sortbydays[which(sortbydays$Datum %in% dates) & sortbydays$Bestand_Einheit == dif.storage[i],]$MengeKum[1] <- MengeKum - dif.storage[i]
          sortbydays[which(sortbydays$Datum %in% dates) & sortbydays$Bestand_Einheit == dif.storage[i],]$Bestand_Einheit <- 0
        }
        
      }
         
    #### Create the consumption ####
      MengeKonsum <- numeric(nrow(sortbydays))
      for (i in sortbydays$Tag_Nr) {
        if(sortbydays$MengeKum[i] <= 0) MengeKonsum[i] <- abs(sortbydays$MengeKum[i])
        else MengeKonsum[i] <- 0
      }
      sortbydays <- cbind(sortbydays, MengeKonsum)
    
    #### and here are the results depending on what you wanna plot ####
      if (what.plotting == "alles") {
        table <- data.frame(Datum = sortbydays$Datum, 
                            Tag_Nr = sortbydays$Tag_Nr, 
                            Warenbestand = sortbydays$Bestand_Einheit,
                            Verzehr = sortbydays$MengeKonsum)
      }
      if (what.plotting == "Verzehr") {
        table <- data.frame(Datum = sortbydays$Datum, 
                            Tag_Nr = sortbydays$Tag_Nr, 
                            Verzehr = sortbydays$MengeKonsum)
      }
      if (what.plotting == "Warenbestand") {
        table <- data.frame(Datum = sortbydays$Datum, 
                            Tag_Nr = sortbydays$Tag_Nr, 
                            Warenbestand = sortbydays$Bestand_Einheit)
      }
      if (what.plotting == "regression") {
        if (is.numeric(plotting.options$VPE) == FALSE) 
          stop("VPE must be a numeric vector with same length than all other vectors.")
        table <- data.frame(Datum = sortbydays$Datum,
                            Tag_Nr = sortbydays$Tag_Nr,
                            Warenbestand = sortbydays$Bestand_Einheit,
                            MengeDif = sortbydays$MengeKum,
                            VPE = rep(VPE, nrow(sortbydays)))
      }
      
      #### check if from/to is set ####
      if (from != "") {
        if (is.character(from) == FALSE) stop("'From' must be a character string in format 'yyyy-mm-dd'")
        from <- as.Date(from, origin = "1970-01-01")
        table <- table[table$Datum >= from,]
        if (to != "") {
          if (is.character(to) == FALSE) stop("'To' must be a character string in format 'yyyy-mm-dd'")
          to <- as.Date(to, origin = "1970-01-01")
          if (from > to) stop("'From' must be before 'to'")
          table <- table[table$Datum <= to,]
        }
      }
      
      return(table)
      
  } # one product - consumption | food.storage | both | regression 
    else {
      group_size <- length(name.of.product)
      
      # for each product one table
      for (i in 1:group_size) {
        # reset sortbypos
        Position <- 1:length(vec.of.products) # length = 3313
        sortbypos <- data.frame(Datum = vec.of.Dates, 
                                Position = Position, 
                                Produkt = vec.of.products)
        # sortbypos <- cbind([sortbypos$Position], sortbypos)
        
        sortbypos <- sortbypos[sortbypos$Produkt == name.of.product[i], ]
        # colnames(sortbypos)[1] <-  Datum (for a better overview)
        colnames(sortbypos)[2] <- paste("Position", name.of.product[i], sep = ".")
        colnames(sortbypos)[3] <- paste("Produkt", name.of.product[i], sep = ".")
        # join comulative change and food storage to sortbypos
        sortbypos <- cbind(sortbypos,
                           MengeKum = plotting.options$comul.change[sortbypos$Position],
                           Bestand_Einheit= plotting.options$food.storage[sortbypos$Position])
        colnames(sortbypos)[4] <- paste("MengeKum", name.of.product[i], sep = ".")
        colnames(sortbypos)[5] <- paste("Warenbestand", name.of.product[i], sep = ".")
        sortbydays <- merge(sortbydays, sortbypos[,-c(2,3)], by ='Datum', all = TRUE) # without position and product column
        
        # define columns where NA shall be replaced by zero; c(MengeKum, LagerKilo)
        important_columns <- c(3 + 3 * (i-1), 4 + 3 * (i-1))
        #replace NAs with  0
        sortbydays[,important_columns[1]][is.na(sortbydays[,important_columns[1]])] <- 0
        
        for (n in Tag_Nr) {
          sortbydays[n, important_columns[2]] <- sum(sortbydays[1:n, important_columns[1]])
        }
        
        # add 'sale to members'
        MengeKonsum <- numeric(nrow(sortbydays))
        for (t in Tag_Nr) {
          if(sortbydays[t, important_columns[1]] <= 0) { # MengeKum.Product <= 0
            MengeKonsum[t] <- abs(sortbydays[t, important_columns[1]])
          } else MengeKonsum[t] <- 0
        }
        sortbydays <- cbind(sortbydays, MengeKonsum)
        colnames(sortbydays)[ncol(sortbydays)] <- paste("Verzehr", name.of.product[i], sep = ".")
      }
        
      LagerCol <- c()
      VerzehrCol <- c()
      # AuffuellenCol <- c() - doesn't work
      for (i in 1:group_size) {
        LagerCol[i] <- c(4 + 3 * (i-1))
        VerzehrCol[i] <- c(5 + 3 * (i-1))
        # AuffuellenCol[i] <- c(8 + 5 * (i-1))
      }
      # now build sums
      Verzehr <- numeric(nrow(sortbydays))
      Lager <- numeric(nrow(sortbydays))
      for (n in Tag_Nr) {
        Verzehr[n] <- sum(sortbydays[n, VerzehrCol])
        Lager[n] <- sum(sortbydays[n, LagerCol])
      }
      sortbydays <- cbind(sortbydays, cbind(Lager, Verzehr))
      colnames(sortbydays)[length(sortbydays) - 1] <- paste("Warenbestand", deparse(substitute(name.of.product)), sep = ".")
      colnames(sortbydays)[length(sortbydays)] <- paste("Verzehr", deparse(substitute(name.of.product)), sep = "." )# names of product-vector
      
      # and here is the result
      MengeKumCol <- c()
      for (i in 1:group_size) {
        MengeKumCol[i] <- c(3 + 3 * (i-1))
      }
      remove <- sort(MengeKumCol)
      table <- sortbydays[, -remove]
      
      if (what.plotting == "allall") {
        result <- list(data = table, name.of.product = name.of.product, name.of.group = deparse(substitute(name.of.product)))
        return(result)
      } 
      
      if (what.plotting == "alles") {
        table <- table[, c(1,2,ncol(table) - 1, ncol(table))]
        colnames(table)[3] <- "Warenbestand"
        colnames(table)[4] <- "Verzehr"
        result <- list(data = table, name.of.product = name.of.product, name.of.group = deparse(substitute(name.of.product)))
        return(result)
      }
      
      if (what.plotting == "Verzehr") {
        table <- table[, c(1,2,ncol(table))]
        colnames(table)[3] <- "Verzehr"
        result <- list(data = table, name.of.product = name.of.product, name.of.group = deparse(substitute(name.of.product)))
        return(result)
      }
      
      if (what.plotting == "Warenbestand") {
        table <- table[, c(1,2,ncol(table)-1)]
        colnames(table)[3] <- "Warenbestand"
        result <- list(data = table, name.of.product = name.of.product, name.of.group = deparse(substitute(name.of.product)))
        return(result)
      }
      
    } # a group - consumption | food storage | both
    
} 