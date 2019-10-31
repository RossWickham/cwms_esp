#reading DSS 7 in dssrip using java available in CWMS install


dssVueDir <- "D:\\Programs\\CWMS-v3.1.1.126\\HEC-ResSim\\3.4\\java"

dssVueDir <- "D:\\Programs\\CWMS-v3.1.1.126\\shared\\java64"

# options(dss_location= dssVueDir )
options(dss_jre_location= dssVueDir )
Sys.setenv(JAVA_HOME= dssVueDir )


library(dssrip)


#test read
dssFileName <- "D:\\CWMS\\watersheds\\forecast\\Test_-_ESP_09302019\\Lower_Snake"
dssFile <- opendss(dssFileName)
tsc <- dssFile$get("//ANAW/FLOW-LOCAL/01Sep2019/6Hour/C:001949|NATURAL/")

#test read of gridded
dssFileName <- "D:\\CWMS\\_data\\DSS\\airtemp.2011.06.dss"
dssFile <- opendss(dssFileName)
grd <- dssFile$get("/SHG/BOISE RIVER/AIRTEMP/01JUN2011:0100//NDGD-RTMA/")

grdInfo <- .jclass(grd$gridData$getGridInfo())

grdData <- matrix(grd$gridData$getData(), grdInfo$getNumberOfCellsX(),grdInfo$getNumberOfCellsY())


image(grdData)
