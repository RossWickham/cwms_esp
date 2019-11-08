



#for testing
if(F)
saveToPdf(config = config,
          espData = allESPData[[1]],
          espQData = allQuantileData[[1]],
          selectedMetrics = metricsToCompute$metric[c(2,5,9)],
          selectedYrs = availableYrs[c(1,4)],
          selectedFcstInfo = fcstInfo[[1]])



saveToPdf <- function(config, espData, espQData, selectedMetrics, selectedYrs, selectedFcstInfo){
  #Save out plots to pdf, following the 'plots' column in the 
  require(dplyr)
  
  cat("\n\nBeginning Save to PDF")
  
  #Initializing inputs
  plotConfig <- config[!is.na(config$pdf_page),] #removing undefined rows
  selectedYrs <- as.numeric(selectedYrs)
  
  init <- F #indicates whether or not plot has been initialized
  
  #Line indicating when the forecast starts
  #yref = "paper" allow you to specify a position that is always relative to the plot,
  #  y=1 refers to the top of plot and y=0 refers to the bottom of the plot:
  #  https://stackoverflow.com/questions/41267246/how-to-add-annotations-horizontal-or-vertical-reference-line-in-plotly
  fcstStartData <- selectedFcstInfo$fcstTime
  
  
  #establishing save directory and file name
  pdfSaveDir <- "plots"
  pdfFileName <- replaceAllSpecialChars(sprintf("%s_%s_%s",
                                                selectedFcstInfo$watershed,
                                                selectedFcstInfo$name,
                                                format(Sys.time(),"%Y%b%d_%H%M")))
  
  
  if(!dir.exists(pdfSaveDir)) dir.create(pdfSaveDir)
  pdfFile <- sprintf("%s/%s.pdf", pdfSaveDir, pdfFileName)

  
  
  #initialize pdf
  pdf(file = pdfFile,onefile = T,paper = "a4",pointsize = 12)
  
  par(xaxs="i")
  
  for( pg in unique(config$pdf_page) ){
    cat(sprintf("\n\tCreating pg %g",pg))

    subConfig <- config[config$pdf_page==pg,] #subsetting plot config fort this page
    
    #establish layout for desired number of plots on the page
    # +1 plot is for the header and legend
    graphics::layout(mat = matrix(1:(nrow(subConfig)+1), ncol=1),heights=c(2,rep(2,nrow(subConfig))))
    
    #Add header and legend
    makeHeaderPlot(selectedMetrics, selectedYrs,selectedFcstInfo,addLineLeg=T)
    
    for(k in 1:nrow(subConfig)){
      
      #extracting plot parameters to simplify eval (had difficulty wrapping plot_ly in with statement)
      sqlite_tblname <- subConfig$sqlite_tblname[k]
      yaxis_label <- gsub("<br>","\n",subConfig$yaxis_label[k])
      
      #extracting ESP lines and quantiles
      plotData <- espData[[sqlite_tblname]]
      qData <- espQData[[sqlite_tblname]]
      
      #initialize plot and grid, adjust for margins:
      #  no spaces between plots in the vertical, bottom plot has dates
      isBottomPlot <- F
      if(k==1) par(mar=c(0,5,2,2)) #top plot
      if(k>1 & k < nrow(subConfig)) par(mar=c(0,5,0,2)) #middle plot
      if(k==nrow(subConfig)){
        par(mar=c(4,5,0,2))
        isBottomPlot <- T}#bottom plot
      
      #establishing axes limits and minor grid lines
      xLimit <- range(qData$date,na.rm=T)
      yLimit <- range(c(qData$min,qData$max),na.rm=T)
      halfMonthDates <- qData$date[day(qData$date) %in% c(1,15) & hour(qData$date)==0]
      
      # plot.new(); box() #for testing
      plot(NA,xlim=xLimit,ylim=yLimit,axes=F,xlab="",ylab=yaxis_label)
      segments(x0 = halfMonthDates,y0 = -1E6,y1 = 1E6,col = minGridCol,lty=minLty)
      grid(nx = NA,ny=NULL)
      axis(2)
      box()
      if(isBottomPlot) axis(1,halfMonthDates,format(halfMonthDates,"%b%d"))
      
      #line for start of forecast
      lines(c(selectedFcstInfo$fcstTime,selectedFcstInfo$fcstTime),
            c(-1E6,1E6),lty=2,col=grey(0,0.5))
      text(x = selectedFcstInfo$fcstTime,y=max(yLimit),labels = "Forecast Start Time",cex=0.5,
           pos=4,srt=-90)
      
      #iterate through ESP traces and plot with transparency in grey
      for( yr in unique(plotData$year)){
        with(plotData[plotData$year==yr,],
             lines(date,value,col=espLinCol))
      }
      
      # Adding metrics if any current selected
      for(metric in selectedMetrics){
        metricLty=metricsToCompute$baseRLty[metricsToCompute$metric==metric]
        lines(qData$date,qData[,metric],col="black", lty=metricLty,lwd=2)
      }
      
      #Adding selected years
      for(yr in selectedYrs){
        with(plotData[plotData$year==yr,],
             lines(date,value,col=getColor(yr,selectedYrs),lwd=2))
      }
      
    } #end for loop, subplot

    
  }  #End loop of pdf pages
  
  #save pdf
  dev.off()
  
  cat(sprintf("\nDone creating pdf\nSaved pdf plot here:\n\t%s/%s", getwd(),pdfFile))
  
}



