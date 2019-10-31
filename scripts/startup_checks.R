#need to perform some startup checks afer loading data, but prior to analyzing


### ESP Data ###############################

#check that paths defined in the 'config' tab are also contained in the database
#prompt with how to correct by changing regular expression in save_to_sql script

### Forecast Volumes ##########################

#Check that the inflow forecast paths are in the forecast.db file
fcstTblInFcst <- sapply(allESPData,
                        function(x) fcstTbl$sqlite_tblname %in% names(x),simplify = T)
if(!all(fcstTblInFcst)){
  cat( sprintf(paste0("\nMissing the 'sqlite_tblname' as defined",
              " in 'fcst_tbl' tab config from the following forecast.db files. Skipping processing:\n\t%s"),
       paste0(names(fcstTblInFcst[!fcstTblInFcst]),collapse="\n\t")))
}

#only expecting one data row
if( nrow(fcstTbl) !=1){
  cat("\nThere can only be one entry (i.e., data row) in the 'fcst_tbl' tab of the config.xlsx")
  stop()
}
