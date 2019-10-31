



saveToPdf <- function(config, espData, espQData, metrics, selectedYrs, selectedFcstInfo){
  #Save out plots to pdf, following the 'plots' column in the 
  require(dplyr)
  plotConfig <- bind_rows(config)
  p <- list()
  init <- F #indicates whether or not plot has been initialized
  
  #Line indicating when the forecast starts
  #yref = "paper" allow you to specify a position that is always relative to the plot,
  #  y=1 refers to the top of plot and y=0 refers to the bottom of the plot:
  #  https://stackoverflow.com/questions/41267246/how-to-add-annotations-horizontal-or-vertical-reference-line-in-plotly
  fcstStartData <- selectedFcstInfo$fcstTime
  fcstStartAnnotation <- list(yref = 'paper', xref = "x", y = 0.5, x = fcstStartData, opacity=0.5,
                              text = "Forecast Start",textangle=-90,showarrow=F)
  
  #establishing save directory and file name
  pdfSaveDir <- "plots"
  pdfFileName <- replaceAllSpecialChars(sprintf("%s_%s_%s",
                                   selectedFcstInfo$watershed,
                                    selectedFcstInfo$name,
                                    format(Sys.time(),"%Y%b%d_%H%M")))
  if(!dir.exists(pdfSaveDir)) dir.create(pdfSaveDir)
  pdfFile <- sprintf("%s/%s.pdf", pdfSaveDir, pdfFileName)
  
  ### CONTINUE HERE ####
  
  #initialize pdf
  pdf(file = pdfFile,onefile = T,paper = "a4")
  
  
  for( pg in unique(config$pdf_page) ){
    
    subConfig <- config[config$pdf_page==pg,]
    #
    #establish layout for desired number of plots on the page
    graphics::layout(mat = matrix(1:nrow(subConfig), ncol=1))
    
    for(k in 1:nrow(subConfig)){
      
      #extracting plot parameters to simplify eval (had difficulty wrapping plot_ly in with statement)
      sqlite_tblname <- subConfig$sqlite_tblname[k]
      yaxis_label <- subConfig$yaxis_label[k]
      
      #extracting ESP lines and quantiles
      plotData <- espData[[sqlite_tblname]]
      qData <- espQData[[sqlite_tblname]]
      
      
      #initialize plot and grid, adjust for margins:
      #  no spaces between plots in the vertical, bottom plot has dates
      if(k==1) par(mar=c(0,5,2,2)) #top plot
      if(k>1 & k < nrow(subConfig)) par(mar=c(0,5,0,2)) #middle plot
      if(k==nrow(subConfig)) par(mar=c(4,5,0,2)) #bottom plot
      
      plot.new(); box()
      
      
      #iterate through ESP traces and plot with transparency in grey
      
      
      # p[[k]] <-plot_ly(plotData, x=~date, y=~value,color=~year,
      #                  type = "scatter",mode="lines",
      #                  hoverinfo="x+y+text",
      #                  text=~paste0(year),
      #                  showlegend=F,name="",legendgroup="allESP",
      #                  line=list(color=colToHex("grey",0.4))) %>%
      #   layout(xaxis=list(title=""),yaxis=list(title=yaxis_label))
      # layout(xaxis=list(title=""),yaxis=list(title=yaxis_label),annotations=list(fcstStartAnnotation))
      
      #dummy to control all ESP
      # p[[k]] <-p[[k]]  %>% add_trace(data = plotData[1,], x=~date, y=~value,color=~year,
      #                                type = "scatter",mode="lines",
      #                                line=list(color=colToHex("grey",0.4)),
      #                                showlegend=!init,name="All ESP",legendgroup="allESP",
      #                                inherit=F)
      
      
      # Adding metrics if any current selected
      # if( length(metrics) != 0){
      #   for( metric in metrics){
      #     lineData <- qData[, c("date",metric)]
      #     names(lineData) <- c("date", "value")
      #     #The line type, as specified in the global.R script
      #     lty_plotly <- metricsToCompute$lty_plotly[metricsToCompute$metric==metric]
      #     
      #     p[[k]] <- p[[k]] %>% 
      #       add_trace(data = lineData,x=~date, y=~value,
      #                 type = "scatter",mode="lines",
      #                 line=list(dash=lty_plotly,color=colToHex("black",0.7)), name=metric,
      #                 legendgroup=metric, showlegend=!init,inherit = F)
      #   }
      # }
      
      #Adding selected ESP years
      # if( length(selectedYrs) != 0){
      #   
      #   if(length(selectedYrs) > 9)
      #     cat("\n\tCan only plot up to 9 ESP years at once and preserve color scheme.\n\tPlease reduce number of selected years.")
      #   
      #   
      #   for( selectedYr in selectedYrs){
      #     lineData <- plotData[plotData$year == selectedYr, c("date","value")]
      #     
      #     p[[k]] <- p[[k]] %>% 
      #       add_trace(data = lineData,x=~date, y=~value,
      #                 line=list(color=getColor(selectedYr,selectedYrs)),
      #                 type = "scatter",mode="lines",name=selectedYr,
      #                 legendgroup=selectedYr, showlegend=!init,inherit = F)
      #   }
      # }
      
      # init <- T
    } #end for loop, subplot
    
    
  }  #End loop of pdf pages
  
  #save pdf
  dev.off()
  
  return(subplot(p,nrows = length(p), shareX = T, titleY = T, widths = 1))
}


