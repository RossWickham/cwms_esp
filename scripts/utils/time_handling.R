#time_handling

POSIXctFromHecTime <- function(hecTimes){
  #input is an integer vector of HecTimes (seconds since 1900-01-01 00:00:00)
  #output is PosIXct
  as.POSIXct(hecTimes * 60, origin = "1899-12-31 00:00", tz = "UTC")
}

convertToSameWY <- function(inDates,wy = 3001,dateColName = "date"){
  #Given a dataframe with a 'date' column (or other if specified in 'dateColName' argument),
  #  returns the same dataframe with a 'wyDate' column where the dates are converted to
  #  the 3001 water year (or other if specified in 'wy' argument and checks to remove Feb 29 data
  year(inDates) <- wy #make all same wate ryear
  inDates <- inDF[!is.na(inDF$wyDate),] #remove bad dates (feb29)
  year(inDF$wyDate[month(inDF$wyDate)>=10]) <- wy-1 #adjust years for months >=Oct
  return(inDF)
}
