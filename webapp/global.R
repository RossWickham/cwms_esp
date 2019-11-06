
cat("\nrunning global")
options(warn=-1) #no warnings, they clutters command prompt window.  output uses 'cat'

#The available quantiles for the dropdown menu, and their associated line types for plotly
metricsToCompute <- data.frame(metric=    c("min", "1%",        "10%", "25%",    "median",
                                            "mean",    "75%",    "90%", "99%",        "max"),
                               #see the plotly reference here for the line type to be used under the scatter>lines>dash
                               #options are: "solid", "dot", "dash", "longdash", "dashdot", or "longdashdot"
                               lty_plotly=c("dot","longdashdot","dash","dashdot","solid",
                                            "longdash", "dashdot","dash","longdashdot","dot" ),
                               stringsAsFactors = F)


"%!in%" <- function(x,y) !(x %in% y) #not in operator

#assuming in webapp folder if not in base project directory
if("scripts" %!in% dir()) setwd("..") 

#loading from project main directory
suppressPackageStartupMessages({
  library(shiny)
  library(DT)
  library(plotly)
  source("scripts/r_setup.R")
})


#Loading configuration data from Excel
config <- loadConfig()
cDataTbl <- loadCurrentDataTbl()
fcstTbl <- loadFcstDataTbl()

#Pulling forecast info, following same name convention as 'allESPData'
fcstInfo <- loadFcstInfo()

#Loading CWMS data as defined in the 
cat("\nLoading Current CWMS Data")
cwmsDataString <- getCurrentCWMSTableStrings(cDataTbl)

#Loading all data to save time later
cat("\nLoading ESP Data")
availableFcsts <- getAvailabelForecasts()
allESPData <- loadAllForecastDB(availableFcsts, config, fcstTbl)
if(length(allESPData) == 0) stop("\n\nNo forecast.db files found in 'forecast' folder")


  
#Computing the desired metrics, as defined in 'metricsToCompute' object above
allQuantileData <- computeAllQuantiles(allESPData, metricsToCompute$metric)

#retrieving the available years in ESP data
availableYrs <- sort(unique(allESPData[[1]][[1]]$year))

#Scripts to check that necessary data are available and config is defined correctly
source("scripts/startup_checks.R")


#Initializing forecast tables as NULL
histFcstFull <- histFcstPartial <- espFcstPartial <- NULL

#retrieve inflow data and compute forecast
fcstDataTbl <- list() #initializing object for finalized output
if(nrow(fcstTbl)==1){
  
  cat("\nLoading Historical CWMS Data and Computing Forecast Volumes")
  cwmsFcst <- getHistoricalCWMS(cwmsPath = fcstTbl$cwms_path,startESPYr = min(availableYrs))
  
  #Forecast time window (e.g., Apr01-Jul31 for Dworshak)
  fcstTWStartDate <- as.Date(fcstTbl$fcst_start_date) #forecast start date (year doesn't matter)
  fcstTWEndDate <- as.Date(fcstTbl$fcst_end_date)     #forecast end date (year doesn't matter)
  
  #Ensuring years are same for all dates
  fcstTWStartDate <- setYear(fcstTWStartDate)
  fcstTWEndDate <- setYear(fcstTWEndDate)
  
  #start date of partial forecast window.  If outside forecast time window, this is the forecast
  #  start date.  Otherwise, it is the current date (year doesn't matter)
  # partialDate <- as.Date(ifelse(Sys.Date()>=fcstStartDate & Sys.Date()<=fcstEndDate,
  #                               Sys.Date(), fcstStartDate))
  # partialDate <- as.Date(fcstEndDate)
  # 
  # #Date strings to be assigned to be used in column names
  # fullDateString <- sprintf("(%s - %s)", dateTommmdd(fcstStartDate),dateTommmdd(fcstEndDate))
  # partialDateString <- ifelse(fcstStartDate==partialDate,
  #                             "(NA - Outside Fcst Time Window)",
  #                             sprintf("(%s - %s)", dateTommmdd(fcstStartDate),dateTommmdd(partialDate)) )
  
  for( selectFcst in names(fcstInfo) ){
    
    #Pulling forecast's end time and adjust year
    fcstEndDate = setYear(as.Date(fcstInfo[[selectFcst]]$endTime))
    if(fcstEndDate <= fcstTWStartDate) fcstEndDate <- fcstTWStartDate #setting equal if less than start date
    if(fcstEndDate >= fcstTWEndDate) fcstEndDate <- fcstTWEndDate #setting equal if greater than end date
    
    #Compute historically observed runoff volume for full forecast time window
    histFcstFull <- computeFcstVols(tsData = cwmsFcst,
                                    startDate = fcstTWStartDate,
                                    endDate = fcstTWEndDate,
                                    fcstEndDate = fcstTWEndDate)
    
    #Compute historically observed runoff volume from start of forecast time window to current date
    histFcstPartial <- computeFcstVols(tsData = cwmsFcst,
                                       startDate = fcstTWStartDate,
                                       endDate = fcstTWEndDate,
                                       fcstEndDate = fcstEndDate)
    
    #Compute ESP runoff volume from start of forecast time window to current date
    espFcstPartial <- computeFcstVols(tsData = allESPData[[selectFcst]],
                                      startDate = fcstTWStartDate,
                                      endDate = fcstTWEndDate,
                                      isESP = T,
                                      fcstEndDate = fcstEndDate)
    
    fcstTbl[[selectFcst]] <- mergeFcst(histFcstFull, histFcstPartial,espFcstPartial)
  }

}


cat("\n\nBrowser is ready - refresh or open new browser session")

