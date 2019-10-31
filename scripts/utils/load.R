
### SQLite ##################

#Look in forecast directory for forecast.db sqlite files
getAvailabelForecasts <- function(watFcstFormat=F){
  #If 'watFcstFormat is True, will rename by <watershed>:<forecast>
  forecastDBFiles <- dir("../forecast","forecast.db",recursive = T, full.names = T)
  
  if(watFcstFormat)
    forecastDBFiles <- sprintf("%s:%s", recursiveDirName(forecastDBFiles,1,T), recursiveDirName(forecastDBFiles,2,T) )
  return(forecastDBFiles)
}

#wrapper so that map function names list element after the table name
#Also formats the dataframe to contain the ensemble year as a column, 
#  format date as POSIXct, and treat value as numeric
dbReadFmtTable_tblNameFirst <- function(tblName, db, config) {
  outDF <- dbReadTable(db, tblName)
  outDF$year <- yearFromEnsembleFPart(outDF$fPart)
  outDF$value <- as.numeric(outDF$value)
  outDF$date <- POSIXctFromHecTime(outDF$date)
  #applying datum shifts and unit conversions
  datum_shift <- config$datum_shift[config$sqlite_tblname==tblName]
  divisor <- config$divisor[config$sqlite_tblname==tblName]
  outDF$value <- (outDF$value+datum_shift)/divisor
  
  return(outDF)
}

loadDFListForecastDF <- function(forecastDBFile, tblNames, config){
  #From a fully qualified path to a forecast.db file,
  #  returns a nested list of all tables as dataframes
  require(RSQLite)
  
  db <- dbConnect(RSQLite::SQLite(),forecastDBFile)
  
  suppressWarnings( #suppress warnings to close db after each read
    out <- Map(dbReadFmtTable_tblNameFirst, tblNames, list(db), list(config))
  )
  
  dbDisconnect(db) 
  return(out)
}



loadAllForecastDB <- function(forecastDBFiles, config){
  #Reads in all available forecast.db files
  require(RSQLite)
  
  tblNames <- getAllConfigVals(config, "sqlite_tblname")
  
  #Load each forecast
  out <- Map(loadDFListForecastDF, forecastDBFiles, list(tblNames), list(config))
  
  #renaming by <watershed>:<forecast>
  names(out) <- getAvailabelForecasts(T)
  
  return(out)
}


dbReadTable_tblNameFirst <- function(tblName, db) dbReadTable(db, tblName)

readSQLTbls <- function(dbFile, tblNames){
  #Loads from an SQLite database
  db <- dbConnect(RSQLite::SQLite(),dbFile)
  #check that the table exists in the file
  missingTbls <- tblNames[tblNames %!in% RSQLite::dbListTables(db)]
  if( length(missingTbls) > 0 ){
    cat(sprintf("Missing the following tables from database:\n\t%s",
                paste0(missingTbls,collapse="\n\t")))
    tblNames <- tblNames %!in% missingTbls #reduce to tables that do exist
    if(length(tblNames)==0) return(NA)     #return NA if no data
  }
  suppressWarnings( #suppress warnings to close db after each read
    out <- Map(dbReadTable_tblNameFirst, tblNames, list(db))
  )
  if(length(tblNames)==1) out <- out[[1]]
  dbDisconnect(db) 
  return(out)
}

writeSqlTbl <- function(dbFile, tblName, inDF){
  #writes dataframe to SQL, deletes old table if it exists
  db <- dbConnect(RSQLite::SQLite(), dbFile)
  if(tblName %in% dbListTables(db) )dbRemoveTable(conn = db, name = tblName)
  dbWriteTable(conn = db, name = tblName, value = inDF)
  dbDisconnect(db) 
}

### Config ###########################

readWorksheet_sheetNamesFirst <- function(sheetName, wb) readWorksheet(wb, sheetName)

loadConfig <- function(){
  #Loads configuration data from the config.xlsx file in the main project directory
  
  require(XLConnect)
  
  wb <- loadWorkbook("config.xlsx")
  
  # sheetNames <- getSheets(wb)
  # out <- Map(readWorksheet_sheetNamesFirst, grep("[^readme]",sheetNames,value = T), list(wb))
  out <- readWorksheet(object = wb, sheet = "config")
  
  #Converting instances where datum_shift is NA to 0;  divisor is NA -> 1 
  # out <- lapply(out, function(x) {x$datum_shift[is.na(x$datum_shift)] <- 0; x$divisor[is.na(x$divisor)] <- 1; return(x)})
  out$datum_shift[is.na(out$datum_shift)] <- 0
  out$divisor[is.na(out$divisor)] <- 1
  
  return(bind_rows(out))
}

