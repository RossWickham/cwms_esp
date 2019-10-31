
### Dates #############


dateTommmdd <- function(inDate) format(inDate,"%b%d")

## Misc ############

recursiveDirName <- function(filePath,nDeep,returnBaseName=F){
  #Retrieve the fully qualified parent directory up 'nDeep' levels
  nDeep = nDeep-1
  dirName <- dirname(filePath)
  ifelse(nDeep==0,
         ifelse(returnBaseName,return(basename(dirName)),return(dirName)),
         return(recursiveDirName(dirName,nDeep,returnBaseName)))
}

yearFromEnsembleFPart <- function(fParts){
  #From a string vector of F parts, extracts the year as a character
  require(stringr)
  #extracts, e.g., "001949" from F part in
  out <- as.character(str_extract_all(fParts,"\\d{6}",T)) 
  return(gsub("(^|[^0-9])0+", "\\1", out, perl = TRUE)) #strips leading zeroes
}

#Get all of the configuration values for a given parameter in the config
getAllConfigVals <- function(config, colName){
  na.omit(bind_rows(config)[, colName])
}


replaceAllSpecialChars <- function(string,repString="_"){
  gsub(pattern = "[^[:alnum:]]",replacement = repString, x = string)
}


### Colors ##########

colToHex <- function(colName, alpha=0.5) mapToRGBA(col2rgb(col = colName),alpha=alpha)

mapToRGBA <- function(rgbaVector,alpha){
  #input is a vector defining the red, green, blue,
  #  and alpha values (in that order) to be passed
  #  to the rgb function
  rgb(rgbaVector[1]/255, rgbaVector[2]/255, rgbaVector[3]/255, alpha)
}




### CWMS Data #############


getCurrentCWMSTableStrings <- function(cDataTbl){
  #Retrieve data from the CWMS database
  cValues <- Map(getLastCWMSValue,cDataTbl$cwms_path,cDataTbl$divisor)
  # cValues <- list(data.frame(date=as.POSIXct("2019-07-31 23:01:00"),value=2239),
  #                 data.frame(date=as.POSIXct("2019-07-31 23:01:00"),value=500))
  
  outStrings <- NULL
  #forming strings
  for( k in 1:nrow(cDataTbl)){
    
    sprintfString <- cDataTbl$format_string[k]
    
    #If there is an additional %s for the date, then pass that into 
    #  the sprintf expression.  Otherwise, just pass the value
    if( any(is.na(cValues[[k]])) ){ #if bad data
      outStrings <- c(outStrings,
                      sprintf(sprintfString,NA, NA ))
    }else if( str_count(sprintfString,"%") > 1 ){
      outStrings <- c(outStrings,
                      sprintf(sprintfString,cValues[[k]][2], format(cValues[[k]]$date,"%Y-%m-%d %H:%M") ))
    }else{
      outStrings <- c(outStrings,
                      sprintf(sprintfString,cValues[[k]][2]))
    }
  }
  
  return(outStrings)
}


### Forecast Info ##################



getFcstInfo <- function(fcstDir){
  #Given a forecast directory, extracts information from the .frcst file
  
  require(XML)
  
  fcstDir <- "D:\\CWMS\\watersheds\\forecast\\Test_-_ESP_10012019\\Lower_Snake"
  
  fcstFile <- dir(path = fcstDir, pattern = ".frcst$",full.names = T)
  
  #reading in as xml
  xmlList <- xmlToList(xmlParse(utf8::utf8_encode(x = readLines(fcstFile))))
  
  #extracting relavant XML information
  out <- list()
  out$watershed <- basename(fcstDir )
  out$description <- xmlList$Description$desc["value"]
  out$lastComputeTime <- as.POSIXct(xmlList$LastComputeTimes$Plugin$ModelAlternative$Time,format="%d %b %Y, %H:%M:%S")
  out$fcstTime <- as.POSIXct(xmlList$ForecastTimeWindow$Forecast,format="%d%b%Y %H%M")
  out$startTime <- as.POSIXct(xmlList$ForecastTimeWindow$Start,format="%d%b%Y %H%M")
  out$endTime <- as.POSIXct(xmlList$ForecastTimeWindow$End,format="%d%b%Y %H%M")
  out$extractTime <- as.POSIXct(xmlList$ForecastTimeWindow$Extract,format="%d%b%Y %H%M")
  out$name <- xmlList$.attrs
  
  return(out)
}


