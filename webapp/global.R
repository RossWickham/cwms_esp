
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

#Retrieving the base R equivalent line types from plotly (functino defined in plot.R)
metricsToCompute$baseRLty <- plotlyLtyToGraphicsLty(metricsToCompute$lty_plotly)

#Loading configuration data from Excel
config <- loadConfig()
cDataTbl <- loadCurrentDataTbl()
fcstTbl <- loadFcstDataTbl()


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

#Pulling forecast info, following same name convention as 'allESPData'
fcstInfo <- loadFcstInfo()

#Scripts to check that necessary data are available and config is defined correctly
source("scripts/startup_checks.R")


#Initializing forecast tables as NULL
histFcstFull <- histFcstPartial <- espFcstPartial <- NULL

#retrieve inflow data and compute forecast
fcstDataTbl <- list() #initializing object for finalized output
if( nrow(fcstTbl)==1 ){
  
  cat("\nLoading Historical CWMS Data and Computing Forecast Volumes")
  cwmsFcst <- getHistoricalCWMS(cwmsPath = fcstTbl$cwms_path,startESPYr = min(availableYrs))
  
  #Pulling the forecast time window start and end dates (e.g., Apr01-Jul31 for Dworshak)
  fcstTWStartDate <- as.Date(fcstTbl$fcst_start_date) #forecast start date (year doesn't matter)
  fcstTWEndDate <- as.Date(fcstTbl$fcst_end_date)     #forecast end date (year doesn't matter)
  
  #Ensuring years are same for all dates by applying the setYear function
  fcstTWStartDate <- setYear(fcstTWStartDate)
  fcstTWEndDate <- setYear(fcstTWEndDate)

  for( selectFcst in names(fcstInfo) ){
    
    #Pulling forecast's end time and adjust year using the setYear function
    fcstEndDate = setYear(as.Date(fcstInfo[[selectFcst]]$endTime))
    
    #Creating an end date for the forecast to be used in computing historical and ESP inflow volumes
    #  within the forecast period.  If the forecast time window is Apr01-Jul31, and the CWMS forecast end
    #  date is May12, then inflow volumes will be computed from Apr01-May12 for the objects 
    #  'histFcstPartial' and 'espFcstPartial'.  The 'histFcstFull will compute inflow volumes for the full
    #  forecast time window, Apr01-Jul31.
    if(fcstEndDate <= fcstTWStartDate) fcstEndDate <- fcstTWStartDate #setting equal if less than start date
    if(fcstEndDate >= fcstTWEndDate) fcstEndDate <- fcstTWEndDate #setting equal if greater than end date
    
    #Compute historically observed runoff volume for FULL forecast time window
    histFcstFull <- computeFcstVols(tsData = cwmsFcst,
                                    startDate = fcstTWStartDate,
                                    endDate = fcstTWEndDate) #using same end date as time window
    
    #Compute historically observed runoff volume from start of forecast time window to END OF FORECAST TIME
    histFcstPartial <- computeFcstVols(tsData = cwmsFcst,
                                       startDate = fcstTWStartDate,
                                       endDate = fcstEndDate)
    
    #Compute ESP runoff volume from start of forecast time window to current END OF FORECAST TIME
    espFcstPartial <- computeFcstVols(tsData = allESPData[[selectFcst]][[fcstTbl$sqlite_tblname]],
                                      startDate = fcstTWStartDate,
                                      endDate = fcstEndDate,
                                      isESP = T)
    
    fcstDataTbl[[selectFcst]] <- mergeFcst(histFcstFull, histFcstPartial,espFcstPartial)
  }  #End for loop of CWMS forecasts

} #End if there is a forecast time window specified

### PDF Save Settings ########

#color and line type settings for minor grid line
minGridCol= grey(0.3,0.3) 
minLty = 3

#color settings for ESP traces (non-selected)
espLinCol = grey(0.5,0.3) 

cat("\n\nBrowser is ready - refresh or open new browser session")