loadCurrentDataTbl <- function(){
  require(XLConnect)
  
  wb <- loadWorkbook("config.xlsx")
  
  # out <- Map(readWorksheet_sheetNamesFirst, grep("[^readme]",sheetNames,value = T), list(wb))
  out <- readWorksheet(object = wb, sheet = "current_data_tbl")
  out$divisor[is.na(out$divisor)] <- 1
  
  return(bind_rows(out))
}

loadFcstDataTbl <- function(){
  require(XLConnect)
  
  wb <- loadWorkbook("config.xlsx")
  
  # out <- Map(readWorksheet_sheetNamesFirst, grep("[^readme]",sheetNames,value = T), list(wb))
  out <- readWorksheet(object = wb, sheet = "fcst_tbl")
  
  return(bind_rows(out))
}

loadFcstInfo <- function(){
  fcstFiles <- dir(dirname(availableFcsts),".frcst$",full.names = T)
  fcstInfo <- Map(getFcstInfo, fcstFiles)
  names(fcstInfo) <- sprintf("%s:%s", recursiveDirName(fcstFiles,1,T), recursiveDirName(fcstFiles,2,T))#renaming based on forecast
  return(fcstInfo)
}

### CWMS ###############################


getLastCWMSValue <- function(cwmspath,divisor){
  #For the CWMS path, extracts the most recent value in the database
  #Also applies a correction as defined in the config file
  
  naReturn <- data.frame(date=NA, value=NA) #what to return for bad read
  
  if(is.na(divisor)) divisor <- 1
  
  #pull data from previous two weeks and expand range as needed
  maxDaysPrior <- 500
  nDaysPrior <- 20
  while(T){
    outDF <- try(
      cwms_to_df(path = cwmspath,
                          start_date = Sys.Date()-nDaysPrior,end_date = Sys.Date())
    )
    if(is.null(outDF)) return(naReturn)
    if(nrow(outDF)>0) break
    nDaysPrior <- nDaysPrior + 50
    if( nDaysPrior > maxDaysPrior ){
      cat(sprintf("\nCould not find any data for CWMS path in last %g days, skipping:\n\t%s",
                  maxDaysPrior,cwmspath))
      return(naReturn)
    }
  }
  
  #Finding most recent value, and applying divisor
  out <- outDF[which.max(outDF$date),]
  out[,2] <- out[,2]/divisor
  return(out)
  
}

getHistoricalCWMS <- function(cwmsPath, startESPYr){
  #Grabs all data available from the provided CWMS path 
  #  that spans the ESP traces.  'startESPYr' is the start
  #  year of the ESP traces (e.g., 1929)
  startESPYr <- as.numeric(startESPYr)
  
  startDate <- as.Date(sprintf("%g-10-01",startESPYr-1)) #starting by water year

  #load from saved historical sqlite database if it exists.
  historicalDBFile <- "historical_data/historical.db"
  loadData <- NULL
  if(file.exists(historicalDBFile)){
    loadData <- readSQLTbls(historicalDBFile, cwmsPath)
    loadData$date <- as.POSIXct(loadData$date,origin="1970-01-01")
  }
  
  #If it does exist, check the last date in the table against current date
  lastHistoricalDate <-Sys.Date()-10
  if(!is.null(loadData)) lastHistoricalDate <-  as.Date(max(loadData$date))
  
  if( !is.null(loadData) & lastHistoricalDate >= Sys.Date() ){
    out <- loadData #just return loaded data, no need to update
  }else if( !is.null(loadData) & as.Date(lastHistoricalDate) < Sys.Date() ){
    #Data needs updating, save new table after merging with latest CWMS data
    cwmsData <- cwms_to_df(path = cwmsPath,
                           start_date = lastHistoricalDate-1,end_date = Sys.Date())
    
    #Correction to CWMS name. After save the sql, sometimes the column names are
    # altered, making the bind_rows function return three columns instead of three
    names(cwmsData) <- names(loadData)
    
    out <- bind_rows(loadData, cwmsData) #merging
    out <- out[!duplicated(out),] #removing duplicates in case of overlap
    writeSqlTbl(historicalDBFile, cwmsPath, out) #saving out latest and greatest
    
  }else{
    #No data, so get all from CWMS database
    out <- cwms_to_df(path = cwmsPath,
                      start_date = startDate,end_date = Sys.Date())
    writeSqlTbl(historicalDBFile, cwmsPath, out) #saving out latest and greatest
  }
  return(out)
}
