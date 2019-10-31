
### Summary Hydrographs #################

computeAllQuantiles <- function(allESPData, metrics){
  #Wrapper to copmute the metrics at each location
  lapply(allESPData, function(x) lapply(x, computeSummaryHydrographByDate,metrics))
}


computeSummaryHydrographByDate <- function(tsData, metrics="mean"){
  #Expecting a dataframe input for 'tsData' that has columns called
  #  'date', and numeric column called 'value'
  #An additional argument can be passed called 'metrics' that defines the percentiles
  #  and mean or median.  It is a character vector that can have the following entries:
  #  perentile: e.g, "10%"
  #  "mean", "median"
  #Output is the summary hydrograph by unique date/month with a column for each metric
  ddply(.data = tsData[, c("date","value")], .variables = .(date), .fun=applyNamedFunctions, fNames=metrics)
}
  



applyNamedFunctions <- function(df, fNames){
  #dataframe with a 'value' column which a series of
  #  functions is applied to
  #fNames defines the percentiles
  #  and mean or median.  It is a character vector that can have the following entries:
  #  perentile: e.g, "10%"
  #  "mean", "median"
  out <- vector("numeric",length(fNames))
  names(out) <- fNames
  
  for( f in fNames ){
    if( grepl("%",f) ){
      #assuming a quantile should be applied
      q <- as.numeric(str_extract(f,"\\d*"))
      out[f] <- quantile(x = df$value, probs = q/100)
    }else{
      #assuming it's a named function
      out[f] <- eval(call(name = f,df$value))
    }
  }
  return(out)
}


### Forecast Volumes ################

sumFcstVolume <- function(wyData){
  
  diff(wyData$date)
  sum(wyData$value[wyData$inFcstPeriod])
}

computeESPFcstVols <- function(allESPData, fcstTbl, startDate, endDate, outColNames){
  #wrapper to map the 'computeFcstVols' to the right path
  #  in 'allESPData', which is organizes by CWMS forecast
  lapply(allESPData,
         function(x) computeFcstVols(tsData = x[[fcstTbl$sqlite_tblname]],
                                     startDate = startDate,
                                     endDate = endDate,isESP = T, outColNames))
}

computeFcstVols <- function(tsData, startDate, endDate,isESP=F, outColNames=c("wy","vol")){
  #sums the inflow volume as kaf by water year for the
  #  time window specified between 'startDate' and 'endDate'
  #  both of which are Date or POSIXct objects that 
  #  a month and day can be extracted from
  #example tsData input:
  #
  # > str(tsData)
  # 'data.frame':	37155 obs. of  2 variables:
  # $ date       : POSIXct, format: "1948-10-01 23:00:00" ...
  # $ DWR_Flow-In: num  1.44 1.42 1.4 1.48 2.51 2.37 1.93 1.89 1.78 1.65 ...
  
  MafPerkcfsd <- 86400/43560/1000 #assuming we'll be getting kcfs from CWMS database
  
  
  #If this is ESP data, need to modify the dates to correspond to the associated year
  if( isESP ) {
    year(tsData$date) <- as.numeric(tsData$year) #any issues here with water years?
    tsData <- tsData[, c("date","value")] #and remove extraneous columns
    #don't need to convert since this is done handled on load and set in the config
    # tsData$value <- tsData$value/1000 #converting to kcfs, which is what will be coming from CWMS db
  }

  #converting time series to average daily to simplify compute and ensure
  #  volume conversion works as expected
  tsData$date <- as.Date(tsData$date)
  names(tsData) <- c("date","value") #simplifying col. names for analysis
  dailyAvg <- tsData %>% group_by(date) %>% summarise_at("value",mean,na.rm=T)
  
  #Extracting the start and end days of year
  #Note: this will have issues if the forecast window crosses between years (which it shouldn't)
  startYday <- yday(as.Date(sprintf("2001-%g-%g", month(startDate), day(startDate))))
  endYday <- yday(as.Date(sprintf("2001-%g-%g", month(endDate), day(endDate))))

  #indicating whether or not dates are in the forecast period
  #  and assigning water year
  dailyAvg$inFcstPeriod <- yday(dailyAvg$date) %in% startYday:endYday
  dailyAvg$wy <- wateryear(dailyAvg$date)


  #summing inflows
  out <- ddply(.data = dailyAvg, .variables = .(wy), summarize,
        vol = round(sum(value[inFcstPeriod],na.rm=T)*MafPerkcfsd,2)  )
  
  if(startDate == endDate) out$vol <- 0 #correction for outside of time window
  
  names(out) <- outColNames #renaming
  
  return(out)
}


mergeFcst <- function(histFcstFull, histFcstPartial,espFcstPartial,selectFcst){
  #Merges the the three historical/esp forecast volume dataframes into one,
  #  using the currently selected ESP volumes
  if( any(is.null(list(histFcstFull, histFcstPartial, espFcstPartial))) ) return(NULL)
  Reduce(merge, list(histFcstFull, histFcstPartial,espFcstPartial[[selectFcst]]))
}

